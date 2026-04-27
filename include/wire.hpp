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

#pragma pack(pop)
