# Story 006: feed_rabbit — Immediate Stat Restoration

> **Epic**: RabbitSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.3 — Hệ thống thức ăn)
**Requirement**: `TR-rabbit-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0004 Accepted ✅, ADR-0005 Accepted ✅

**ADR Governing Implementation**: ADR-0004 (food effect values from balance.json) + ADR-0005 (only RabbitSystem writes RabbitData fields)
**ADR Decision Summary**: `feed_rabbit(rabbit_id, food_item)` looks up the rabbit, applies stat increases defined in balance.json for the given food type, clamps stats at 100.0, and returns `true`. Returns `false` if the rabbit is not found. Food effect values (hunger restore, growth bonus, etc.) are all from balance.json `"food"` section.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: No post-cutoff APIs. Dictionary lookup with typed values.

**Control Manifest Rules (Core layer)**:
- Forbidden: hardcoded food effect values
- Forbidden: `direct_rabbitdata_mutation` from outside `rabbit_system.gd`

---

## Acceptance Criteria

*From GDD §3.3 food table and ADR-0004 loading pattern:*

- [ ] `feed_rabbit(rabbit_id: String, food: FoodItem) -> bool` exists in `rabbit_system.gd`
- [ ] Returns `false` for unknown `rabbit_id` — no crash
- [ ] Returns `true` on successful feeding
- [ ] Grass: `rabbit.hunger` increases by `_grass_hunger_restore` (from balance.json)
- [ ] Carrot: `rabbit.hunger` increases by `_carrot_hunger_restore` AND `rabbit.growth_progress` increases by `_carrot_growth_bonus`
- [ ] Star Carrot: `rabbit.growth_progress` increases by `_star_carrot_growth_bonus` AND `rabbit.happiness` increases by `_star_carrot_happiness_bonus`
- [ ] `rabbit.hunger` clamps at `100.0` maximum after feeding
- [ ] `rabbit.growth_progress` and other stats clamp at `100.0` maximum
- [ ] `FoodItem` is a typed resource/enum-backed struct with `food_type: String` or `food_type: FoodType` enum
- [ ] All food effect magnitudes loaded from `balance.json "food"` section

---

## Implementation Notes

*Derived from ADR-0004 food section and ADR-0005 mutation contract:*

### FoodItem type

Define a lightweight inner class or separate resource file:

```gdscript
# Option A — inner class on RabbitSystem (simplest for this story)
class FoodItem:
    var food_type: String = ""
    func _init(type: String) -> void:
        food_type = type
```

### feed_rabbit implementation

```gdscript
var _grass_hunger_restore: float = 30.0
var _carrot_hunger_restore: float = 40.0
var _carrot_growth_bonus: float = 10.0
var _star_carrot_growth_bonus: float = 25.0
var _star_carrot_happiness_bonus: float = 10.0

func feed_rabbit(rabbit_id: String, food: FoodItem) -> bool:
    var rabbit: RabbitData = get_rabbit(rabbit_id)
    if rabbit == null:
        return false
    match food.food_type:
        "grass":
            rabbit.hunger = minf(100.0, rabbit.hunger + _grass_hunger_restore)
        "carrot":
            rabbit.hunger = minf(100.0, rabbit.hunger + _carrot_hunger_restore)
            rabbit.growth_progress = minf(100.0, rabbit.growth_progress + _carrot_growth_bonus)
        "star_carrot":
            rabbit.growth_progress = minf(100.0, rabbit.growth_progress + _star_carrot_growth_bonus)
            rabbit.happiness = minf(100.0, rabbit.happiness + _star_carrot_happiness_bonus)
        _:
            push_warning("RabbitSystem: unknown food type '%s'" % food.food_type)
    GameState.mark_dirty()
    return true
```

### balance.json keys to load

Add to `_load_balance_data()` — `"food"` section:
- `"grass_hunger_restore"` → `_grass_hunger_restore`
- `"carrot_hunger_restore"` → `_carrot_hunger_restore`
- `"carrot_growth_bonus"` → `_carrot_growth_bonus`
- `"star_carrot_growth_bonus"` → `_star_carrot_growth_bonus`
- `"star_carrot_happiness_bonus"` — add this key to balance.json alongside this story

---

## Out of Scope

- Story 003: automatic stat decay per tick — separate from player-triggered feeding
- GDD §3.3 food items beyond grass/carrot/star_carrot — implement remaining food types in a follow-up story when FoodSystem epic is created
- FoodSystem epic: food inventory management, growing food, crafting recipes

---

## QA Test Cases

- **AC-1**: grass increases hunger
  - Given: rabbit with `hunger=50.0`; `_grass_hunger_restore=30.0`; grass FoodItem
  - When: `feed_rabbit(id, grass)`
  - Then: `rabbit.hunger == 80.0`; returns `true`

- **AC-2**: carrot increases hunger and growth_progress
  - Given: rabbit with `hunger=50.0`, `growth_progress=20.0`; `_carrot_hunger_restore=40.0`, `_carrot_growth_bonus=10.0`
  - When: `feed_rabbit(id, carrot)`
  - Then: `rabbit.hunger == 90.0`, `rabbit.growth_progress == 30.0`

- **AC-3**: hunger clamps at 100.0
  - Given: rabbit with `hunger=90.0`; carrot restores 40
  - When: `feed_rabbit(id, carrot)`
  - Then: `rabbit.hunger == 100.0` (not 130.0)

- **AC-4**: returns false for unknown rabbit
  - Given: fresh RabbitSystem; no rabbits added
  - When: `feed_rabbit("phantom-id", grass_item)`
  - Then: returns `false`; no crash; no error

- **AC-5**: star carrot increases growth and happiness
  - Given: rabbit with `growth_progress=40.0`, `happiness=60.0`; `_star_carrot_growth_bonus=25.0`, `_star_carrot_happiness_bonus=10.0`
  - When: `feed_rabbit(id, star_carrot)`
  - Then: `rabbit.growth_progress == 65.0`, `rabbit.happiness == 70.0`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/rabbit_system_feeding_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/rabbit_system_feeding_test.gd` — 5 test functions

---

## Dependencies

- Depends on: **Story 002 must be DONE** — `feed_rabbit` calls `get_rabbit()` from the roster
- Unlocks: Story 007 (aura bonus — parallel, not dependent on feeding)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 9/9 passing
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/core/rabbit_system_feeding_test.gd` ✅
**Code Review**: Skipped — Lean mode
