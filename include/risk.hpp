#pragma once
#include ""strategy.hpp""
#include <cstdint>

struct RiskGuard {
    int32_t  max_position = 100;
    uint64_t max_notional = 10'000'000ULL;
    int32_t  net_position = 0;
    uint64_t notional_used = 0;

    void reset() noexcept {
        net_position  = 0;
        notional_used = 0;
    }
};
