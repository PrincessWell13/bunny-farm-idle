# Story 001: Genome Schema + AlleleCatalogue

> **Epic**: GeneticsSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.2 Genetics System)
**Requirement**: `TR-genetics-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0006 Accepted ✅

**ADR Governing Implementation**: ADR-0006 (Genetics Allele Model)
**ADR Decision Summary**: Define `Genome` (Resource with 6 named `GeneSlot` fields), `GeneSlot` (Resource with `allele_a`/`allele_b` strings and `expressed()` method), `AlleleCatalogue` (constants file), `BreedPreview` (Resource value object), `TraitEffects` (RefCounted value object). All files in `src/core/genetics/`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `class_name` on Resource subclasses, `RefCounted` for value objects — stable APIs, no post-cutoff risk.

**Control Manifest Rules (Core layer)**:
- Required: callable-based signal emit (not applicable to pure data classes)
- Forbidden: `direct_rabbitdata_mutation` — breed() must never write to parent fields
- Forbidden: `inline_allele_strings` — allele keys must come from `AlleleCatalogue` constants

---

## Acceptance Criteria

*From GDD §3.2 and ADR-0006 resource hierarchy:*

- [ ] `GeneSlot extends Resource` with `allele_a: String = "none"` and `allele_b: String = "none"` instantiates without autoload or scene dependency
- [ ] `GeneSlot.expressed()` returns `allele_a`
- [ ] `Genome extends Resource` with 6 named `GeneSlot` fields (`color`, `size`, `ears`, `trait_a`, `trait_b`, `special`) — each defaults to a new `GeneSlot` instance
- [ ] `AlleleCatalogue` defines `COLORS` (11 entries), `TRAITS_TIER1` (6), `TRAITS_TIER2` (8), `TRAITS_TIER3` (10), `TRAIT_NONE = "none"`
- [ ] `BreedPreview extends Resource` with `color_probabilities: Dictionary`, `trait_a_probabilities: Dictionary`, `trait_b_probabilities: Dictionary`, `mutation_chance: float`, `estimated_rarity` fields
- [ ] `TraitEffects extends RefCounted` with `growth_rate_bonus`, `fertility_bonus`, `mutation_bonus`, `coin_bonus`, `drop_rate_bonus`, `legendary_blood_bonus` (all float = 0.0), `has_ultra_trait: bool = false`, `ultra_trait_id: String = ""`
- [ ] All 5 types can be instantiated in a unit test without any autoload or scene dependency

---

## Implementation Notes

*Derived from ADR-0006 Resource Hierarchy and Migration Plan:*

Create files in order: `gene_slot.gd` → `genome.gd` → `allele_catalogue.gd` → `breed_preview.gd` → `trait_effects.gd`. All in `src/core/genetics/`.

`Genome` initialises each slot field as a new `GeneSlot` in the var declaration:
```gdscript
var color: GeneSlot = GeneSlot.new()
```

`AlleleCatalogue` is constants only — no `extends` needed, just `class_name AlleleCatalogue`. It must not require instantiation.

`TraitEffects` uses `extends RefCounted` (not `Resource`) because it is a transient computed value — it is never saved to disk and has no identity.

`BreedPreview` uses `extends Resource` so it can be passed as a typed return value across the system boundary.

The `COLORS` constant in `AlleleCatalogue` must list exactly 11 entries matching the ADR order: `["white", "brown", "grey", "spotted", "striped", "calico", "gold", "silver", "galaxy", "rainbow", "legendary"]`.

---

## Out of Scope

- Story 002: the `breed()` algorithm that uses these types
- Story 003: `get_breed_preview()` that populates `BreedPreview`
- Story 004: rarity tier mapping that interprets `COLORS`
- Story 005: trait stacking that produces `TraitEffects` values

---

## QA Test Cases

- **AC-1 & AC-2**: `GeneSlot` instantiation and `expressed()`
  - Given: `var slot := GeneSlot.new()`; `slot.allele_a = "gold"`
  - When: `slot.expressed()`
  - Then: returns `"gold"` (allele_a)

- **AC-1 default fields**: GeneSlot defaults
  - Given: `var slot := GeneSlot.new()`
  - When: access `slot.allele_a`, `slot.allele_b`
  - Then: both equal `"none"`

- **AC-3**: `Genome` instantiation with 6 named slots
  - Given: `var genome := Genome.new()`
  - When: access `genome.color`, `genome.size`, `genome.ears`, `genome.trait_a`, `genome.trait_b`, `genome.special`
  - Then: each is a `GeneSlot` instance (not null)

- **AC-4**: `AlleleCatalogue` catalogue sizes
  - Given: access `AlleleCatalogue.COLORS`, `AlleleCatalogue.TRAITS_TIER1`, etc.
  - When: check `.size()`
  - Then: COLORS.size() == 11, TRAITS_TIER1.size() == 6, TRAITS_TIER2.size() == 8, TRAITS_TIER3.size() == 10

- **AC-5**: `BreedPreview` default fields
  - Given: `var preview := BreedPreview.new()`
  - When: access fields
  - Then: `color_probabilities` is empty Dictionary, `mutation_chance == 0.0`

- **AC-6**: `TraitEffects` default fields
  - Given: `var fx := TraitEffects.new()`
  - When: access fields
  - Then: all bonus floats == 0.0, `has_ultra_trait == false`, `ultra_trait_id == ""`

- **AC-7**: no-dependency instantiation
  - Given: no autoloads registered, no scene tree
  - When: `GeneSlot.new()`, `Genome.new()`, `BreedPreview.new()`, `TraitEffects.new()`
  - Then: no errors; all instantiate cleanly

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/genetics_schema_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/genetics_schema_test.gd` — 8 test functions

---

## Dependencies

- Depends on: None (foundational data types for GeneticsSystem)
- Unlocks: Story 002 (breed algorithm), Story 003 (preview), Story 004 (rarity), Story 005 (trait stacking)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 7/7 passing
**Deviations**: ADVISORY — `BreedPreview.estimated_rarity` typed as `int` (forward-compat placeholder; `GeneticsSystem.RarityTier` enum defined in Story 004)
**Test Evidence**: Logic — `tests/unit/core/genetics_schema_test.gd` ✅ (8 test functions)
**Code Review**: Skipped — Lean mode
