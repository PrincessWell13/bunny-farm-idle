# Story S05-08: Save/Load Round-Trip — Sprint-04 Fields

> **Epic**: SaveSystem
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-05-18
> **Sprint**: Sprint 05

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3 — Economy, FoodSystem, ExpeditionSystem)
**Requirement**: `TR-save-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (Firebase Local-First Save), ADR-0009 (FoodSystem), ADR-0011 (ExpeditionSystem)
**Origin**: QA Condition C04-06 from sprint-04 sign-off report.

**Problem statement**: `_serialise_game_state()` in `save_system.gd` does not include `farm_plots`
or `food_inventory`. These Sprint-04 fields (FoodSystem) are silently dropped on save, meaning
they are lost on the next load. `active_expeditions` is already in the schema but has never been
verified through a full round-trip test.

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (Foundation layer)**:
- Required: SaveSystem only accesses GameState via `_gs()` helper — never direct autoload call (C-01)
- Required: pure data fields — no engine node refs in serialised output (F-05)
- Forbidden: calling SceneManager from SaveSystem (C-02)

---

## Acceptance Criteria

1. `_serialise_game_state()` includes a `food_inventory` key (Dictionary) with the full contents of `GameState.food_inventory`
2. `_serialise_game_state()` includes a `farm_plots` key (Array) with the full contents of `GameState.farm_plots`
3. `_populate_game_state()` restores `food_inventory` from the save dictionary using `.get("food_inventory", {})`
4. `_populate_game_state()` restores `farm_plots` from the save dictionary using `.get("farm_plots", [])`
5. A full serialise→deserialise round-trip for `food_inventory` preserves all item keys and quantities
6. A full serialise→deserialise round-trip for `farm_plots` preserves all plot entries (food_id, started_at, duration)
7. A full serialise→deserialise round-trip for `active_expeditions` preserves all slot fields (slot_id, zone_id, started_at, loot_seed, status)
8. `_populate_game_state({})` (empty dict) sets `food_inventory = {}`, `farm_plots = []` without crash

---

## Implementation Notes

Modify `src/core/save_system.gd`:

```gdscript
func _serialise_game_state() -> Dictionary:
    var gs := _gs()
    # ... existing fields ...
    return {
        # ... existing keys ...
        "food_inventory": gs.food_inventory.duplicate(),
        "farm_plots": gs.farm_plots.duplicate(),
        # active_expeditions already present — verify only
    }

func _populate_game_state(data: Dictionary) -> void:
    var gs := _gs()
    # ... existing fields ...
    gs.food_inventory = data.get("food_inventory", {})
    gs.farm_plots = data.get("farm_plots", [])
    # active_expeditions already present — verify only
```

---

## Out of Scope

- Changing the FoodSystem or ExpeditionSystem serialisation format beyond what's already in GameState
- Firebase push/fetch round-trip — tested by story-003 and story-004
- HabitatSystem hutch serialisation — not yet implemented

---

## Test Evidence

**Story Type**: Integration
**Required test file**: `tests/integration/core/save_load_sprint04_test.gd`
- Must cover all 8 ACs
- Must use injected GameState and TimeManager (no autoload access in tests)
- Must not write to `user://` — use temp path injection via `_system._save_path`

**Status**: [x] `tests/integration/core/save_load_sprint04_test.gd` — 8 test functions

---

## Dependencies

- Depends on: save-system/story-003-gamestate-serialisation.md (Complete ✅)
- Depends on: food-system/story-001-inventory-schema.md (Complete ✅)
- Depends on: expedition-system/story-001-start-expedition.md (Complete ✅)

---

## Completion Notes
**Completed**: 2026-05-22
**Criteria**: 8/8 passing
**Root cause fixed**: `_serialise_game_state()` and `_populate_game_state()` were both missing `food_inventory` and `farm_plots` — Sprint-04 fields would have been silently lost on every save/load cycle. Added 4 lines total (2 per method).
**Deviations**: None
**Test Evidence**: Integration — `tests/integration/core/save_load_sprint04_test.gd` (8 tests, all ACs covered)
**Code Review**: Skipped — Lean mode
**Closes**: QA Condition C04-06 from sprint-04 sign-off
