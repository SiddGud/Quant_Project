#pragma once
#include ""book.hpp""
#include <cstdint>

enum class Signal : uint8_t {
    NO_SIGNAL = 0,
    BUY       = 1,
    SELL      = 2,
};

constexpr uint32_t IMBALANCE_NUM   = 3;
constexpr uint32_t IMBALANCE_DENOM = 2;

[[nodiscard]]
inline Signal decide(const OrderBook& book) noexcept {
    if (!book.has_data()) return Signal::NO_SIGNAL;

    const uint64_t bq = book.bid_qty;
    const uint64_t aq = book.ask_qty;

    if (bq * IMBALANCE_DENOM > aq * IMBALANCE_NUM) return Signal::BUY;
    if (aq * IMBALANCE_DENOM > bq * IMBALANCE_NUM) return Signal::SELL;

    return Signal::NO_SIGNAL;
}

inline const char* signal_str(Signal s) {
    switch (s) {
        case Signal::BUY:       return ""BUY"";
        case Signal::SELL:      return ""SELL"";
        case Signal::NO_SIGNAL: return ""NO_SIGNAL"";
    }
    return ""UNKNOWN"";
}
