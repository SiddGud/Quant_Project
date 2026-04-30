#pragma once
#include <cstdint>

#pragma pack(push, 1)

struct MarketPacket {
    uint16_t instrument_id;
    int32_t  bid_price;
    int32_t  ask_price;
    uint32_t bid_qty;
    uint32_t ask_qty;
    uint64_t seq_no;
};

static_assert(sizeof(MarketPacket) == 26);

struct OrderPacket {
    uint16_t instrument_id;
    int32_t  price;
    uint32_t qty;
    uint8_t  side;
    uint64_t seq_no;
};

static_assert(sizeof(OrderPacket) == 19);

#pragma pack(pop)

enum class ProcessResult : uint8_t {
    ORDER_EMITTED  = 0,
    NO_SIGNAL      = 1,
    RISK_REJECTED  = 2,
    INVALID_FRAME  = 3,
};

inline const char* result_str(ProcessResult r) {
    switch (r) {
        case ProcessResult::ORDER_EMITTED: return "ORDER_EMITTED";
        case ProcessResult::NO_SIGNAL:     return "NO_SIGNAL";
        case ProcessResult::RISK_REJECTED: return "RISK_REJECTED";
        case ProcessResult::INVALID_FRAME: return "INVALID_FRAME";
    }
    return "UNKNOWN";
}
