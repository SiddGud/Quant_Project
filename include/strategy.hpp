#pragma once
#include "book.hpp"

// ─────────────────────────────────────────────────────────────────────────────
// Imbalance Strategy
//
// Reads visible bid/ask quantities from the book and emits a directional
// signal.  The threshold is intentionally simple — this is a controlled
// workload for benchmarking the engine hot-path, not a profitable alpha.
//
// Same logic as the original PulseBook imbalance strategy, just without
// the DPDK packet-path wrapper.
//
// Decision rules:
//   bid_qty > ask_qty * IMBALANCE_THRESHOLD  →  BUY
//   ask_qty > bid_qty * IMBALANCE_THRESHOLD  →  SELL
//   otherwise                                →  NO_SIGNAL
// ─────────────────────────────────────────────────────────────────────────────

enum class Signal : uint8_t {
    NO_SIGNAL = 0,
    BUY       = 1,
    SELL      = 2,
};

// Imbalance threshold: one side must be 1.5× stronger to generate a signal.
// Stored as a rational (3/2) to avoid floating-point in the hot path.
constexpr uint32_t IMBALANCE_NUM   = 3;
constexpr uint32_t IMBALANCE_DENOM = 2;

[[nodiscard]]
inline Signal decide(const OrderBook& book) noexcept {
    if (!book.has_data()) return Signal::NO_SIGNAL;

    const uint64_t bq = book.bid_qty;
    const uint64_t aq = book.ask_qty;

    // bid_qty > ask_qty * (3/2)  →  BUY
    if (bq * IMBALANCE_DENOM > aq * IMBALANCE_NUM) return Signal::BUY;

    // ask_qty > bid_qty * (3/2)  →  SELL
    if (aq * IMBALANCE_DENOM > bq * IMBALANCE_NUM) return Signal::SELL;

    return Signal::NO_SIGNAL;
}

inline const char* signal_str(Signal s) {
    switch (s) {
        case Signal::BUY:       return "BUY";
        case Signal::SELL:      return "SELL";
        case Signal::NO_SIGNAL: return "NO_SIGNAL";
    }
    return "UNKNOWN";
}
