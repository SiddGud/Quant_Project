#pragma once
#include <cstdint>

// ─────────────────────────────────────────────────────────────────────────────
// Wire Protocol
//
// Fixed-size, POD structs that can be cast directly from raw bytes.
// No dynamic allocation, no serialisation overhead — same design philosophy
// as the 62-byte Ethernet frames used in production HFT systems.
// ─────────────────────────────────────────────────────────────────────────────

#pragma pack(push, 1)

// Inbound market-data packet  (26 bytes)
struct MarketPacket {
    uint16_t instrument_id;  // symbol index
    int32_t  bid_price;      // best bid in integer ticks
    int32_t  ask_price;      // best ask in integer ticks
    uint32_t bid_qty;        // visible bid quantity
    uint32_t ask_qty;        // visible ask quantity
    uint64_t seq_no;         // monotonic sequence number
};
static_assert(sizeof(MarketPacket) == 26, "MarketPacket size mismatch");

// Outbound order packet  (19 bytes)
struct OrderPacket {
    uint16_t instrument_id;
    int32_t  price;
    uint32_t qty;
    uint8_t  side;   // 0 = BUY, 1 = SELL
    uint64_t seq_no;
};
static_assert(sizeof(OrderPacket) == 19, "OrderPacket size mismatch");

#pragma pack(pop)

// Result codes (mirrors INVALID_FRAME / RISK_REJECT semantics from original)
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
