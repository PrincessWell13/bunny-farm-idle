# Story 001: RabbitData Schema + Instantiation

> **Epic**: RabbitSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.1 Rabbit System)
**Requirement**: `TR-rabbit-001`, `TR-rabbit-002`, `TR-rabbit-003`, `TR-rabbit-004`, `TR-rabbit-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0005 Accepted ✅

**ADR Governing Implementation**: ADR-0005: RabbitData as Godot Resource — Immutable from Outside RabbitSystem
**ADR Decision Summary**: `RabbitData` is `class_name RabbitData extends Resource`. All 15+ typed fields declared as `var`s (no `@export`). Only RabbitSystem writes to them. Other systems receive the reference and may only read.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Resource` class and `class_name` are unchanged in 4.4–4.6. `Array[RabbitData]` typed arrays are stable. `Genome = null` default is valid; the Genome class is defined in ADR-0006 (pending).

**Control Manifest Rules (Core layer)**:
- Required: All fields statically typed
- Forbidden: `@export` on any RabbitData field — no Inspector exposure
- Forbidden: `direct_rabbitdata_mutation` — no file outside `rabbit_system.gd` may assign to RabbitData fields

---

## Acceptance Criteria

*From GDD §3.1 and ADR-0005 schema:*

- [ ] `class_name RabbitData extends Resource` declared in `src/core/rabbit_data.gd`
- [ ] `enum RabbitStage { BABY, JUVENILE, ADULT, ELDER, SANCTUARY }` declared on RabbitData
- [ ] All 15 typed fields present with correct types and defaults:
  - `rabbit_id: String = ""`
  - `display_name: String = ""`
  - `stage: RabbitStage = RabbitStage.BABY`
  - `genome: Genome = null`
  - `hunger: float = 100.0`
  - `happiness: float = 100.0`
  - `health: float = 100.0`
  - `cleanliness: float = 100.0`
  - `growth_progress: float = 0.0`
  - `fertility: float = 1.0`
  - `mutation_chance: float = 0.05`
  - `aura_type: String = ""`
  - `birth_timestamp: int = 0`
  - `parent_a_id: String = ""`
  - `parent_b_id: String = ""`
  - `hutch_id: String = ""`
- [ ] `RabbitData.new()` succeeds in GdUnit4 with no scene or autoload loaded — no errors
- [ ] No `@export` annotation on any field
- [ ] Grep confirms no assignment to any RabbitData field outside `rabbit_system.gd`

---

## Implementation Notes

*Derived from ADR-0005:*

`rabbit_data.gd` is a pure data container — no methods except defaults. Do not add any logic or signal declarations here; those belong in `rabbit_system.gd`.

The `genome: Genome = null` field references the `Genome` class defined by ADR-0006 (pending). Declare the field but leave it null — the Genome schema is out of scope for this story.

`mutation_chance: float = 0.05` matches `balance.json "genetics.base_mutation_chance"` — the default is also in balance.json; this is the GDScript-side fallback only.

`birth_timestamp: int` stores Unix seconds (use `Time.get_unix_time_from_system()` when populating — do not call it here in the schema).

Do not implement any serialisation logic here. SaveSystem's `_rabbit_to_dict()` is a SaveSystem story (save-system epic).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `RabbitSystem` add/get/remove methods — uses RabbitData but doesn't belong in this file
- ADR-0006: `Genome` and `GeneSlot` class definitions — `genome` field is declared null here only
- SaveSystem epic: `_rabbit_to_dict()` / `_dict_to_rabbit()` serialisation
- Any logic, methods, or signals on `RabbitData` itself

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC-1**: `RabbitData.new()` in headless GdUnit4 succeeds
  - Given: GdUnit4 test suite with no autoloads loaded
  - When: `var r := RabbitData.new()`
  - Then: `is_instance_valid(r)` is true; no error in Godot console
  - Edge cases: N/A — this is a Resource, not a Node

- **AC-2**: Default field values match ADR-0005 schema
  - Given: `var r := RabbitData.new()`
  - When: read `r.hunger`, `r.happiness`, `r.health`, `r.cleanliness`, `r.growth_progress`, `r.fertility`, `r.mutation_chance`, `r.birth_timestamp`
  - Then: 100.0, 100.0, 100.0, 100.0, 0.0, 1.0, 0.05, 0
  - Edge cases: float equality acceptable here (these are exact typed literals)

- **AC-3**: stage defaults to BABY
  - Given: `var r := RabbitData.new()`
  - When: read `r.stage`
  - Then: `r.stage == RabbitData.RabbitStage.BABY`

- **AC-4**: All string fields default to empty string
  - Given: `var r := RabbitData.new()`
  - When: read `r.rabbit_id`, `r.display_name`, `r.aura_type`, `r.parent_a_id`, `r.parent_b_id`, `r.hutch_id`
  - Then: all == `""`

- **AC-5**: genome field is null by default
  - Given: `var r := RabbitData.new()`
  - When: read `r.genome`
  - Then: `r.genome == null`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/rabbit_data_schema_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/rabbit_data_schema_test.gd` — 7 test functions

---

## Dependencies

- Depends on: None — this is the foundational data type
- Unlocks: Story 002 (RabbitSystem roster requires RabbitData to exist)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 6/6 passing (all 7 test functions COVERED)
**Deviations**: ADVISORY — `genome` typed as `Resource` placeholder instead of `Genome` (Genome class pending ADR-0006; using it directly causes parse error)
**Test Evidence**: Logic — `tests/unit/core/rabbit_data_schema_test.gd` ✅
**Code Review**: Skipped — Lean mode
