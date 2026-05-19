# Story 004: get_hutch_bonuses() — Cleanliness-Derived Production Multipliers

> **Epic**: HabitatSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.4 Habitat System)
**Requirement**: `TR-habitat-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0010 Accepted ✅, ADR-0004 Accepted ✅

**ADR Governing Implementation**: ADR-0010: HabitatSystem Hutch Ownership and Rabbit Assignment Model; ADR-0004: JSON Balance Data — No Hardcoded Values
**ADR Decision Summary**: `get_hutch_bonuses(hutch_id)` derives `production_mult` and `fertility_mult` from the hutch's current `cleanliness` value by iterating an ordered threshold array loaded from `balance.json`. The array is ordered highest-to-lowest; the first matching tier is returned. Clean (≥0.75) returns a bonus multiplier; dirty (cleanliness in the lowest tier) returns a penalty multiplier. Result is not cached — callers cache if needed.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Dictionary` return types, `Array` iteration, and `float` comparison are stable across all Godot 4.x versions. No post-cutoff APIs used.

**Control Manifest Rules (Core layer)**:
- Required: Threshold values loaded from `balance.json` at `_ready()` — never hardcoded (F-04)
- Required: Return type is `Dictionary` (typed), not untyped Variant (F-02)
- Required: Neutral fallback returned for unknown `hutch_id` — no crash on bad input
- Forbidden: Hardcoded threshold literals (`0.75`, `0.40`, `1.2`, etc.) in `src/` (F-04)
- Forbidden: Caching the result on `HutchData` — `get_hutch_bonuses()` derives at query time

---

## Acceptance Criteria

1. `get_hutch_bonuses(hutch_id: String) -> Dictionary` implemented on `HabitatSystem`
2. Return Dictionary always contains exactly two keys: `"production_mult": float` and `"fertility_mult": float`
3. If `hutch_id` is not found in `GameState.hutches`, return `{ "production_mult": 1.0, "fertility_mult": 1.0 }` (neutral — no bonus, no penalty)
4. `_cleanliness_thresholds` is loaded from `balance.json` key `habitat.cleanliness_thresholds` in `_load_balance_data()` — it is an ordered Array of Dictionaries from highest `min` to lowest
5. `get_hutch_bonuses()` iterates `_cleanliness_thresholds` from index 0 (highest threshold) and returns the first entry where `hutch.cleanliness >= entry.min`
6. When `cleanliness >= 0.75` (clean tier, per ADR-0010 example): `production_mult > 1.0` and `fertility_mult >= 1.0`
7. When `cleanliness < 0.40` (dirty tier, per ADR-0010 example): `production_mult < 1.0` and `fertility_mult < 1.0`
8. When `cleanliness` is in the mid-range tier (between the high and low thresholds): multipliers return the configured mid-range values (e.g., `1.0` for neutral)
9. Threshold values (`min`, `production_mult`, `fertility_mult`) are read entirely from `balance.json` — no numeric literals appear in the function body
10. If `balance.json` is missing `habitat.cleanliness_thresholds` at boot, `push_error()` is called and `_cleanliness_thresholds` falls back to a single-entry neutral array `[{ "min": 0.0, "production_mult": 1.0, "fertility_mult": 1.0 }]`
11. `get_hutch_bonuses()` does not modify any state — it is a pure read with no side effects

---

## Implementation Notes

*Derived from ADR-0010:*

The threshold lookup algorithm per ADR-0010:
```gdscript
func get_hutch_bonuses(hutch_id: String) -> Dictionary:
    var hutch: HutchData = _find_hutch(hutch_id)
    if hutch == null:
        return { "production_mult": 1.0, "fertility_mult": 1.0 }
    for threshold: Dictionary in _cleanliness_thresholds:
        if hutch.cleanliness >= (threshold["min"] as float):
            return {
                "production_mult": threshold["production_mult"] as float,
                "fertility_mult": threshold["fertility_mult"] as float
            }
    return { "production_mult": 1.0, "fertility_mult": 1.0 }
```

The `balance.json` schema for cleanliness thresholds (ADR-0010 reference values — actual values may be tuned):
```json
"habitat": {
    "cleanliness_thresholds": [
        { "min": 0.75, "production_mult": 1.2, "fertility_mult": 1.1 },
        { "min": 0.40, "production_mult": 1.0, "fertility_mult": 1.0 },
        { "min": 0.0,  "production_mult": 0.8, "fertility_mult": 0.9 }
    ]
}
```

The array must be ordered from highest `min` to lowest. If `balance.json` is provided in a different order, document this requirement explicitly for the designer who edits it (or sort in `_load_balance_data()`).

`IdleProductionSystem` is the primary consumer of `get_hutch_bonuses()`. It calls this method per tick to apply per-hutch multipliers to coin calculations. The return type is `Dictionary` rather than a typed Resource because ADR-0010 explicitly chose this for simplicity; `IdleProductionSystem` does not import `HabitatSystem` types directly.

`get_hutch_bonuses()` must not cache its result on `HutchData`. Caching, if needed for performance, is the responsibility of the caller. At max scale (6 hutch bonus lookups per tick), the cost is negligible.

A `_find_hutch(hutch_id: String) -> HutchData` private helper is recommended to avoid duplicating the `GameState.hutches` scan across multiple public methods (`get_hutch_bonuses`, `get_capacity`, `assign_rabbit`). This helper returns `null` if not found.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `HutchData` schema definition
- Story 002: Rabbit assignment — occupancy does not affect bonus calculation directly
- Story 003: Cleanliness decay — this story only reads the `cleanliness` value; Story 003 writes it
- Story 005: `get_capacity()` — separate concern

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC-3**: Unknown hutch_id returns neutral
  - Given: `GameState.hutches` does not contain `"nonexistent_hutch"`
  - When: `HabitatSystem.get_hutch_bonuses("nonexistent_hutch")`
  - Then: returns `{ "production_mult": 1.0, "fertility_mult": 1.0 }`

- **AC-6**: Clean hutch returns production bonus
  - Given: a `HutchData` with `cleanliness = 0.9` (above 0.75 threshold)
  - When: `HabitatSystem.get_hutch_bonuses("h1")`
  - Then: `result["production_mult"] > 1.0`; `result["fertility_mult"] >= 1.0`

- **AC-7**: Dirty hutch returns penalty
  - Given: a `HutchData` with `cleanliness = 0.2` (below 0.40 threshold)
  - When: `HabitatSystem.get_hutch_bonuses("h1")`
  - Then: `result["production_mult"] < 1.0`; `result["fertility_mult"] < 1.0`

- **AC-8**: Mid-range cleanliness returns mid-range values
  - Given: a `HutchData` with `cleanliness = 0.55` (between 0.40 and 0.75)
  - When: `HabitatSystem.get_hutch_bonuses("h1")`
  - Then: returns the mid-tier values from `balance.json` (neutral: `production_mult == 1.0`)

- **AC-5**: Threshold iteration order — boundary values
  - Given: `cleanliness = 0.75` (exactly at the clean threshold)
  - When: `HabitatSystem.get_hutch_bonuses("h1")`
  - Then: returns the clean-tier values (first matching tier, inclusive lower bound)

- **AC-5**: Threshold iteration order — boundary at 0.40
  - Given: `cleanliness = 0.40` (exactly at the mid threshold)
  - When: `HabitatSystem.get_hutch_bonuses("h1")`
  - Then: returns the mid-tier values (not the dirty-tier values)

- **AC-10**: Missing balance.json key falls back to neutral
  - Given: `balance.json` has no `habitat.cleanliness_thresholds` key
  - When: `HabitatSystem._ready()` calls `_load_balance_data()`
  - Then: `push_error()` logged; subsequent `get_hutch_bonuses()` calls return `production_mult == 1.0` for any cleanliness value

- **AC-11**: No state mutation
  - Given: a `HutchData` with `cleanliness = 0.6`
  - When: `HabitatSystem.get_hutch_bonuses("h1")` called 3 times
  - Then: `hutch.cleanliness` is still `0.6` after all three calls

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/habitat_system_bonuses_test.gd` — must exist and pass

**Status**: [ ] `tests/unit/core/habitat_system_bonuses_test.gd` — 8 test functions

---

## Dependencies

- Depends on: Story 003 (cleanliness decay establishes the `cleanliness` value contract; Story 001 for HutchData schema)
- Unlocks: IdleProductionSystem integration (hutch bonus multipliers consumed in production calculation)

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 11/11 passing
**Deviations**: `_cleanliness_thresholds` initialized with neutral fallback literal at declaration — GDScript-side default, balance.json overwrites at runtime; matches _decay_rate pattern
**Test Evidence**: Logic: `tests/unit/core/habitat_system_bonuses_test.gd` (8 test functions)
**Code Review**: Skipped — Lean mode
