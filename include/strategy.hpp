#pragma once
#include ""book.hpp""
#include <cstdint>

enum class Signal : uint8_t {
    NO_SIGNAL = 0,
    BUY       = 1,
    SELL      = 2,
};

inline const char* signal_str(Signal s) {
    switch (s) {
        case Signal::BUY:       return ""BUY"";
        case Signal::SELL:      return ""SELL"";
        case Signal::NO_SIGNAL: return ""NO_SIGNAL"";
    }
    return ""UNKNOWN"";
}
