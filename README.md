# quant-project

A low-latency order book engine written in C++20.

The idea is straightforward. A market-data packet comes in, the engine updates its internal view of the order book, decides whether to buy or sell based on visible liquidity, runs a quick risk check, and emits an outbound order packet. All of this happens in a single function call with no heap allocation and no I/O on the hot path.

I built this to understand what actually makes a trading engine fast at the packet-processing level, not at the infrastructure level.

---

## Why I built it

Most resources on low-latency trading focus on the networking stack, or on distributed systems, or on infrastructure. Very few actually show the packet-to-order decision loop in isolation.

I wanted to see how fast that loop could be when kept small and predictable. So I stripped everything down to the minimum: fixed-size binary packets, integer price ticks, a flat order book in plain struct fields, and inline risk checks. No JSON, no database calls, no logging inside the measured path.

The benchmark at the end runs 1,000,000 events and measures the full hot-path latency in nanoseconds.

---

## How the hot path works

```
incoming MarketPacket
    |
    v
validate frame               (reject if ask <= bid)
    |
    v
update L2 order book         (store bid/ask price and qty)
    |
    v
run imbalance strategy       (compare bid vs ask quantity)
    |
    v
inline risk check            (position and notional limits)
    |
    v
encode OrderPacket           (fill and return the output struct)
```

The entire sequence is inside one `TradingEngine::process()` call. At -O3 the compiler inlines everything, so it ends up as a tight block of comparisons and struct writes.

---

## Strategy

The strategy is a simple imbalance check. If one side of the book has 1.5x more visible quantity than the other, it generates a directional signal.

```
bid_qty > ask_qty * 1.5  ->  BUY
ask_qty > bid_qty * 1.5  ->  SELL
otherwise                ->  NO_SIGNAL
```

The comparison is done in integer arithmetic to avoid floating-point in the hot path. Instead of `bid > ask * 1.5`, it computes `bid * 2 > ask * 3`.

This strategy is not meant to be profitable. It is a controlled workload for benchmarking the engine.

---

## Risk checks

Two checks happen inline before any order is emitted:

- Net position must stay within +/- 100 lots (configurable)
- Total notional must stay below 10,000,000 ticks (configurable)

The check and the state update are split into separate methods. `check()` is side-effect-free. `commit()` updates the state. This makes the logic easier to reason about and test.

---

## Wire format

Two packed structs, cast-able directly from raw bytes.

```cpp
struct MarketPacket {    // 26 bytes
    uint16_t instrument_id;
    int32_t  bid_price;
    int32_t  ask_price;
    uint32_t bid_qty;
    uint32_t ask_qty;
    uint64_t seq_no;
};

struct OrderPacket {     // 19 bytes
    uint16_t instrument_id;
    int32_t  price;
    uint32_t qty;
    uint8_t  side;       // 0 = BUY, 1 = SELL
    uint64_t seq_no;
};
```

No dynamic allocation. No serialisation library. The structs have `static_assert` size checks so a mismatch fails at compile time.

---

## Project layout

```
include/
    wire.hpp        fixed-size market and order packet structs
    book.hpp        L2 order book, top-of-book state only
    strategy.hpp    imbalance signal: BUY / SELL / NO_SIGNAL
    risk.hpp        inline position and notional limit checks
    engine.hpp      TradingEngine::process(), the hot path
src/
    main.cpp        correctness scenarios and latency benchmark
CMakeLists.txt
```

---

## Build

Requires g++ 12 or later, cmake 3.16 or later.

```
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make
```

Or directly:

```
g++ -std=c++20 -O3 -march=native -o quant_engine src/main.cpp -Iinclude
```

---

## Run

```
./quant_engine           runs the five correctness scenarios
./quant_engine bench     runs the 1M-event latency benchmark
```

---

## Correctness scenarios

The engine is tested against five distinct outcomes:

| Scenario | Expected result |
|---|---|
| Balanced book, bid qty equals ask qty | NO_SIGNAL |
| Bid side dominant | ORDER_EMITTED, side = BUY |
| Ask side dominant | ORDER_EMITTED, side = SELL |
| Signal generated but notional limit exceeded | RISK_REJECTED |
| Packet where ask price is less than bid price | INVALID_FRAME |

All five pass.

---

## Benchmark results

Measured on a 12th-gen Intel laptop running Windows. Build flags: -O3 -march=native.

The measured boundary is: after the MarketPacket struct is constructed, through validation, book update, strategy, risk check, and order encoding, before the return value is read. This is engine latency only, not wire or NIC latency.

Batched timing is used (1000 calls per timing sample) because Windows steady_clock has around 100 ns resolution and timing individual calls would produce mostly zeros.

```
Events:         1,000,000
Orders emitted: ~100,000

p50    =   2 ns    (12th-gen Intel, Windows, Release build)
p95    =   6 ns
p99    =   6 ns
p99.9  =  57 ns
Max    =  57 ns
```

The high tail is OS scheduling jitter. The engine itself is consistently under 10 ns per call.

---

## Design decisions

A few things that mattered more than I expected going in:

Fixed-size structs meant no dynamic parsing. Every field is at a known offset, so the decode is just a cast.

Integer price ticks eliminated floating-point from all comparisons. The strategy and risk checks are now branch-predictable integer operations.

Keeping the L2 book as plain struct fields instead of a map kept all book state in one cache line. There is no pointer chasing.

Separating check() and commit() in the risk guard made it easier to unit test risk logic without worrying about state mutation.

The single process() call means the compiler can see the entire hot path at once and inline across all four components.


