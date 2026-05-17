# ADR-0006: Genetics — Allele Inheritance Model and Mutation Algorithm

## Status
Accepted

## Date
2026-05-16

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — pure GDScript logic; no engine API surface used |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | `RandomNumberGenerator` (stable); `@abstract` on `BaseAllele` (4.5 — approved in ADR-0002) |
| **Verification Required** | Confirm `RandomNumberGenerator` seeding behaviour is deterministic for replay testing in Godot 4.6 headless mode |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (static typing — all allele keys and probability tables typed), ADR-0004 (mutation chance, rarity weights, trait tier weights from balance.json), ADR-0005 (RabbitData.genome field — this ADR defines what lives in it) |
| **Enables** | Any story implementing breeding UI, gene preview, trait stacking, collection registration, or gene journal |
| **Blocks** | All genetics-related stories until Accepted |
| **Ordering Note** | ADR-0005 must be Accepted first — `Genome` is a nested resource on `RabbitData` |

## Context

### Problem Statement
The GDD's genetics system is the core differentiator: 6-slot genomes, 2 alleles per slot, inheritance via random allele selection, mutation rolls, 24 traits across 3 tiers with synergy and cancellation interactions, and 7 rarity tiers. This is a rich combinatorial space. We need precise data structures and algorithm rules so that: (a) unit tests can verify inheritance math deterministically, (b) `get_breed_preview()` gives accurate probability tables without side effects, (c) the mutation algorithm is tunable from `balance.json`, and (d) trait stacking effects are composable and do not require exhaustive hardcoded combinatorics.

### Constraints
- `GeneticsSystem.breed()` must not modify either parent (ADR-0005 immutability rule)
- All probability weights loaded from `balance.json` (ADR-0004 — no hardcoded floats in `src/`)
- All types statically typed (ADR-0002)
- `get_breed_preview()` must be a pure function — no `RandomNumberGenerator` calls, no side effects
- The allele catalogue (all valid allele key strings) must be defined as constants, not magic strings

### Requirements
- Must encode 6 named gene slots (color, size, ears, trait_a, trait_b, special)
- Must support 7 color rarity tiers with tunable weights
- Must support 24 traits across 3 tiers
- Must produce a `BreedPreview` with per-slot color and trait probability breakdowns
- Must apply synergy, cancellation, and hidden combo trait stacking rules
- Must be unit-testable with a seeded `RandomNumberGenerator`

## Decision

### Resource Hierarchy

```gdscript
# src/core/genetics/genome.gd
class_name Genome extends Resource

var color: GeneSlot = GeneSlot.new()    # allele keys: color catalogue
var size: GeneSlot = GeneSlot.new()     # allele keys: "small" | "medium" | "large"
var ears: GeneSlot = GeneSlot.new()     # allele keys: "floppy" | "upright" | "stubby"
var trait_a: GeneSlot = GeneSlot.new()  # allele keys: trait catalogue (24 traits + "none")
var trait_b: GeneSlot = GeneSlot.new()
var special: GeneSlot = GeneSlot.new()  # allele keys: special catalogue or "none"
```

```gdscript
# src/core/genetics/gene_slot.gd
class_name GeneSlot extends Resource

var allele_a: String = "none"
var allele_b: String = "none"

# The expressed allele — computed, not stored.
# For color/size/ears: allele_a is always dominant (first-inherited wins).
# For traits: both alleles express independently (no dominance).
func expressed() -> String:
    return allele_a
```

### Allele Catalogues (constants, not magic strings)

```gdscript
# src/core/genetics/allele_catalogue.gd
class_name AlleleCatalogue

# Color alleles — ordered by rarity tier (index 0 = most common)
const COLORS: Array[String] = [
    "white", "brown", "grey",           # common (~60%)
    "spotted", "striped", "calico",     # uncommon (~25%)
    "gold", "silver",                   # rare (~10%)
    "galaxy",                           # very rare (~3%)
    "rainbow",                          # epic (~1%)
    "legendary"                         # legendary (~0.1%)
]

# Trait alleles (24 + "none")
const TRAITS_TIER1: Array[String] = [
    "fast_eater", "efficient_eater", "active", "calm", "sturdy", "curious"
]
const TRAITS_TIER2: Array[String] = [
    "speed_grower", "high_fertility", "lucky", "charming",
    "heat_resistant", "cold_adapted", "night_owl", "early_bird"
]
const TRAITS_TIER3: Array[String] = [
    "gene_beacon", "immortal_gene", "mutation_master",
    "golden_touch", "legendary_blood",
    "aura_emitter", "ultra_sense", "time_bender", "void_walker", "cosmic_link"
]
const TRAIT_NONE: String = "none"
```

### Inheritance Algorithm

```
For each of the 6 GeneSlots:
  1. Pick allele_a for child: 50% chance parent_a.allele_a, 50% parent_a.allele_b
  2. Pick allele_b for child: 50% chance parent_b.allele_a, 50% parent_b.allele_b
  3. Mutation roll (per allele):
     - roll random float 0.0–1.0
     - if < effective_mutation_chance → replace with random allele from that slot's catalogue
     - mutation_chance = base (from balance.json) + item_boost + trait_boost + hutch_bonus
```

```gdscript
# src/core/genetics_system.gd
class_name GeneticsSystem extends Node

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func breed(parent_a: RabbitData, parent_b: RabbitData) -> RabbitData:
    # Neither parent is modified — new RabbitData returned
    var child: RabbitData = RabbitData.new()
    child.genome = _build_child_genome(parent_a.genome, parent_b.genome,
                                       parent_a.mutation_chance, parent_b.mutation_chance)
    child.parent_a_id = parent_a.rabbit_id
    child.parent_b_id = parent_b.rabbit_id
    child.birth_timestamp = int(Time.get_unix_time_from_system())
    return child

func _build_child_genome(genome_a: Genome, genome_b: Genome,
                          mut_a: float, mut_b: float) -> Genome:
    var child_genome: Genome = Genome.new()
    var effective_mutation: float = (mut_a + mut_b) * 0.5  # average of both parents
    child_genome.color  = _inherit_slot(genome_a.color,   genome_b.color,   effective_mutation, "color")
    child_genome.size   = _inherit_slot(genome_a.size,    genome_b.size,    effective_mutation, "size")
    child_genome.ears   = _inherit_slot(genome_a.ears,    genome_b.ears,    effective_mutation, "ears")
    child_genome.trait_a = _inherit_slot(genome_a.trait_a, genome_b.trait_a, effective_mutation, "trait")
    child_genome.trait_b = _inherit_slot(genome_a.trait_b, genome_b.trait_b, effective_mutation, "trait")
    child_genome.special = _inherit_slot(genome_a.special, genome_b.special, effective_mutation, "special")
    return child_genome

func _inherit_slot(slot_a: GeneSlot, slot_b: GeneSlot,
                   mutation_chance: float, catalogue_key: String) -> GeneSlot:
    var child_slot: GeneSlot = GeneSlot.new()
    # Pick one allele from each parent
    child_slot.allele_a = slot_a.allele_a if _rng.randf() < 0.5 else slot_a.allele_b
    child_slot.allele_b = slot_b.allele_a if _rng.randf() < 0.5 else slot_b.allele_b
    # Mutation roll per allele
    if _rng.randf() < mutation_chance:
        child_slot.allele_a = _random_allele(catalogue_key)
    if _rng.randf() < mutation_chance:
        child_slot.allele_b = _random_allele(catalogue_key)
    return child_slot
```

### Gene Preview (Pure Function — No RNG)

`get_breed_preview()` calculates probability distributions analytically without RNG.
For each allele position, the 4 possible outcomes (a→a, a→b, b→a, b→b) each have 25%
base probability, adjusted by mutation chance.

```gdscript
func get_breed_preview(parent_a: RabbitData, parent_b: RabbitData) -> BreedPreview:
    var preview: BreedPreview = BreedPreview.new()
    preview.color_probabilities = _slot_probabilities(
        parent_a.genome.color, parent_b.genome.color,
        (parent_a.mutation_chance + parent_b.mutation_chance) * 0.5, "color")
    preview.trait_a_probabilities = _slot_probabilities(
        parent_a.genome.trait_a, parent_b.genome.trait_a,
        (parent_a.mutation_chance + parent_b.mutation_chance) * 0.5, "trait")
    preview.mutation_chance = (parent_a.mutation_chance + parent_b.mutation_chance) * 0.5
    preview.estimated_rarity = _estimate_rarity(preview.color_probabilities)
    return preview
```

```gdscript
# BreedPreview fields:
class_name BreedPreview extends Resource
var color_probabilities: Dictionary = {}   # allele_key → probability float (0.0–1.0)
var trait_a_probabilities: Dictionary = {}
var trait_b_probabilities: Dictionary = {}
var mutation_chance: float = 0.0
var estimated_rarity: RarityTier = RarityTier.COMMON
```

### Rarity Determination

A rabbit's rarity tier is derived from its expressed color allele, not stored:

```gdscript
enum RarityTier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

func get_rarity(rabbit: RabbitData) -> RarityTier:
    var expressed_color: String = rabbit.genome.color.expressed()
    return _color_to_rarity_tier(expressed_color)
```

Rarity weights in `balance.json` (ADR-0004, `genetics.rarity_weights` section) drive mutation pool selection — a random color allele mutation uses these weights to pick which tier the new allele falls in.

### Trait Stacking Rules

`apply_trait_stacking()` reads the expressed traits from `trait_a` and `trait_b` slots and returns a `TraitEffects` value object. It does NOT modify the rabbit.

Three interaction types, resolved in order:

1. **Cancellation** (checked first): if `(calm, active)` or similar opposing pair → weaker trait suppressed
2. **Synergy**: if matching pair present → apply combined bonus (e.g., `fast_eater + efficient_eater` → `optimized` bonus ×1.3)
3. **Hidden combo**: if 3 specific traits present across `trait_a`, `trait_b`, `special` → `ultra_trait` unlocked (discovery — not shown in preview)

```gdscript
# TraitEffects — value object, no identity
class_name TraitEffects extends RefCounted
var growth_rate_bonus: float = 0.0
var fertility_bonus: float = 0.0
var mutation_bonus: float = 0.0
var coin_bonus: float = 0.0
var drop_rate_bonus: float = 0.0
var legendary_blood_bonus: float = 0.0
var has_ultra_trait: bool = false
var ultra_trait_id: String = ""
```

The full stacking table (which pairs → which bonus) is data-driven: stored in `balance.json` under `genetics.trait_synergies` and `genetics.trait_cancellations`. This is not yet in the ADR-0004 schema — it must be added to `balance.json` when `GeneticsSystem` is implemented.

## Alternatives Considered

### Alternative B: Alleles as enum integers instead of String keys
- **Description**: Each allele is an integer index into a fixed catalogue array.
- **Pros**: Marginally faster comparison; slightly smaller JSON footprint.
- **Cons**: Integer alleles are opaque in save files and logs — `3` vs `"gold"`. Debugging, data editing, and readability all suffer. Renumbering a catalogue entry corrupts all existing saves.
- **Rejection Reason**: String keys are human-readable in `savegame.json`, diffable in version control, and safe to reorder. The performance delta is immeasurable for 24 active rabbits.

### Alternative C: Genome as Array[GeneSlot] with 6 elements
- **Description**: `var genome: Array[GeneSlot]` indexed 0–5.
- **Pros**: Trivially iterable for bulk slot processing.
- **Cons**: `genome[2]` is opaque — readers must know slot 2 = ears. Named properties (`genome.ears`) are self-documenting and prevent index-off-by-one errors. Static analysis catches `genome.colour` (typo) but not `genome[9]`.
- **Rejection Reason**: Named fields are clearer for a 6-slot fixed schema. Iteration is not a common operation; access by name is.

### Alternative D: Dominant/recessive allele model (Mendelian)
- **Description**: Each slot has a dominant allele that expresses, hiding the recessive. Players must understand heterozygosity to predict offspring.
- **Pros**: More biologically authentic; deeper strategy.
- **Cons**: Significantly more complex for players to reason about. The GDD does not mention dominant/recessive — it says "player sees probability pie chart" suggesting all alleles have equal weight in the preview.
- **Rejection Reason**: Complexity not warranted by the GDD's design intent. The current model (allele_a as expressed, both alleles visible in preview) gives sufficient strategy depth without requiring genetics education.

## Consequences

### Positive
- `breed()` is deterministic given a seeded `RandomNumberGenerator` — fully unit-testable
- `get_breed_preview()` is a pure function — testable without any RNG
- String allele keys make `savegame.json` human-readable and debuggable
- Trait stacking table in `balance.json` means new synergies can be added without code changes
- `Genome` as a `Resource` nests cleanly in `RabbitData` and serialises via SaveSystem's explicit dict pattern

### Negative
- String key comparison is marginally slower than integer enum comparison — immaterial for 24 rabbits
- Trait stacking interaction table needs to be maintained in `balance.json` — must be kept in sync with the `TRAITS_TIER*` catalogues
- Hidden combo detection iterates all 3 trait slots — O(N) where N = combo table size; acceptable

### Risks
- **Risk**: Mutation produces an allele key that is not in any catalogue — breaks rarity lookup.
  - **Mitigation**: `_random_allele(catalogue_key)` only picks from `AlleleCatalogue` arrays. GdUnit4 fuzz test: run 10,000 breeds, assert all output allele keys are in valid catalogues.
- **Risk**: `BreedPreview` probabilities don't sum to 1.0 due to floating-point drift.
  - **Mitigation**: `get_breed_preview()` normalises probability dictionaries before returning. Unit test asserts sum within epsilon.

## GDD Requirements Addressed

| GDD Req ID | GDD Section | Requirement | How This ADR Addresses It |
|------------|-------------|-------------|--------------------------|
| TR-genetics-001 | §3.2 | 6-slot genome per rabbit | `Genome` resource with 6 named `GeneSlot` fields on `RabbitData` |
| TR-genetics-002 | §3.2 | Offspring inherits 1 allele per slot from each parent | `_inherit_slot()` random allele pick from parent_a and parent_b |
| TR-genetics-003 | §3.2 | Mutation roll at base 5%, modifiable by items/traits | Per-allele mutation roll using `effective_mutation_chance`; base from `balance.json` |
| TR-genetics-004 | §3.2 | Gene Preview with probability pie chart before breeding | `get_breed_preview()` pure function returning `BreedPreview` with probability dictionaries |
| TR-genetics-005 | §3.2 | Trait stacking: synergy, cancellation, hidden combos | `apply_trait_stacking()` resolves all 3 interaction types; table in `balance.json` |
| TR-genetics-006 | §3.2 | 7 color-rarity tiers with specific probability weights | `AlleleCatalogue.COLORS` + rarity weights in `balance.json genetics.rarity_weights` |

## Performance Implications
- **CPU**: `breed()` runs on user action (not per-frame). 6 slots × 4 RNG calls = 24 RNG calls per breed. <0.1ms.
- **CPU**: `get_breed_preview()` is pure math — no RNG. 6 slot probability tables. <0.5ms.
- **Memory**: `Genome` + 6 `GeneSlot` resources per rabbit × 24 rabbits = ~150 resource objects. Trivial.
- **Load Time**: No impact — genomes are deserialised by SaveSystem as part of rabbit loading.
- **Network**: No impact.

## Migration Plan
Greenfield — create in order: `allele_catalogue.gd`, `gene_slot.gd`, `genome.gd`, `breed_preview.gd`, `trait_effects.gd`, then `genetics_system.gd`. All files in `src/core/genetics/`.

## Validation Criteria
- [ ] GdUnit4 test: `breed(parent_a, parent_b)` with known seed produces deterministic child genome across 100 runs
- [ ] GdUnit4 test: `get_breed_preview()` probability dictionaries sum to 1.0 (within 0.0001 epsilon) for each slot
- [ ] GdUnit4 test: after 10,000 simulated breeds, all output allele keys are members of `AlleleCatalogue` arrays
- [ ] GdUnit4 test: `breed()` does not modify `parent_a.genome` or `parent_b.genome` (verify all fields unchanged after call)
- [ ] GdUnit4 test: trait synergy `fast_eater + efficient_eater` → `TraitEffects.growth_rate_bonus > 0`
- [ ] GdUnit4 test: trait cancellation `calm + active` → weaker trait suppressed

## Related Decisions
- ADR-0002: All allele keys are String constants in `AlleleCatalogue` — never inline string literals in game logic
- ADR-0004: Mutation chance, rarity weights, trait synergy table all in `balance.json` — not hardcoded
- ADR-0005: `RabbitData.genome: Genome` field — this ADR defines what `Genome` contains
- `docs/architecture/architecture.md` — Principle #3: "RabbitData is sacred — GeneticsSystem never mutates parents"
