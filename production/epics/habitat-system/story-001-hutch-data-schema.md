# Story 001: HutchData Schema + Instantiation

> **Epic**: HabitatSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.4 Habitat System)
**Requirement**: `TR-habitat-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0010 Accepted ✅

**ADR Governing Implementation**: ADR-0010: HabitatSystem Hutch Ownership and Rabbit Assignment Model
**ADR Decision Summary**: `HutchData` is `class_name HutchData extends Resource`. Four typed fields: `hutch_id: String`, `level: int`, `occupants: Array[String]`, `cleanliness: float`. No `@export` annotations. Serialisation handled by `SaveSystem` via explicit field iteration (same pattern as `RabbitData` — ADR-0005).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Resource` subclassing and `class_name` are unchanged in 4.4–4.6. `Array[String]` typed arrays are stable. `HutchData.new()` in a GdUnit4 headless context requires no scene or autoload.

**Control Manifest Rules (Core layer)**:
- Required: All fields statically typed (F-02)
- Required: No `@export` on any HutchData field — no Inspector exposure (mirrors C-01 pattern for RabbitData)
- Forbidden: `direct_hutchdata_mutation` — no file outside `habitat_system.gd` may assign to HutchData fields
- Forbidden: Hardcoded numeric defaults for balance-sourced values in schema (F-04); the `cleanliness: float = 1.0` default is a schema default, not a balance value

---

## Acceptance Criteria

1. `class_name HutchData extends Resource` declared in `src/core/hutch_data.gd`
2. All four typed fields present with correct types and defaults:
   - `hutch_id: String = ""`
   - `level: int = 1`
   - `occupants: Array[String] = []`
   - `cleanliness: float = 1.0`
3. `HutchData.new()` succeeds in GdUnit4 with no scene or autoload loaded — no errors
4. No `@export` annotation on any field
5. `hutch_id` is unique per instance: two separately instantiated `HutchData` objects with different assigned `hutch_id` values are not equal by `hutch_id`
6. `occupants` starts as an empty `Array[String]` — `occupants.is_empty()` is `true` on a fresh instance
7. `cleanliness` defaults to `1.0` on a fresh instance
8. Round-trip through `SaveSystem`-style manual serialisation: a `Dictionary` produced by iterating fields can be used to reconstruct a `HutchData` with identical field values (validates the save contract described in ADR-0010)
9. Grep confirms no assignment to any `HutchData` field outside `habitat_system.gd` (policy gate — verified at story-done time)

---

## Implementation Notes

*Derived from ADR-0010:*

`hutch_data.gd` is a pure data container — no methods, no signals, no logic. Do not add methods here; mutation logic belongs exclusively in `habitat_system.gd`.

The `occupants: Array[String]` field stores `rabbit_id` string keys. It is NOT typed `Array[RabbitData]` — HutchData holds only IDs, not live references, so that it serialises cleanly without circular references.

`level: int = 1` represents the hutch's upgrade tier. Capacity for that level is looked up by `HabitatSystem.get_capacity()` against the `balance.json` table — it is not stored on the schema itself.

`cleanliness: float = 1.0` is the schema-side default (full cleanliness at creation). The decay rate comes from `balance.json`; the schema default is independent of balance configuration.

Do not implement serialisation logic here. `SaveSystem`'s `_hutch_to_dict()` / `_dict_to_hutch()` methods (SaveSystem epic) own the round-trip. The round-trip acceptance criterion (AC-8) is tested here with an inline helper that mirrors that pattern — not by calling `SaveSystem` directly.

The `Array[String]` default `= []` on a `Resource` subclass creates a fresh array per instance in Godot 4 (Resources do not share default array instances the way some other patterns might). Verify this in AC-3 / AC-6.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `assign_rabbit()` / `remove_rabbit()` mutation API
- Story 003: Cleanliness decay via `TimeManager.tick`
- Story 004: `get_hutch_bonuses()` bonus derivation
- Story 005: `get_capacity()` and level-based capacity table
- SaveSystem epic: production `_hutch_to_dict()` / `_dict_to_hutch()` methods

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC-1**: `HutchData` class declaration
  - Given: GdUnit4 headless test suite with no autoloads loaded
  - When: `var h := HutchData.new()`
  - Then: `is_instance_valid(h)` is `true`; no error in Godot console; `h is Resource` is `true`

- **AC-2**: Default field values
  - Given: `var h := HutchData.new()`
  - When: read all fields
  - Then: `h.hutch_id == ""`, `h.level == 1`, `h.cleanliness == 1.0`
  - Edge cases: float equality acceptable here — `1.0` is an exact typed literal

- **AC-3**: `occupants` starts empty and is a typed array
  - Given: `var h := HutchData.new()`
  - When: read `h.occupants`
  - Then: `h.occupants.is_empty()` is `true`; `h.occupants` is `Array[String]`

- **AC-4**: No `@export` on any field
  - Given: parse `src/core/hutch_data.gd` source
  - When: grep for `@export`
  - Then: zero matches

- **AC-5**: `hutch_id` uniqueness (assignment check)
  - Given: `var a := HutchData.new(); var b := HutchData.new()`
  - When: `a.hutch_id = "hutch_001"; b.hutch_id = "hutch_002"`
  - Then: `a.hutch_id != b.hutch_id`

- **AC-6**: `occupants` array independence between instances
  - Given: `var a := HutchData.new(); var b := HutchData.new()`
  - When: `a.occupants.append("rabbit_001")`
  - Then: `b.occupants.is_empty()` is still `true` — arrays are not shared

- **AC-7**: `cleanliness` clamps correctly when assigned
  - Given: `var h := HutchData.new()`
  - When: `h.cleanliness = 1.0` (schema default)
  - Then: `h.cleanliness == 1.0`

- **AC-8**: Manual round-trip serialisation
  - Given: `var h := HutchData.new(); h.hutch_id = "h1"; h.level = 2; h.occupants = ["r1", "r2"]; h.cleanliness = 0.65`
  - When: convert to Dictionary `{ "hutch_id": h.hutch_id, "level": h.level, "occupants": h.occupants.duplicate(), "cleanliness": h.cleanliness }` then reconstruct a new `HutchData` from those keys
  - Then: all fields on the reconstructed instance match the original values exactly

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/hutch_data_schema_test.gd` — must exist and pass

**Status**: [ ] `tests/unit/core/hutch_data_schema_test.gd` — 8 test functions

---

## Dependencies

- Depends on: None — this is the foundational HabitatSystem data type
- Unlocks: Story 002 (assign/remove API requires HutchData to exist), Story 003 (decay requires HutchData), Story 004 (bonuses require HutchData), Story 005 (capacity requires HutchData)

## Completion Notes
**Completed**: 2026-05-18
**Criteria**: 8/8 passing
**Deviations**: None — `level: int = 1` and `cleanliness: float = 1.0` are schema defaults, explicitly permitted by ADR-0010
**Test Evidence**: Logic: `tests/unit/core/hutch_data_schema_test.gd` (8 test functions)
**Code Review**: Skipped — lean mode
