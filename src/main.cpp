#include "../include/backtest.hpp"
#include "../include/engine.hpp"

#include <algorithm>
#include <chrono>
#include <iostream>
#include <string>
#include <vector>

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Correctness scenarios
// ─────────────────────────────────────────────────────────────────────────────

static void run_scenarios() {
    std::cout << "--- scenarios ---\n";
    OrderPacket out{};
    int passed = 0;

    auto check = [&](const char* name, bool ok) {
        std::cout << (ok ? "[PASS] " : "[FAIL] ") << name << "\n";
        if (ok) ++passed;
    };

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 500,  500),  out);
      check("NO_SIGNAL balanced book",  r == ProcessResult::NO_SIGNAL); }

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 1500, 500),  out);
      check("BUY  bid dominant",  r == ProcessResult::ORDER_EMITTED && out.side == 0); }

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100000, 100100, 500,  1500), out);
      check("SELL ask dominant",  r == ProcessResult::ORDER_EMITTED && out.side == 1); }

    { TradingEngine eng; eng.risk.max_notional = 100;
      auto r = eng.process(make_packet(1, 100000, 100100, 1500, 500),  out);
      check("RISK_REJECTED notional",   r == ProcessResult::RISK_REJECTED); }

    { TradingEngine eng;
      auto r = eng.process(make_packet(1, 100100, 99900, 1500, 500),   out);
      check("INVALID_FRAME ask < bid",  r == ProcessResult::INVALID_FRAME); }

    std::cout << "\n" << passed << "/5 passed\n";
}

// ─────────────────────────────────────────────────────────────────────────────
// Latency benchmark
// ─────────────────────────────────────────────────────────────────────────────

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

    uint64_t order_count = 0, no_sig_count = 0;
    std::cout << "running " << N << " events (batches of " << BATCH << ")...\n";

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

    std::cout << "\nevents:  " << N          << "\n";
    std::cout << "orders:  " << order_count  << "\n";
    std::cout << "no-sig:  " << no_sig_count << "\n\n";
    std::cout << "min    " << samples.front()             << " ns\n";
    std::cout << "mean   " << static_cast<int64_t>(mean) << " ns\n";
    std::cout << "p50    " << pct(50.0)                  << " ns\n";
    std::cout << "p95    " << pct(95.0)                  << " ns\n";
    std::cout << "p99    " << pct(99.0)                  << " ns\n";
    std::cout << "p99.9  " << pct(99.9)                  << " ns\n";
    std::cout << "max    " << samples.back()              << " ns\n";
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

int main(int argc, char* argv[]) {
    if (argc > 1) {
        std::string mode = argv[1];
        if (mode == "bench") {
            run_benchmark();
            return 0;
        }
        if (mode == "backtest") {
            std::string file = (argc > 2) ? argv[2] : "data/sample.csv";
            BacktestRunner runner;
            BacktestStats  stats = runner.run(file);
            BacktestRunner::print_report(stats, file);
            return 0;
        }
        std::cerr << "usage: quant_engine [bench | backtest [file.csv]]\n";
        return 1;
    }
    run_scenarios();
    return 0;
}
