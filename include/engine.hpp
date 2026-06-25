#pragma once
#include "book.hpp"
#include "risk.hpp"
#include "strategy.hpp"
#include "wire.hpp"

struct TradingEngine {
    OrderBook book;
    RiskGuard risk;

    uint64_t packets_in     = 0;
    uint64_t orders_out     = 0;
    uint64_t no_signals     = 0;
    uint64_t risk_rejects   = 0;
    uint64_t invalid_frames = 0;

    [[nodiscard]]
    ProcessResult process(const MarketPacket& in, OrderPacket& out) noexcept {
        ++packets_in;

        if (!book.update(in)) {
            ++invalid_frames;
            return ProcessResult::INVALID_FRAME;
        }

        const Signal sig = decide(book);
        if (sig == Signal::NO_SIGNAL) {
            ++no_signals;
            return ProcessResult::NO_SIGNAL;
        }

        const int32_t  order_price = (sig == Signal::BUY) ? book.ask_price : book.bid_price;
        const uint32_t order_qty   = 10;

        if (!risk.check(sig, order_price, order_qty)) {
            ++risk_rejects;
            return ProcessResult::RISK_REJECTED;
        }
        risk.commit(sig, order_price, order_qty);

        out.instrument_id = in.instrument_id;
        out.price         = order_price;
        out.qty           = order_qty;
        out.side          = (sig == Signal::BUY) ? 0 : 1;
        out.seq_no        = in.seq_no;

        ++orders_out;
        return ProcessResult::ORDER_EMITTED;
    }

    void reset_stats() noexcept {
        packets_in = orders_out = no_signals = risk_rejects = invalid_frames = 0;
        risk.reset();
    }
};
