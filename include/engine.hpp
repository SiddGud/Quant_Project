#pragma once
#include "book.hpp"
#include "strategy.hpp"
#include "risk.hpp"
#include "wire.hpp"

// ─────────────────────────────────────────────────────────────────────────────
// Trading Engine  —  the hot path
//
// Ties together the order book, strategy, and risk guard into a single
// process() call.  This is the function that gets benchmarked.
//
// Hot-path sequence (identical in structure to the original PulseBook):
//
//   MarketPacket in
//       │
//       ▼
//   Validate frame           → INVALID_FRAME if bad
//       │
//       ▼
//   OrderBook::update()      → updates bid/ask state
//       │
//       ▼
//   Strategy::decide()       → NO_SIGNAL / BUY / SELL
//       │
//       ▼
//   RiskGuard::check()       → RISK_REJECTED if limit breached
//       │
//       ▼
//   Encode OrderPacket        → ORDER_EMITTED
//
// Design constraints (same as original):
//   • No heap allocation inside process()
//   • No I/O or logging inside process()
//   • All state lives in this struct (no globals)
// ─────────────────────────────────────────────────────────────────────────────

struct TradingEngine {
    OrderBook  book;
    RiskGuard  risk;

    uint64_t packets_in    = 0;
    uint64_t orders_out    = 0;
    uint64_t no_signals    = 0;
    uint64_t risk_rejects  = 0;
    uint64_t invalid_frames = 0;

    // Process one market packet.
    // Fills `out` and returns ORDER_EMITTED if an order was generated.
    // `out` is only valid when ORDER_EMITTED is returned.
    [[nodiscard]]
    ProcessResult process(const MarketPacket& in, OrderPacket& out) noexcept {
        ++packets_in;

        // ── 1. Frame validation ──────────────────────────────────────────────
        // Reject packets where ask ≤ bid or prices are non-positive.
        // (Mirrors INVALID_FRAME path in original PulseBook.)
        if (!book.update(in)) {
            ++invalid_frames;
            return ProcessResult::INVALID_FRAME;
        }

        // ── 2. Strategy decision ─────────────────────────────────────────────
        const Signal sig = decide(book);
        if (sig == Signal::NO_SIGNAL) {
            ++no_signals;
            return ProcessResult::NO_SIGNAL;
        }

        // ── 3. Inline risk check ─────────────────────────────────────────────
        // Use mid-price as order price (simplified; real systems use limit price)
        const int32_t  order_price = (sig == Signal::BUY) ? book.ask_price
                                                           : book.bid_price;
        const uint32_t order_qty   = 10;  // fixed lot size for V1

        if (!risk.check(sig, order_price, order_qty)) {
            ++risk_rejects;
            return ProcessResult::RISK_REJECTED;
        }
        risk.commit(sig, order_price, order_qty);

        // ── 4. Encode order packet ───────────────────────────────────────────
        out.instrument_id = in.instrument_id;
        out.price         = order_price;
        out.qty           = order_qty;
        out.side          = (sig == Signal::BUY) ? 0 : 1;
        out.seq_no        = in.seq_no;

        ++orders_out;
        return ProcessResult::ORDER_EMITTED;
    }

    void reset_stats() noexcept {
        packets_in     = 0;
        orders_out     = 0;
        no_signals     = 0;
        risk_rejects   = 0;
        invalid_frames = 0;
        risk.reset();
    }
};
