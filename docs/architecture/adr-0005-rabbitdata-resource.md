# ADR-0005: RabbitData as Godot Resource — Immutable from Outside RabbitSystem

## Status
Accepted

## Date
2026-05-16

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — `Resource` class and `class_name` unchanged in 4.4–4.6 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None — `Resource`, typed `Array[Resource]` are stable |
| **Verification Required** | Confirm `Array[RabbitData]` serialises cleanly via `JSON.stringify()` in SaveSystem — Resource properties are not auto-serialised by Godot's JSON class; SaveSystem must iterate typed properties explicitly |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameState owns `rabbits: Array[RabbitData]`), ADR-0002 (GDScript static typing — all fields typed), ADR-0004 (growth timings and decay rates from balance.json) |
| **Enables** | ADR-0006 (Genetics — `breed()` returns a new `RabbitData`; this ADR defines the data contract it must satisfy) |
| **Blocks** | Any story implementing rabbit lifecycle, stat decay, breeding, or idle production until Accepted |
| **Ordering Note** | Must be Accepted before ADR-0006 (Genetics) — the genome schema is a nested field on `RabbitData` |

## Context

### Problem Statement
Every system — RabbitSystem, GeneticsSystem, IdleProductionSystem, HabitatSystem, FoodSystem, and the entire Presentation layer — needs to read rabbit data. If any of those systems can write to `RabbitData` properties directly, rabbit state can be mutated from anywhere, making the lifecycle state machine unreliable and serialisation unpredictable. We need to define the canonical data structure for a rabbit and establish who is allowed to mutate it.

### Constraints
- GameState owns `rabbits: Array[RabbitData]` (ADR-0001) — the type is already fixed
- All fields must be statically typed (ADR-0002)
- All decay rates, growth timings, and thresholds must come from `balance.json` (ADR-0004)
- Max 24 active rabbits at once (performance budget from technical-preferences.md)
- `RabbitData` must be JSON-serialisable for SaveSystem

### Requirements
- Must represent all 4 visible stats (hunger, happiness, health, cleanliness) and all hidden stats
- Must encode the 5-stage lifecycle (Baby → Juvenile → Adult → Elder → Sanctuary)
- Must store the 6-slot genome reference (for Genetics system — schema defined in ADR-0006)
- Must be constructable in GdUnit4 tests without any scene or autoload
- Must be passable by reference to GeneticsSystem without GeneticsSystem being able to mutate it (convention-enforced)

## Decision

**`RabbitData` is `class_name RabbitData extends Resource`.** All properties are declared as typed `var`s. They are **not `@export`-ed** — no Inspector exposure. Only `RabbitSystem` methods may write to a `RabbitData` instance. All other systems receive the reference and may read fields freely but must never assign to them.

### RabbitData Schema

```gdscript
class_name RabbitData extends Resource

enum RabbitStage { BABY, JUVENILE, ADULT, ELDER, SANCTUARY }

var rabbit_id: String = ""
var display_name: String = ""
var stage: RabbitStage = RabbitStage.BABY
var genome: Genome = null           # 6 GeneSlot resources — schema in ADR-0006
var hunger: float = 100.0           # 0–100; decays over real time
var happiness: float = 100.0        # 0–100
var health: float = 100.0           # 0–100; reaches 0 → rabbit_died signal
var cleanliness: float = 100.0      # 0–100 (drives happiness decay + disease chance)
var growth_progress: float = 0.0    # 0–100; crossing threshold → stage advance
var fertility: float = 1.0          # multiplier; modified by traits + food
var mutation_chance: float = 0.05   # base from balance.json; boosted by items/traits
var aura_type: String = ""          # empty = no aura; non-empty = AuraSystem lookup key
var birth_timestamp: int = 0        # Unix seconds
var parent_a_id: String = ""        # empty = no parent (founder rabbit)
var parent_b_id: String = ""
var hutch_id: String = ""           # empty = unassigned
```

### RabbitSystem Mutation Contract

Only `RabbitSystem` calls these mutation patterns. No other file in `src/` may assign
to a `RabbitData` field directly:

```gdscript
# src/core/rabbit_system.gd — the ONLY place RabbitData fields are written
func _tick_rabbit(rabbit: RabbitData, delta: float) -> void:
    rabbit.hunger -= _hunger_decay_rate * delta
    rabbit.cleanliness -= _cleanliness_decay_rate * delta
    if rabbit.hunger <= 0.0:
        rabbit.health -= _health_decay_when_starving * delta
    rabbit.growth_progress += _growth_rate_for_stage(rabbit) * delta
    _check_stage_advance(rabbit)
    _check_death(rabbit)
    GameState.mark_dirty()

func _check_stage_advance(rabbit: RabbitData) -> void:
    # Stage thresholds loaded from balance.json in _ready()
    # Emits EventBus.rabbit_matured when stage changes
    pass
```

Callers outside `RabbitSystem` use these read-only methods:

```gdscript
func get_rabbit(rabbit_id: String) -> RabbitData        # null if not found
func get_all_rabbits() -> Array[RabbitData]
func get_rabbits_in_hutch(hutch_id: String) -> Array[RabbitData]
func add_rabbit(data: RabbitData) -> String              # returns assigned rabbit_id
func remove_rabbit(rabbit_id: String) -> void
func feed_rabbit(rabbit_id: String, food: FoodItem) -> bool
func get_aura_bonus(hutch_id: String) -> AuraBonus
```

### Lifecycle State Machine

```
BABY ──────────────────────────► JUVENILE
  growth_progress crosses 100      (traits begin expressing)
       │
       ▼
JUVENILE ──────────────────────► ADULT
  second growth threshold           (can breed, sell, expedition)
       │
       ▼
ADULT ─────────────────────────► ELDER
  birth_timestamp + lifespan_s      (fertility −50%, aura ×2)
       │
       ▼
ELDER ─────────────────────────► SANCTUARY
  elder_threshold elapsed           (passive farm buff, no longer in main hutch)
```

If `health` reaches 0 at any stage: `RabbitSystem` calls `remove_rabbit()` and emits `EventBus.rabbit_died(rabbit_id)`.

Decay rates and stage transition thresholds all loaded from `balance.json` (ADR-0004).

### Serialisation Contract

`SaveSystem` serialises `RabbitData` by iterating its known typed fields — not via `inst_to_dict()` or `ResourceSaver`. This is required because `Resource` does not automatically include non-exported properties in JSON serialisation.

```gdscript
# SaveSystem serialises rabbits as:
func _rabbit_to_dict(rabbit: RabbitData) -> Dictionary:
    return {
        "rabbit_id": rabbit.rabbit_id,
        "display_name": rabbit.display_name,
        "stage": rabbit.stage,
        "genome": _genome_to_dict(rabbit.genome),
        "hunger": rabbit.hunger,
        "happiness": rabbit.happiness,
        "health": rabbit.health,
        "cleanliness": rabbit.cleanliness,
        "growth_progress": rabbit.growth_progress,
        "fertility": rabbit.fertility,
        "mutation_chance": rabbit.mutation_chance,
        "aura_type": rabbit.aura_type,
        "birth_timestamp": rabbit.birth_timestamp,
        "parent_a_id": rabbit.parent_a_id,
        "parent_b_id": rabbit.parent_b_id,
        "hutch_id": rabbit.hutch_id,
    }
```

## Alternatives Considered

### Alternative B: Node-based RabbitEntity
- **Description**: Each rabbit is a `Node2D` child of the scene tree, owning its own data as node properties.
- **Pros**: Signals can be declared on the node; lifecycle changes fire directly.
- **Cons**: Nodes have scene-tree overhead; idle game rabbits are pure data 99% of the time. Serialising a live scene tree is far harder than serialising a `Resource`. Max 24 rabbits per scene means nodes are cheap, but the added complexity is not justified.
- **Rejection Reason**: Idle game rabbits are data objects, not interactive actors. The `Resource` type is purpose-built for data containers in Godot.

### Alternative C: Dictionary-based rabbit data
- **Description**: `GameState.rabbits` stores `Array[Dictionary]` with string keys.
- **Pros**: Trivially JSON-serialisable; flexible schema.
- **Cons**: No type safety, no IDE autocomplete, silent key typos at runtime. `GeneticsSystem.breed(parent_a: Dictionary, parent_b: Dictionary)` signatures are unverifiable by the compiler. Any system can write any key at any time.
- **Rejection Reason**: Untyped dictionaries are explicitly banned in `src/` (ADR-0002). Type safety is non-negotiable for the core data model.

## Consequences

### Positive
- `breed(parent_a: RabbitData, parent_b: RabbitData) → RabbitData` is fully type-safe and compiler-checked
- `SaveSystem` iterates known fields — no surprises from runtime-only or Inspector-only properties
- GdUnit4 tests can construct `RabbitData` directly without any scene, autoload, or file I/O
- All consumers of rabbit data get a clear, documented read contract

### Negative
- Godot's `Resource` does not enforce read-only fields — the immutability contract is enforced by convention and code review, not by the language
- `Array[RabbitData]` passed by reference — callers must not cache stale references after a rabbit is removed
- SaveSystem must maintain the manual `_rabbit_to_dict()` function; adding a new field to `RabbitData` requires updating it

### Risks
- **Risk**: A contributor writes `rabbit.hunger = 50` directly in a system other than RabbitSystem.
  - **Mitigation**: Register `direct_rabbitdata_mutation` as a forbidden pattern. Code review gate: PRs touching `src/` grep for `\.hunger\s*=`, `\.health\s*=`, etc. outside `rabbit_system.gd`.
- **Risk**: `SaveSystem._rabbit_to_dict()` falls out of sync with the `RabbitData` schema (missing new fields after a schema update).
  - **Mitigation**: GdUnit4 round-trip test: serialise a fully-populated `RabbitData`, deserialise it, assert every field matches original.

## GDD Requirements Addressed

| GDD Req ID | GDD Section | Requirement | How This ADR Addresses It |
|------------|-------------|-------------|--------------------------|
| TR-rabbit-001 | §3.1 | 4 visible stats (Hunger, Happiness, Health, Cleanliness) with real-time decay | Typed float fields on `RabbitData`; decay driven by `RabbitSystem._tick_rabbit()` |
| TR-rabbit-002 | §3.1 | Hidden stats (Growth Rate, Fertility, Mutation Chance, Lifespan, Aura) | `growth_progress`, `fertility`, `mutation_chance`, `aura_type`, lifespan tracked via `birth_timestamp` + balance.json value |
| TR-rabbit-003 | §3.1 | 5-stage lifecycle (Baby → Juvenile → Adult → Elder → Sanctuary) | `RabbitStage` enum; transitions owned by `RabbitSystem._check_stage_advance()` |
| TR-rabbit-004 | §3.1 | Aura buff system — special rabbits buff neighbours | `aura_type: String` field on `RabbitData`; AuraSystem reads and resolves the effect |
| TR-rabbit-005 | §3.2 | Parentage tracking for Gene Journal / genealogy tree | `parent_a_id`, `parent_b_id` stored on every rabbit; enables `GenePuzzleSystem.get_genealogy()` |
| TR-genetics-001 | §3.2 | 6-slot genome (color, size, ears, trait1, trait2, special) on every rabbit | `genome: Genome` typed field — schema defined in ADR-0006 |

## Performance Implications
- **CPU**: `Resource` allocation is trivial. 24 rabbits × ~20 fields each = negligible. `_tick_rabbit()` runs once per second (not per frame) — no performance concern.
- **Memory**: 24 `RabbitData` resources at max population ≈ <50KB including genome data. Well within 256MB mobile budget.
- **Load Time**: `SaveSystem` deserialises 24 dictionaries → 24 `RabbitData` objects at boot. <1ms. No impact.
- **Network**: No impact — `RabbitData` is local-only; Firebase sync is handled by SaveSystem.

## Migration Plan
Greenfield — create `src/core/rabbit_data.gd` with the schema above as one of the first source files, before `rabbit_system.gd` or `genetics_system.gd`.

## Validation Criteria
- [ ] `RabbitData` can be instantiated in a GdUnit4 test with no scene or autoload dependencies
- [ ] Round-trip test: `_rabbit_to_dict()` → `_dict_to_rabbit()` → all fields match original
- [ ] Grep confirms no `.hunger =`, `.health =`, `.happiness =`, `.cleanliness =` assignments outside `rabbit_system.gd`
- [ ] Stage transition test: `RabbitSystem` advances `BABY → JUVENILE` when `growth_progress` crosses threshold
- [ ] Death test: `RabbitSystem` emits `rabbit_died` and removes rabbit when `health` reaches 0

## Related Decisions
- ADR-0001: `GameState.rabbits: Array[RabbitData]` — GameState owns the array, RabbitSystem mutates elements
- ADR-0002: All fields statically typed; no Dictionary-based rabbit data permitted
- ADR-0004: All decay rates and stage thresholds loaded from `balance.json` (never hardcoded)
- ADR-0006 (pending): Genetics — defines the `Genome` and `GeneSlot` resource schemas nested under `RabbitData.genome`
