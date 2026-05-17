# Epic: EventBus

> **Layer**: Foundation
> **GDD**: design/gdd/bunny-farm-idle-master.md
> **Architecture Module**: `src/core/event_bus.gd`
> **Status**: Ready
> **Control Manifest Version**: pending — run `/create-control-manifest` to assign
> **Stories**: 2 stories created

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Signal catalogue](story-001-signal-catalogue.md) | Logic | Complete | ADR-0003 |
| 002 | [Connect-emit-disconnect](story-002-connect-emit-disconnect.md) | Integration | Complete | ADR-0003 |

## Overview

EventBus is the sole communication channel for all cross-layer events. It is autoload #1 — the very first thing registered, so every other system can safely connect to its signals in `_ready()`. It owns nothing except signal definitions. All 22 typed signals live here, and nothing else. Writing EventBus is the prerequisite for every other system that emits or consumes signals.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | EventBus is autoload #1; must boot before all others; owns only signal definitions | LOW |
| ADR-0003: Signal-Based Communication | 22 typed signals defined here; snake_case past-tense naming; typed callable connect only | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-rabbit-001 | Hunger/Health decay notifies UI | ADR-0003 ✅ (`rabbit_stat_changed`) |
| TR-genetics-004 | Gene preview before breeding | ADR-0003 ✅ (`breed_requested`, `breeding_completed`) |
| TR-economy-001 | Currency changes reflected in HUD | ADR-0003 ✅ (`currency_changed`) |
| TR-ui-004 | ≤2 taps for frequent actions | ADR-0003 ✅ (`nav_tab_pressed`) |

> Note: All 22 signals must be implemented as defined in ADR-0003. No signal may be omitted or renamed.

## Complete Signal Catalogue (from ADR-0003)

```gdscript
## Rabbit lifecycle
signal rabbit_born(rabbit_id: String)
signal rabbit_matured(rabbit_id: String, new_stage: RabbitData.RabbitStage)
signal rabbit_stat_changed(rabbit_id: String)
signal rabbit_died(rabbit_id: String)

## Economy
signal currency_changed(currency: EconomyManager.CurrencyType, new_balance: int, delta: int)

## Production
signal production_ticked(carrot_coin: int, star_dust: int)

## Breeding
signal breed_requested(parent_a_id: String, parent_b_id: String)
signal breeding_completed(child_id: String)

## Habitat
signal hutch_dirtied(hutch_id: String)
signal hutch_upgraded(hutch_id: String, new_level: int)
signal rabbit_assigned_to_hutch(rabbit_id: String, hutch_id: String)

## Expedition
signal expedition_completed(slot_id: int, loot_summary: String)

## Save / sync
signal save_requested()
signal save_synced()
signal new_game_started()

## UI navigation
signal nav_tab_pressed(tab: HUD.NavTab)
signal notification_requested(text: String, duration_sec: float)

## Events / seasons
signal season_changed(new_season: SeasonSystem.Season)
signal event_activated(event_id: String)
signal merchant_appeared()

## Prestige
signal prestige_executed(new_prestige_count: int)

## Guild
signal guild_contribution_submitted(amount: int)
signal guild_boss_attacked(damage: int)
```

## Forbidden Patterns (from Architecture Registry)

- `string_based_signal_connect` — never `connect("signal_name", obj, "method")`; always `EventBus.signal_name.connect(callable)`
- `upward_direct_method_calls` — EventBus emits only; no methods that call other systems

## Definition of Done

This epic is complete when:
- [ ] All stories are implemented, reviewed, and closed via `/story-done`
- [ ] `EventBus` autoload registered as #1 in Godot Project Settings
- [ ] All 22 signals defined with exact typed signatures from ADR-0003
- [ ] No string-based `connect()` calls in `src/` (grep verified)
- [ ] GdUnit4: EventBus instantiates in isolation; all signals accessible
- [ ] GdUnit4: connect and emit cycle works for at least `rabbit_born` and `currency_changed`

## Next Step

Run `/create-stories event-bus` to break this epic into implementable stories.
