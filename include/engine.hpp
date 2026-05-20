#pragma once
#include ""book.hpp""
#include ""strategy.hpp""
#include ""risk.hpp""
#include ""wire.hpp""

struct TradingEngine {
    OrderBook  book;
    RiskGuard  risk;

    [[nodiscard]]
    ProcessResult process(const MarketPacket& in, OrderPacket& out) noexcept {
        if (!book.update(in))
            return ProcessResult::INVALID_FRAME;
        const Signal   sig         = decide(book);
        if (sig == Signal::NO_SIGNAL)
            return ProcessResult::NO_SIGNAL;
        const int32_t  order_price = (sig == Signal::BUY) ? book.ask_price : book.bid_price;
        const uint32_t order_qty   = 10;
        if (!risk.check(sig, order_price, order_qty))
            return ProcessResult::RISK_REJECTED;
        risk.commit(sig, order_price, order_qty);
        out.instrument_id = in.instrument_id;
        out.price         = order_price;
        out.qty           = order_qty;
        out.side          = (sig == Signal::BUY) ? 0 : 1;
        out.seq_no        = in.seq_no;
        return ProcessResult::ORDER_EMITTED;
    }
};
