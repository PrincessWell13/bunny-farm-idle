# QA Evidence — S05-06 Food Inventory Widget

**Story**: `production/epics/hud/story-004-food-inventory-widget.md`
**Story Type**: UI
**Date**: 2026-05-22
**Reviewer**: gdscript-specialist

---

## Implementation Summary

The food inventory widget is implemented as part of `src/ui/hud.gd` (Story-004 section).
Scenes wire individual food labels via `HUD.register_food_label(food_id, label)`.

**Signal deviation noted**: Story specified `rabbit_fed(rabbit_id, food_id)` but the actual
EventBus signal is `food_used(food_id: String)`. Implementation uses `food_used`:
- `FoodSystem.feed_rabbit()` now emits `EventBus.food_used.emit(food_id)` on successful deduction
- HUD subscribes to `food_used` (not a non-existent `rabbit_fed`)
- `food_used` signal was already defined in `event_bus.gd` but was previously never emitted

---

## AC Verification

| AC | Description | Status | Notes |
|----|-------------|--------|-------|
| AC-1 | Subscribe food_harvested + rabbit_fed in _ready(); disconnect in _exit_tree() | PASS | Uses `food_used` instead of `rabbit_fed` (see deviation note). Both subscribe in `_ready()`, disconnect via `is_connected` guard in `_exit_tree()`. |
| AC-2 | _ready() calls FoodSystem.get_inventory() for initial display | PASS | `_refresh_food_display()` called at end of `_ready()` — reads all keys from `FoodSystem.get_inventory()`. |
| AC-3 | Grass label always visible, including at 0 | PASS | `_update_food_label()` sets `label.text = str(count)` — never hides the label. "0" is displayed when count is 0. |
| AC-4 | food_harvested increments count by quantity | PASS | `_on_food_harvested()` adds quantity to `_food_counts[food_id]`, then calls `_update_food_label()`. |
| AC-5 | food deduction decrements count by 1 | PASS | `_on_food_used()` decrements `_food_counts[food_id]` by 1, clamped to 0. |
| AC-6 | Never displays negative count | PASS | `maxi(..., 0)` clamp in `_on_food_used()` guarantees floor at 0. |
| AC-7 | No hardcoded "grass" key in update logic | PASS | All update methods use `food_id` parameter from signal payload. The string "grass" does not appear in any update path. |

---

## Files Modified

| File | Change |
|------|--------|
| `src/ui/hud.gd` | Added Story-004 section: `_food_counts`, `_food_labels`, `register_food_label()`, `get_food_count()`, `_refresh_food_display()`, `_update_food_label()`, `_on_food_harvested()`, `_on_food_used()` |
| `src/core/food_system.gd` | Added `EventBus.food_used.emit(food_id)` after successful deduction in `feed_rabbit()` |

---

## Manual Screenshot Checklist

*Pending in-game sign-off once HUD.tscn scene has food labels wired:*

- [ ] Screenshot: HUD showing grass count = N (non-zero from save state) on load
- [ ] Screenshot: HUD showing grass count = 0 (label visible, not hidden)
- [ ] Screenshot: grass count increments after farm plot harvest fires `food_harvested`
- [ ] Screenshot: grass count decrements after `feed_rabbit()` fires `food_used`
- [ ] Observation: count never goes below 0 after feeding with 0 grass
- [ ] Code inspection: no string `"grass"` literal in the update handler path

---

## QA Sign-Off

**Status**: Pending in-game scene wiring and manual screenshot capture.
