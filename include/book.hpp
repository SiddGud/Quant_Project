#pragma once
#include "wire.hpp"
#include <cstdint>

// ─────────────────────────────────────────────────────────────────────────────
// L2 Order Book
//
// Tracks the best bid and best ask from incoming market-data packets.
// Fixed-size, no heap allocation — designed for a predictable memory footprint.
//
// In the original PulseBook this was a fixed-depth array book fed via DPDK
// mbufs. Here the same state is maintained; the only difference is the packet
// arrives as a stack-local struct instead of a DMA ring buffer.
// ─────────────────────────────────────────────────────────────────────────────

struct OrderBook {
    // Best bid / ask state (top of book)
    int32_t  bid_price = 0;
    int32_t  ask_price = 0;
    uint32_t bid_qty   = 0;
    uint32_t ask_qty   = 0;

    // Update the book with a new market packet.
    // Validates that ask > bid before applying the update.
    // Returns false if the packet looks malformed.
    [[nodiscard]]
    bool update(const MarketPacket& pkt) noexcept {
        // Basic sanity: ask must be strictly above bid, both positive
        if (pkt.ask_price <= pkt.bid_price || pkt.bid_price <= 0)
            return false;

        bid_price = pkt.bid_price;
        ask_price = pkt.ask_price;
        bid_qty   = pkt.bid_qty;
        ask_qty   = pkt.ask_qty;
        return true;
    }

    // Spread in ticks
    [[nodiscard]] int32_t spread() const noexcept { return ask_price - bid_price; }

    // True once we have seen at least one valid update
    [[nodiscard]] bool has_data() const noexcept { return bid_price > 0; }
};
