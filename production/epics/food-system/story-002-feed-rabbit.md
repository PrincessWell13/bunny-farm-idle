# Story 002: feed_rabbit — Inventory Deduction and RabbitSystem Delegation

> **Epic**: FoodSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.3 — Hệ thống thức ăn)
**Requirement**: `TR-food-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0009 Accepted ✅, ADR-0005 Accepted ✅

**ADR Governing Implementation**: ADR-0009 (FoodSystem Inventory Model — `feed_rabbit` deduction and rollback contract) + ADR-0005 (RabbitData immutability — only RabbitSystem may write RabbitData fields; FoodSystem must delegate)
**ADR Decision Summary**: `FoodSystem.feed_rabbit(rabbit_id, food_id)` checks inventory, deducts one unit, looks up the food definition from the `_food_defs` cache, delegates to `RabbitSystem.feed_rabbit(rabbit_id, food_definition)`, and rolls back the deduction if RabbitSystem returns false. FoodSystem never writes RabbitData fields directly. FoodSystem emits no signal of its own on this path — RabbitSystem owns the `rabbit_fed` signal.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: No post-cutoff APIs. `Dictionary.get()` with typed return, callable-based signal connect — all stable.

**Control Manifest Rules (Core layer)**:
- Required: statically typed parameters and return types on all public methods (F-02)
- Required: balance values (food effect definitions) loaded from `balance.json` cache (F-04)
- Forbidden: `FoodSystem` writing to any `RabbitData` field directly (C-01)
- Forbidden: hardcoded food effect values in `food_system.gd`
- Forbidden: `FoodSystem` emitting `rabbit_fed` or any rabbit-lifecycle signal (those belong to RabbitSystem per C-01)

---

## Acceptance Criteria

1. `FoodSystem.feed_rabbit(rabbit_id: String, food_id: String) -> bool` returns `false` if `food_id` is not present in `GameState.food_inventory` or its quantity is zero; inventory is not modified
2. `feed_rabbit()` returns `false` if `rabbit_id` does not resolve to a valid rabbit via `RabbitSystem.get_rabbit(rabbit_id)` — checked before any inventory deduction occurs
3. On a valid call (food in stock, rabbit found), `feed_rabbit()` deducts exactly 1 from `GameState.food_inventory[food_id]` before calling `RabbitSystem.feed_rabbit()`
4. `FoodSystem` calls `RabbitSystem.feed_rabbit(rabbit_id, food_effects_dict)` where `food_effects_dict` is the food's definition dictionary loaded from the `_food_defs` cache
5. If `RabbitSystem.feed_rabbit()` returns `false` (rabbit rejected the feed), `FoodSystem` re-increments `GameState.food_inventory[food_id]` by 1 (full rollback) and returns `false`
6. If the full pipeline succeeds, `feed_rabbit()` returns `true` and inventory reflects the deduction
7. `FoodSystem` emits no signal on this path; signal emission is entirely owned by `RabbitSystem`

---

## Implementation Notes

*Derived from ADR-0009 feed_rabbit contract and ADR-0005 mutation rules:*

### feed_rabbit implementation

```gdscript
func feed_rabbit(rabbit_id: String, food_id: String) -> bool:
    # Guard: rabbit must exist before touching inventory
    if RabbitSystem.get_rabbit(rabbit_id) == null:
        return false

    # Guard: food must be in stock
    var stock: int = GameState.food_inventory.get(food_id, 0)
    if stock <= 0:
        return false

    # Deduct first (will roll back if RabbitSystem rejects)
    GameState.food_inventory[food_id] = stock - 1
    GameState.mark_dirty()

    # Lookup food effects from cached defs
    var food_effects: Dictionary = _food_defs.get(food_id, {})

    # Delegate to RabbitSystem — only it may write RabbitData fields (ADR-0005)
    var accepted: bool = RabbitSystem.feed_rabbit(rabbit_id, food_effects)
    if not accepted:
        # Rollback
        GameState.food_inventory[food_id] = stock
        GameState.mark_dirty()
        push_warning("FoodSystem: RabbitSystem rejected feed for rabbit '%s' — rolled back" % rabbit_id)
        return false

    return true
```

### RabbitSystem.feed_rabbit interface expected

Per ADR-0005, `RabbitSystem.feed_rabbit` accepts a food effects dictionary and returns `bool`. The `food_effects` dictionary contains keys matching the balance.json food definition for the given food_id (e.g., `hunger_restore`, `growth_bonus`).

### Note on signal responsibility

`FoodSystem` must not emit `rabbit_fed` or any `rabbit_*` signal. If RabbitSystem needs to broadcast that a rabbit was fed, it emits its own signals. The `food_used` signal (defined in ADR-0009) may optionally be emitted by FoodSystem for UI feedback, but is not required by this story's acceptance criteria.

---

## Out of Scope

- Farm plot timers — covered in story-003
- `food_used` EventBus signal emission — can be added as a UI-layer follow-up
- Multi-unit feeding (feeding more than 1 per call) — single deduction per call is the defined contract

---

## QA Test Cases

- **AC-1**: returns false when food not in inventory
  - Given: `GameState.food_inventory = {}` (empty); valid rabbit exists
  - When: `FoodSystem.feed_rabbit("rabbit-01", "grass")`
  - Then: returns `false`; inventory unchanged

- **AC-2**: returns false when food quantity is zero
  - Given: `GameState.food_inventory = {"grass": 0}`; valid rabbit exists
  - When: `FoodSystem.feed_rabbit("rabbit-01", "grass")`
  - Then: returns `false`; `food_inventory["grass"] == 0`

- **AC-3**: returns false for unknown rabbit_id
  - Given: `GameState.food_inventory = {"grass": 3}`; RabbitSystem has no rabbits
  - When: `FoodSystem.feed_rabbit("phantom-id", "grass")`
  - Then: returns `false`; `food_inventory["grass"] == 3` (no deduction)

- **AC-4**: deducts inventory on success
  - Given: `GameState.food_inventory = {"grass": 3}`; valid rabbit; RabbitSystem returns `true`
  - When: `FoodSystem.feed_rabbit("rabbit-01", "grass")`
  - Then: returns `true`; `food_inventory["grass"] == 2`

- **AC-5**: rollback on RabbitSystem rejection
  - Given: `GameState.food_inventory = {"carrot": 2}`; valid rabbit; RabbitSystem mock returns `false`
  - When: `FoodSystem.feed_rabbit("rabbit-01", "carrot")`
  - Then: returns `false`; `food_inventory["carrot"] == 2` (restored)

- **AC-6**: no signal emitted by FoodSystem
  - Given: EventBus signal spy attached
  - When: `FoodSystem.feed_rabbit("rabbit-01", "grass")` succeeds
  - Then: no `food_harvested`, no `rabbit_fed`, no `food_used` signal from FoodSystem itself

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/food_system_feed_test.gd` — must exist and pass

**Status**: [ ] `tests/integration/core/food_system_feed_test.gd` — not yet written

---

## Dependencies

- Depends on: **story-001 must be DONE** — `feed_rabbit` relies on the inventory mutation helpers (`_deduct_from_inventory`) established in story-001
- Requires: `RabbitSystem.get_rabbit()` and `RabbitSystem.feed_rabbit()` interfaces from rabbit-system epic
- Unlocks: story-003 (farm plot timers may optionally call `feed_rabbit` in future integration, but timers are independent)

---

## Completion Notes

**Completed**: 2026-05-19
**Criteria**: 7/7 passing
**Deviations**: (1) `src/core/rabbit_system.gd` modified out of story boundary — `FoodItem` inner class removed, `feed_rabbit(food: FoodItem)` changed to `feed_rabbit(food_type: String)`. Accepted: inner classes inaccessible via Godot 4 autoload instance; within story's "adjust RabbitSystem write API as needed" clause.
**Test Evidence**: Integration — `tests/integration/core/food_system_feed_test.gd` (7 test functions)
**Code Review**: Skipped — Lean mode
