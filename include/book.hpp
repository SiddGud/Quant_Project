#pragma once
#include "wire.hpp"
#include <cstdint>

struct OrderBook {
    int32_t  bid_price = 0;
    int32_t  ask_price = 0;
    uint32_t bid_qty   = 0;
    uint32_t ask_qty   = 0;

    [[nodiscard]]
    bool update(const MarketPacket& pkt) noexcept {
        if (pkt.ask_price <= pkt.bid_price || pkt.bid_price <= 0)
            return false;
        bid_price = pkt.bid_price;
        ask_price = pkt.ask_price;
        bid_qty   = pkt.bid_qty;
        ask_qty   = pkt.ask_qty;
        return true;
    }

    bool    has_data() const noexcept { return bid_price > 0; }
    int32_t spread()   const noexcept { return ask_price - bid_price; }
};
