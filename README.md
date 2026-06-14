# Core-Billing

- 🛒 Tebex: [core-forge.tebex.io/package/7254081](https://core-forge.tebex.io/package/7254081)

A lightweight server-side billing system for FiveM player-owned shops and services.
Employees bill nearby players, customers accept or decline, and everything is validated server-side.
Built for QBCore, ESX, and QBox.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [How It Works](#how-it-works)
- [Support](#support)

---

## Features

- Employees bill nearby players for goods or services
- Automatic employee profit calculation (configurable %)
- Customers accept or decline bills in real time via ox_lib dialog
- Pending bills expire automatically if ignored or declined
- Server-side price validation — no client-side manipulation possible
- Stores pending bills in a tracked table, cleans up on payment or expiry
- Lightweight — no bloat, built for real gameplay flow
- QBCore | ESX | QBox compatible

---

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- [Renewed-Banking](https://github.com/Renewed-Scripts/Renewed-Banking) — for society account payouts
- QBCore / ESX / QBox

---

## Installation

1. Place the `core-billing` folder in your server's `resources` directory

2. Add to your `server.cfg`

```
ensure core-billing
```

3. Configure to match your server — see [Configuration](#configuration)

4. Restart your server or run `refresh` then `ensure core-billing` in console

---

## Configuration

All settings are in `config.lua`

```lua
Config.ProfitPercent = 10        -- Employee cut as a percentage of the bill
Config.BillExpiry = 300000       -- Time in ms before a pending bill expires (default 5 min)
Config.MaxBillAmount = 10000     -- Maximum bill amount a player can send
Config.Currency = 'cash'         -- Payment type
```

---

## How It Works

1. Employee opens the billing menu and enters an amount
2. A bill is sent to the nearest player in range
3. Customer receives an ox_lib prompt to accept or decline
4. If accepted — funds transfer, employee receives their profit cut, society receives the remainder
5. If declined or ignored — bill expires and is removed from the table
6. All transactions validated server-side before any money moves

---

## Support

- 💬 Discord: [discord.gg/TBb4QKHQtm](https://discord.gg/TBb4QKHQtm)
- 🛒 Tebex: [core-forge.tebex.io/package/7254081](https://core-forge.tebex.io/package/7254081)
- 📺 YouTube: [youtube.com/@CoreForgeFivem](https://youtube.com/@CoreForgeFivem)
- 📁 GitHub: [github.com/Core-Forge-5](https://github.com/Core-Forge-5)