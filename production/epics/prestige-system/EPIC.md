# Epic: PrestigeSystem

> **Layer**: Feature
> **GDD**: design/gdd/bunny-farm-idle-master.md §4–§5
> **Architecture Module**: `src/core/prestige_system.gd`
> **Status**: Ready
> **Stories**: 2 stories created

## Stories

| # | File | Title | Status | Type |
|---|------|-------|--------|------|
| 001 | story-001-can-prestige-execute.md | can_prestige() + execute_prestige() | Ready | Logic |
| 002 | story-002-prestige-bonus.md | Prestige Bonus — Stacking Production Multiplier | Ready | Logic |
> **Control Manifest Version**: 2026-05-18

## Overview

PrestigeSystem is the gateway to the meta-loop reset cycle. It exposes `can_prestige()` (checks Legendary rabbit owned AND CollectionSystem ≥ 80% complete) and `execute_prestige()` (increments `GameState.prestige_count`, calls `GameState.prestige_reset()` with the keep-list defined in ADR-0001, and stacks the new permanent bonus into the production formula). Up to 20 prestige levels exist; each level's bonus is defined in `balance.json`. PrestigeSystem does not own the reset logic — it delegates to `GameState.prestige_reset()`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | `GameState.prestige_reset(keep: Dictionary)` is the sole reset entry point | LOW |
| ADR-0004: Balance JSON | `prestige.bonuses_per_level` dictionary in `balance.json`; up to 20 levels | LOW |
| ADR-0007: Idle Production Offline | `prestige_bonus` from `GameState.prestige_count` factored into production formula | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-prestige-001 | Prestige bonuses persist and affect production | ADR-0007 ✅ |
| TR-prestige-002 | Selective reset (keep some data, wipe rest) | ADR-0001 ✅ |
| TR-prestige-003 | Up to 20 prestige levels with stacking bonuses | ADR-0004 ✅ |

## Definition of Done

This epic is complete when:
- `can_prestige()` correctly validates all preconditions
- `execute_prestige()` triggers selective state wipe via `GameState.prestige_reset()`
- Prestige count increments and bonus stacks in production formula
- Cap at 20 levels enforced
- All Logic stories have passing tests in `tests/unit/`

## Next Step

Run `/dev-story production/epics/prestige-system/story-001-can-prestige-execute.md`
