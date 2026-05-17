# Epic: GeneticsSystem

> **Layer**: Core
> **GDD**: design/gdd/bunny-farm-idle-master.md (§3.2 Genetics System — Core Differentiator)
> **Architecture Module**: `src/core/genetics_system.gd` + `src/core/genetics/` directory
> **Status**: Ready
> **Control Manifest Version**: pending — run `/create-control-manifest` to assign
> **Stories**: 5 stories — all Ready (ADR-0006 Accepted 2026-05-17)

## Overview

GeneticsSystem is the core differentiator of the game. It owns the breeding algorithm: slot-by-slot allele inheritance from two parent rabbits, per-allele mutation rolls, and the pure probability calculation for the gene preview pie chart. It also resolves trait stacking interactions (synergy bonuses, cancellation rules, hidden Ultra Trait combos) and determines a rabbit's rarity tier from its expressed color allele. Neither `breed()` nor `get_breed_preview()` modifies the parent rabbits. All probability weights and mutation chances are loaded from `balance.json`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: GDScript Language | `@abstract` on `BaseAllele` base class; all allele keys statically typed | LOW |
| ADR-0004: JSON Balance Data | Mutation chance, rarity weights, trait synergy/cancellation table — all from `balance.json` | LOW |
| ADR-0005: RabbitData Resource | `RabbitData.genome: Genome` field; `breed()` returns new `RabbitData` without modifying parents | LOW |
| ADR-0006: Genetics Allele Model | Full allele inheritance algorithm, `Genome` + `GeneSlot` schema, `AlleleCatalogue` constants, `BreedPreview` + `TraitEffects` value objects | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-genetics-001 | 6-slot genome (color, size, ears, trait_a, trait_b, special) | ADR-0006 ✅ |
| TR-genetics-002 | Offspring inherits 1 allele from each parent per slot | ADR-0006 ✅ |
| TR-genetics-003 | Mutation roll at base 5%, modifiable by items/traits/hutch | ADR-0006 ✅, ADR-0004 ✅ |
| TR-genetics-004 | Gene Preview with probability pie chart before breeding | ADR-0006 ✅ (`get_breed_preview()` pure function) |
| TR-genetics-005 | Trait stacking: synergy, cancellation, hidden combo (Ultra Trait) | ADR-0006 ✅ |
| TR-genetics-006 | 7 color-rarity tiers with specific probability weights | ADR-0006 ✅, ADR-0004 ✅ |

> Note: All requirements covered by ADRs. No blocking gaps.

## Key Interfaces

```gdscript
# src/core/genetics_system.gd
func breed(parent_a: RabbitData, parent_b: RabbitData) -> RabbitData
func get_breed_preview(parent_a: RabbitData, parent_b: RabbitData) -> BreedPreview
func get_trait_effects(rabbit: RabbitData) -> TraitEffects
func get_rarity(rabbit: RabbitData) -> RarityTier

# src/core/genetics/allele_catalogue.gd
class_name AlleleCatalogue
const COLORS: Array[String]
const TRAITS_TIER1: Array[String]
const TRAITS_TIER2: Array[String]
const TRAITS_TIER3: Array[String]

# src/core/genetics/genome.gd
class_name Genome extends Resource
var color: GeneSlot; var size: GeneSlot; var ears: GeneSlot
var trait_a: GeneSlot; var trait_b: GeneSlot; var special: GeneSlot
```

## Forbidden Patterns (from Architecture Registry)

- `inline_allele_strings` — allele keys must come from `AlleleCatalogue` constants, never inline `"gold"` or `"fast_eater"` literals
- `direct_rabbitdata_mutation` — `breed()` must never write to `parent_a` or `parent_b` fields
- `upward_direct_method_calls` — GeneticsSystem may not call Feature or Presentation methods

## Definition of Done

This epic is complete when:
- [ ] All stories are implemented, reviewed, and closed via `/story-done`
- [ ] GdUnit4: `breed()` with seeded RNG produces deterministic child genome over 100 runs
- [ ] GdUnit4: `get_breed_preview()` probability dicts sum to 1.0 (± 0.0001) per slot
- [ ] GdUnit4: 10,000 simulated breeds — all output allele keys are in `AlleleCatalogue` arrays
- [ ] GdUnit4: `breed()` does not modify `parent_a.genome` or `parent_b.genome`
- [ ] GdUnit4: trait synergy `fast_eater + efficient_eater` → `TraitEffects.growth_rate_bonus > 0`
- [ ] GdUnit4: trait cancellation `calm + active` → weaker trait suppressed
- [ ] Minimum 80% test coverage on genetics formulas (per technical-preferences.md)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Genome Schema + AlleleCatalogue](story-001-genome-schema.md) | Logic | Complete | ADR-0006 ✅ |
| 002 | [Breed — Inheritance + Mutation Algorithm](story-002-inheritance-mutation.md) | Logic | Complete | ADR-0006 ✅ + ADR-0004 ✅ |
| 003 | [Gene Preview — Probability Tables](story-003-breed-preview.md) | Logic | Complete | ADR-0006 ✅ |
| 004 | [Rarity Tier Determination](story-004-rarity-tier.md) | Logic | Complete | ADR-0006 ✅ + ADR-0004 ✅ |
| 005 | [Trait Stacking — Synergy, Cancellation, Ultra Trait](story-005-trait-stacking.md) | Logic | Complete | ADR-0006 ✅ + ADR-0004 ✅ |

## Next Step

Run `/dev-story production/epics/genetics-system/story-001-genome-schema.md` to begin implementation. Work in dependency order: 001 → 002 → 003/004 → 005.
