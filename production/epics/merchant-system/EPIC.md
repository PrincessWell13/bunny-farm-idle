# Epic: MerchantSystem

> **Layer**: Feature
> **GDD**: design/gdd/bunny-farm-idle-master.md §3.10
> **Architecture Module**: `src/core/merchant_system.gd`
> **Status**: Blocked — ADR-0015 (MerchantSystem rotation) not yet written
> **Stories**: Not yet created — run `/create-stories merchant-system`
> **Control Manifest Version**: 2026-05-18

## Overview

MerchantSystem governs the wandering merchant who visits the farm on a random timer. It maintains an active offer list (a small selection of special items, rabbits, or modifiers not available in the regular shop), handles offer expiry, and processes purchases via EconomyManager. Offers are seeded from `balance.json` offer pools; the merchant spawn interval is also configurable. The merchant's offers are visible in the UI only when active; the system emits `merchant_arrived` and `merchant_departed` signals on EventBus.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | MerchantSystem boots after EconomyManager and RabbitSystem | LOW |
| ADR-0003: EventBus Signals | `merchant_arrived(offers: Array)` / `merchant_departed` emitted on EventBus | LOW |
| ADR-0004: Balance JSON | Offer pools, spawn intervals, pricing in `balance.json` | LOW |
| ~~ADR-0015~~: MerchantSystem Rotation | **MISSING** — offer selection algorithm and expiry model not decided | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-merchant-001 | Random merchant rotation + pricing | ❌ No ADR (ADR-0015 needed) |

## Definition of Done

This epic is complete when:
- Merchant spawns on timer within configured interval range
- Offer selection produces valid, non-duplicate offers from balance.json pools
- Accepted offers deduct currency correctly via EconomyManager
- Merchant departs after expiry or all offers accepted
- All Logic stories have passing tests in `tests/unit/`

## Next Step

1. Write ADR-0015: `/architecture-decision "MerchantSystem offer rotation and expiry model"`
2. Then: `/create-stories merchant-system`
