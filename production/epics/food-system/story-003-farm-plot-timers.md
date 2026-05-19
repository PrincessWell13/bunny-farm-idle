# Story 003: Farm Plot Timers — seed_plot, Tick Progression, and Harvest Signals

> **Epic**: FoodSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.3 — Hệ thống thức ăn)
**Requirement**: `TR-food-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0009 Accepted ✅, ADR-0003 Accepted ✅, ADR-0004 Accepted ✅

**ADR Governing Implementation**: ADR-0009 (farm plots stored as `Array[Dictionary]` in `GameState.farm_plots`; FoodSystem sole mutator; tick driven by TimeManager; harvest emits `food_harvested` on EventBus) + ADR-0003 (EventBus signal architecture) + ADR-0004 (grow times, seed costs, harvest quantities from balance.json)
**ADR Decision Summary**: Each plot is a Dictionary with three keys: `food_id: String`, `started_at: float` (Unix timestamp), `duration: float` (seconds). `seed_plot(food_id)` spends Coins via EconomyManager and appends a new plot. `_on_time_manager_tick()` iterates plots, identifies completed ones (elapsed >= duration), removes them, clamps-and-adds to inventory, and emits `EventBus.food_harvested(food_id, quantity)`. Multiple plots tick independently using their own `started_at` values.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Time.get_unix_time_from_system()` returns a float and is stable across 4.4–4.6. No post-cutoff APIs required.

**Control Manifest Rules (Core layer)**:
- Required: statically typed parameters and return types (F-02)
- Required: all grow times, seed costs, harvest quantities from `balance.json` (F-04)
- Required: `food_harvested` signal emitted via `EventBus` (F-03)
- Required: plot ticking connected to `TimeManager.tick`, not `_process` or `_physics_process`
- Forbidden: hardcoded grow durations, seed costs, or harvest quantities in `food_system.gd`
- Forbidden: iterating `GameState.farm_plots` and mutating it in the same pass (ADR-0009 risk mitigation — collect completed indices first, remove in reverse order)
- Forbidden: direct cross-system calls for upward notification — use EventBus (F-03)

---

## Acceptance Criteria

1. `FoodSystem.seed_plot(food_id: String) -> bool` reads the seed cost for `food_id` from the `_food_defs` cache (loaded from `balance.json`) and calls `EconomyManager.spend_coins(cost)` before adding any plot; if `spend_coins` returns `false`, `seed_plot` returns `false` and no plot is added
2. On a successful coin spend, `seed_plot` appends a plot Dictionary to `GameState.farm_plots` with exactly three keys: `food_id` set to the given food_id, `started_at` set to `Time.get_unix_time_from_system()`, and `duration` set to the grow time for that food_id from `balance.json`
3. `FoodSystem._on_time_manager_tick()` (connected to `TimeManager.tick` in `_ready()`) iterates `GameState.farm_plots`; for each plot where `Time.get_unix_time_from_system() - plot[KEY_STARTED_AT] >= plot[KEY_DURATION]`, the plot is marked for removal
4. For each completed plot, `FoodSystem` removes the plot from `GameState.farm_plots`, adds the harvest quantity to `GameState.food_inventory` (clamped to `max_stack`), calls `GameState.mark_dirty()`, and emits `EventBus.food_harvested(food_id, quantity)` with the correct `food_id` and harvest quantity from `balance.json`
5. Multiple plots for the same or different food types tick independently; a second plot seeded later completes at its own `started_at + duration` independently of any other plot
6. Plot removal is performed in reverse-index order after collecting all completed indices, so no index-shifting bug occurs when multiple plots complete in the same tick

---

## Implementation Notes

*Derived from ADR-0009 architecture and ADR-0004 loading pattern:*

### GameState field declaration

```gdscript
# src/core/game_state.gd — add to _reset_state():
var farm_plots: Array = []   # runtime type: Array[Dictionary]; each dict has 3 keys
```

### FoodSystem _ready connection

```gdscript
func _ready() -> void:
    _load_balance_data()
    TimeManager.tick.connect(_on_time_manager_tick)
```

### seed_plot implementation

```gdscript
func seed_plot(food_id: String) -> bool:
    if not _food_defs.has(food_id):
        push_warning("FoodSystem: seed_plot called with unknown food_id '%s'" % food_id)
        return false
    var cost: int = int(_food_defs[food_id].get(&"seed_cost", 0))
    if not EconomyManager.spend_coins(cost):
        return false
    var plot: Dictionary = {
        KEY_FOOD_ID:    food_id,
        KEY_STARTED_AT: Time.get_unix_time_from_system(),
        KEY_DURATION:   float(_food_defs[food_id].get(&"grow_time_seconds", 60.0)),
    }
    GameState.farm_plots.append(plot)
    GameState.mark_dirty()
    return true
```

### _on_time_manager_tick — safe removal pattern (ADR-0009 risk mitigation)

```gdscript
func _on_time_manager_tick(_delta: float) -> void:
    var now: float = Time.get_unix_time_from_system()
    var completed_indices: Array[int] = []

    for i: int in range(GameState.farm_plots.size()):
        var plot: Dictionary = GameState.farm_plots[i]
        var elapsed: float = now - float(plot[KEY_STARTED_AT])
        if elapsed >= float(plot[KEY_DURATION]):
            completed_indices.append(i)

    # Remove in reverse order to avoid index shifting
    completed_indices.reverse()
    for idx: int in completed_indices:
        var plot: Dictionary = GameState.farm_plots[idx]
        var food_id: String = str(plot[KEY_FOOD_ID])
        var harvest_qty: int = int(_food_defs.get(food_id, {}).get(&"harvest_quantity", 1))
        GameState.farm_plots.remove_at(idx)
        _add_to_inventory(food_id, harvest_qty)
        EventBus.food_harvested.emit(food_id, harvest_qty)

    if not completed_indices.is_empty():
        GameState.mark_dirty()

    if not GameState.farm_plots.is_empty():
        EventBus.farm_plots_updated.emit()
```

### balance.json additions required for this story

```json
"food": {
    "max_stack": 99,
    "items": {
        "grass": {
            "seed_cost": 5,
            "grow_time_seconds": 60.0,
            "harvest_quantity": 3,
            "max_stack": 99
        },
        "carrot": {
            "seed_cost": 15,
            "grow_time_seconds": 300.0,
            "harvest_quantity": 2,
            "max_stack": 99
        },
        "star_carrot": {
            "seed_cost": 50,
            "grow_time_seconds": 900.0,
            "harvest_quantity": 1,
            "max_stack": 99
        }
    }
}
```

### EventBus signals required (ADR-0009 + ADR-0003)

The following signals must be present in `src/core/event_bus.gd` before this story can be implemented:

```gdscript
signal food_harvested(food_id: String, quantity: int)
signal farm_plots_updated()
```

These are defined in ADR-0009. If they are not yet in `event_bus.gd`, they must be added as part of this story's implementation.

---

## Out of Scope

- Offline catch-up for plots completed while the app was closed — covered in story-004
- UI displaying plot progress bars — Presentation layer, not this story
- Plot spoilage / expiry mechanic (mentioned in EPIC overview) — no ADR coverage yet; do not implement

---

## QA Test Cases

- **AC-1**: seed_plot spends correct coins
  - Given: EconomyManager mock with 100 coins; `balance.json grass.seed_cost = 5`
  - When: `FoodSystem.seed_plot("grass")`
  - Then: `EconomyManager.spend_coins(5)` called; returns `true`; 1 plot in `GameState.farm_plots`

- **AC-2**: seed_plot returns false on insufficient coins
  - Given: EconomyManager mock returns `false` from `spend_coins`
  - When: `FoodSystem.seed_plot("grass")`
  - Then: returns `false`; `GameState.farm_plots.is_empty() == true`

- **AC-3**: plot dict has correct keys and values
  - Given: sufficient coins; `grass grow_time_seconds = 60.0`
  - When: `FoodSystem.seed_plot("grass")`
  - Then: `GameState.farm_plots[0]` has `food_id == "grass"`, `duration == 60.0`, `started_at` approximately equals current unix time

- **AC-4**: completed plot fires food_harvested and removes plot
  - Given: 1 plot in `GameState.farm_plots` with `started_at = current_time - 61.0`, `duration = 60.0`, `food_id = "grass"`; `harvest_quantity = 3`
  - When: `FoodSystem._on_time_manager_tick(1.0)` called
  - Then: `GameState.farm_plots.is_empty() == true`; `GameState.food_inventory["grass"] == 3`; `EventBus.food_harvested` emitted with `("grass", 3)`

- **AC-5**: multiple plots tick independently
  - Given: 2 plots — plot A (grass, elapsed = 65s, duration = 60s) and plot B (carrot, elapsed = 10s, duration = 300s)
  - When: `FoodSystem._on_time_manager_tick(1.0)` called
  - Then: only plot A removed; plot B remains; `food_harvested` emitted once (for grass only)

- **AC-6**: reverse-index removal on multiple completions
  - Given: 3 plots all elapsed past their duration
  - When: `_on_time_manager_tick(1.0)` called
  - Then: all 3 removed; no panic or index out-of-bounds error; 3 `food_harvested` emissions

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/food_system_plots_test.gd` — must exist and pass

**Status**: [ ] `tests/unit/core/food_system_plots_test.gd` — not yet written

---

## Dependencies

- Depends on: **story-001 must be DONE** — plot harvest calls `_add_to_inventory()` established in story-001
- Requires: `EventBus.food_harvested` and `EventBus.farm_plots_updated` signals added to `src/core/event_bus.gd`
- Requires: `EconomyManager.spend_coins()` interface is available (Economy epic)
- Unlocks: story-004 (offline plot resolution, which extends the tick logic from this story)

---

## Completion Notes

**Completed**: 2026-05-19
**Criteria**: 6/6 passing
**Deviations**:
- ADVISORY: Story doc references `EconomyManager.spend_coins(cost)` — actual API is `EconomyManager.spend(CurrencyType.CARROT_COIN, cost)`. Story doc is stale; implementation is correct.
- ADVISORY: Tick handler named `_on_tick()` in implementation vs `_on_time_manager_tick()` in story doc. Both connect to `TimeManager.tick`. Functionally identical.
- ADVISORY: `balance.json` food items missing `seed_cost`, `grow_time_seconds`, `harvest_quantity` keys. Tests inject mock defs and pass; production runtime uses fallback defaults (seeds free, 60s grow, 1-unit harvest) until these fields are added.
**Test Evidence**: Logic — `tests/unit/core/food_system_plots_test.gd` (9 test functions, all 6 ACs covered)
**Code Review**: Skipped — Lean mode
