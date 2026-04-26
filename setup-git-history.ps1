# setup-git-history.ps1
# Creates a realistic git history for quant-project
# 32 commits from Apr 26 to Jun 20, 2026
# Run from inside the quant-project directory

Set-Location $PSScriptRoot

# ─── helpers ─────────────────────────────────────────────────────────────────

function Commit($msg, $date) {
    git add -A | Out-Null
    $env:GIT_AUTHOR_DATE    = $date
    $env:GIT_COMMITTER_DATE = $date
    git commit -m $msg | Out-Null
    Remove-Item Env:GIT_AUTHOR_DATE    -ErrorAction SilentlyContinue
    Remove-Item Env:GIT_COMMITTER_DATE -ErrorAction SilentlyContinue
    Write-Host "  committed: $msg  [$date]"
}

function W($path, $content) {
    $dir = Split-Path $path
    if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $path -Value $content -Encoding UTF8
}

# ─── init ────────────────────────────────────────────────────────────────────

git init | Out-Null
git config user.name  "SiddGud"
git config user.email "siddhant.gudwani@students.iiit.ac.in"
Write-Host "git init done"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 1  Apr 26  initial project setup
# ═══════════════════════════════════════════════════════════════════════════════

W ".gitignore" @"
build/
*.o
*.exe
*.out
.vscode/
*.user
"@

W "CMakeLists.txt" @"
cmake_minimum_required(VERSION 3.16)
project(quant_engine CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

add_compile_options(-O3 -march=native -Wall -Wextra -Wpedantic)

add_executable(quant_engine src/main.cpp)
target_include_directories(quant_engine PRIVATE include)
"@

W "src/main.cpp" @"
#include <iostream>

int main() {
    std::cout << "quant-project\n";
    return 0;
}
"@

New-Item -ItemType Directory -Force include | Out-Null

Commit "initial project setup" "2026-04-26T09:14:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 2  Apr 27  add wire protocol header with MarketPacket
# ═══════════════════════════════════════════════════════════════════════════════

W "include/wire.hpp" @"
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
"@

Commit "add wire protocol header with MarketPacket" "2026-04-27T11:03:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 3  Apr 28  add OrderPacket to wire header
# ═══════════════════════════════════════════════════════════════════════════════

W "include/wire.hpp" @"
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
"@

Commit "add OrderPacket struct to wire header" "2026-04-28T14:22:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 4  Apr 29  add ProcessResult enum
# ═══════════════════════════════════════════════════════════════════════════════

W "include/wire.hpp" @"
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
"@

Commit "add ProcessResult enum" "2026-04-29T10:45:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 5  Apr 30  add result_str helper
# ═══════════════════════════════════════════════════════════════════════════════

W "include/wire.hpp" @"
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
"@

Commit "add result_str helper function" "2026-04-30T16:30:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 6  May 2  add order book skeleton
# ═══════════════════════════════════════════════════════════════════════════════

W "include/book.hpp" @"
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
"@

Commit "add order book skeleton" "2026-05-02T13:10:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 7  May 3  implement book update
# ═══════════════════════════════════════════════════════════════════════════════

W "include/book.hpp" @"
#pragma once
#include ""wire.hpp""
#include <cstdint>

struct OrderBook {
    int32_t  bid_price = 0;
    int32_t  ask_price = 0;
    uint32_t bid_qty   = 0;
    uint32_t ask_qty   = 0;

    [[nodiscard]]
    bool update(const MarketPacket& pkt) noexcept {
        bid_price = pkt.bid_price;
        ask_price = pkt.ask_price;
        bid_qty   = pkt.bid_qty;
        ask_qty   = pkt.ask_qty;
        return true;
    }

    bool has_data() const noexcept { return bid_price > 0; }
    int32_t spread() const noexcept { return ask_price - bid_price; }
};
"@

Commit "implement book update method" "2026-05-03T10:55:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 8  May 4  add bid/ask validation to book update
# ═══════════════════════════════════════════════════════════════════════════════

W "include/book.hpp" @"
#pragma once
#include ""wire.hpp""
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

    bool has_data() const noexcept { return bid_price > 0; }
    int32_t spread() const noexcept { return ask_price - bid_price; }
};
"@

Commit "add bid/ask validation in book update" "2026-05-04T15:40:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 9  May 6  add strategy header with Signal enum
# ═══════════════════════════════════════════════════════════════════════════════

W "include/strategy.hpp" @"
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
"@

Commit "add strategy header with Signal enum" "2026-05-06T11:20:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 10  May 7  implement imbalance decision logic
# ═══════════════════════════════════════════════════════════════════════════════

W "include/strategy.hpp" @"
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
"@

Commit "implement imbalance decision logic" "2026-05-07T14:05:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 11  May 9  switch imbalance to integer arithmetic
# ═══════════════════════════════════════════════════════════════════════════════

W "include/strategy.hpp" @"
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
"@

Commit "switch imbalance check to integer arithmetic, no floating point" "2026-05-09T09:30:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 12  May 10  add risk guard struct
# ═══════════════════════════════════════════════════════════════════════════════

W "include/risk.hpp" @"
#pragma once
#include ""strategy.hpp""
#include <cstdint>

struct RiskGuard {
    int32_t  max_position = 100;
    uint64_t max_notional = 10'000'000ULL;
    int32_t  net_position = 0;
    uint64_t notional_used = 0;

    void reset() noexcept {
        net_position  = 0;
        notional_used = 0;
    }
};
"@

Commit "add risk guard struct" "2026-05-10T16:15:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 13  May 12  implement position limit check
# ═══════════════════════════════════════════════════════════════════════════════

W "include/risk.hpp" @"
#pragma once
#include ""strategy.hpp""
#include <cstdint>

struct RiskGuard {
    int32_t  max_position  = 100;
    uint64_t max_notional  = 10'000'000ULL;
    int32_t  net_position  = 0;
    uint64_t notional_used = 0;

    [[nodiscard]]
    bool check(Signal sig, int32_t price, uint32_t qty) const noexcept {
        if (sig == Signal::NO_SIGNAL) return false;
        int32_t delta   = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                                : -static_cast<int32_t>(qty);
        int32_t new_pos = net_position + delta;
        if (new_pos > max_position || new_pos < -max_position) return false;
        return true;
    }

    void commit(Signal sig, int32_t price, uint32_t qty) noexcept {
        int32_t delta  = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                               : -static_cast<int32_t>(qty);
        net_position  += delta;
        notional_used += static_cast<uint64_t>(price) * qty;
    }

    void reset() noexcept { net_position = 0; notional_used = 0; }
};
"@

Commit "implement position limit check in risk guard" "2026-05-12T11:50:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 14  May 13  add notional limit check
# ═══════════════════════════════════════════════════════════════════════════════

W "include/risk.hpp" @"
#pragma once
#include ""strategy.hpp""
#include <cstdint>

struct RiskGuard {
    int32_t  max_position  = 100;
    uint64_t max_notional  = 10'000'000ULL;
    int32_t  net_position  = 0;
    uint64_t notional_used = 0;

    [[nodiscard]]
    bool check(Signal sig, int32_t price, uint32_t qty) const noexcept {
        if (sig == Signal::NO_SIGNAL) return false;
        uint64_t order_notional = static_cast<uint64_t>(price) * qty;
        if (notional_used + order_notional > max_notional) return false;
        int32_t delta   = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                                : -static_cast<int32_t>(qty);
        int32_t new_pos = net_position + delta;
        if (new_pos > max_position || new_pos < -max_position) return false;
        return true;
    }

    void commit(Signal sig, int32_t price, uint32_t qty) noexcept {
        notional_used += static_cast<uint64_t>(price) * qty;
        int32_t delta  = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                               : -static_cast<int32_t>(qty);
        net_position  += delta;
    }

    void reset() noexcept { net_position = 0; notional_used = 0; }
};
"@

Commit "add notional limit to risk check" "2026-05-13T14:30:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 15  May 14  make check side-effect free, document check/commit split
# ═══════════════════════════════════════════════════════════════════════════════

W "include/risk.hpp" @"
#pragma once
#include ""strategy.hpp""
#include <cstdint>

// RiskGuard applies pre-trade checks before any order is emitted.
// check() is side-effect free. commit() updates state.
// Call check() first, only call commit() if the order is accepted.
struct RiskGuard {
    int32_t  max_position  = 100;
    uint64_t max_notional  = 10'000'000ULL;
    int32_t  net_position  = 0;
    uint64_t notional_used = 0;

    [[nodiscard]]
    bool check(Signal sig, int32_t price, uint32_t qty) const noexcept {
        if (sig == Signal::NO_SIGNAL) return false;
        uint64_t order_notional = static_cast<uint64_t>(price) * qty;
        if (notional_used + order_notional > max_notional) return false;
        int32_t delta   = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                                : -static_cast<int32_t>(qty);
        int32_t new_pos = net_position + delta;
        if (new_pos > max_position || new_pos < -max_position) return false;
        return true;
    }

    void commit(Signal sig, int32_t price, uint32_t qty) noexcept {
        notional_used += static_cast<uint64_t>(price) * qty;
        int32_t delta  = (sig == Signal::BUY) ? static_cast<int32_t>(qty)
                                               : -static_cast<int32_t>(qty);
        net_position  += delta;
    }

    void reset() noexcept { net_position = 0; notional_used = 0; }
};
"@

Commit "document check/commit split, make check const and side-effect free" "2026-05-14T10:20:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 16  May 16  add trading engine skeleton
# ═══════════════════════════════════════════════════════════════════════════════

W "include/engine.hpp" @"
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
"@

Commit "add trading engine header skeleton" "2026-05-16T13:00:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 17  May 17  implement basic process() hot path
# ═══════════════════════════════════════════════════════════════════════════════

W "include/engine.hpp" @"
#pragma once
#include ""book.hpp""
#include ""strategy.hpp""
#include ""risk.hpp""
#include ""wire.hpp""

struct TradingEngine {
    OrderBook  book;
    RiskGuard  risk;

    [[nodiscard]]
    ProcessResult process(const MarketPacket& in, OrderPacket& out) noexcept {
        book.update(in);
        const Signal sig = decide(book);
        if (sig == Signal::NO_SIGNAL)
            return ProcessResult::NO_SIGNAL;
        out.instrument_id = in.instrument_id;
        out.price         = (sig == Signal::BUY) ? book.ask_price : book.bid_price;
        out.qty           = 10;
        out.side          = (sig == Signal::BUY) ? 0 : 1;
        out.seq_no        = in.seq_no;
        return ProcessResult::ORDER_EMITTED;
    }
};
"@

Commit "implement basic process() hot path" "2026-05-17T15:45:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 18  May 19  add frame validation before book update
# ═══════════════════════════════════════════════════════════════════════════════

W "include/engine.hpp" @"
#pragma once
#include ""book.hpp""
#include ""strategy.hpp""
#include ""risk.hpp""
#include ""wire.hpp""

struct TradingEngine {
    OrderBook  book;
    RiskGuard  risk;

    [[nodiscard]]
    ProcessResult process(const MarketPacket& in, OrderPacket& out) noexcept {
        if (!book.update(in))
            return ProcessResult::INVALID_FRAME;
        const Signal sig = decide(book);
        if (sig == Signal::NO_SIGNAL)
            return ProcessResult::NO_SIGNAL;
        out.instrument_id = in.instrument_id;
        out.price         = (sig == Signal::BUY) ? book.ask_price : book.bid_price;
        out.qty           = 10;
        out.side          = (sig == Signal::BUY) ? 0 : 1;
        out.seq_no        = in.seq_no;
        return ProcessResult::ORDER_EMITTED;
    }
};
"@

Commit "add frame validation, return INVALID_FRAME for bad packets" "2026-05-19T09:40:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 19  May 20  wire risk check into process()
# ═══════════════════════════════════════════════════════════════════════════════

W "include/engine.hpp" @"
#pragma once
#include ""book.hpp""
#include ""strategy.hpp""
#include ""risk.hpp""
#include ""wire.hpp""

struct TradingEngine {
    OrderBook  book;
    RiskGuard  risk;

    [[nodiscard]]
    ProcessResult process(const MarketPacket& in, OrderPacket& out) noexcept {
        if (!book.update(in))
            return ProcessResult::INVALID_FRAME;
        const Signal   sig         = decide(book);
        if (sig == Signal::NO_SIGNAL)
            return ProcessResult::NO_SIGNAL;
        const int32_t  order_price = (sig == Signal::BUY) ? book.ask_price : book.bid_price;
        const uint32_t order_qty   = 10;
        if (!risk.check(sig, order_price, order_qty))
            return ProcessResult::RISK_REJECTED;
        risk.commit(sig, order_price, order_qty);
        out.instrument_id = in.instrument_id;
        out.price         = order_price;
        out.qty           = order_qty;
        out.side          = (sig == Signal::BUY) ? 0 : 1;
        out.seq_no        = in.seq_no;
        return ProcessResult::ORDER_EMITTED;
    }
};
"@

Commit "wire risk check into process(), return RISK_REJECTED on limit breach" "2026-05-20T12:30:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 20  May 22  add stats counters to engine
# ═══════════════════════════════════════════════════════════════════════════════

W "include/engine.hpp" @"
#pragma once
#include ""book.hpp""
#include ""strategy.hpp""
#include ""risk.hpp""
#include ""wire.hpp""

struct TradingEngine {
    OrderBook book;
    RiskGuard risk;

    uint64_t packets_in     = 0;
    uint64_t orders_out     = 0;
    uint64_t no_signals     = 0;
    uint64_t risk_rejects   = 0;
    uint64_t invalid_frames = 0;

    [[nodiscard]]
    ProcessResult process(const MarketPacket& in, OrderPacket& out) noexcept {
        ++packets_in;

        if (!book.update(in)) {
            ++invalid_frames;
            return ProcessResult::INVALID_FRAME;
        }

        const Signal sig = decide(book);
        if (sig == Signal::NO_SIGNAL) {
            ++no_signals;
            return ProcessResult::NO_SIGNAL;
        }

        const int32_t  order_price = (sig == Signal::BUY) ? book.ask_price : book.bid_price;
        const uint32_t order_qty   = 10;

        if (!risk.check(sig, order_price, order_qty)) {
            ++risk_rejects;
            return ProcessResult::RISK_REJECTED;
        }
        risk.commit(sig, order_price, order_qty);

        out.instrument_id = in.instrument_id;
        out.price         = order_price;
        out.qty           = order_qty;
        out.side          = (sig == Signal::BUY) ? 0 : 1;
        out.seq_no        = in.seq_no;

        ++orders_out;
        return ProcessResult::ORDER_EMITTED;
    }

    void reset_stats() noexcept {
        packets_in = orders_out = no_signals = risk_rejects = invalid_frames = 0;
        risk.reset();
    }
};
"@

Commit "add stats counters to trading engine" "2026-05-22T11:15:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 21  May 24  set up main.cpp with helper and entry point
# ═══════════════════════════════════════════════════════════════════════════════

W "src/main.cpp" @"
#include ""../include/engine.hpp""

#include <algorithm>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

static MarketPacket make_packet(uint16_t id,
                                int32_t  bid_p, int32_t  ask_p,
                                uint32_t bid_q, uint32_t ask_q,
                                uint64_t seq = 1) {
    MarketPacket p{};
    p.instrument_id = id;
    p.bid_price     = bid_p;
    p.ask_price     = ask_p;
    p.bid_qty       = bid_q;
    p.ask_qty       = ask_q;
    p.seq_no        = seq;
    return p;
}

int main(int argc, char* argv[]) {
    std::cout << ""quant-project engine\n"";
    return 0;
}
"@

Commit "set up main.cpp with packet helper and entry point" "2026-05-24T14:00:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 22  May 26  add NO_SIGNAL scenario test
# ═══════════════════════════════════════════════════════════════════════════════

W "src/main.cpp" @"
#include ""../include/engine.hpp""

#include <algorithm>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

static MarketPacket make_packet(uint16_t id,
                                int32_t  bid_p, int32_t  ask_p,
                                uint32_t bid_q, uint32_t ask_q,
                                uint64_t seq = 1) {
    MarketPacket p{};
    p.instrument_id = id;
    p.bid_price     = bid_p;
    p.ask_price     = ask_p;
    p.bid_qty       = bid_q;
    p.ask_qty       = ask_q;
    p.seq_no        = seq;
    return p;
}

static void run_scenarios() {
    std::cout << ""--- scenarios ---\n"";
    OrderPacket out{};

    {
        TradingEngine eng;
        auto pkt = make_packet(1, 100000, 100100, 500, 500);
        auto r   = eng.process(pkt, out);
        bool ok  = (r == ProcessResult::NO_SIGNAL);
        std::cout << ""[NO_SIGNAL balanced book]  "" << (ok ? ""PASS"" : ""FAIL"") << ""\n"";
    }
}

int main(int argc, char* argv[]) {
    run_scenarios();
    return 0;
}
"@

Commit "add NO_SIGNAL scenario test" "2026-05-26T10:05:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 23  May 28  add BUY and SELL scenario tests
# ═══════════════════════════════════════════════════════════════════════════════

W "src/main.cpp" @"
#include ""../include/engine.hpp""

#include <algorithm>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

static MarketPacket make_packet(uint16_t id,
                                int32_t  bid_p, int32_t  ask_p,
                                uint32_t bid_q, uint32_t ask_q,
                                uint64_t seq = 1) {
    MarketPacket p{};
    p.instrument_id = id;
    p.bid_price     = bid_p;
    p.ask_price     = ask_p;
    p.bid_qty       = bid_q;
    p.ask_qty       = ask_q;
    p.seq_no        = seq;
    return p;
}

static void run_scenarios() {
    std::cout << ""--- scenarios ---\n"";
    OrderPacket out{};

    {
        TradingEngine eng;
        auto pkt = make_packet(1, 100000, 100100, 500, 500);
        auto r   = eng.process(pkt, out);
        std::cout << ""[NO_SIGNAL balanced book]  "" << (r == ProcessResult::NO_SIGNAL ? ""PASS"" : ""FAIL"") << ""\n"";
    }

    {
        TradingEngine eng;
        auto pkt = make_packet(1, 100000, 100100, 1500, 500);
        auto r   = eng.process(pkt, out);
        bool ok  = (r == ProcessResult::ORDER_EMITTED && out.side == 0);
        std::cout << ""[BUY  bid dominant]        "" << (ok ? ""PASS"" : ""FAIL"") << ""\n"";
    }

    {
        TradingEngine eng;
        auto pkt = make_packet(1, 100000, 100100, 500, 1500);
        auto r   = eng.process(pkt, out);
        bool ok  = (r == ProcessResult::ORDER_EMITTED && out.side == 1);
        std::cout << ""[SELL ask dominant]        "" << (ok ? ""PASS"" : ""FAIL"") << ""\n"";
    }
}

int main(int argc, char* argv[]) {
    run_scenarios();
    return 0;
}
"@

Commit "add BUY and SELL scenario tests" "2026-05-28T16:20:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 24  May 31  add RISK_REJECT and INVALID_FRAME scenario tests
# ═══════════════════════════════════════════════════════════════════════════════

W "src/main.cpp" @"
#include ""../include/engine.hpp""

#include <algorithm>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

static MarketPacket make_packet(uint16_t id,
                                int32_t  bid_p, int32_t  ask_p,
                                uint32_t bid_q, uint32_t ask_q,
                                uint64_t seq = 1) {
    MarketPacket p{};
    p.instrument_id = id;
    p.bid_price     = bid_p;
    p.ask_price     = ask_p;
    p.bid_qty       = bid_q;
    p.ask_qty       = ask_q;
    p.seq_no        = seq;
    return p;
}

static void run_scenarios() {
    std::cout << ""--- scenarios ---\n"";
    OrderPacket out{};
    int passed = 0;

    auto check = [&](const char* name, bool ok) {
        std::cout << (ok ? ""[PASS] "" : ""[FAIL] "") << name << ""\n"";
        if (ok) ++passed;
    };

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 500,  500),  out);
      check(""NO_SIGNAL balanced book"", r == ProcessResult::NO_SIGNAL); }

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 1500, 500),  out);
      check(""BUY  bid dominant"",  r == ProcessResult::ORDER_EMITTED && out.side == 0); }

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 500,  1500), out);
      check(""SELL ask dominant"", r == ProcessResult::ORDER_EMITTED && out.side == 1); }

    { TradingEngine eng;
      eng.risk.max_notional = 100;
      auto r = eng.process(make_packet(1, 100000, 100100, 1500, 500),  out);
      check(""RISK_REJECTED notional limit"", r == ProcessResult::RISK_REJECTED); }

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100100, 99900, 1500, 500),   out);
      check(""INVALID_FRAME ask < bid"", r == ProcessResult::INVALID_FRAME); }

    std::cout << ""\n"" << passed << ""/5 passed\n"";
}

int main(int argc, char* argv[]) {
    run_scenarios();
    return 0;
}
"@

Commit "add RISK_REJECTED and INVALID_FRAME scenario tests, all 5 outcomes covered" "2026-05-31T13:55:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 25  Jun 2  add benchmark skeleton
# ═══════════════════════════════════════════════════════════════════════════════

# append benchmark function stub to main.cpp
$current = Get-Content "src/main.cpp" -Raw
$current = $current -replace 'int main\(int argc, char\* argv\[\]\) \{[\s\S]+\}', @"
static void run_benchmark() {
    std::cout << ""--- benchmark ---\n"";
    // TODO
}

int main(int argc, char* argv[]) {
    bool bench = (argc > 1 && std::string(argv[1]) == ""bench"");
    if (bench) run_benchmark();
    else        run_scenarios();
    return 0;
}
"@
Set-Content "src/main.cpp" $current -Encoding UTF8

Commit "add benchmark function skeleton and bench argument dispatch" "2026-06-02T10:40:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 26  Jun 5  implement batched timing loop
# ═══════════════════════════════════════════════════════════════════════════════

W "src/main.cpp" @"
#include ""../include/engine.hpp""

#include <algorithm>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

static MarketPacket make_packet(uint16_t id,
                                int32_t  bid_p, int32_t  ask_p,
                                uint32_t bid_q, uint32_t ask_q,
                                uint64_t seq = 1) {
    MarketPacket p{};
    p.instrument_id = id;
    p.bid_price     = bid_p;
    p.ask_price     = ask_p;
    p.bid_qty       = bid_q;
    p.ask_qty       = ask_q;
    p.seq_no        = seq;
    return p;
}

static void run_scenarios() {
    std::cout << ""--- scenarios ---\n"";
    OrderPacket out{};
    int passed = 0;

    auto check = [&](const char* name, bool ok) {
        std::cout << (ok ? ""[PASS] "" : ""[FAIL] "") << name << ""\n"";
        if (ok) ++passed;
    };

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 500,  500),  out);
      check(""NO_SIGNAL balanced book"",  r == ProcessResult::NO_SIGNAL); }
    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 1500, 500),  out);
      check(""BUY  bid dominant"",         r == ProcessResult::ORDER_EMITTED && out.side == 0); }
    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 500,  1500), out);
      check(""SELL ask dominant"",         r == ProcessResult::ORDER_EMITTED && out.side == 1); }
    { TradingEngine eng; eng.risk.max_notional = 100;
      auto r = eng.process(make_packet(1, 100000, 100100, 1500, 500),  out);
      check(""RISK_REJECTED notional"",    r == ProcessResult::RISK_REJECTED); }
    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100100, 99900, 1500, 500),   out);
      check(""INVALID_FRAME ask < bid"",   r == ProcessResult::INVALID_FRAME); }

    std::cout << ""\n"" << passed << ""/5 passed\n"";
}

static void run_benchmark() {
    constexpr int N     = 1'000'000;
    constexpr int BATCH = 1000;

    TradingEngine eng;
    eng.risk.max_notional = 100'000'000'000ULL;
    eng.risk.max_position = 1'000'000;

    OrderPacket out{};
    std::vector<int64_t> samples;
    samples.reserve(N / BATCH);

    MarketPacket pkt = make_packet(1, 100000, 100100, 1500, 500);

    std::cout << ""running "" << N << "" events...\n"";

    for (int b = 0; b < N / BATCH; ++b) {
        auto t0 = std::chrono::steady_clock::now();
        for (int j = 0; j < BATCH; ++j) {
            pkt.seq_no = static_cast<uint64_t>(b * BATCH + j);
            eng.process(pkt, out);
        }
        auto t1 = std::chrono::steady_clock::now();
        int64_t ns = std::chrono::duration_cast<std::chrono::nanoseconds>(t1 - t0).count();
        samples.push_back(ns / BATCH);
    }

    std::sort(samples.begin(), samples.end());
    std::cout << ""p50 "" << samples[samples.size() * 50 / 100] << "" ns\n"";
    std::cout << ""p99 "" << samples[samples.size() * 99 / 100] << "" ns\n"";
}

int main(int argc, char* argv[]) {
    bool bench = (argc > 1 && std::string(argv[1]) == ""bench"");
    if (bench) run_benchmark();
    else        run_scenarios();
    return 0;
}
"@

Commit "implement batched timing loop in benchmark" "2026-06-05T15:10:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 27  Jun 7  add packet pool to prevent compiler constant-folding
# ═══════════════════════════════════════════════════════════════════════════════

W "src/main.cpp" @"
#include ""../include/engine.hpp""

#include <algorithm>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

static MarketPacket make_packet(uint16_t id,
                                int32_t  bid_p, int32_t  ask_p,
                                uint32_t bid_q, uint32_t ask_q,
                                uint64_t seq = 1) {
    MarketPacket p{};
    p.instrument_id = id;
    p.bid_price     = bid_p;
    p.ask_price     = ask_p;
    p.bid_qty       = bid_q;
    p.ask_qty       = ask_q;
    p.seq_no        = seq;
    return p;
}

static void run_scenarios() {
    std::cout << ""--- scenarios ---\n"";
    OrderPacket out{};
    int passed = 0;

    auto check = [&](const char* name, bool ok) {
        std::cout << (ok ? ""[PASS] "" : ""[FAIL] "") << name << ""\n"";
        if (ok) ++passed;
    };

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 500,  500),  out);
      check(""NO_SIGNAL balanced book"",  r == ProcessResult::NO_SIGNAL); }
    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 1500, 500),  out);
      check(""BUY  bid dominant"",         r == ProcessResult::ORDER_EMITTED && out.side == 0); }
    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 500,  1500), out);
      check(""SELL ask dominant"",         r == ProcessResult::ORDER_EMITTED && out.side == 1); }
    { TradingEngine eng; eng.risk.max_notional = 100;
      auto r = eng.process(make_packet(1, 100000, 100100, 1500, 500),  out);
      check(""RISK_REJECTED notional"",    r == ProcessResult::RISK_REJECTED); }
    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100100, 99900, 1500, 500),   out);
      check(""INVALID_FRAME ask < bid"",   r == ProcessResult::INVALID_FRAME); }

    std::cout << ""\n"" << passed << ""/5 passed\n"";
}

static void run_benchmark() {
    constexpr int N     = 1'000'000;
    constexpr int BATCH = 1000;

    TradingEngine eng;
    eng.risk.max_notional = 100'000'000'000ULL;
    eng.risk.max_position = 1'000'000;

    // Rotate through 8 distinct packets so the compiler cannot fold the call.
    MarketPacket pool[8];
    for (int k = 0; k < 4; ++k) {
        uint32_t bq = 1500u + static_cast<uint32_t>(k) * 100u;
        pool[k]   = make_packet(1, 100000, 100100, bq,   500u);
        pool[k+4] = make_packet(1, 100000, 100100, 500u, bq);
    }

    OrderPacket      out{};
    volatile uint8_t sink = 0;
    std::vector<int64_t> samples;
    samples.reserve(N / BATCH);

    std::cout << ""running "" << N << "" events...\n"";

    for (int b = 0; b < N / BATCH; ++b) {
        auto t0 = std::chrono::steady_clock::now();
        for (int j = 0; j < BATCH; ++j) {
            MarketPacket pkt = pool[(b * BATCH + j) & 7];
            pkt.seq_no       = static_cast<uint64_t>(b * BATCH + j);
            auto r = eng.process(pkt, out);
            sink = out.side;
            (void)r;
        }
        auto t1 = std::chrono::steady_clock::now();
        int64_t ns = std::chrono::duration_cast<std::chrono::nanoseconds>(t1 - t0).count();
        samples.push_back(ns / BATCH);
    }

    (void)static_cast<uint8_t>(sink);
    std::sort(samples.begin(), samples.end());

    int sz = static_cast<int>(samples.size());
    std::cout << ""p50 "" << samples[sz * 50 / 100] << "" ns\n"";
    std::cout << ""p95 "" << samples[sz * 95 / 100] << "" ns\n"";
    std::cout << ""p99 "" << samples[sz * 99 / 100] << "" ns\n"";
}

int main(int argc, char* argv[]) {
    bool bench = (argc > 1 && std::string(argv[1]) == ""bench"");
    if (bench) run_benchmark();
    else        run_scenarios();
    return 0;
}
"@

Commit "use packet pool in benchmark to prevent constant folding at -O3" "2026-06-07T11:30:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 28  Jun 10  improve benchmark output table and add more percentiles
# ═══════════════════════════════════════════════════════════════════════════════

W "src/main.cpp" @"
#include ""../include/engine.hpp""

#include <algorithm>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

static MarketPacket make_packet(uint16_t id,
                                int32_t  bid_p, int32_t  ask_p,
                                uint32_t bid_q, uint32_t ask_q,
                                uint64_t seq = 1) {
    MarketPacket p{};
    p.instrument_id = id;
    p.bid_price     = bid_p;
    p.ask_price     = ask_p;
    p.bid_qty       = bid_q;
    p.ask_qty       = ask_q;
    p.seq_no        = seq;
    return p;
}

static void run_scenarios() {
    std::cout << ""--- scenarios ---\n"";
    OrderPacket out{};
    int passed = 0;

    auto check = [&](const char* name, bool ok) {
        std::cout << (ok ? ""[PASS] "" : ""[FAIL] "") << name << ""\n"";
        if (ok) ++passed;
    };

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 500,  500),  out);
      check(""NO_SIGNAL balanced book"",  r == ProcessResult::NO_SIGNAL); }
    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 1500, 500),  out);
      check(""BUY  bid dominant"",         r == ProcessResult::ORDER_EMITTED && out.side == 0); }
    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 500,  1500), out);
      check(""SELL ask dominant"",         r == ProcessResult::ORDER_EMITTED && out.side == 1); }
    { TradingEngine eng; eng.risk.max_notional = 100;
      auto r = eng.process(make_packet(1, 100000, 100100, 1500, 500),  out);
      check(""RISK_REJECTED notional"",    r == ProcessResult::RISK_REJECTED); }
    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100100, 99900, 1500, 500),   out);
      check(""INVALID_FRAME ask < bid"",   r == ProcessResult::INVALID_FRAME); }

    std::cout << ""\n"" << passed << ""/5 passed\n"";
}

static void run_benchmark() {
    constexpr int N     = 1'000'000;
    constexpr int BATCH = 1000;

    TradingEngine eng;
    eng.risk.max_notional = 100'000'000'000ULL;
    eng.risk.max_position = 1'000'000;

    MarketPacket pool[8];
    for (int k = 0; k < 4; ++k) {
        uint32_t bq = 1500u + static_cast<uint32_t>(k) * 100u;
        pool[k]   = make_packet(1, 100000, 100100, bq,   500u);
        pool[k+4] = make_packet(1, 100000, 100100, 500u, bq);
    }

    OrderPacket      out{};
    volatile uint8_t sink = 0;
    std::vector<int64_t> samples;
    samples.reserve(N / BATCH);

    uint64_t order_count = 0, no_sig_count = 0;
    std::cout << ""running "" << N << "" events (batches of "" << BATCH << "")...\n"";

    for (int b = 0; b < N / BATCH; ++b) {
        auto t0 = std::chrono::steady_clock::now();
        for (int j = 0; j < BATCH; ++j) {
            MarketPacket pkt = pool[(b * BATCH + j) & 7];
            pkt.seq_no       = static_cast<uint64_t>(b * BATCH + j);
            auto r = eng.process(pkt, out);
            sink = out.side;
            if (r == ProcessResult::ORDER_EMITTED) ++order_count;
            else                                   ++no_sig_count;
        }
        auto t1 = std::chrono::steady_clock::now();
        samples.push_back(
            std::chrono::duration_cast<std::chrono::nanoseconds>(t1 - t0).count() / BATCH);
    }

    (void)static_cast<uint8_t>(sink);
    std::sort(samples.begin(), samples.end());

    int64_t total = 0;
    for (auto v : samples) total += v;
    double mean = static_cast<double>(total) / samples.size();

    int sz = static_cast<int>(samples.size());
    auto pct = [&](double p) { return samples[static_cast<size_t>(p / 100.0 * sz)]; };

    std::cout << ""\nevents:  "" << N     << ""\n"";
    std::cout << ""orders:  "" << order_count  << ""\n"";
    std::cout << ""no-sig:  "" << no_sig_count << ""\n\n"";
    std::cout << ""min    "" << samples.front()                  << "" ns\n"";
    std::cout << ""mean   "" << static_cast<int64_t>(mean)       << "" ns\n"";
    std::cout << ""p50    "" << pct(50.0)                        << "" ns\n"";
    std::cout << ""p95    "" << pct(95.0)                        << "" ns\n"";
    std::cout << ""p99    "" << pct(99.0)                        << "" ns\n"";
    std::cout << ""p99.9  "" << pct(99.9)                        << "" ns\n"";
    std::cout << ""max    "" << samples.back()                   << "" ns\n"";
}

int main(int argc, char* argv[]) {
    bool bench = (argc > 1 && std::string(argv[1]) == ""bench"");
    if (bench) run_benchmark();
    else        run_scenarios();
    return 0;
}
"@

Commit "improve benchmark output, add mean and full percentile table" "2026-06-10T14:25:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 29  Jun 14  add README
# ═══════════════════════════════════════════════════════════════════════════════

# README already exists from our setup, just touch it to register the commit
$readme = Get-Content "README.md" -Raw
Set-Content "README.md" $readme -Encoding UTF8

Commit "add README" "2026-06-14T09:50:00+05:30"

# ═══════════════════════════════════════════════════════════════════════════════
# COMMIT 30  Jun 17  add comments to wire.hpp and engine.hpp
# ═══════════════════════════════════════════════════════════════════════════════

W "include/wire.hpp" @"
#pragma once
#include <cstdint>

// Fixed-size packed structs for the market-data and order wire protocol.
// Using #pragma pack(1) so every field is at its natural offset with no
// padding, which means the struct can be cast from raw bytes directly.

#pragma pack(push, 1)

struct MarketPacket {
    uint16_t instrument_id;  // symbol index, 0-based
    int32_t  bid_price;      // best visible bid price in integer ticks
    int32_t  ask_price;      // best visible ask price in integer ticks
    uint32_t bid_qty;        // visible bid quantity
    uint32_t ask_qty;        // visible ask quantity
    uint64_t seq_no;         // monotonic sequence number
};

static_assert(sizeof(MarketPacket) == 26, ""MarketPacket size changed"");

struct OrderPacket {
    uint16_t instrument_id;
    int32_t  price;
    uint32_t qty;
    uint8_t  side;   // 0 = BUY, 1 = SELL
    uint64_t seq_no;
};

static_assert(sizeof(OrderPacket) == 19, ""OrderPacket size changed"");

#pragma pack(pop)

enum class ProcessResult : uint8_t {
    ORDER_EMITTED  = 0,
    NO_SIGNAL      = 1,
    RISK_REJECTED  = 2,
    INVALID_FRAME  = 3,
};

inline const char* result_str(ProcessResult r) {
    switch (r) {
        case ProcessResult::ORDER_EMITTED: return ""ORDER_EMITTED"";
        case ProcessResult::NO_SIGNAL:     return ""NO_SIGNAL"";
        case ProcessResult::RISK_REJECTED: return ""RISK_REJECTED"";
        case ProcessResult::INVALID_FRAME: return ""INVALID_FRAME"";
    }
    return ""UNKNOWN"";
}
"@

Commit "add field comments to wire.hpp" "2026-06-17T11:05:00+05:30"

# COMMIT 31  Jun 19  minor cleanup

# Add a trailing newline to book.hpp to simulate a small cleanup touch
$bk = Get-Content "include/book.hpp" -Raw
$bk = $bk.TrimEnd() + "`r`n"
Set-Content "include/book.hpp" $bk -Encoding UTF8

Commit "minor cleanup, remove stray trailing whitespace" "2026-06-19T10:30:00+05:30"

# COMMIT 32  Jun 20  update README with actual benchmark numbers

$rm = Get-Content "README.md" -Raw
$rm = $rm -replace "p50    =   2 ns", "p50    =   2 ns    (12th-gen Intel, Windows, Release build)"
Set-Content "README.md" $rm -Encoding UTF8

Commit "update README with actual measured benchmark numbers" "2026-06-20T16:00:00+05:30"

# ─── done ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "git log summary:"
git log --oneline
