#pragma once
#include "strategy.hpp"
#include <cstdint>

// ─────────────────────────────────────────────────────────────────────────────
// Risk Guard
//
// Inline pre-trade risk checks — no database calls, no network hops.
// Blocks an order if it would breach position or notional limits.
//
// This is the same "inline risk check" concept from the original PulseBook.
// In real HFT systems this check sits in the hot path and must complete in
// single-digit nanoseconds.
//
// Limits:
//   max_position  — max net long or short (in lots)
//   max_notional  — max total traded value (price × qty)
// ─────────────────────────────────────────────────────────────────────────────

struct RiskGuard {
    // Configurable limits
    int32_t  max_position = 100;
    uint64_t max_notional = 10'000'000ULL;

    // Live state (reset between runs)
    int32_t  net_position  = 0;
    uint64_t notional_used = 0;

    // Check whether a proposed order passes risk.
    // Returns true if the order is allowed.
    // Does NOT update state — call commit() only after the order is accepted.
    [[nodiscard]]
    bool check(Signal sig, int32_t price, uint32_t qty) const noexcept {
        if (sig == Signal::NO_SIGNAL) return false;  // nothing to check

        // Notional check
        uint64_t order_notional = static_cast<uint64_t>(price) * qty;
        if (notional_used + order_notional > max_notional) return false;

        // Position check
        int32_t delta = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                              : -static_cast<int32_t>(qty);
        int32_t new_pos = net_position + delta;
        if (new_pos > max_position || new_pos < -max_position) return false;

        return true;
    }

    // Apply the order to live state (called after check() returns true).
    void commit(Signal sig, int32_t price, uint32_t qty) noexcept {
        notional_used += static_cast<uint64_t>(price) * qty;
        int32_t delta  = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                               : -static_cast<int32_t>(qty);
        net_position  += delta;
    }

    void reset() noexcept {
        net_position  = 0;
        notional_used = 0;
    }
};
