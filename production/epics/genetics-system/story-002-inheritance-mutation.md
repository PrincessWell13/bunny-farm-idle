# Story 002: Breed — Inheritance + Mutation Algorithm

> **Epic**: GeneticsSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.2 Genetics System)
**Requirement**: `TR-genetics-002`, `TR-genetics-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0006 Accepted ✅, ADR-0004 Accepted ✅

**ADR Governing Implementation**: ADR-0006 (Genetics Allele Model) + ADR-0004 (Balance JSON)
**ADR Decision Summary**: `breed(parent_a, parent_b)` returns a new `RabbitData` without modifying parents. Per slot, child inherits one random allele from parent_a and one from parent_b (50/50 each). Per allele, a mutation roll replaces the allele with a random catalogue entry if `randf() < effective_mutation_chance`. Effective mutation = `(parent_a.mutation_chance + parent_b.mutation_chance) * 0.5`. Base mutation chance loaded from `balance.json`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RandomNumberGenerator.seed` is stable in Godot 4.6 for deterministic replay testing.

**Control Manifest Rules (Core layer)**:
- Required: `breed()` returns new `RabbitData` — never modifies parents
- Forbidden: `direct_rabbitdata_mutation` — no writes to `parent_a` or `parent_b` fields
- Forbidden: `inline_allele_strings` — `_random_allele()` must use `AlleleCatalogue` arrays only
- Required: mutation chance loaded from `balance.json` — no hardcoded floats

---

## Acceptance Criteria

*From GDD §3.2 and ADR-0006 inheritance algorithm:*

- [ ] `breed(parent_a, parent_b)` returns a new `RabbitData` with a non-null `genome`
- [ ] `child.parent_a_id == parent_a.rabbit_id` and `child.parent_b_id == parent_b.rabbit_id`
- [ ] For each slot, `child.genome.color.allele_a` is either `parent_a.genome.color.allele_a` or `parent_a.genome.color.allele_b`
- [ ] For each slot, `child.genome.color.allele_b` is either `parent_b.genome.color.allele_a` or `parent_b.genome.color.allele_b`
- [ ] `breed()` does not modify `parent_a.genome` or `parent_b.genome` — all parent alleles unchanged after call
- [ ] With `mutation_chance = 0.0` on both parents: child alleles are always from parent alleles (no catalogue-only alleles appear)
- [ ] With `mutation_chance = 1.0` on both parents: all child alleles are mutated (replaced with valid catalogue entries)
- [ ] With a fixed `_rng.seed`, `breed()` produces identical child genome across 100 repeated calls
- [ ] After 10,000 simulated breeds, all output allele keys exist in `AlleleCatalogue` arrays (no orphan strings)

---

## Implementation Notes

*Derived from ADR-0006 Decision — Inheritance Algorithm:*

Create `src/core/genetics_system.gd` with `class_name GeneticsSystem extends Node`.

The `_rng: RandomNumberGenerator` must be injectable for deterministic testing:
```gdscript
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
```

Expose `func set_rng(rng: RandomNumberGenerator) -> void` so tests can inject a seeded RNG.

`_inherit_slot(slot_a, slot_b, mutation_chance, catalogue_key)` uses exactly 4 `_rng.randf()` calls per slot:
1. Pick `allele_a` from parent_a (< 0.5 → slot_a.allele_a, else slot_a.allele_b)
2. Pick `allele_b` from parent_b (< 0.5 → slot_b.allele_a, else slot_b.allele_b)
3. Mutation roll for `allele_a`
4. Mutation roll for `allele_b`

`_random_allele(catalogue_key: String) -> String` dispatches on key:
- `"color"` → random pick from `AlleleCatalogue.COLORS`
- `"size"` → `["small", "medium", "large"]`
- `"ears"` → `["floppy", "upright", "stubby"]`
- `"trait"` → random pick from TIER1+TIER2+TIER3+["none"]
- `"special"` → `["none"]` (expand in future story)

Effective mutation: `(parent_a.mutation_chance + parent_b.mutation_chance) * 0.5`.

`breed()` also sets `child.birth_timestamp = int(Time.get_unix_time_from_system())`.

**Do not call `_load_balance_data()` in this story** — that is deferred to Story 004 which adds `get_rarity()` and the rarity weights section. This story uses only `RabbitData.mutation_chance` which is already a field on `RabbitData`.

---

## Out of Scope

- Story 001: the data types (`Genome`, `GeneSlot`, `AlleleCatalogue`) — must be DONE first
- Story 003: `get_breed_preview()` — adds to `genetics_system.gd` in a follow-up
- Story 004: rarity weight loading from `balance.json`
- Story 005: trait stacking — separate method, separate story

---

## QA Test Cases

- **AC-1 & AC-2**: `breed()` returns new RabbitData with parentage
  - Given: `parent_a` with `rabbit_id = "a"`, `parent_b` with `rabbit_id = "b"`; both with valid genomes
  - When: `var child := system.breed(parent_a, parent_b)`
  - Then: `child != null`, `child.genome != null`, `child.parent_a_id == "a"`, `child.parent_b_id == "b"`

- **AC-3 & AC-4**: allele provenance (no mutation)
  - Given: `parent_a.genome.color = GeneSlot(allele_a="white", allele_b="brown")`; `parent_b.genome.color = GeneSlot(allele_a="grey", allele_b="spotted")`; `mutation_chance = 0.0`
  - When: `system.breed(parent_a, parent_b)`
  - Then: `child.genome.color.allele_a in ["white", "brown"]`; `child.genome.color.allele_b in ["grey", "spotted"]`

- **AC-5**: parent immutability
  - Given: `parent_a.genome.color.allele_a = "gold"` before breed
  - When: `system.breed(parent_a, parent_b)`
  - Then: `parent_a.genome.color.allele_a` still equals `"gold"` after breed; no parent field changed

- **AC-6**: no mutation at 0.0
  - Given: both parents `mutation_chance = 0.0`; known alleles only
  - When: breed 100 times
  - Then: every child allele is in `["white", "brown", "grey", "spotted"]` (parent alleles only)

- **AC-7**: full mutation at 1.0
  - Given: both parents `mutation_chance = 1.0`; `parent alleles = "white"` in all slots
  - When: breed once
  - Then: at least some child alleles differ from `"white"` (mutation replaced them)

- **AC-8**: deterministic with seeded RNG
  - Given: `system._rng.seed = 12345`; fixed parents
  - When: `system.breed(parent_a, parent_b)` called 100 times, resetting seed each time
  - Then: all 100 child genomes are identical

- **AC-9**: fuzz — all alleles valid after 10,000 breeds
  - Given: 10,000 breed calls with random parents
  - When: collect all child allele strings
  - Then: every allele key is in `AlleleCatalogue.COLORS`, `TRAITS_TIER1`, `TRAITS_TIER2`, `TRAITS_TIER3`, `["none"]`, `["small","medium","large"]`, or `["floppy","upright","stubby"]`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/genetics_inheritance_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/genetics_inheritance_test.gd` — 8 test functions

---

## Dependencies

- Depends on: **Story 001 must be DONE** — `Genome`, `GeneSlot`, `AlleleCatalogue` must exist
- Unlocks: Story 003 (preview adds to same file), Story 004 (rarity adds to same file), Story 005 (trait stacking adds to same file)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 9/9 passing
**Deviations**: OUT OF SCOPE (valid) — `rabbit_data.gd` genome field retyped `Resource` → `Genome`; required for static typing in `breed()`; no logic change
**Test Evidence**: Logic — `tests/unit/core/genetics_inheritance_test.gd` ✅ (8 test functions)
**Code Review**: Skipped — Lean mode
