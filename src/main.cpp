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
