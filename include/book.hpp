#pragma once
#include ""wire.hpp""
#include <cstdint>

struct OrderBook {
    int32_t  bid_price = 0;
    int32_t  ask_price = 0;
    uint32_t bid_qty   = 0;
    uint32_t ask_qty   = 0;

    bool update(const MarketPacket& pkt) noexcept;
    bool has_data() const noexcept { return bid_price > 0; }
    int32_t spread() const noexcept { return ask_price - bid_price; }
};
