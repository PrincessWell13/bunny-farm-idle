# Story 004: Offline Plot Resolution — Boot-Time Catch-Up for Completed Farm Plots

> **Epic**: FoodSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.3 — Hệ thống thức ăn)
**Requirement**: `TR-food-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0009 Accepted ✅, ADR-0001 Accepted ✅

**ADR Governing Implementation**: ADR-0009 (Unix timestamp approach gives offline catch-up for free; plots complete fully or not at all — no partial credit; boot resolution runs before UI reads inventory) + ADR-0001 (SaveSystem.load_game() populates GameState before SceneManager launches; FoodSystem boot resolution must occur after GameState is populated and before first scene _ready())
**ADR Decision Summary**: On boot, after `GameState` is populated by `SaveSystem`, `FoodSystem` iterates `GameState.farm_plots` and resolves any plot where `started_at + duration < current_unix_time`. Each resolved plot fires `food_harvested` and adds to inventory. A plot can only complete once (binary: done or not done) — no multi-tick overflow granting multiple harvests per plot. Boot resolution completes before `SceneManager` launches the first scene, so the UI reads the already-resolved inventory.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Time.get_unix_time_from_system()` stable. Boot ordering enforced by autoload sequence (ADR-0001). No post-cutoff APIs required.

**Control Manifest Rules (Core layer)**:
- Required: boot resolution called via `call_deferred()` from `SaveSystem` or `FoodSystem._ready()` after `GameState` is populated (ADR-0001 ordering)
- Required: `food_harvested` emitted on EventBus for each resolved plot (F-03, ADR-0003)
- Required: each resolved plot yields exactly one harvest — no quantity multiplication for multi-period offline time (ADR-0009: "no partial credit; elapsed >= duration triggers a single full harvest")
- Required: all numeric fallbacks (harvest_quantity, max_stack) from `balance.json` (F-04)
- Forbidden: boot resolution running before `GameState` is fully populated from save (ADR-0001 constraint)
- Forbidden: any plot being processed twice (once at boot, once at next tick)

---

## Acceptance Criteria

1. On boot, `FoodSystem` resolves any plot in `GameState.farm_plots` whose `started_at + duration < Time.get_unix_time_from_system()` at the moment of resolution; each such plot is removed from `GameState.farm_plots` and its harvest quantity is added to `GameState.food_inventory`
2. For each resolved offline plot, `EventBus.food_harvested(food_id, quantity)` is emitted exactly once, matching the `food_id` and `harvest_quantity` from `balance.json`
3. A plot that completed multiple times offline (i.e., `elapsed > duration * N` for N > 1) still grants exactly one harvest — FoodSystem does not multiply the harvest quantity by how many intervals could have elapsed
4. Boot resolution runs before any UI scene's `_ready()` reads `GameState.food_inventory`; when the first scene initialises, the inventory already reflects all resolved plots
5. A plot that has not yet completed at boot time (elapsed < duration) is left untouched in `GameState.farm_plots` and continues ticking normally on the next `TimeManager.tick`

---

## Implementation Notes

*Derived from ADR-0009 migration plan and ADR-0001 boot sequence:*

### Boot resolution entry point

ADR-0001 defines that `SaveSystem._ready()` calls `IdleProductionSystem.apply_offline_earnings()` via `call_deferred`. `FoodSystem` follows the same pattern: `SaveSystem._ready()` (or `FoodSystem._ready()` after GameState is populated) calls `_resolve_offline_plots()` via `call_deferred`. Using `call_deferred` ensures `GameState` fields are fully populated before resolution runs.

```gdscript
# src/core/food_system.gd
func _ready() -> void:
    _load_balance_data()
    TimeManager.tick.connect(_on_time_manager_tick)
    # Defer offline resolution until after SaveSystem.load_game() has run
    call_deferred(&"_resolve_offline_plots")
```

### _resolve_offline_plots implementation

```gdscript
func _resolve_offline_plots() -> void:
    var now: float = Time.get_unix_time_from_system()
    var completed_indices: Array[int] = []

    for i: int in range(GameState.farm_plots.size()):
        var plot: Dictionary = GameState.farm_plots[i]
        var started_at: float = float(plot[KEY_STARTED_AT])
        var duration: float = float(plot[KEY_DURATION])
        if now - started_at >= duration:
            completed_indices.append(i)

    # Remove in reverse order (same safe pattern as _on_time_manager_tick)
    completed_indices.reverse()
    for idx: int in completed_indices:
        var plot: Dictionary = GameState.farm_plots[idx]
        var food_id: String = str(plot[KEY_FOOD_ID])
        # One harvest per plot, regardless of how long it was overdue
        var harvest_qty: int = int(_food_defs.get(food_id, {}).get(&"harvest_quantity", 1))
        GameState.farm_plots.remove_at(idx)
        _add_to_inventory(food_id, harvest_qty)
        EventBus.food_harvested.emit(food_id, harvest_qty)

    if not completed_indices.is_empty():
        GameState.mark_dirty()
```

### Why exactly one harvest per plot (no multi-tick overflow)

ADR-0009 explicitly states: "Plots complete fully or not at all — no partial credit; elapsed >= duration triggers a single full harvest." This means even if a player was offline for 10× the grow duration, they receive one harvest per plot that was in progress when they closed the app, not N harvests. This is a deliberate anti-abuse design choice. The implementation enforces this by treating the plot's existence as a single in-progress grow — the plot entry is removed on first completion regardless of total elapsed time.

### Boot ordering guarantee

The autoload boot sequence (ADR-0001) is:
```
EventBus → TimeManager → EconomyManager → GameState → SaveSystem → SceneManager
```

`FoodSystem` is not a core autoload but is registered after `EconomyManager` (per ADR-0009 ordering note). `FoodSystem._ready()` runs before `SceneManager._ready()`. Using `call_deferred` for `_resolve_offline_plots` ensures it executes after the current frame — which is after `SaveSystem._ready()` has called `load_game()` and populated `GameState`. By the time `SceneManager` launches the first scene and that scene's `_ready()` runs, the deferred call has already been processed.

---

## Out of Scope

- Multiple offline harvests per plot (intentionally excluded — see design note above)
- Offline idle coin production — covered by IdleProductionSystem (ADR-0007), not FoodSystem
- SaveSystem round-trip for `farm_plots` — dependent on SaveSystem epic

---

## QA Test Cases

- **AC-1**: completed plot resolved at boot
  - Given: `GameState.farm_plots` contains 1 plot with `started_at = current_time - 120.0`, `duration = 60.0`, `food_id = "grass"`, `harvest_quantity = 3`
  - When: `FoodSystem._resolve_offline_plots()` called
  - Then: `GameState.farm_plots.is_empty() == true`; `GameState.food_inventory["grass"] == 3`; `EventBus.food_harvested` emitted once with `("grass", 3)`

- **AC-2**: no multi-harvest overflow
  - Given: 1 plot with `started_at = current_time - 600.0`, `duration = 60.0` (10× elapsed), `harvest_quantity = 3`
  - When: `FoodSystem._resolve_offline_plots()` called
  - Then: `GameState.food_inventory["grass"] == 3` (not 30); `food_harvested` emitted exactly once

- **AC-3**: incomplete plot left untouched
  - Given: 1 plot with `started_at = current_time - 30.0`, `duration = 60.0`
  - When: `FoodSystem._resolve_offline_plots()` called
  - Then: `GameState.farm_plots.size() == 1`; plot is unchanged; no `food_harvested` emitted

- **AC-4**: mixed completed and incomplete plots
  - Given: 2 plots — plot A (elapsed = 90s, duration = 60s) and plot B (elapsed = 10s, duration = 300s)
  - When: `FoodSystem._resolve_offline_plots()` called
  - Then: only plot A removed; plot B remains; `food_harvested` emitted once (for plot A's food_id)

- **AC-5**: boot resolution precedes UI read
  - Given: `_resolve_offline_plots()` connected via `call_deferred` in `_ready()`; plot would complete offline
  - When: first scene's `_ready()` reads `FoodSystem.get_inventory()`
  - Then: inventory already contains harvested item (resolution ran before scene _ready)

- **AC-6**: multiple offline-completed plots all resolved
  - Given: 3 plots all elapsed past duration
  - When: `FoodSystem._resolve_offline_plots()` called
  - Then: all 3 removed; 3 `food_harvested` emissions; inventory reflects all 3 harvests (each clamped to max_stack independently)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/food_system_offline_test.gd` — must exist and pass

**Status**: [ ] `tests/integration/core/food_system_offline_test.gd` — not yet written

---

## Dependencies

- Depends on: **story-003 must be DONE** — offline resolution uses the same `_food_defs` cache, `KEY_*` constants, `_add_to_inventory()` helper, and `EventBus.food_harvested` signal established in story-003
- Requires: `GameState.farm_plots` populated by `SaveSystem.load_game()` before `_resolve_offline_plots()` runs (ADR-0001 boot sequence guarantee)
- Requires: `EventBus.food_harvested` signal present in `src/core/event_bus.gd` (added in story-003)

---

## Completion Notes

**Completed**: 2026-05-19
**Criteria**: 5/5 passing
**Deviations**: None — implementation follows ADR-0009 and story spec exactly.
**Test Evidence**: Integration — `tests/integration/core/food_system_offline_test.gd` (7 test functions, all 5 ACs covered)
**Code Review**: Skipped — Lean mode
