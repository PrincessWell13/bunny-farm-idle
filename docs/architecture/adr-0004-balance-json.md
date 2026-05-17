# ADR-0004: JSON Balance Data — No Hardcoded Values

## Status
Accepted

## Date
2026-05-16

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — FileAccess reads and JSON parsing unchanged in 4.4–4.6 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None — `FileAccess.get_file_as_string()` and `JSON.parse_string()` are stable |
| **Verification Required** | Confirm `FileAccess.get_file_as_string("res://assets/data/balance.json")` works in exported Android/iOS builds — file must be included in export filters |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (systems load balance.json in _ready() — boot order determines when), ADR-0002 (typed GDScript — extracted values stored as typed variables) |
| **Enables** | ADR-0005 (RabbitData — rarity weights and trait probabilities from balance.json), ADR-0006 (Genetics — mutation chance and allele probabilities) |
| **Blocks** | No system may hardcode a balance value — this ADR must be Accepted before any system with numeric game data is implemented |
| **Ordering Note** | `assets/data/balance.json` must exist (even as a skeleton) before any system's _ready() runs in a playtest build |

## Context

### Problem Statement
Every GDD system contains tuning knobs: mutation rates, sell prices, production rates, offline multipliers, habitat bonuses, food effects, expedition durations, prestige bonuses, and more. If these values are hardcoded as literals in `.gd` files, every balance change requires a code edit, a test run, and a rebuild. For a solo developer iterating on feel and balance, this loop is too expensive. All numeric balance values must be externalised into a single file that can be edited without touching code.

### Constraints
- Technical preferences explicitly state: "No hardcoded balance values — all in `assets/data/balance.json`"
- The file must be readable in exported Android and iOS builds (included in export filters)
- ADR-0001 fixed autoloads at 6 — no new autoload is added for balance loading
- All values extracted from the file must be stored in typed local variables (ADR-0002)

### Requirements
- Must allow any balance value to be changed without editing a `.gd` file
- Must fail safely: if a key is missing, the system uses a documented fallback default
- Must be human-readable and version-controllable (meaningful diffs on value changes)
- Must load fast enough to not measurably affect app startup time

## Decision

**All numeric balance values are stored in `assets/data/balance.json`.** No `.gd` file in `src/` may contain a magic number representing a game balance value. The only permitted numeric literals in `src/` are: array/loop indices, boolean-like flags (0/1), and engine constants (e.g., `Color.WHITE`).

Each system loads `balance.json` independently in `_ready()` using `FileAccess.get_file_as_string()` + `JSON.parse_string()`, reads its own top-level section, and stores extracted values as typed instance variables with named defaults. The file is ~50KB max — loading it N times at boot is acceptable.

### Loading Pattern

```gdscript
# Standard pattern — every system that needs balance data uses this in _ready()
func _ready() -> void:
    _load_balance_data()

func _load_balance_data() -> void:
    var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
    if text.is_empty():
        push_error("GeneticsSystem: balance.json not found — using defaults")
        return
    var parsed: Variant = JSON.parse_string(text)
    if not parsed is Dictionary:
        push_error("GeneticsSystem: balance.json parse failed — using defaults")
        return
    var section: Dictionary = (parsed as Dictionary).get("genetics", {}) as Dictionary
    _base_mutation_chance = section.get("base_mutation_chance", 0.05)
    _rarity_weights = section.get("rarity_weights", _default_rarity_weights())
    # ... each value extracted and stored in a typed instance variable
```

Rules:
- `push_error()` logs to Godot's error console but does not crash the game
- Default values are named constants or helper functions — never inline magic numbers
- Each system reads only its own top-level section key

### balance.json Schema

```json
{
  "_version": 1,
  "_comment": "All numeric balance values. Edit here, not in code.",

  "genetics": {
    "base_mutation_chance": 0.05,
    "max_mutation_chance": 0.30,
    "rarity_weights": {
      "common": 60, "spotted": 15, "striped": 10,
      "gold": 10, "silver": 3, "galaxy": 1.5,
      "rainbow": 0.4, "legendary": 0.1
    },
    "trait_tier_weights": { "tier1": 70, "tier2": 25, "tier3": 5 }
  },

  "rabbit": {
    "hunger_decay_per_second": 0.5,
    "health_decay_per_second_when_starving": 1.0,
    "happiness_decay_per_second": 0.2,
    "cleanliness_decay_per_second": 0.1,
    "growth_baby_to_juvenile_seconds": 3600,
    "growth_juvenile_to_adult_seconds": 7200,
    "growth_adult_to_elder_seconds": 86400
  },

  "economy": {
    "rabbit_sell_price_base": 10,
    "rabbit_sell_price_per_rarity_tier": [10, 50, 200, 500, 2000, 10000, 50000, 100000],
    "merchant_spawn_interval_min_seconds": 14400,
    "merchant_spawn_interval_max_seconds": 28800
  },

  "idle_production": {
    "base_cc_per_rabbit_per_second": 0.05,
    "offline_multiplier_background": 0.75,
    "offline_multiplier_under_4h": 0.60,
    "offline_multiplier_4_to_12h": 0.50,
    "offline_multiplier_over_12h": 0.40,
    "max_offline_hours": 72
  },

  "habitat": {
    "cleanliness_disease_threshold": 20.0,
    "hutch_capacity": [4, 8, 12, 16, 24],
    "hutch_growth_bonus": [0.0, 0.05, 0.0, 0.0, 0.0],
    "hutch_mutation_bonus": [0.0, 0.0, 0.0, 0.0, 0.05]
  },

  "food": {
    "grass_hunger_restore": 30.0,
    "carrot_hunger_restore": 40.0,
    "carrot_growth_bonus": 10.0,
    "star_carrot_growth_bonus": 25.0,
    "mystic_mushroom_mutation_boost": 0.10,
    "mystic_mushroom_duration_seconds": 1800
  },

  "expedition": {
    "zones": [
      { "id": "forest", "duration_seconds": 1800, "rabbit_count": 1 },
      { "id": "eastern_meadow", "duration_seconds": 7200, "rabbit_count": 2 },
      { "id": "snow_mountain", "duration_seconds": 28800, "rabbit_count": 3 },
      { "id": "ancient_lands", "duration_seconds": 86400, "rabbit_count": 5 },
      { "id": "cosmic_realm", "duration_seconds": 172800, "rabbit_count": 5, "requires_prestige": 1 }
    ]
  },

  "prestige": {
    "bonuses_per_level": {
      "1": { "growth_rate_bonus": 0.15 },
      "2": { "mutation_chance_bonus": 0.08 },
      "3": { "offline_production_bonus": 0.15 },
      "4": { "expedition_slot_bonus": 1 },
      "5": { "unlocks": "cosmic_hutch" },
      "10": { "legendary_chance_bonus": 0.005 },
      "20": { "unlocks": "cosmic_rabbit" }
    }
  },

  "season": {
    "days_per_season": 7,
    "spring": { "fertility_bonus": 0.30 },
    "summer": { "growth_rate_bonus": 0.20 },
    "autumn": { "harvest_bonus": 0.50 },
    "winter": { "offline_production_bonus": 0.30 }
  }
}
```

### What Counts as a "Balance Value"

| Type | In balance.json? | Example |
|------|-----------------|---------|
| Game tuning numbers | ✅ Yes | mutation rate, sell price, hunger decay |
| Gameplay durations | ✅ Yes | expedition time, growth time |
| Probability weights | ✅ Yes | rarity table, trait tier odds |
| Unlock thresholds | ✅ Yes | prestige requirements |
| Array/loop indices | ❌ No | `rabbits[0]`, `slot_id == 2` |
| Engine constants | ❌ No | `Color.WHITE`, `Vector2.ZERO` |
| UI pixel sizes | ❌ No | min touch target = 44px (UX constraint, not balance) |

### Data Flow

```
assets/data/balance.json  (read-only at runtime)
        │
        ├─── GeneticsSystem._ready()      → _base_mutation_chance: float
        ├─── RabbitSystem._ready()        → _hunger_decay: float
        ├─── IdleProductionSystem._ready()→ _base_cc_rate: float
        ├─── HabitatSystem._ready()       → _hutch_capacities: Array[int]
        ├─── FoodSystem._ready()          → _food_effects: Dictionary
        ├─── ExpeditionSystem._ready()    → _zone_configs: Array
        ├─── SeasonSystem._ready()        → _season_multipliers: Dictionary
        └─── PrestigeSystem._ready()      → _prestige_bonuses: Dictionary

No system writes to balance.json at runtime.
```

## Alternatives Considered

### Alternative B: Godot .tres Resource files per system
- **Description**: Each system has a `BalanceResource.tres` edited in the Godot Inspector.
- **Pros**: Type-safe loading via `preload()`; Inspector UI for editing.
- **Cons**: `.tres` files are not human-readable diffs. Hard to hand to a non-technical designer. Version control diffs are noisy.
- **Rejection Reason**: JSON is universally readable. A designer can open `balance.json` in any text editor without opening Godot. That is the goal.

### Alternative C: GDScript constants in BalanceConstants.gd
- **Description**: A single autoloaded file defines all balance values as typed GDScript constants.
- **Pros**: Full static typing; IDE autocomplete on all values; no JSON parsing.
- **Cons**: Changing a value still requires editing a `.gd` file and re-running tests. Defeats the purpose of externalisation.
- **Rejection Reason**: This is still hardcoding — the value is in code, just centralised. The goal is to enable balance changes without touching code.

## Consequences

### Positive
- Balance values can be changed without editing any `.gd` file
- JSON diffs are clean and readable in code review — value changes are obvious
- Unit tests can inject a mock balance dictionary, skipping file I/O entirely
- A future live-tuning or A/B testing system can swap the file contents at runtime

### Negative
- Loading `balance.json` N times at boot (once per system) — acceptable for 50KB, worth noting if file grows
- Dictionary key access is not type-safe at runtime — typo in a key name silently returns the fallback default
- Adding a new balance value requires both updating the JSON file and the loader in the relevant system

### Risks
- **Risk**: `balance.json` missing from export package — all systems use defaults, game ships miscalibrated.
  - **Mitigation**: Add `assets/data/*.json` to Export → Resources → Filters. Boot-time check in GameState logs an error if file is missing.
- **Risk**: JSON key typo causes silent fallback to default value.
  - **Mitigation**: All fallback defaults documented in this ADR's schema. CI validation script cross-checks expected keys against the file on every commit.

## GDD Requirements Addressed

| GDD Requirement ID | Requirement | How This ADR Addresses It |
|--------------------|-------------|--------------------------|
| TR-genetics-003 | Mutation roll at base 5%, modifiable by items/traits | `genetics.base_mutation_chance` in balance.json — tunable without code change |
| TR-genetics-006 | 7 color-rarity tiers with specific probability weights | `genetics.rarity_weights` dictionary — all probabilities in one auditable place |
| TR-idle-003 | Tiered offline multipliers by absence duration | `idle_production.offline_multiplier_*` keys — all 4 tiers in balance.json |
| TR-habitat-001 | Hutch capacity 4–24 by level | `habitat.hutch_capacity` array indexed by level |
| TR-season-002 | Season modifies global fertility, growth, production | `season.*_bonus` keys per season — all multipliers tunable |
| TR-prestige-003 | Up to 20 prestige levels with stacking bonuses | `prestige.bonuses_per_level` dictionary — all rewards in one place |

## Performance Implications
- **CPU**: `FileAccess.get_file_as_string()` + `JSON.parse_string()` ≈ 0.5–2ms per call for a 50KB file. ~10 systems × 2ms = ~20ms total at boot. Acceptable.
- **Memory**: Parsed values stored as typed instance variables — no long-lived Dictionary references after `_ready()`. Minimal ongoing memory use.
- **Load Time**: ~20ms added to cold boot. Acceptable for a mobile game with target boot time under 5 seconds.
- **Network**: No impact — file is local.

## Migration Plan
Greenfield — create `assets/data/balance.json` with the schema above as the first asset in the project, before any system is implemented.

## Validation Criteria
- [ ] CI lint check: no multi-digit numeric literals outside indices/flags in `src/` (grep for pattern)
- [ ] Deleting `balance.json` causes `push_error` in all systems; no crash; game runs with defaults
- [ ] Changing `genetics.base_mutation_chance` from `0.05` to `0.10` changes observed mutation rate in GdUnit4 test without any `.gd` change
- [ ] Android/iOS export includes `assets/data/balance.json` (verified in export log)

## Related Decisions
- ADR-0001: Systems load balance.json in `_ready()` — after autoloads are initialised
- ADR-0002: All extracted balance values stored as statically typed instance variables
- ADR-0006 (pending): Genetics allele model references `genetics.*` keys from this schema
- `docs/architecture/architecture.md` — Principle #3: "RabbitData is sacred — all balance values from balance.json"
