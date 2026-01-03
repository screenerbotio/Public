<div align="center">
<img src="assets/logo.svg" alt="ScreenerBot Logo" width="200" height="200" />

# ScreenerBot

### The First Native Local Trading System for Solana DeFi
</div>

ScreenerBot is a high-performance automated trading engine built in Rust, designed for professional traders who demand maximum speed, precision, and full self-custody.

---

## Why ScreenerBot?

Most Solana tools rely on delayed APIs and shared infrastructure. ScreenerBot runs locally on your hardware, calculating prices directly from blockchain data and executing trades through your own wallet—eliminating platform lag and custody risk.

### Key Advantages
- **Native Performance:** Compiled Rust engine for sub-millisecond strategy evaluation.
- **Direct Pricing:** Calculate spot prices from pool reserves in real-time (<50ms).
- **Multi-Source Intelligence:** Integrated data from DexScreener, GeckoTerminal, and RugCheck.
- **Advanced Strategies:** Trailing stop-loss, ROI targets, and multi-entry DCA support.
- **Full Security:** Private keys never leave your machine. Automatic pre-trade safety checks.

---

## Core Features
- **Direct Pool Support:** 12+ DEX protocols including Raydium, Orca, and Meteora.
- **Smart Routing:** Automatic best-route selection via Jupiter, GMGN, or direct pools.
- **Real-Time Monitoring:** Live transaction streaming and P&L tracking.
- **Unified Database:** Comprehensive token intelligence and historical data.
- **Web Dashboard:** Professional local interface for monitoring and configuration.

---

## Getting Started

ScreenerBot is available as a bundled application for macOS, Windows, and Linux.

### Quick Install (Linux VPS)

Install ScreenerBot on your VPS with a single command:

```bash
bash <(curl -fsSL https://screenerbot.io/install.sh)
```

Or download and run the management script:

```bash
curl -fsSL https://raw.githubusercontent.com/screenerbot/Public/main/screenerbot.sh -o screenerbot.sh
chmod +x screenerbot.sh
sudo ./screenerbot.sh
```

The script provides an interactive menu for:
- 📦 Install/Update/Uninstall ScreenerBot
- ⚙️ Systemd service management (auto-start, restart, logs)
- 💾 Backup and restore your data
- 🔔 Telegram update notifications
- 📊 Status monitoring

### Desktop Applications

Download pre-built applications from our website:

- **macOS:** DMG installer (Apple Silicon & Intel)
- **Windows:** EXE installer (x64 & ARM64)
- **Linux Desktop:** DEB/RPM packages

### Resources

- **Website:** [screenerbot.io](https://screenerbot.io)
- **Downloads:** [screenerbot.io/download](https://screenerbot.io/download)
- **Documentation:** [screenerbot.io/docs](https://screenerbot.io/docs)
- **VPS Guide:** [screenerbot.io/docs/getting-started/running](https://screenerbot.io/docs/getting-started/running)
- **Community:** [t.me/screenerbotio](https://t.me/screenerbotio)

---

## Project Status

ScreenerBot is a private project. This repository contains public resources and documentation. The source code is not publicly available.

Built for the Solana DeFi community.
