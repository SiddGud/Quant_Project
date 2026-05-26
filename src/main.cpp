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
