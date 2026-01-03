<div align="center">

<img src="assets/logo.svg" alt="ScreenerBot Logo" width="180" height="180" />

# ScreenerBot

### Professional Automated Trading for Solana DeFi

[![Website](https://img.shields.io/badge/Website-screenerbot.io-blue?style=flat-square)](https://screenerbot.io)
[![Documentation](https://img.shields.io/badge/Docs-screenerbot.io%2Fdocs-green?style=flat-square)](https://screenerbot.io/docs)
[![Download](https://img.shields.io/badge/Download-Latest-orange?style=flat-square)](https://screenerbot.io/download)
[![Telegram](https://img.shields.io/badge/Telegram-Community-blue?style=flat-square&logo=telegram)](https://t.me/screenerbotio)

**The first native local trading system for Solana DeFi.**  
Real-time token discovery • Multi-DEX support • Full self-custody • 24/7 automated trading

</div>

---

## Why ScreenerBot?

Most trading tools rely on delayed APIs and shared infrastructure. ScreenerBot runs locally on your hardware, calculating prices directly from blockchain data and executing trades through your own wallet—eliminating platform lag and custody risk.

| Feature | ScreenerBot | Cloud Bots |
|---------|-------------|------------|
| **Execution Speed** | Sub-millisecond strategy evaluation | API latency dependent |
| **Price Data** | Direct from on-chain pools (<50ms) | Delayed API feeds |
| **Private Keys** | Never leave your machine | Stored on remote servers |
| **Customization** | Fully configurable strategies | Limited presets |
| **Uptime Control** | You control availability | Platform dependent |

---

## Core Features

### 🔍 Token Discovery & Analysis
- **Multi-Source Discovery** — Continuous monitoring of DexScreener, GeckoTerminal, and Raydium pools
- **Security Analysis** — Automated Rugcheck scoring, mint/freeze authority detection, holder distribution analysis
- **Intelligent Filtering** — Advanced multi-criteria filtering (liquidity, volume, market cap, age, and more)

### 📊 Real-Time Price Monitoring
- **11 Native DEX Decoders** — Raydium (CLMM, CPMM, Legacy), Orca Whirlpool, Meteora (DAMM, DBC, DLMM), Pumpfun, and more
- **Direct Pool Pricing** — Calculate spot prices from pool reserves in real-time
- **OHLCV Data** — Multi-timeframe candlestick data for technical analysis

### ⚡ Automated Trading
- **Strategy-Based Execution** — Configurable entry/exit conditions with technical indicators
- **DCA Support** — Dollar-cost averaging with multiple entry points
- **Trailing Stop-Loss** — Dynamic stop-loss that follows price movements
- **ROI Targets** — Partial exits at configurable profit levels
- **Time Overrides** — Force exits after configurable hold periods

### 🛡️ Safety & Security
- **Full Self-Custody** — Private keys encrypted locally, never transmitted
- **Pre-Trade Safety Checks** — Automatic security verification before every trade
- **Loss Limit Protection** — Configurable period-based loss limits with auto-pause
- **Emergency Stop** — One-click halt of all trading activity
- **Token Blacklisting** — Automatic blocking of risky or underperforming tokens

### 🔀 Smart Routing
- **Jupiter V6 Integration** — Best-route selection through Jupiter aggregator
- **GMGN Routing** — Alternative routing for optimal execution
- **Automatic Selection** — Bot selects best route based on price impact

### 📱 Dashboard & Monitoring
- **Web Dashboard** — Professional local interface for monitoring and configuration
- **Real-Time P&L** — Live profit/loss tracking for all positions
- **Transaction History** — Complete trade log with detailed analytics
- **Telegram Notifications** — Instant alerts for trades, positions, and system events

---

## Quick Install (VPS/Linux Server)

Run ScreenerBot 24/7 on a Linux VPS with a single command:

```bash
curl -fsSL https://screenerbot.io/install.sh | bash
```

**Alternative installation:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/screenerbotio/ScreenerBot-Public/main/screenerbot.sh)
```

### What the Installer Does

| Step | Description |
|------|-------------|
| 🔍 **Detection** | Auto-detects architecture (x64/arm64) |
| 📦 **Download** | Fetches latest headless package |
| 📁 **Install** | Installs to `/opt/screenerbot` |
| ⚙️ **Service** | Creates systemd service with auto-start |
| 🔗 **Command** | Adds `screenerbot` command globally |

### Management Menu

After installation, run `screenerbot` anytime to access the interactive menu:

```
┌─────────────────────────────────────────────┐
│           ScreenerBot Manager               │
├─────────────────────────────────────────────┤
│  1. Install / Update ScreenerBot            │
│  2. Uninstall ScreenerBot                   │
│  3. Start / Stop / Restart Service          │
│  4. View Live Logs                          │
│  5. Backup & Restore Data                   │
│  6. Select Specific Version                 │
│  7. Configure Telegram Notifications        │
│  8. Check Status                            │
└─────────────────────────────────────────────┘
```

### VPS Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **OS** | Ubuntu 20.04+ / Debian 11+ | Ubuntu 22.04 LTS |
| **CPU** | 2 vCPUs | 4+ vCPUs |
| **RAM** | 4 GB | 8 GB |
| **Storage** | 20 GB SSD | 40 GB SSD |
| **Network** | Stable connection | Unmetered bandwidth |

**Recommended Providers:** DigitalOcean, Vultr, Linode, Hetzner, AWS EC2

---

## Desktop Installation

Download pre-built applications from [screenerbot.io/download](https://screenerbot.io/download):

### macOS

| Architecture | Package |
|--------------|---------|
| Apple Silicon (M1/M2/M3) | `.dmg` installer |
| Intel | `.dmg` installer |

1. Download the appropriate `.dmg` file
2. Open and drag ScreenerBot to Applications
3. Right-click → Open (first time only, to bypass Gatekeeper)

### Windows

| Architecture | Package |
|--------------|---------|
| x64 (most PCs) | `.exe` installer |
| ARM64 | `.exe` installer |

1. Download the `.exe` installer
2. Run installer and follow prompts
3. Launch from Start Menu or Desktop shortcut

### Linux Desktop

| Format | Distributions |
|--------|---------------|
| `.deb` | Ubuntu, Debian, Linux Mint |
| `.rpm` | Fedora, RHEL, CentOS, openSUSE |
| `.AppImage` | Universal (any distribution) |

```bash
# Debian/Ubuntu
sudo dpkg -i screenerbot_*.deb

# Fedora/RHEL
sudo rpm -i screenerbot_*.rpm

# AppImage
chmod +x ScreenerBot*.AppImage
./ScreenerBot*.AppImage
```

---

## Data Directory Structure

ScreenerBot stores all data locally in your system's application data folder:

### Locations by Platform

| Platform | Data Directory |
|----------|----------------|
| **macOS** | `~/Library/Application Support/ScreenerBot/` |
| **Windows** | `%LOCALAPPDATA%\ScreenerBot\` |
| **Linux** | `~/.local/share/ScreenerBot/` |

### Directory Contents

```
ScreenerBot/
├── data/
│   ├── config.toml          # Main configuration file
│   ├── tokens.db            # Token database
│   ├── positions.db         # Position history
│   ├── transactions.db      # Transaction records
│   ├── ohlcvs.db            # Price history
│   ├── events.db            # System events log
│   └── wallet.db            # Wallet snapshots
└── logs/
    └── screenerbot_*.log    # Daily rotating logs
```

> **Note:** All databases are SQLite format. The `config.toml` stores encrypted wallet data—never share this file.

---

## Configuration

### Dashboard Configuration (Recommended)

The web dashboard provides a safe, validated interface for all settings:

1. Open the dashboard at `http://localhost:8080` (or your configured port)
2. Navigate to **Config** in the sidebar
3. Modify settings with instant validation
4. Changes apply immediately (hot-reload)

### Initial Setup Requirements

Before trading, you must configure:

| Setting | Description |
|---------|-------------|
| **Wallet** | Your Solana wallet private key (encrypted locally) |
| **RPC Endpoint** | Solana RPC URL (Helius, QuickNode, Triton, or public) |

### Key Configuration Sections

| Section | Purpose |
|---------|---------|
| **Trader** | Entry/exit rules, position limits, safety settings |
| **Positions** | DCA settings, partial exits, loss detection |
| **Filtering** | Token criteria (liquidity, volume, market cap, etc.) |
| **Swaps** | Router preferences, slippage, priority fees |
| **RPC** | Endpoint URLs, rate limits, failover settings |
| **Telegram** | Bot token, chat ID, notification preferences |

---

## Dashboard Access

After starting ScreenerBot, access the dashboard:

| Environment | URL |
|-------------|-----|
| **Local/Desktop** | `http://localhost:8080` |
| **VPS (via SSH tunnel)** | `ssh -L 8080:localhost:8080 user@your-vps-ip` then `http://localhost:8080` |

### Dashboard Pages

| Page | Description |
|------|-------------|
| **Home** | System overview, quick stats, recent activity |
| **Billboard** | Live filtered tokens ready for trading |
| **Positions** | Open and closed position management |
| **Tokens** | Token database with security and market data |
| **Trader** | Trading controls, monitors, safety settings |
| **Filtering** | Configure token filtering criteria |
| **Config** | All system settings |
| **System** | Service status, logs, diagnostics |

---

## Trading Workflow

```
┌─────────────┐    ┌──────────────┐    ┌────────────┐    ┌─────────────┐
│  Discovery  │───▶│   Security   │───▶│  Filtering │───▶│   Trading   │
│             │    │   Analysis   │    │            │    │   Engine    │
└─────────────┘    └──────────────┘    └────────────┘    └─────────────┘
      │                   │                  │                  │
      ▼                   ▼                  ▼                  ▼
  DexScreener        Rugcheck           Liquidity          Entry/Exit
  GeckoTerminal      Mint Auth          Volume             Strategies
  Raydium Pools      Freeze Auth        Market Cap         Position Mgmt
```

1. **Discovery** — Continuously monitor sources for new tokens
2. **Security** — Verify each token passes security checks
3. **Filtering** — Apply your configured criteria
4. **Trading** — Execute strategies on qualified tokens

---

## Supported DEXs

ScreenerBot features native on-chain decoders for price discovery:

| DEX | Pool Types |
|-----|------------|
| **Raydium** | CLMM, CPMM, Legacy AMM |
| **Orca** | Whirlpool (Concentrated Liquidity) |
| **Meteora** | DAMM, DBC, DLMM |
| **Pumpfun** | AMM, Legacy |
| **Fluxbeam** | Standard AMM |
| **Moonit** | Standard AMM |

> All trade execution routes through Jupiter V6 or GMGN aggregators for optimal pricing.

---

## Links & Resources

| Resource | Link |
|----------|------|
| 🌐 **Website** | [screenerbot.io](https://screenerbot.io) |
| 📚 **Documentation** | [screenerbot.io/docs](https://screenerbot.io/docs) |
| ⬇️ **Download** | [screenerbot.io/download](https://screenerbot.io/download) |
| 💬 **Community** | [t.me/screenerbotio](https://t.me/screenerbotio) |

### Documentation Sections

- [Introduction](https://screenerbot.io/docs/introduction) — What is ScreenerBot?
- [Installation Guide](https://screenerbot.io/docs/getting-started/installation) — Platform-specific setup
- [Initial Setup](https://screenerbot.io/docs/getting-started/setup) — Wallet & RPC configuration
- [VPS Guide](https://screenerbot.io/docs/getting-started/installation/vps) — 24/7 server setup
- [Dashboard Guide](https://screenerbot.io/docs/getting-started/dashboard) — Using the web interface
- [Trading Controls](https://screenerbot.io/docs/trading/trading-controls) — Entry/exit configuration
- [Trailing Stop](https://screenerbot.io/docs/trading/trailing-stop) — Dynamic stop-loss
- [DCA Guide](https://screenerbot.io/docs/trading/dca-guide) — Dollar-cost averaging
- [Telegram Setup](https://screenerbot.io/docs/telegram) — Notification configuration
- [Troubleshooting](https://screenerbot.io/docs/reference/troubleshooting) — Common issues & solutions

---

## Project Status

ScreenerBot is a private project under active development. This repository contains:

- ✅ Public documentation and resources
- ✅ VPS installation script (`screenerbot.sh`)
- ✅ Logo and brand assets

The trading engine source code is not publicly available.

---

<div align="center">

**Built for the Solana DeFi community** 🚀

[Website](https://screenerbot.io) • [Documentation](https://screenerbot.io/docs) • [Download](https://screenerbot.io/download) • [Telegram](https://t.me/screenerbotio)

</div>
