# ADR-0010: HabitatSystem Hutch Ownership and Rabbit Assignment Model

## Status
Accepted

## Date
2026-05-18

## Last Verified
2026-05-18

## Decision Makers
GDScript Specialist, Godot Specialist

## Summary
Multiple gameplay systems need to query hutch capacity, cleanliness bonuses, and rabbit slot state, but there was no defined owner for hutch data or an authoritative write path for rabbit assignment. This ADR establishes `HutchData` as a typed `Resource` owned exclusively by `HabitatSystem`, with a validated `assign_rabbit()` / `remove_rabbit()` API that is the sole mutation path for hutch occupancy.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — `Resource`, `class_name`, `Array[String]`, and `Dictionary` return types are stable since Godot 4.0; no post-cutoff APIs used |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm `Array[String]` on a `Resource` subclass round-trips cleanly through `SaveSystem`'s manual serialisation path (same pattern as `RabbitData` — ADR-0005) |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameState owns `hutches: Array[HutchData]`; HabitatSystem boots after RabbitSystem), ADR-0003 (EventBus — `rabbit_assigned_to_hutch` signal routed through EventBus), ADR-0004 (capacity table and cleanliness decay rate from `balance.json`), ADR-0005 (HabitatSystem reads `RabbitData` but never writes to it) |
| **Enables** | IdleProductionSystem integration — `get_hutch_bonuses()` is the data contract IdleProductionSystem consumes per tick |
| **Blocks** | Any story implementing hutch slot allocation, cleanliness mechanics, or production multipliers until Accepted |
| **Ordering Note** | HabitatSystem must be registered in the Autoload order after RabbitSystem so that `assign_rabbit()` can validate rabbit existence via RabbitSystem at boot |

## Context

### Problem Statement
The idle production loop requires per-hutch cleanliness bonuses, and the breeding and placement flows require validated slot assignment. Without a defined data model and single-owner write path for hutch state, any system could modify occupancy or cleanliness independently, making capacity enforcement unreliable and offline time calculations non-deterministic. A clear ownership model must be established before any hutch-affecting story can be implemented.

### Current State
Prototype: hutch data was tracked as plain `Dictionary` values with no validated write path. Capacity was checked ad-hoc at call sites. Cleanliness was not yet implemented. This approach was sufficient for the prototype but cannot support the production save/load, offline accumulation, and multi-system query requirements.

### Constraints

- `GameState.hutches: Array[HutchData]` is the canonical store (ADR-0001) — the array type is fixed
- All fields must be statically typed (ADR-0002)
- Capacity values and cleanliness decay rates must come from `balance.json` (ADR-0004)
- Max 24 visible rabbits at once across all hutches (platform constraint — `technical-preferences.md`)
- `HutchData` must be JSON-serialisable by `SaveSystem` using the same manual field-iteration pattern as `RabbitData` (ADR-0005)
- `HabitatSystem` must never write to `RabbitData` fields — it may only read them (ADR-0005)

### Requirements

- Represent hutch identity, level, occupant list, and cleanliness as typed fields
- Enforce capacity by hutch level (4–24 slots; TR-habitat-001)
- Provide a single validated write path for rabbit-to-hutch assignment and removal (TR-habitat-002)
- Supply a cleanliness-derived production multiplier to `IdleProductionSystem` on demand
- Decay cleanliness per `TimeManager.tick` at a rate configurable in `balance.json`
- Each hutch must be independently queryable without scanning other hutches

## Decision

`HutchData` is `class_name HutchData extends Resource` with typed fields. `HabitatSystem` is the exclusive writer to all `HutchData` instances. Assignment is validated at the API boundary. Bonuses are returned as plain `Dictionary` values derived at query time from the current cleanliness level.

### HutchData Schema

```gdscript
class_name HutchData extends Resource

var hutch_id: String = ""
var level: int = 1                    # 1–N; capacity is looked up from balance.json by level
var occupants: Array[String] = []     # rabbit_id strings; max size = get_capacity(hutch_id)
var cleanliness: float = 1.0          # 0.0–1.0; decays per TimeManager.tick
```

### Architecture

```
GameState
  └── hutches: Array[HutchData]
                    │
                    │  exclusive write access
                    ▼
             HabitatSystem
              ├── assign_rabbit(rabbit_id, hutch_id) → bool
              ├── remove_rabbit(rabbit_id) → bool
              ├── get_hutch_bonuses(hutch_id) → Dictionary
              ├── get_capacity(hutch_id) → int
              └── _on_tick(delta) [cleanliness decay]
                    │
                    │  read-only
                    ├──────────────────────► RabbitSystem
                    │                         (rabbit existence check in assign_rabbit)
                    │
                    │  signals via EventBus
                    └──────────────────────► EventBus.rabbit_assigned_to_hutch(rabbit_id, hutch_id)
                                             EventBus.hutch_cleanliness_changed(hutch_id, cleanliness)

IdleProductionSystem
  └── calls get_hutch_bonuses(hutch_id) per tick
        └── returns { "production_mult": float, "fertility_mult": float }
```

### Key Interfaces

```gdscript
# src/core/habitat_system.gd
class_name HabitatSystem extends Node

# Places a rabbit into a hutch slot.
# Validates: (a) rabbit exists in RabbitSystem, (b) occupants.size() < get_capacity(),
# (c) rabbit not already assigned to any hutch.
# On success: appends rabbit_id to hutch.occupants, emits EventBus.rabbit_assigned_to_hutch.
# Returns false and emits no signal if any validation fails.
func assign_rabbit(rabbit_id: String, hutch_id: String) -> bool

# Removes a rabbit from whichever hutch it currently occupies.
# Scans GameState.hutches for the occupying hutch (O(hutches × occupants) — acceptable
# given max 24 total occupants and infrequent calls).
# On success: removes rabbit_id from hutch.occupants, emits EventBus.rabbit_assigned_to_hutch
# with hutch_id = "" to signal the rabbit is now unassigned.
# Returns false if rabbit_id is not currently assigned to any hutch.
func remove_rabbit(rabbit_id: String) -> bool

# Returns the cleanliness-derived bonus multipliers for a hutch.
# Thresholds loaded from balance.json at _ready().
# Returns { "production_mult": float, "fertility_mult": float }.
# Returns { "production_mult": 1.0, "fertility_mult": 1.0 } if hutch_id not found.
func get_hutch_bonuses(hutch_id: String) -> Dictionary

# Returns the maximum occupant count for a hutch, looked up by hutch.level
# against the capacity table in balance.json (range: 4–24).
func get_capacity(hutch_id: String) -> int
```

### Cleanliness Decay

```gdscript
# Called by TimeManager.tick signal each second.
func _on_tick(delta: float) -> void:
    for hutch: HutchData in GameState.hutches:
        if hutch.occupants.is_empty():
            continue
        hutch.cleanliness -= _decay_rate * delta
        hutch.cleanliness = clampf(hutch.cleanliness, 0.0, 1.0)
        EventBus.hutch_cleanliness_changed.emit(hutch.hutch_id, hutch.cleanliness)
    GameState.mark_dirty()
```

`_decay_rate` is loaded from `balance.json` key `habitat.cleanliness_decay_per_second` in `_ready()`. Empty hutches do not decay.

### Bonus Derivation

```gdscript
# balance.json defines cleanliness_thresholds as an ordered array of breakpoints:
# [{ "min": 0.75, "production_mult": 1.2, "fertility_mult": 1.1 },
#  { "min": 0.40, "production_mult": 1.0, "fertility_mult": 1.0 },
#  { "min": 0.0,  "production_mult": 0.8, "fertility_mult": 0.9 }]
# get_hutch_bonuses() iterates from highest to lowest and returns the first matching tier.
```

### Implementation Guidelines

- Load `_capacity_table: Array` and `_cleanliness_thresholds: Array` from `balance.json` in `_ready()`. Never hardcode numeric values.
- Connect to `TimeManager.tick` in `_ready()`:
  ```gdscript
  TimeManager.tick.connect(_on_tick)
  ```
- `assign_rabbit()` must call `RabbitSystem.get_rabbit(rabbit_id)` to confirm existence before appending. Do not cache the `RabbitData` reference — read it once for validation and discard.
- `assign_rabbit()` scans `GameState.hutches` to confirm the rabbit is not already assigned elsewhere before proceeding. A rabbit may occupy at most one hutch at a time.
- `get_hutch_bonuses()` derives its result entirely from the current `hutch.cleanliness` value and the loaded threshold table. It does not cache the result — call sites may cache if needed.
- `HabitatSystem` must never assign to any field on `RabbitData`. It reads `rabbit_id` only for validation lookups.
- `HutchData` fields are not `@export`-ed. Serialisation is handled by `SaveSystem` via explicit field iteration (same pattern as `ADR-0005`).

## Alternatives Considered

### Alternative 1: Flat Array[RabbitData] with hutch_id field on each rabbit

- **Description**: Keep hutch membership entirely on `RabbitData.hutch_id` (which already exists per ADR-0005). `HabitatSystem` queries rabbit state by iterating `GameState.rabbits` and filtering by `hutch_id`.
- **Pros**: No separate `HutchData` resource needed; hutch membership is readable in one place on the rabbit.
- **Cons**: Every hutch capacity check requires a full rabbit array scan. `HabitatSystem` would need write access to `RabbitData.hutch_id`, violating the ADR-0005 exclusive-write contract on `RabbitSystem`. Hutch-level state (cleanliness, level) has no natural home and would end up on `GameState` as a parallel `Dictionary`.
- **Estimated Effort**: Similar initial effort; significantly higher maintenance burden as hutch complexity grows.
- **Rejection Reason**: Violates the RabbitSystem write monopoly on `RabbitData` (ADR-0005) and degrades hutch query performance relative to a direct `HutchData` lookup.

### Alternative 2: Node-based hutch scene tracking occupants

- **Description**: Each hutch is a scene node owning its own `occupants` array as a node property. `HabitatSystem` finds hutch nodes via group membership or a node path.
- **Pros**: Hutch signals can be declared directly on the node; decoupled from `GameState`.
- **Cons**: Hutches are data, not interactive actors — there is no gameplay reason for them to exist as scene-tree nodes. Serialising live node trees is significantly more complex than serialising `Resource` instances. Node group lookups (`get_nodes_in_group()`) are slower than direct `Array[HutchData]` indexing at save/load time.
- **Estimated Effort**: Higher — requires scene authoring, group registration, and a custom serialisation path.
- **Rejection Reason**: Idle game hutches are pure data containers. Aligning with the `Resource` pattern (ADR-0005) keeps the architecture consistent and the serialisation path simple.

## Consequences

### Positive
- Capacity enforcement is guaranteed at a single API boundary — no call site can silently overfill a hutch
- `get_hutch_bonuses()` gives `IdleProductionSystem` a clean, typed contract without coupling it to `HutchData` internals
- `HutchData` can be instantiated in GdUnit4 tests without any scene, autoload, or file I/O — same testability profile as `RabbitData`
- Each hutch is independently queryable in O(1) given a `hutch_id` — no cross-hutch scanning required for capacity or bonus lookups

### Negative
- `assign_rabbit()` performs an O(hutches × occupants) scan to detect duplicate assignments. At max scale (e.g. 6 hutches × 24 occupants) this is 144 comparisons — acceptable for an infrequent operation, but not suitable for hot-path use
- `SaveSystem` must maintain a manual `_hutch_to_dict()` function; adding a new field to `HutchData` requires updating it (same maintenance burden as `RabbitData`)
- `RabbitData.hutch_id` (ADR-0005) and `HutchData.occupants` are now dual sources of hutch membership truth. `HabitatSystem` is responsible for keeping them in sync on every `assign_rabbit()` / `remove_rabbit()` call

### Neutral
- Cleanliness decay fires on every `TimeManager.tick` for all occupied hutches. At max scale this is 6 hutch updates per second — negligible CPU cost but a design commitment to tick-driven decay rather than delta-accumulation on next query

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| `RabbitData.hutch_id` and `HutchData.occupants` diverge (dual-source desync) | Medium | High — rabbits appear unassigned or double-assigned | `assign_rabbit()` and `remove_rabbit()` update both atomically; GdUnit4 consistency test after every assignment operation |
| Contributor writes to `hutch.cleanliness` or `hutch.occupants` outside `HabitatSystem` | Low | Medium — cleanliness decay becomes non-deterministic | Register direct `HutchData` field mutation outside `habitat_system.gd` as a forbidden pattern; enforce at code review |
| `balance.json` missing `habitat.cleanliness_decay_per_second` at boot | Low | High — null decay rate causes a runtime error | `_ready()` asserts the key exists and falls back to a safe default with a logged warning |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|----------------|--------|
| CPU (assign_rabbit scan) | N/A | < 0.1ms (max 144 string comparisons) | < 1ms |
| CPU (tick decay, 6 hutches) | N/A | < 0.01ms per tick | < 1ms per tick |
| Memory (6 HutchData instances) | N/A | < 5KB | 256MB ceiling |
| Load Time (SaveSystem deserialise) | N/A | < 0.5ms | No impact |

## Migration Plan
Greenfield — create `src/core/hutch_data.gd` and `src/core/habitat_system.gd` as new files. No existing production code references `HutchData`.

1. Create `src/core/hutch_data.gd` with the schema above
2. Create `src/core/habitat_system.gd`; register it as an Autoload after `RabbitSystem` in Project Settings
3. Add `habitat.cleanliness_decay_per_second` and `habitat.cleanliness_thresholds` and `habitat.capacity_by_level` to `assets/data/balance.json`
4. Update `SaveSystem` with `_hutch_to_dict()` and `_dict_to_hutch()` methods
5. Wire `TimeManager.tick` → `HabitatSystem._on_tick` in `_ready()`

**Rollback plan**: Remove `HabitatSystem` from the Autoload list and delete `hutch_data.gd` and `habitat_system.gd`. No other system depends on this ADR at the time it is first accepted.

## Validation Criteria

- [ ] `HutchData` can be instantiated in a GdUnit4 test with no scene or autoload dependencies
- [ ] `assign_rabbit()` returns `false` when the hutch is at capacity; returns `true` and appends to `occupants` when a valid slot exists
- [ ] `assign_rabbit()` returns `false` if the rabbit is already assigned to any hutch
- [ ] `remove_rabbit()` clears the rabbit from `occupants` and emits `rabbit_assigned_to_hutch` with `hutch_id = ""`
- [ ] `get_hutch_bonuses()` returns `production_mult < 1.0` when `cleanliness < 0.40` (penalty tier)
- [ ] `get_hutch_bonuses()` returns `production_mult > 1.0` when `cleanliness >= 0.75` (bonus tier)
- [ ] Cleanliness decay does not run on empty hutches (confirmed by unit test with zero occupants)
- [ ] Round-trip test: `_hutch_to_dict()` → `_dict_to_hutch()` → all fields match original
- [ ] `get_capacity()` returns 4 for a level-1 hutch and 24 for the max-level hutch (values from `balance.json`)

## GDD Requirements Addressed

| GDD Req ID | GDD Section | Requirement | How This ADR Addresses It |
|------------|-------------|-------------|--------------------------|
| TR-habitat-001 | §4.1 | Hutch capacity 4–24 slots by level | `get_capacity()` looks up `hutch.level` in the `balance.json` capacity table; schema defined here, data sourced from ADR-0004 |
| TR-habitat-002 | §4.1 | Hutch slot allocation and rabbit placement | `assign_rabbit()` / `remove_rabbit()` API with three-condition validation gate; exclusive write ownership enforced by convention and code review |

## Related

- ADR-0001: `GameState.hutches: Array[HutchData]` — GameState owns the array, HabitatSystem mutates elements
- ADR-0003: EventBus — `rabbit_assigned_to_hutch` and `hutch_cleanliness_changed` signals routed through EventBus
- ADR-0004: All capacity values and cleanliness rates loaded from `balance.json`; never hardcoded
- ADR-0005: `RabbitData.hutch_id` field; HabitatSystem reads but never writes `RabbitData`
- `src/core/hutch_data.gd` (to be created)
- `src/core/habitat_system.gd` (to be created)
