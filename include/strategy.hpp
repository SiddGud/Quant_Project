#pragma once
#include ""book.hpp""
#include <cstdint>

enum class Signal : uint8_t {
    NO_SIGNAL = 0,
    BUY       = 1,
    SELL      = 2,
};

[[nodiscard]]
inline Signal decide(const OrderBook& book) noexcept {
    if (!book.has_data()) return Signal::NO_SIGNAL;

    const double bq = book.bid_qty;
    const double aq = book.ask_qty;

    if (bq > aq * 1.5) return Signal::BUY;
    if (aq > bq * 1.5) return Signal::SELL;

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
