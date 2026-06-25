#pragma once
#include "engine.hpp"

#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>

// ─────────────────────────────────────────────────────────────────────────────
// Backtester
//
// Loads a CSV of historical market snapshots, replays them through the
// TradingEngine one by one, and tracks PnL and statistics.
//
// CSV format (optional header line starting with 'i' is skipped):
//   instrument_id,bid_price,ask_price,bid_qty,ask_qty
//   1,100000,100100,500,500
//   1,100000,100100,1500,500
//   ...
//
// PnL accounting (mark-to-market):
//   BUY  order: cash -= price * qty   position += qty
//   SELL order: cash += price * qty   position -= qty
//   Final PnL  = cash_flow + net_position * last_mid_price
// ─────────────────────────────────────────────────────────────────────────────

struct BacktestStats {
    uint64_t ticks_total    = 0;
    uint64_t orders_emitted = 0;
    uint64_t buy_orders     = 0;
    uint64_t sell_orders    = 0;
    uint64_t risk_rejects   = 0;
    uint64_t no_signals     = 0;
    uint64_t invalid_frames = 0;

    int64_t  net_position   = 0;   // net lots held (positive = long)
    int64_t  cash_flow      = 0;   // cumulative cash change in ticks
    int32_t  last_mid       = 0;   // last observed mid price

    // Mark-to-market PnL in ticks.
    // Positive means the strategy made money over this replay.
    [[nodiscard]]
    int64_t pnl() const noexcept {
        return cash_flow + net_position * static_cast<int64_t>(last_mid);
    }
};

// Parse one CSV line into a MarketPacket.
// Returns false if the line is a comment, header, or malformed.
[[nodiscard]]
static bool parse_csv_line(const std::string& line, MarketPacket& out, uint64_t seq) noexcept {
    // skip empty lines, comment lines, and probable header rows
    if (line.empty() || line[0] == '#' || line[0] == 'i' || line[0] == 's') return false;

    std::istringstream ss(line);
    std::string tok;
    int32_t f[5] = {};
    int n = 0;

    while (n < 5 && std::getline(ss, tok, ',')) {
        try              { f[n++] = std::stoi(tok); }
        catch (...)      { return false; }
    }
    if (n < 5) return false;

    out = MarketPacket{};
    out.instrument_id = static_cast<uint16_t>(f[0]);
    out.bid_price     = f[1];
    out.ask_price     = f[2];
    out.bid_qty       = static_cast<uint32_t>(f[3]);
    out.ask_qty       = static_cast<uint32_t>(f[4]);
    out.seq_no        = seq;
    return true;
}

class BacktestRunner {
public:
    // Run the backtest against the CSV at `filename`.
    BacktestStats run(const std::string& filename) const {
        std::ifstream file(filename);
        if (!file.is_open()) {
            std::cerr << "backtest: cannot open file: " << filename << "\n";
            return {};
        }

        TradingEngine engine;
        BacktestStats stats;
        OrderPacket   out{};
        std::string   line;
        uint64_t      seq = 0;

        while (std::getline(file, line)) {
            // strip Windows-style \r if present
            if (!line.empty() && line.back() == '\r') line.pop_back();

            MarketPacket pkt{};
            if (!parse_csv_line(line, pkt, seq++)) continue;

            ++stats.ticks_total;
            stats.last_mid = (pkt.bid_price + pkt.ask_price) / 2;

            const ProcessResult r = engine.process(pkt, out);

            switch (r) {
                case ProcessResult::ORDER_EMITTED:
                    ++stats.orders_emitted;
                    if (out.side == 0) {          // BUY  — we pay ask, hold long
                        ++stats.buy_orders;
                        stats.cash_flow    -= static_cast<int64_t>(out.price) * out.qty;
                        stats.net_position += static_cast<int64_t>(out.qty);
                    } else {                      // SELL — we receive bid, hold short
                        ++stats.sell_orders;
                        stats.cash_flow    += static_cast<int64_t>(out.price) * out.qty;
                        stats.net_position -= static_cast<int64_t>(out.qty);
                    }
                    break;
                case ProcessResult::NO_SIGNAL:     ++stats.no_signals;     break;
                case ProcessResult::RISK_REJECTED: ++stats.risk_rejects;   break;
                case ProcessResult::INVALID_FRAME: ++stats.invalid_frames; break;
            }
        }

        return stats;
    }

    // Print a human-readable summary of a completed backtest.
    static void print_report(const BacktestStats& s, const std::string& filename) {
        auto sep = [](){ std::cout << "-------------------------------\n"; };

        std::cout << "\nbacktest report\n";
        sep();
        std::cout << "file             " << filename          << "\n";
        sep();
        std::cout << "ticks processed  " << s.ticks_total    << "\n";
        std::cout << "  no-signal      " << s.no_signals      << "\n";
        std::cout << "  invalid frames " << s.invalid_frames  << "\n";
        sep();
        std::cout << "orders emitted   " << s.orders_emitted  << "\n";
        std::cout << "  buy orders     " << s.buy_orders       << "\n";
        std::cout << "  sell orders    " << s.sell_orders      << "\n";
        std::cout << "risk rejections  " << s.risk_rejects     << "\n";
        sep();
        std::cout << "net position     " << s.net_position     << " lots\n";
        std::cout << "cash flow        " << s.cash_flow        << " ticks\n";
        std::cout << "last mid price   " << s.last_mid         << " ticks\n";

        const int64_t p = s.pnl();
        std::cout << "pnl (mtm)        " << p << " ticks";
        if      (p > 0) std::cout << "  [ profitable ]\n";
        else if (p < 0) std::cout << "  [ loss ]\n";
        else            std::cout << "  [ flat ]\n";

        sep();
    }
};
