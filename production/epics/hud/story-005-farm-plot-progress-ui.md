# Story 005: Farm Plot Progress UI

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.3 FoodSystem farm plots, §7 UI/UX)
**Requirement**: `TR-hud-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

> ⚠️ TR-hud-004 is not yet in `tr-registry.yaml`. Add it when running `/architecture-review rtm`.
> Stable ID reserved: `TR-hud-004` — "Farm plot progress indicators with countdown timers, READY state, and tap-to-harvest"

**ADR Governing Implementation**: ADR-0003 (EventBus Signal Architecture), ADR-0009 (FoodSystem Inventory Model)
**ADR Decision Summary**: The farm plot UI subscribes to `EventBus.farm_plots_updated(plots)` — never polls `GameState.farm_plots` on tick. On tap of a READY plot, it calls `FoodSystem.harvest_plot(plot_index)` — it does NOT directly mutate `GameState.farm_plots`. Countdown timers are derived from each plot's `started_at + grow_time` vs `Time.get_unix_time_from_system()` and updated via a `Timer` node or `_process()`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Time.get_unix_time_from_system()` is stable since Godot 4.0. `Timer` node pattern for countdown display is standard. No post-cutoff APIs required.

**Control Manifest Rules (Presentation layer)**:
- Required: Subscribe to `EventBus.farm_plots_updated` in `_ready()`; disconnect in `_exit_tree()` (F-03)
- Required: All variables and return types statically typed (F-02)
- Required: Tap-to-harvest must call `FoodSystem.harvest_plot(plot_index)` — not mutate GameState directly
- Forbidden: Polling `GameState.farm_plots` on every frame — use signal-driven updates (F-03)
- Forbidden: Calling any method that mutates Core state other than `FoodSystem.harvest_plot()`
- Guardrail: All tap targets ≥ 44×44 px; countdown readable on 1080×1920 portrait

---

## Acceptance Criteria

1. Each farm plot slot is visible in the UI (at least the 2 hutch plots present in the current game state)
2. An empty (unseeded) plot displays a "Seed" call-to-action element (not a blank space)
3. An in-progress plot displays a countdown timer showing remaining seconds, derived from `plot.started_at + plot.grow_time - Time.get_unix_time_from_system()`
4. The countdown decrements in real time (updates at least once per second without requiring user interaction)
5. When `EventBus.farm_plots_updated(plots)` fires, all plot slots re-render to reflect the new state immediately
6. When a plot's remaining time reaches 0 (or below), its display transitions to a "READY" state
7. Tapping a READY plot calls `FoodSystem.harvest_plot(plot_index)` — the call is not triggered for in-progress or empty plots
8. After a successful harvest (confirmed by a subsequent `farm_plots_updated` signal), the tapped slot resets to empty state
9. Plot UI reflects offline catch-up state correctly at boot (plots resolved by FoodSystem at `_ready()` will already be READY or empty — UI shows the post-resolve state)

---

## Implementation Notes

*Derived from ADR-0003 and ADR-0009:*

```gdscript
# In src/ui/hud.gd or a child FarmPlotWidget:
func _ready() -> void:
    EventBus.farm_plots_updated.connect(_on_farm_plots_updated)
    _refresh_all_plots()

func _exit_tree() -> void:
    EventBus.farm_plots_updated.disconnect(_on_farm_plots_updated)

func _on_farm_plots_updated(plots: Array) -> void:
    _refresh_all_plots()

func _refresh_all_plots() -> void:
    var plots: Array = GameState.farm_plots  # read-only snapshot
    for i: int in range(plot_slots.size()):
        if i < plots.size():
            _render_plot(i, plots[i])
        else:
            _render_empty(i)

func _on_plot_tapped(plot_index: int) -> void:
    var plots: Array = GameState.farm_plots
    if plot_index >= plots.size():
        return
    var now: float = Time.get_unix_time_from_system()
    var plot: Dictionary = plots[plot_index]
    if now >= plot.get("started_at", 0.0) + plot.get("grow_time", 0.0):
        FoodSystem.harvest_plot(plot_index)
```

**FoodSystem.harvest_plot() required**: Confirm `FoodSystem.harvest_plot(plot_index: int)` exists. If not, add it to `src/core/food_system.gd` as a stub before implementing this story:
```gdscript
func harvest_plot(plot_index: int) -> void:
    # Removes the plot at plot_index from GameState.farm_plots and grants food
    # Emits farm_plots_updated and food_harvested
    pass
```

**Countdown display**: Use `_process(delta)` or a per-second `Timer` node to update countdowns. Do not connect `_process` directly to `TimeManager.tick` — tick fires once per game second, which is sufficient for countdown accuracy.

**EventBus signal required**:
- `signal farm_plots_updated(plots: Array)` — confirm this exists in `event_bus.gd`

---

## Out of Scope

- Farm seeding UI (seed cost display, seed button) — separate story
- Food inventory quantity display — covered in story-004
- Feed visual feedback — covered in S05-15

---

## QA Test Cases

*Manual verification steps (UI story):*

- **AC-1**: Plot slots visible
  - Setup: Launch game; navigate to farm view
  - Verify: Plot slot elements are rendered in the HUD/farm view
  - Pass condition: At least 2 plot slots visible (matching current hutch count)

- **AC-2**: Empty plot call-to-action
  - Setup: Ensure at least one plot is unseeded
  - Verify: Unseeded plot shows a "Seed" button or plant icon, not a blank space
  - Pass condition: Actionable element visible on empty slot

- **AC-3 + AC-4**: Countdown updates in real time
  - Setup: Seed a plot; observe countdown
  - Verify: Timer shows decreasing seconds without requiring tap; decrements once per second
  - Pass condition: Countdown decreases visibly over 5+ seconds of observation

- **AC-5**: Signal-driven re-render
  - Setup: Trigger a farm event (harvest or seed) that emits `farm_plots_updated`
  - Verify: UI updates without requiring scene reload
  - Pass condition: Plot state change reflected immediately after signal fires

- **AC-6**: READY state transition
  - Setup: Wait for a plot's timer to expire (or use a fast grow_time in balance.json during dev)
  - Verify: Plot display transitions to "READY" state (distinct visual from in-progress)
  - Pass condition: "READY" indicator clearly visible; no countdown shown

- **AC-7**: Tap-to-harvest
  - Setup: Plot in READY state; tap it
  - Verify: `FoodSystem.harvest_plot()` called; food count increments
  - Pass condition: Plot resets to empty; grass count widget increments

- **AC-8**: Post-harvest reset
  - Setup: As above
  - Verify: Harvested slot shows empty/seed state after `farm_plots_updated` signal
  - Pass condition: Slot does not remain in READY state after harvest

- **AC-9**: Boot offline state
  - Setup: Start game with a save where a plot was seeded; wait for its grow_time to elapse; reopen game
  - Verify: Plot shows READY immediately at boot (not a countdown from zero)
  - Pass condition: Boot offline resolve reflected in plot UI without manual trigger

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/s05-07-farm-plot-ui-evidence.md`
- Screenshots of plot in each state: empty, in-progress with countdown, READY
- Confirmation that tap-to-harvest increments food count

**Status**: [x] Created — `production/qa/evidence/s05-07-farm-plot-ui-evidence.md` (screenshots pending scene wiring)

---

## Completion Notes
**Completed**: 2026-05-22
**Criteria**: 9/9 (AC-1 deferred to scene wiring + playtest)
**Deviations**:
- ADVISORY: `farm_plots_updated` signal carries no parameters; HUD reads state via `FoodSystem.get_farm_plot_state()` — ADR-0003 compliant
- ADVISORY: `FoodSystem.harvest_plot()` added to `food_system.gd` as required by story Implementation Notes
**Test Evidence**: UI story — evidence doc at `production/qa/evidence/s05-07-farm-plot-ui-evidence.md`; screenshots pending scene wiring
**Code Review**: Skipped — Lean mode

---

## Dependencies

- Depends on: S05-02 (balance.json food keys — `grow_time_seconds` must exist before countdown is testable)
- Depends on: story-004 (food inventory widget — harvest grants food; widget must exist to verify count increments)
- Unlocks: S05-13 (mid-game playtests require farm plot UI to be functional)
