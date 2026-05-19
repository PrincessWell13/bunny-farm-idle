# Epic: CollectionSystem

> **Layer**: Feature
> **GDD**: design/gdd/bunny-farm-idle-master.md §3.13
> **Architecture Module**: `src/core/collection_system.gd`
> **Status**: Blocked — ADR-0017 (CollectionSystem) not yet written
> **Stories**: Not yet created — run `/create-stories collection-system`
> **Control Manifest Version**: 2026-05-18

## Overview

CollectionSystem is the Pokedex for rabbits — it tracks which species/coat variants the player has ever bred or owned. `register_rabbit(rabbit: RabbitData)` is called whenever a new rabbit is born (via `rabbit_born` EventBus signal). `get_completion_percent()` returns the float used by PrestigeSystem to gate prestige eligibility (requires ≥ 80%). Completion milestones trigger reward signals (items, Gems) via EconomyManager. The full species catalogue is defined in `balance.json`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: EventBus Signals | CollectionSystem listens for `rabbit_born` — does not call RabbitSystem directly | LOW |
| ADR-0004: Balance JSON | Species catalogue and milestone rewards in `balance.json` | LOW |
| ~~ADR-0017~~: CollectionSystem | **MISSING** — persistence model for species registry not decided | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-collection-001 | Pokedex completion tracking + rewards | ❌ No ADR (ADR-0017 needed) |

## Definition of Done

This epic is complete when:
- New species are registered correctly on `rabbit_born`
- `get_completion_percent()` returns accurate value across save/load
- Completion milestones trigger reward signals
- PrestigeSystem reads completion percent correctly for eligibility check
- All Logic stories have passing tests in `tests/unit/`

## Next Step

1. Write ADR-0017: `/architecture-decision "CollectionSystem species registry persistence model"`
2. Then: `/create-stories collection-system`
