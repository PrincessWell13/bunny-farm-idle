# Story 001: Inventory Schema — food_inventory Initialisation and Mutation Contract

> **Epic**: FoodSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.3 — Hệ thống thức ăn)
**Requirement**: `TR-food-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0009 Accepted ✅

**ADR Governing Implementation**: ADR-0009 (FoodSystem Inventory Model and Farm Plot Timer)
**ADR Decision Summary**: Food inventory is stored as `Dictionary[String, int]` at `GameState.food_inventory`, keyed by `food_id` string. FoodSystem is the sole mutator. Inventory keys must be valid food_id strings from balance.json. Quantity is clamped to `balance.json food.max_stack` (default 99) on any add operation. `get_inventory()` returns a copy, not a reference.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Dictionary` and `Dictionary.duplicate()` are stable in Godot 4.6. No post-cutoff APIs required.

**Control Manifest Rules (Core layer)**:
- Required: all variables and function signatures must be statically typed (F-02)
- Required: balance values (`max_stack` default) loaded from `balance.json` via `_load_balance_data()` (F-04)
- Forbidden: hardcoded balance values in `food_system.gd`
- Forbidden: direct mutation of `GameState.food_inventory` from any script other than `FoodSystem`

---

## Acceptance Criteria

1. `GameState.food_inventory` initialises as an empty `Dictionary` when `GameState._reset_state()` is called; no keys or values are present at initialisation
2. `FoodSystem.get_inventory()` returns a copy of `GameState.food_inventory` (via `Dictionary.duplicate()`), not a direct reference; mutating the returned Dictionary does not affect `GameState.food_inventory`
3. All keys present in `GameState.food_inventory` at runtime are valid `food_id` strings drawn from the `food` section of `balance.json`; no unknown key is ever written to the inventory
4. Inventory quantity for any food_id never goes below zero; any code path that would produce a negative quantity must be rejected before the mutation occurs
5. When an add operation would push a food_id's quantity above `balance.json food.max_stack` (default 99), the quantity is clamped to `max_stack`; the excess is silently discarded

---

## Implementation Notes

*Derived from ADR-0009 data model and ADR-0004 loading pattern:*

### GameState field declaration

```gdscript
# src/core/game_state.gd — add to _reset_state():
var food_inventory: Dictionary = {}   # runtime type: Dictionary[String, int]
```

### FoodSystem get_inventory

```gdscript
func get_inventory() -> Dictionary:
    return GameState.food_inventory.duplicate()
```

### FoodSystem internal add helper (used by harvest path in story-003)

```gdscript
func _add_to_inventory(food_id: String, quantity: int) -> void:
    if not _food_defs.has(food_id):
        push_warning("FoodSystem: unknown food_id '%s' — skipping inventory add" % food_id)
        return
    var current: int = GameState.food_inventory.get(food_id, 0)
    var max_stack: int = int(_food_defs[food_id].get(&"max_stack", _default_max_stack))
    GameState.food_inventory[food_id] = mini(current + quantity, max_stack)
    GameState.mark_dirty()
```

### FoodSystem internal deduct helper (used by feed_rabbit in story-002)

```gdscript
func _deduct_from_inventory(food_id: String, quantity: int) -> bool:
    var current: int = GameState.food_inventory.get(food_id, 0)
    if current < quantity:
        return false
    GameState.food_inventory[food_id] = current - quantity
    GameState.mark_dirty()
    return true
```

### balance.json — food section additions required

```json
"food": {
    "max_stack": 99,
    "items": {
        "grass":      { "max_stack": 99 },
        "carrot":     { "max_stack": 99 },
        "star_carrot":{ "max_stack": 99 }
    }
}
```

`_food_defs` cache is loaded once in `FoodSystem._ready()` using the ADR-0004 loading pattern. Fall back to `_default_max_stack = 99` if the key is absent for any food type.

### StringName constants to avoid key-typo bugs (ADR-0009 risk mitigation)

```gdscript
const KEY_FOOD_ID    := &"food_id"
const KEY_STARTED_AT := &"started_at"
const KEY_DURATION   := &"duration"
const KEY_MAX_STACK  := &"max_stack"
```

---

## Out of Scope

- Farm plot data structure (`GameState.farm_plots`) — covered in story-003
- Feeding pipeline — covered in story-002
- SaveSystem round-trip for `food_inventory` — dependent on SaveSystem epic

---

## QA Test Cases

- **AC-1**: initialises empty
  - Given: `GameState._reset_state()` called on a fresh GameState
  - When: `GameState.food_inventory` is read
  - Then: `food_inventory.is_empty() == true`

- **AC-2**: `get_inventory()` returns a copy
  - Given: `GameState.food_inventory = {"grass": 5}`
  - When: `var copy := FoodSystem.get_inventory(); copy["grass"] = 99`
  - Then: `GameState.food_inventory["grass"] == 5` (original unchanged)

- **AC-3**: unknown food_id rejected
  - Given: `_food_defs` contains only `"grass"`, `"carrot"`, `"star_carrot"`
  - When: `FoodSystem._add_to_inventory("unknown_food", 1)` is called
  - Then: `GameState.food_inventory` does not contain `"unknown_food"`; a warning is pushed

- **AC-4**: quantity never goes negative
  - Given: `GameState.food_inventory = {"grass": 0}`
  - When: `FoodSystem._deduct_from_inventory("grass", 1)` is called
  - Then: returns `false`; `GameState.food_inventory["grass"] == 0`

- **AC-5**: max_stack clamp on add
  - Given: `GameState.food_inventory = {"grass": 97}`; `max_stack = 99`
  - When: `FoodSystem._add_to_inventory("grass", 5)`
  - Then: `GameState.food_inventory["grass"] == 99` (clamped, not 102)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/food_system_inventory_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/food_system_inventory_test.gd` — 7 test functions

---

## Dependencies

- No story dependencies — this is the foundation story for the FoodSystem epic
- Requires `GameState.food_inventory` field to exist before testing
- Unlocks: story-002 (feed_rabbit), story-003 (farm plot timers)

---

## Completion Notes

**Completed**: 2026-05-19
**Criteria**: 5/5 passing
**Deviations**:
- ADVISORY: `var _default_max_stack: int = 99` — GDScript-side fallback default, overwritten from balance.json at runtime. Consistent with established fallback pattern (HabitatSystem stories).
**Test Evidence**: Logic — `tests/unit/core/food_system_inventory_test.gd` (7 functions) ✅
**Code Review**: Skipped — Lean mode
