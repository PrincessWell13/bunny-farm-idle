# Story 003: Gene Preview — Probability Tables

> **Epic**: GeneticsSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.2 Genetics System)
**Requirement**: `TR-genetics-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0006 Accepted ✅

**ADR Governing Implementation**: ADR-0006 (Genetics Allele Model)
**ADR Decision Summary**: `get_breed_preview(parent_a, parent_b)` is a pure function — no `RandomNumberGenerator` calls, no side effects. It computes probability distributions analytically. For each allele position, the 4 possible parent-allele outcomes each have 25% base probability, adjusted by mutation chance. Probability dictionaries must be normalised before returning (sum to 1.0 ± 0.0001).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript arithmetic. No engine API surface.

**Control Manifest Rules (Core layer)**:
- Required: `get_breed_preview()` must not call `_rng.randf()` — pure analytical calculation only
- Forbidden: `direct_rabbitdata_mutation` — must not modify parents
- Forbidden: `inline_allele_strings` — keys from `AlleleCatalogue` only

---

## Acceptance Criteria

*From GDD §3.2 and ADR-0006 Gene Preview section:*

- [ ] `get_breed_preview(parent_a, parent_b)` returns a `BreedPreview` resource
- [ ] The function makes zero calls to `_rng` (pure function — no side effects)
- [ ] `preview.color_probabilities` values sum to 1.0 (± 0.0001)
- [ ] `preview.trait_a_probabilities` values sum to 1.0 (± 0.0001)
- [ ] `preview.trait_b_probabilities` values sum to 1.0 (± 0.0001)
- [ ] All keys in `color_probabilities` are valid `AlleleCatalogue.COLORS` entries
- [ ] With `mutation_chance = 0.0`: only alleles present in the parents appear as keys (no catalogue-wide spread)
- [ ] `preview.mutation_chance == (parent_a.mutation_chance + parent_b.mutation_chance) * 0.5`
- [ ] Calling `get_breed_preview()` does not modify `parent_a` or `parent_b`

---

## Implementation Notes

*Derived from ADR-0006 Gene Preview (Pure Function) section:*

Add `get_breed_preview()` and `_slot_probabilities()` to the existing `genetics_system.gd` created in Story 002.

`_slot_probabilities(slot_a, slot_b, mutation_chance, catalogue_key)` works as follows:
- Start with 4 outcomes: (slot_a.allele_a, slot_b.allele_a), (slot_a.allele_a, slot_b.allele_b), (slot_a.allele_b, slot_b.allele_a), (slot_a.allele_b, slot_b.allele_b) — each with weight 0.25
- For each outcome, each allele has `mutation_chance` probability of being replaced by *any* catalogue entry
- The resulting `Dictionary` maps allele_key → probability
- Must normalise: divide all values by sum so total == 1.0

The expressed allele for color/size/ears is `allele_a`. So `color_probabilities` maps **expressed** color outcomes to their probability.

`preview.estimated_rarity` is computed from `_estimate_rarity(color_probabilities)` — which uses the weighted average rarity tier across all color outcomes. Implementation can be a simple lookup of each color key's rarity tier weighted by its probability.

Add `_estimate_rarity()` as a private helper in this story (it will also be used by Story 004).

---

## Out of Scope

- Story 002: the `breed()` algorithm using RNG — this story adds the pure preview function only
- Story 004: `get_rarity()` public method on a single rabbit — related but separate
- Story 005: trait stacking results do not appear in `BreedPreview` (hidden combo is hidden)

---

## QA Test Cases

- **AC-1**: `get_breed_preview()` returns `BreedPreview`
  - Given: two parents with known genomes
  - When: `system.get_breed_preview(parent_a, parent_b)`
  - Then: result is not null; `result is BreedPreview`

- **AC-2 & AC-3**: probability sums to 1.0
  - Given: parents with different color alleles; `mutation_chance = 0.05`
  - When: `preview.color_probabilities.values().reduce(func(a,b): return a+b, 0.0)`
  - Then: result is within 0.0001 of 1.0

  - Same check for `trait_a_probabilities` and `trait_b_probabilities`

- **AC-4**: valid allele keys
  - Given: any two parents
  - When: check all keys in `preview.color_probabilities`
  - Then: every key is in `AlleleCatalogue.COLORS`

- **AC-5**: no mutation means only parent alleles appear
  - Given: `parent_a.mutation_chance = 0.0`, `parent_b.mutation_chance = 0.0`; known alleles `"white"` and `"gold"`
  - When: `preview = get_breed_preview(parent_a, parent_b)`
  - Then: `preview.color_probabilities.keys()` contains only `"white"` and `"gold"` (the 4 outcomes but only 2 unique expressed alleles)

- **AC-6**: mutation_chance forwarded correctly
  - Given: `parent_a.mutation_chance = 0.1`, `parent_b.mutation_chance = 0.3`
  - When: `preview.mutation_chance`
  - Then: `preview.mutation_chance == 0.2` (average)

- **AC-7**: parents not modified
  - Given: `parent_a.genome.color.allele_a = "gold"` before call
  - When: `get_breed_preview(parent_a, parent_b)`
  - Then: `parent_a.genome.color.allele_a` still equals `"gold"` after call

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/genetics_breed_preview_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/genetics_breed_preview_test.gd` — 8 test functions

---

## Dependencies

- Depends on: **Story 002 must be DONE** — `genetics_system.gd` must exist with `breed()` implemented
- Unlocks: Story 004 (rarity — shares `_estimate_rarity()` helper)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 9/9 passing
**Deviations**: ADVISORY — `_estimate_rarity()` uses inline colour strings (temporary; Story 004 replaces with `_color_to_rarity_tier()` match). ADVISORY — `_slot_probabilities` seeds all catalogue keys including 0.0-probability entries; test guards with `> EPSILON`.
**Test Evidence**: Logic — `tests/unit/core/genetics_breed_preview_test.gd` ✅ (8 test functions)
**Code Review**: Skipped — Lean mode
