# Epic: IdleProductionSystem

> **Layer**: Core
> **GDD**: design/gdd/bunny-farm-idle-master.md (§3.12 Idle & Offline)
> **Architecture Module**: `src/core/idle_production_system.gd` + `src/core/earnings_report.gd`
> **Status**: Ready
> **Control Manifest Version**: pending — run `/create-control-manifest` to assign
> **Stories**: 4 stories — all Ready (ADR-0007 Accepted 2026-05-17)

## Overview

IdleProductionSystem calculates how many Carrot Coins the player's rabbits produce. It exposes two pure functions: `get_tick_earnings()` for the real-time 1-second tick, and `calculate_offline_earnings()` for catch-up when the player returns. Both return an `EarningsReport` — the caller (TimeManager tick handler or SaveSystem boot) passes the result to `EconomyManager.add()`. The system never mutates any state itself. All production rates and the four offline multiplier tiers are loaded from `balance.json`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: JSON Balance Data | `base_cc_per_rabbit_per_second`, offline multipliers, `max_offline_hours` — all from `balance.json` | LOW |
| ADR-0007: Idle Production Formula | Pure function formula: `floor(rabbit_count × base_rate × hutch_bonus × season_mult × prestige_bonus × offline_multiplier × delta_seconds)`; 4 offline tiers; EarningsReport value object | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-idle-001 | Real-time idle production at online rate (100%) | ADR-0007 ✅ |
| TR-idle-002 | Offline catch-up applied on app resume | ADR-0007 ✅ |
| TR-idle-003 | 4 tiered multipliers: background 75%, <4h 60%, 4–12h 50%, >12h 40% | ADR-0007 ✅, ADR-0004 ✅ |
| TR-season-001 | Season multiplier factored into production | ADR-0007 ✅ |
| TR-prestige-001 | Prestige offline production bonus factored in | ADR-0007 ✅ |

> ⚠️ Blocked requirement: TR-idle-004 — item-based offline modifiers (Alarm Bunny +70%, Auto-Feeder) — deferred to ADR-0010 (not yet written). Stories for item modifiers will be Blocked until ADR-0010 is Accepted.

## Key Interfaces

```gdscript
# src/core/idle_production_system.gd
func get_tick_earnings() -> EarningsReport
func calculate_offline_earnings(offline_seconds: float, was_backgrounded: bool) -> EarningsReport

# src/core/earnings_report.gd
class_name EarningsReport extends RefCounted
var carrot_coin: int
var star_dust: int
var applied_multiplier: float
var delta_seconds: float
var source_breakdown: Array
```

## Offline Multiplier Tiers

| Condition | Multiplier | Balance Key |
|-----------|-----------|-------------|
| Foreground (online) | 1.00 | — |
| Background (minimised) | 0.75 | `idle_production.offline_multiplier_background` |
| Offline < 4 hours | 0.60 | `idle_production.offline_multiplier_under_4h` |
| Offline 4–12 hours | 0.50 | `idle_production.offline_multiplier_4_to_12h` |
| Offline > 12 hours | 0.40 | `idle_production.offline_multiplier_over_12h` |

Cap: `idle_production.max_offline_hours` (72h) — no earnings credited beyond this.

## Forbidden Patterns

- `IdleProductionSystem` must never call `EconomyManager.add()` directly — caller does this
- `hardcoded_balance_values` — all rates loaded from `balance.json`; no inline floats in `src/`

## Definition of Done

This epic is complete when:
- [ ] All stories are implemented, reviewed, and closed via `/story-done`
- [ ] GdUnit4: `calculate_offline_earnings(0, false)` → `carrot_coin == 0`
- [ ] GdUnit4: 24 adult rabbits × 1 second → `carrot_coin == floor(24 × 0.05 × 1.0)` = 1
- [ ] GdUnit4: delta = 3 hours → `applied_multiplier == 0.60`
- [ ] GdUnit4: delta = 8 hours → `applied_multiplier == 0.50`
- [ ] GdUnit4: delta = 100 hours → capped at 72 hours worth
- [ ] GdUnit4: BABY rabbits not counted in `productive_count`
- [ ] Grep: `calculate_offline_earnings()` never calls `EconomyManager.add()` directly
- [ ] All rates verified loading from `balance.json` (grep: no float literals in `idle_production_system.gd`)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [EarningsReport Schema](story-001-earnings-report-schema.md) | Logic | Complete | ADR-0007 ✅ |
| 002 | [Production Formula — Tick Earnings](story-002-production-formula.md) | Logic | Complete | ADR-0007 ✅ + ADR-0004 ✅ |
| 003 | [Offline Catch-Up + Multiplier Tiers](story-003-offline-tiers.md) | Logic | Complete | ADR-0007 ✅ + ADR-0004 ✅ |
| 004 | [Season + Prestige Integration](story-004-season-prestige-integration.md) | Integration | Complete | ADR-0007 ✅ |

## Next Step

Run `/architecture-decision retrofit docs/architecture/adr-0007-idle-production-offline.md` to promote ADR-0007 to Accepted — this unblocks all 4 stories immediately.
