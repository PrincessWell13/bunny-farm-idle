# Epic: HabitatSystem

> **Layer**: Feature
> **GDD**: design/gdd/bunny-farm-idle-master.md §3.4
> **Architecture Module**: `src/core/habitat_system.gd` + `src/core/hutch_data.gd`
> **Status**: Ready
> **Stories**: 5 stories created — see table below
> **Control Manifest Version**: 2026-05-18

## Overview

HabitatSystem manages the hutch entities that form the physical structure of the player's farm. It owns the `Array[HutchData]` living inside `GameState.hutches`, enforces per-hutch rabbit capacity rules (4–24 slots by level), tracks cleanliness decay over time, and exposes `get_hutch_bonuses()` so that IdleProductionSystem can read per-hutch production multipliers. Rabbits are assigned to and removed from hutches exclusively through `assign_rabbit()` and `remove_rabbit()` — no other system may mutate hutch occupancy directly.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | HabitatSystem boots as autoload #5 (after GameState) | LOW |
| ADR-0004: Balance JSON | Hutch capacity array and cleanliness decay rate in `balance.json` | LOW |
| ADR-0005: RabbitData Resource | RabbitData is read-only outside RabbitSystem — HabitatSystem reads but never writes rabbit stats | LOW |
| ADR-0010: HabitatSystem Hutch Ownership | HutchData Resource; HabitatSystem exclusive write path; cleanliness decay | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-habitat-001 | Hutch capacity 4–24 by level | ADR-0004 ✅ (data only) |
| TR-habitat-002 | Hutch slot allocation + rabbit placement | ADR-0010 ✅ |


## Stories

| Story | Title | Type | TR-IDs | Status |
|-------|-------|------|--------|--------|
| [story-001](story-001-hutch-data-schema.md) | HutchData Schema + Instantiation | Logic | TR-habitat-002 | Ready |
| [story-002](story-002-assign-remove-rabbit.md) | assign_rabbit() / remove_rabbit() API | Logic | TR-habitat-002 | Ready |
| [story-003](story-003-cleanliness-decay.md) | Cleanliness Decay via TimeManager Tick | Logic | TR-habitat-001, TR-habitat-002 | Ready |
| [story-004](story-004-hutch-bonuses.md) | get_hutch_bonuses() — Cleanliness-Derived Production Multipliers | Logic | TR-habitat-001 | Ready |
| [story-005](story-005-capacity-levels.md) | get_capacity() — Level-Based Hutch Slot Count | Logic | TR-habitat-001 | Ready |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- Rabbits can be assigned to and removed from hutches with capacity enforcement
- Cleanliness decays per tick and is readable by IdleProductionSystem
- `get_hutch_bonuses()` returns correct multipliers
- All Logic and Integration stories have passing tests in `tests/`

## Next Step

1. Implement stories in dependency order: story-001 first, then story-002 through story-005 (003–005 may proceed in parallel once story-001 is done)
2. Add `rabbit_assigned_to_hutch` and `hutch_cleanliness_changed` signals to `src/core/event_bus.gd` (required by stories 002 and 003)
3. Add `habitat` namespace keys to `assets/data/balance.json`: `cleanliness_decay_per_second`, `cleanliness_thresholds`, `capacity_by_level`
4. Run `/story-done` after each story passes its GdUnit4 test suite
