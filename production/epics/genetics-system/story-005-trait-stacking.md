# Story 005: Trait Stacking — Synergy, Cancellation, Ultra Trait

> **Epic**: GeneticsSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.2 Genetics System)
**Requirement**: `TR-genetics-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0006 Accepted ✅, ADR-0004 Accepted ✅

**ADR Governing Implementation**: ADR-0006 (Genetics Allele Model) + ADR-0004 (Balance JSON)
**ADR Decision Summary**: `get_trait_effects(rabbit)` reads expressed traits from `trait_a`, `trait_b`, and `special` slots, then resolves three interaction types in order: (1) cancellation — opposing pairs suppress the weaker trait, (2) synergy — matching pairs apply a combined bonus multiplier, (3) hidden combo — 3 specific traits across all slots unlock an ultra trait. The full interaction table lives in `balance.json` under `genetics.trait_synergies` and `genetics.trait_cancellations`. Returns a `TraitEffects` value object without modifying the rabbit.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript logic. No engine API surface.

**Control Manifest Rules (Core layer)**:
- Required: synergy/cancellation table loaded from `balance.json` — no hardcoded pairs in source
- Forbidden: `direct_rabbitdata_mutation` — `get_trait_effects()` must not modify rabbit
- Forbidden: `upward_direct_method_calls` — GeneticsSystem may not call Feature or Presentation methods

---

## Acceptance Criteria

*From GDD §3.2 and ADR-0006 Trait Stacking Rules:*

- [ ] `get_trait_effects(rabbit)` returns a `TraitEffects` object without modifying the rabbit
- [ ] With `trait_a = "none"` and `trait_b = "none"`: all bonuses are 0.0, `has_ultra_trait = false`
- [ ] Synergy: `fast_eater` + `efficient_eater` → `TraitEffects.growth_rate_bonus > 0`
- [ ] Cancellation: `calm` + `active` → weaker trait suppressed (its bonus contribution is 0 when cancelled)
- [ ] Cancellation check runs before synergy — a cancelled trait cannot participate in a synergy
- [ ] Hidden combo: a rabbit with 3 specific traits (from balance.json combo table) across `trait_a`, `trait_b`, `special` → `has_ultra_trait = true` and `ultra_trait_id` is non-empty
- [ ] `get_trait_effects()` does not modify `rabbit.genome` or any rabbit field
- [ ] Synergy/cancellation/combo tables loaded from `balance.json`; fallback defaults used if absent

---

## Implementation Notes

*Derived from ADR-0006 Trait Stacking Rules section:*

Add `get_trait_effects()` and helpers to `src/core/genetics_system.gd`.

Resolution order (strict — do not reorder):
1. **Cancellation** (checked first): for each pair in `genetics.trait_cancellations`, if both traits are present, suppress the "weaker" one (defined in the table as the second entry in the pair). Mark it cancelled in a local Set.
2. **Synergy**: for each pair in `genetics.trait_synergies`, if both traits are present AND neither is cancelled, apply the bonus defined in the table to `TraitEffects`.
3. **Hidden combo**: for each combo in `genetics.ultra_combos`, if all 3 traits are present across trait_a, trait_b, special (cancelled status does not block combo), set `has_ultra_trait = true` and `ultra_trait_id`.

Collect active traits from `rabbit.genome.trait_a.expressed()`, `rabbit.genome.trait_b.expressed()`, and `rabbit.genome.special.expressed()`.

`balance.json` `genetics` section additions needed for this story:
```json
"trait_synergies": [
  { "traits": ["fast_eater", "efficient_eater"], "bonus": { "growth_rate_bonus": 0.3 } }
],
"trait_cancellations": [
  { "traits": ["calm", "active"], "suppressed": "active" }
],
"ultra_combos": [
  { "traits": ["gene_beacon", "mutation_master", "golden_touch"], "ultra_trait_id": "omega_gene" }
]
```

These are defaults — the actual table can be expanded in `balance.json` without code changes.

`_load_balance_data()` must be extended to load these three arrays. Store as typed instance variables.

---

## Out of Scope

- Story 001: `TraitEffects` resource definition (must be DONE)
- Story 002: `breed()` — trait stacking is a separate read-only operation applied after breeding
- Presentation layer: UI showing synergy bonuses, ultra trait unlock animation

---

## QA Test Cases

- **AC-1**: `get_trait_effects()` returns TraitEffects
  - Given: any rabbit
  - When: `system.get_trait_effects(rabbit)`
  - Then: result is not null; `result is TraitEffects`

- **AC-2**: no traits → all zeros
  - Given: rabbit with `genome.trait_a.allele_a = "none"`, `trait_b.allele_a = "none"`, `special.allele_a = "none"`
  - When: `var fx := system.get_trait_effects(rabbit)`
  - Then: `fx.growth_rate_bonus == 0.0`, `fx.fertility_bonus == 0.0`, `fx.has_ultra_trait == false`

- **AC-3**: synergy applies growth bonus
  - Given: rabbit with `trait_a.allele_a = "fast_eater"`, `trait_b.allele_a = "efficient_eater"`
  - When: `var fx := system.get_trait_effects(rabbit)`
  - Then: `fx.growth_rate_bonus > 0.0`

- **AC-4**: cancellation suppresses weaker trait
  - Given: rabbit with `trait_a.allele_a = "calm"`, `trait_b.allele_a = "active"`
  - When: `var fx := system.get_trait_effects(rabbit)`
  - Then: the `"active"` trait's bonus contribution is 0 (suppressed); `"calm"` trait's bonus may still apply

- **AC-5**: cancellation runs before synergy
  - Given: a combination where one trait is in a cancellation pair AND a synergy pair
  - When: `get_trait_effects()`
  - Then: the cancelled trait does NOT contribute to synergy bonus

- **AC-6**: hidden combo unlocks ultra trait
  - Given: rabbit with `trait_a.allele_a = "gene_beacon"`, `trait_b.allele_a = "mutation_master"`, `special.allele_a = "golden_touch"`; balance.json defines this combo
  - When: `var fx := system.get_trait_effects(rabbit)`
  - Then: `fx.has_ultra_trait == true`, `fx.ultra_trait_id == "omega_gene"`

- **AC-7**: rabbit not modified
  - Given: rabbit with known trait values before call
  - When: `get_trait_effects(rabbit)`
  - Then: `rabbit.genome.trait_a.allele_a` unchanged after call

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/genetics_trait_stacking_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/genetics_trait_stacking_test.gd` — 8 test functions

---

## Dependencies

- Depends on: **Story 002 must be DONE** — `genetics_system.gd` must exist; **Story 001 must be DONE** — `TraitEffects` class must exist
- Unlocks: GeneticsSystem epic complete (all 5 stories done = full genetics pipeline functional)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 8/8 passing
**Deviations**: ADVISORY — fallback default dicts in `_trait_synergies`/`_trait_cancellations`/`_ultra_combos` var declarations contain inline trait key strings (design intent: fallback for missing balance.json; same pattern as story-004 `_rarity_weights`). ADVISORY — AC-8 (JSON loading path) has no dedicated unit test; structural verification only.
**Test Evidence**: Logic — `tests/unit/core/genetics_trait_stacking_test.gd` ✅ (8 test functions)
**Code Review**: Skipped — Lean mode
