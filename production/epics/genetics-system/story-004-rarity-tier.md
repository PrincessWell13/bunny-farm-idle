# Story 004: Rarity Tier Determination

> **Epic**: GeneticsSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.2 Genetics System)
**Requirement**: `TR-genetics-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0006 Accepted ✅, ADR-0004 Accepted ✅

**ADR Governing Implementation**: ADR-0006 (Genetics Allele Model) + ADR-0004 (Balance JSON)
**ADR Decision Summary**: A rabbit's rarity tier is derived from its expressed color allele — not stored. `get_rarity(rabbit)` reads `rabbit.genome.color.expressed()` and maps it to a `RarityTier` enum. Rarity weights (used for mutation pool selection) are loaded from `balance.json` under `genetics.rarity_weights`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript enum and Dictionary lookup. No engine API surface.

**Control Manifest Rules (Core layer)**:
- Required: rarity weights loaded from `balance.json` — no hardcoded floats
- Forbidden: `inline_allele_strings` — color keys from `AlleleCatalogue` only
- Forbidden: `direct_rabbitdata_mutation` — `get_rarity()` must not modify the rabbit

---

## Acceptance Criteria

*From GDD §3.2 and ADR-0006 Rarity Determination section:*

- [ ] `RarityTier` enum defined: `COMMON, UNCOMMON, RARE, EPIC, LEGENDARY`
- [ ] `get_rarity(rabbit)` returns `RarityTier.COMMON` for `color.allele_a = "white"`, `"brown"`, or `"grey"`
- [ ] `get_rarity(rabbit)` returns `RarityTier.UNCOMMON` for `"spotted"`, `"striped"`, or `"calico"`
- [ ] `get_rarity(rabbit)` returns `RarityTier.RARE` for `"gold"` or `"silver"`
- [ ] `get_rarity(rabbit)` returns `RarityTier.EPIC` for `"galaxy"` or `"rainbow"`
- [ ] `get_rarity(rabbit)` returns `RarityTier.LEGENDARY` for `"legendary"`
- [ ] All 11 `AlleleCatalogue.COLORS` entries map to a `RarityTier` without error
- [ ] `_random_allele("color")` returns only entries from `AlleleCatalogue.COLORS` (no orphan strings)
- [ ] Rarity weights for mutation pool selection are loaded from `balance.json` `genetics.rarity_weights`; fallback defaults used if absent

---

## Implementation Notes

*Derived from ADR-0006 Rarity Determination section:*

Add to `src/core/genetics_system.gd`:
- `enum RarityTier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }` — at the top of the file
- `func get_rarity(rabbit: RabbitData) -> RarityTier` — public method
- `func _color_to_rarity_tier(color: String) -> RarityTier` — private helper

The color→tier mapping (from ADR-0006 `AlleleCatalogue.COLORS` ordering):
```
COMMON:     white, brown, grey
UNCOMMON:   spotted, striped, calico
RARE:       gold, silver
EPIC:       galaxy, rainbow
LEGENDARY:  legendary
```

This mapping lives in `_color_to_rarity_tier()` as a `match` statement — not as a dictionary in `balance.json`. The *weights* (probability of landing in each tier during mutation) come from `balance.json`, but the color→tier mapping is fixed by the catalogue order.

Load from `balance.json` in `_load_balance_data()`:
```gdscript
var genetics_section: Dictionary = data.get("genetics", {}) as Dictionary
var rarity_weights: Dictionary = genetics_section.get("rarity_weights", {}) as Dictionary
# Store per-tier weights for _random_allele("color") weighted selection
```

`_random_allele("color")` uses the loaded rarity weights to pick a tier first, then picks a random allele within that tier — this is what makes common colors more likely to appear from mutation than legendary ones.

Default rarity weights (if `balance.json` absent):
- `common`: 0.60, `uncommon`: 0.25, `rare`: 0.10, `epic`: 0.04, `legendary`: 0.01

---

## Out of Scope

- Story 001: `AlleleCatalogue.COLORS` constant definition
- Story 002: `_random_allele()` stub — this story upgrades it to use rarity weights
- Story 003: `_estimate_rarity()` used in BreedPreview — called by this story's mapping logic

---

## QA Test Cases

- **AC-1 (enum)**: RarityTier enum accessible
  - Given: `GeneticsSystem` class loaded
  - When: `GeneticsSystem.RarityTier.LEGENDARY`
  - Then: resolves without error

- **AC-2/3**: known color → rarity tier
  - Given: rabbit with `genome.color.allele_a = "white"`
  - When: `system.get_rarity(rabbit)`
  - Then: `== GeneticsSystem.RarityTier.COMMON`

  - Given: `allele_a = "gold"` → Then: `RarityTier.RARE`
  - Given: `allele_a = "legendary"` → Then: `RarityTier.LEGENDARY`
  - Given: `allele_a = "galaxy"` → Then: `RarityTier.EPIC`
  - Given: `allele_a = "spotted"` → Then: `RarityTier.UNCOMMON`

- **AC-5 (full catalogue)**: all colors map without error
  - Given: for each color in `AlleleCatalogue.COLORS`
  - When: create rabbit with that color as expressed allele; call `get_rarity()`
  - Then: returns a valid `RarityTier` value (no crash, no UNKNOWN)

- **AC-6**: `_random_allele("color")` only produces catalogue values
  - Given: call `_random_allele("color")` 1000 times
  - When: collect all results
  - Then: every result is in `AlleleCatalogue.COLORS`

- **AC-7**: balance.json rarity weights loaded
  - Given: a mock balance.json with `genetics.rarity_weights.legendary = 0.5`
  - When: system loads balance and calls `_random_allele("color")` 100 times
  - Then: roughly 50% of results are `"legendary"` (statistically — test with high tolerance ±20%)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/genetics_rarity_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/genetics_rarity_test.gd` — 8 test functions

---

## Dependencies

- Depends on: **Story 002 must be DONE** — `genetics_system.gd` must exist with `_load_balance_data()` stub
- Unlocks: Story 005 (trait stacking — completes the `get_trait_effects()` public API)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 9/9 passing
**Deviations**: None — inline string ADVISORY from story-003 resolved by `_color_to_rarity_tier()` match statement. `_estimate_rarity()` refactored to use it.
**Test Evidence**: Logic — `tests/unit/core/genetics_rarity_test.gd` ✅ (8 test functions)
**Code Review**: Skipped — Lean mode
