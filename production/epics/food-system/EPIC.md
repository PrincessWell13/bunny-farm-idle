# Epic: FoodSystem

> **Layer**: Feature
> **GDD**: design/gdd/bunny-farm-idle-master.md §3.3
> **Architecture Module**: `src/core/food_system.gd`
> **Status**: Ready
> **Stories**: 4 stories created — see table below
> **Control Manifest Version**: 2026-05-18

## Overview

FoodSystem owns the player's food inventory dictionary and the farm plot grow timers. It exposes `feed_rabbit(rabbit_id, food_id)` which deducts the food from inventory, then calls `RabbitSystem.feed_rabbit()` to apply the stat restoration. It also tracks farm plot states — each plot has a grow timer that produces food items on completion. Spending Coins via EconomyManager seeds new plots. All food definitions (stat effects, grow time, spoilage) live in `balance.json`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | FoodSystem boots after RabbitSystem and EconomyManager | LOW |
| ADR-0004: Balance JSON | Food stat effects, grow timers, spoilage rates in `balance.json` | LOW |
| ADR-0009: FoodSystem Inventory Model | Dictionary inventory + GameState farm_plots; FoodSystem sole mutator | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-food-001 | Food inventory + farm plot timers + feeding pipeline | ADR-0009 ✅ |


## Stories

| Story | Title | Type | TR-ID | ADRs | Status |
|-------|-------|------|-------|------|--------|
| [story-001](story-001-inventory-schema.md) | Inventory Schema — food_inventory Initialisation and Mutation Contract | Logic | TR-food-001 | ADR-0009 | Ready |
| [story-002](story-002-feed-rabbit.md) | feed_rabbit — Inventory Deduction and RabbitSystem Delegation | Integration | TR-food-001 | ADR-0009, ADR-0005 | Ready |
| [story-003](story-003-farm-plot-timers.md) | Farm Plot Timers — seed_plot, Tick Progression, and Harvest Signals | Logic | TR-food-001 | ADR-0009, ADR-0003, ADR-0004 | Ready |
| [story-004](story-004-offline-plot-resolution.md) | Offline Plot Resolution — Boot-Time Catch-Up for Completed Farm Plots | Integration | TR-food-001 | ADR-0009, ADR-0001 | Ready |

## Definition of Done

This epic is complete when:
- Food inventory updates correctly on feed and on farm plot harvest
- `feed_rabbit()` deducts inventory and invokes `RabbitSystem.feed_rabbit()`
- Farm plot timers progress per `TimeManager.tick` and signal completion
- No food item quantities go negative
- All Logic and Integration stories have passing tests in `tests/`

## Next Step

1. Implement story-001: add `food_inventory` field to `GameState`, write `get_inventory()` and internal mutation helpers in `FoodSystem`, write `tests/unit/core/food_system_inventory_test.gd`
2. Implement story-002 (after story-001 is Done): wire `FoodSystem.feed_rabbit()` delegation and rollback, write `tests/integration/core/food_system_feed_test.gd`
3. Implement story-003 (after story-001 is Done): add `farm_plots` field to `GameState`, implement `seed_plot()` and `_on_time_manager_tick()`, add `food_harvested` + `farm_plots_updated` to `EventBus`, write `tests/unit/core/food_system_plots_test.gd`
4. Implement story-004 (after story-003 is Done): add `_resolve_offline_plots()` boot hook, write `tests/integration/core/food_system_offline_test.gd`
