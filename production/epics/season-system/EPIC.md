# Epic: SeasonSystem

> **Layer**: Feature
> **GDD**: design/gdd/bunny-farm-idle-master.md §3.5
> **Architecture Module**: `src/core/season_system.gd`
> **Status**: Ready
> **Stories**: 2 stories — run `/dev-story` to implement
> **Control Manifest Version**: 2026-05-18

## Overview

SeasonSystem owns the in-game calendar: it tracks the current season enum (Spring / Summer / Autumn / Winter), advances the day-within-season counter on each `TimeManager` day tick, and emits `season_changed` on the EventBus when a season boundary is crossed. It exposes `get_active_multipliers()` so that IdleProductionSystem can read the current season's production bonus, and `get_current_season()` for UI display. All season durations and multiplier values live in `balance.json`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | SeasonSystem boots after TimeManager; day counter sourced from TimeManager | LOW |
| ADR-0003: EventBus Signals | `season_changed(new_season: String)` emitted on EventBus; no direct UI calls | LOW |
| ADR-0004: Balance JSON | Season durations, fertility/growth/production multipliers per season in `balance.json` | LOW |
| ADR-0007: Idle Production Offline | `season_mult` read from SeasonSystem in production formula | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-season-001 | Season multipliers affect production | ADR-0007 ✅ |
| TR-season-002 | Season modifies global fertility, growth, production | ADR-0004 ✅ |

## Definition of Done

This epic is complete when:
- Season advances on day boundary via TimeManager tick
- `season_changed` signal fires correctly on EventBus
- `get_active_multipliers()` returns correct multipliers for active season
- IdleProductionSystem integrates seasonal multiplier (already partially implemented in story-004)
- All Logic stories have passing tests in `tests/unit/`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Season Clock](story-001-season-clock.md) | Logic | Ready | ADR-0001, ADR-0003, ADR-0004 |
| 002 | [Active Multipliers](story-002-active-multipliers.md) | Logic | Ready | ADR-0004, ADR-0007 |

## Next Step

Run `/dev-story production/epics/season-system/story-001-season-clock.md`
