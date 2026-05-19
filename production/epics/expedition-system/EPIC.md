# Epic: ExpeditionSystem

> **Layer**: Feature
> **GDD**: design/gdd/bunny-farm-idle-master.md §3.6
> **Architecture Module**: `src/core/expedition_system.gd`
> **Status**: Active — ADR-0011 Accepted, 3 stories created
> **Stories**: story-001-start-expedition.md, story-002-collect-loot.md, story-003-offline-catchup.md
> **Control Manifest Version**: 2026-05-18

## Overview

ExpeditionSystem manages the async "send rabbits away" feature: players assign rabbits to expedition slots, each slot tracks start time and zone, and rewards are collected when the timer elapses. `start_expedition(zone_id, rabbit_ids)` validates requirements (rabbit stats, slot availability) and records start timestamp via `Time.get_unix_time_from_system()`. `collect(slot_id)` resolves loot using a pre-rolled deterministic seed and grants rewards via `EconomyManager`. `_resolve_offline_expeditions()` handles expeditions that completed while the app was backgrounded. All zone definitions, loot tables, and duration curves live in `balance.json`. This system is pure idle — no realtime interaction needed once an expedition is started.

## Governing ADRs

| ADR | Decision Summary | Status | Engine Risk |
|-----|-----------------|--------|-------------|
| ADR-0001: Autoload Boot Sequence | ExpeditionSystem boots after RabbitSystem and EconomyManager | ✅ Accepted | LOW |
| ADR-0004: Balance JSON | Zone definitions, loot table weights, duration curves in `balance.json` | ✅ Accepted | LOW |
| ADR-0011: ExpeditionSystem Async Timer | Unix-timestamp slot model; loot pre-rolled at start via `loot_seed`; offline catch-up via single boot pass | ✅ Accepted | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-expedition-001 | Async expedition timer + reward roll | ADR-0011 ✅ |

## Stories

| Story | Sprint | Title | Status | Type | Test File |
|-------|--------|-------|--------|------|-----------|
| story-001 | S04-06 | `start_expedition()` + slot model | Ready | Logic | `tests/unit/core/expedition_system_start_test.gd` |
| story-002 | S04-10 | `collect()` + loot roll | Ready | Integration | `tests/integration/core/expedition_system_collect_test.gd` |
| story-003 | S04-11 | `_resolve_offline_expeditions()` | Ready | Integration | `tests/integration/core/expedition_system_offline_test.gd` |

Story dependency chain: story-001 → story-002 → story-003

## Definition of Done

This epic is complete when:
- Expeditions start, persist across saves, and resolve correctly on collect
- Loot rolls produce deterministic results from balance.json weights
- Offline catch-up correctly handles expeditions that completed while backgrounded
- All Logic and Integration stories have passing tests in `tests/`

## Prerequisite Before story-001 Implementation

Add the `expeditions` section to `assets/data/balance.json` with 5 zones (near_forest, east_meadow, snow_mountain, ancient_lands, rabbit_universe) and their loot tables. The required JSON shape is documented in story-001 Context section.
