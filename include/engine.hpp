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
        book.update(in);
        const Signal sig = decide(book);
        if (sig == Signal::NO_SIGNAL)
            return ProcessResult::NO_SIGNAL;
        out.instrument_id = in.instrument_id;
        out.price         = (sig == Signal::BUY) ? book.ask_price : book.bid_price;
        out.qty           = 10;
        out.side          = (sig == Signal::BUY) ? 0 : 1;
        out.seq_no        = in.seq_no;
        return ProcessResult::ORDER_EMITTED;
    }
};
