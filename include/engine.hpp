#pragma once
#include ""book.hpp""
#include ""strategy.hpp""
#include ""risk.hpp""
#include ""wire.hpp""

struct TradingEngine {
    OrderBook  book;
    RiskGuard  risk;

    [[nodiscard]]
    ProcessResult process(const MarketPacket& in, OrderPacket& out) noexcept;
};
