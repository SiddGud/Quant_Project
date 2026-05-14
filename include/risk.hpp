#pragma once
#include ""strategy.hpp""
#include <cstdint>

// RiskGuard applies pre-trade checks before any order is emitted.
// check() is side-effect free. commit() updates state.
// Call check() first, only call commit() if the order is accepted.
struct RiskGuard {
    int32_t  max_position  = 100;
    uint64_t max_notional  = 10'000'000ULL;
    int32_t  net_position  = 0;
    uint64_t notional_used = 0;

    [[nodiscard]]
    bool check(Signal sig, int32_t price, uint32_t qty) const noexcept {
        if (sig == Signal::NO_SIGNAL) return false;
        uint64_t order_notional = static_cast<uint64_t>(price) * qty;
        if (notional_used + order_notional > max_notional) return false;
        int32_t delta   = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                                : -static_cast<int32_t>(qty);
        int32_t new_pos = net_position + delta;
        if (new_pos > max_position || new_pos < -max_position) return false;
        return true;
    }

    void commit(Signal sig, int32_t price, uint32_t qty) noexcept {
        notional_used += static_cast<uint64_t>(price) * qty;
        int32_t delta  = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                               : -static_cast<int32_t>(qty);
        net_position  += delta;
    }

    void reset() noexcept { net_position = 0; notional_used = 0; }
};
