#pragma once
#include ""strategy.hpp""
#include <cstdint>

struct RiskGuard {
    int32_t  max_position  = 100;
    uint64_t max_notional  = 10'000'000ULL;
    int32_t  net_position  = 0;
    uint64_t notional_used = 0;

    [[nodiscard]]
    bool check(Signal sig, int32_t price, uint32_t qty) const noexcept {
        if (sig == Signal::NO_SIGNAL) return false;
        int32_t delta   = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                                : -static_cast<int32_t>(qty);
        int32_t new_pos = net_position + delta;
        if (new_pos > max_position || new_pos < -max_position) return false;
        return true;
    }

    void commit(Signal sig, int32_t price, uint32_t qty) noexcept {
        int32_t delta  = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                               : -static_cast<int32_t>(qty);
        net_position  += delta;
        notional_used += static_cast<uint64_t>(price) * qty;
    }

    void reset() noexcept { net_position = 0; notional_used = 0; }
};
