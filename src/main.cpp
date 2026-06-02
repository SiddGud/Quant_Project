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

