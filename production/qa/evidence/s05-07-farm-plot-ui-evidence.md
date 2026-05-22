# QA Evidence — S05-07: Farm Plot Progress UI

**Story**: production/epics/hud/story-005-farm-plot-progress-ui.md
**Story type**: UI (advisory gate)
**Date**: 2026-05-22
**Author**: gdscript-specialist

---

## Implementation Summary

Changes made:
- `src/core/food_system.gd`: Added `harvest_plot(plot_index: int) -> bool`
  - Guards: bounds check + readiness check (elapsed ≥ duration)
  - On success: removes plot, adds to inventory, emits food_harvested + farm_plots_updated
- `src/ui/hud.gd`: Added Story-005 farm plot UI section
  - `@export var plot_slot_labels: Array[Label]` — one per slot
  - `@export var plot_slot_buttons: Array[Button]` — one per slot (tap targets)
  - `_countdown_timer: Timer` — 1-second interval, fires `_update_countdowns`
  - `_refresh_all_plots()` — reads FoodSystem.get_farm_plot_state(), renders all slots
  - `_render_plot()` / `_render_empty()` — per-slot render helpers
  - `on_plot_tapped(plot_index)` — readiness guard → FoodSystem.harvest_plot()
  - `farm_plots_updated` signal connected/disconnected in _ready/_exit_tree

---

## Acceptance Criteria Checklist

| AC | Description | Status | Notes |
|----|-------------|--------|-------|
| AC-1 | Farm plot slots visible in UI | ⏳ Pending | Requires scene wiring in HUD.tscn |
| AC-2 | Empty plot shows "SEED" call-to-action | ⏳ Pending | `_render_empty()` sets label.text = "SEED" — verify in scene |
| AC-3 | In-progress plot shows countdown in seconds | ⏳ Pending | `_render_plot()` sets "%ds" % remaining — verify in scene |
| AC-4 | Countdown decrements in real time (≥ once/second) | ✅ Code confirmed | `_countdown_timer.wait_time = 1.0` fires `_update_countdowns` |
| AC-5 | `farm_plots_updated` signal triggers immediate re-render | ✅ Code confirmed | `_on_farm_plots_updated` calls `_refresh_all_plots()` |
| AC-6 | Countdown → "READY" transition when timer expires | ✅ Code confirmed | `_set_slot_display` changes label to "READY" when remaining ≤ 0 |
| AC-7 | Tapping READY plot calls `FoodSystem.harvest_plot()` | ✅ Code confirmed | `on_plot_tapped` guards remaining > 0, then delegates |
| AC-8 | After harvest, slot resets to empty state | ✅ Code confirmed | `farm_plots_updated` fires → `_refresh_all_plots()` → `_render_empty` |
| AC-9 | Boot offline state shows READY immediately | ✅ Code confirmed | `_refresh_all_plots()` in `_ready()` after FoodSystem deferred resolve |

---

## Screenshot Checklist

*(To be completed after scene wiring in Godot editor)*

- [ ] Screenshot: farm view showing 2+ plot slots
- [ ] Screenshot: at least one empty slot displaying "SEED"
- [ ] Screenshot: at least one in-progress slot with countdown (e.g. "45s")
- [ ] Screenshot: at least one READY slot with "READY" label and enabled button
- [ ] Screenshot: after tapping READY — slot resets and food count increments

---

## Sign-off

**Lead sign-off**: Pending — requires screenshots above
