# Control Manifest — Bunny Farm Idle

**Manifest Version**: 2026-05-18
**Engine**: Godot 4.6 / GDScript
**Generated from**: ADR-0001 through ADR-0008 (all Accepted or Proposed)
**Purpose**: Authoritative rule set for all story implementation. Stories embed this version date. If a story's manifest version is older than this file's header date, run `/story-readiness` before implementing.

---

## How to Use This Document

1. Find your story's **system** in the table of contents below.
2. Read its **Required Patterns** — these are mandatory. Every implementation must follow them.
3. Read its **Forbidden Patterns** — these cause an automatic code review rejection.
4. Check **Performance Guardrails** — violations block the production gate.
5. Read **Interface Contracts** — these are the API boundaries other systems depend on.

If your story touches multiple systems, read each relevant section.

---

## Table of Contents

- [Foundation Layer Rules](#foundation-layer-rules)
  - [F-01: Autoload Boot Sequence (ADR-0001)](#f-01-autoload-boot-sequence)
  - [F-02: Language Standards (ADR-0002)](#f-02-language-standards)
  - [F-03: EventBus Signal Architecture (ADR-0003)](#f-03-eventbus-signal-architecture)
  - [F-04: Balance Data Loading (ADR-0004)](#f-04-balance-data-loading)
  - [F-05: Save System Local-First (ADR-0008)](#f-05-save-system-local-first)
- [Core Layer Rules](#core-layer-rules)
  - [C-01: RabbitData Ownership (ADR-0005)](#c-01-rabbitdata-ownership)
  - [C-02: Genetics Breeding Purity (ADR-0006)](#c-02-genetics-breeding-purity)
  - [C-03: Idle Production Statelessness (ADR-0007)](#c-03-idle-production-statelessness)
- [Cross-Layer Rules](#cross-layer-rules)
- [Performance Guardrails](#performance-guardrails)
- [Signal Registry](#signal-registry)

---

## Foundation Layer Rules

### F-01: Autoload Boot Sequence

**Source ADR**: ADR-0001 (`adr-0001-autoload-boot-sequence.md`) — Status: Accepted

#### Required Patterns

- Autoloads must boot in this exact order: `EventBus → TimeManager → EconomyManager → GameState → SaveSystem → SceneManager`
- Each autoload's `_ready()` must complete before the next autoload is allowed to call methods on it
- `SaveSystem._ready()` must call `GameState.load_from_save()` to restore persisted state on boot
- `SceneManager._ready()` is the final boot step; it signals that the game is ready for gameplay
- Only `RabbitSystem` may write to `RabbitData` fields (enforced at all layers)
- New autoloads require an ADR update — create an ADR before adding any new autoload

#### Forbidden Patterns

- Adding new autoloads to `project.godot` without a corresponding ADR update
- Calling methods on a later-booting autoload from an earlier-booting one during `_ready()`
  - Example: `EventBus._ready()` must NOT call `GameState` methods
- Calling `SceneManager.change_scene()` before `SaveSystem._ready()` completes
- Direct mutation of `GameState` fields from any script other than `GameState` itself and `SaveSystem`
- Out-of-order boot — do not reorder autoloads in `project.godot`

#### Interface Contracts

```
EventBus:        No dependencies — first to boot
TimeManager:     Depends on EventBus (subscribes to signals only)
EconomyManager:  Depends on EventBus, TimeManager
GameState:       Depends on EventBus, EconomyManager (reads economy config)
SaveSystem:      Depends on GameState (calls load_from_save on ready)
SceneManager:    Depends on all above — last to complete boot
```

---

### F-02: Language Standards

**Source ADR**: ADR-0002 (`adr-0002-gdscript-language-choice.md`) — Status: Proposed

#### Required Patterns

- All game source code in `src/` must be written in GDScript (`.gd` files)
- All variable declarations must have explicit type annotations:
  ```gdscript
  var hunger_level: float = 1.0       # ✅ correct
  var name: String = "Bun"            # ✅ correct
  ```
- All function parameters must have type annotations:
  ```gdscript
  func feed_rabbit(rabbit: RabbitData, amount: float) -> void:  # ✅ correct
  ```
- All function return types must be declared:
  ```gdscript
  func get_hunger() -> float:  # ✅ correct
  ```
- Class names must be declared with `class_name` on files that are referenced by other scripts
- Files must use `snake_case` naming: `rabbit_data.gd`, `genetics_system.gd`
- Classes must use `PascalCase`: `class_name RabbitData`
- Constants must use `SCREAMING_SNAKE_CASE`: `const MAX_HUNGER: float = 100.0`

#### Forbidden Patterns

- C# files (`.cs`) anywhere in `src/` — Godot C# is not permitted in this project
- Untyped variable declarations in `src/`:
  ```gdscript
  var hunger = 1.0       # ❌ forbidden — missing type annotation
  var data               # ❌ forbidden — completely untyped
  ```
- Untyped function parameters or return types:
  ```gdscript
  func feed(rabbit, amount):  # ❌ forbidden
  ```
- Variadic arguments (`...args`) in game logic scripts — too loose for a typed codebase
- Third-party addons or plugins without explicit `technical-director` approval (tracked in `technical-preferences.md`)

---

### F-03: EventBus Signal Architecture

**Source ADR**: ADR-0003 (`adr-0003-eventbus-signals.md`) — Status: Accepted

#### Required Patterns

- All cross-system communication must use the `EventBus` autoload — no direct method calls between separate system autoloads
- Signals must be defined on `EventBus` (in `src/core/event_bus.gd`), not on individual systems
- Signal connections must use callable syntax:
  ```gdscript
  EventBus.rabbit_fed.connect(_on_rabbit_fed)           # ✅ correct
  EventBus.rabbit_fed.connect(Callable(self, "_on_rabbit_fed"))  # ✅ also correct
  ```
- Signal names must be past-tense snake_case describing what happened:
  - `rabbit_fed`, `breeding_completed`, `hutch_upgraded` ✅
- Signal handler method names must follow the pattern `_on_[signal_name]`:
  - `_on_rabbit_fed()`, `_on_breeding_completed()` ✅
- All signals must be typed — all parameters must have type declarations in the signal definition
- Emit signals only after the state change is complete (not before)
- Disconnect signals in `_exit_tree()` to prevent dangling connections:
  ```gdscript
  func _exit_tree() -> void:
      EventBus.rabbit_fed.disconnect(_on_rabbit_fed)
  ```

#### Forbidden Patterns

- String-based signal connections:
  ```gdscript
  EventBus.connect("rabbit_fed", self, "_on_rabbit_fed")  # ❌ Godot 3 syntax, forbidden
  ```
- Defining game-domain signals on individual system classes instead of EventBus:
  ```gdscript
  # In genetics_system.gd:
  signal breeding_completed(result)  # ❌ forbidden — define on EventBus
  ```
- Upward calls from child systems to parent autoloads via direct method invocation:
  ```gdscript
  GameState.add_coins(100)  # ❌ forbidden from inside RabbitSystem
  # Correct: emit EventBus.coins_earned, let EconomyManager handle it
  ```
- Emitting signals inside a signal handler triggered by the same signal (re-entrant emit)
- Using `call_deferred()` to work around signal ordering issues — fix the ordering instead

#### Signal Registry

All 23 defined EventBus signals (from `src/core/event_bus.gd`):

**Rabbit lifecycle:**
- `rabbit_born(rabbit: RabbitData)`
- `rabbit_fed(rabbit: RabbitData, amount: float)`
- `rabbit_happiness_changed(rabbit: RabbitData, new_value: float)`
- `rabbit_health_changed(rabbit: RabbitData, new_value: float)`
- `rabbit_cleanliness_changed(rabbit: RabbitData, new_value: float)`
- `rabbit_stage_changed(rabbit: RabbitData, new_stage: String)`
- `rabbit_died(rabbit: RabbitData)`
- `rabbit_sent_on_expedition(rabbit: RabbitData, location: String)`
- `rabbit_returned_from_expedition(rabbit: RabbitData, rewards: Dictionary)`

**Breeding:**
- `breeding_started(parent_a: RabbitData, parent_b: RabbitData)`
- `breeding_completed(offspring: RabbitData)`

**Economy:**
- `coins_earned(amount: float, source: String)`
- `coins_spent(amount: float, reason: String)`
- `gems_spent(amount: int, reason: String)`
- `hutch_upgraded(hutch_id: String, new_tier: int)`

**Progression:**
- `player_level_up(new_level: int)`
- `achievement_unlocked(achievement_id: String)`
- `season_changed(new_season: String)`

**Save/Load:**
- `save_requested()`
- `save_completed(success: bool)`
- `load_completed(success: bool)`

**Session:**
- `offline_earnings_calculated(report: Dictionary)`
- `game_ready()`

---

### F-04: Balance Data Loading

**Source ADR**: ADR-0004 (`adr-0004-balance-json.md`) — Status: Accepted

#### Required Patterns

- All balance/tuning values must live in `assets/data/balance.json`
- Each system that uses balance data must implement a `_load_balance_data()` private method called from `_ready()`:
  ```gdscript
  func _ready() -> void:
      _load_balance_data()

  func _load_balance_data() -> void:
      var file := FileAccess.open("res://assets/data/balance.json", FileAccess.READ)
      var json_string := file.get_as_text()
      file.close()
      var data: Dictionary = JSON.parse_string(json_string)
      _base_hunger_rate = data["rabbit"]["base_hunger_rate"]
      # ... etc
  ```
- Balance values loaded from JSON must be stored in typed private member variables
- The `balance.json` structure must have a dedicated namespace per system (e.g., `"rabbit"`, `"economy"`, `"genetics"`)

#### Forbidden Patterns

- Hardcoded numeric balance values in game logic:
  ```gdscript
  var hunger_decay: float = 0.05   # ❌ forbidden — must come from balance.json
  const MUTATION_CHANCE: float = 0.03  # ❌ forbidden — must come from balance.json
  ```
- Magic numeric literals in any formula or condition in `src/`:
  ```gdscript
  if hunger < 25.0:  # ❌ forbidden — 25.0 must be a named constant loaded from JSON
  ```
- Loading balance data outside of `_load_balance_data()` (e.g., directly in a formula function)
- Caching balance values into module-level constants at compile time (must load at runtime for live tuning support)

#### Interface Contracts

```
balance.json schema (top-level keys):
  "rabbit"    → hunger rates, happiness rates, health rates, stage durations
  "economy"   → coin rates, gem costs, upgrade costs
  "genetics"  → mutation rates, allele probabilities, rarity weights
  "idle"      → production rates per tier, offline caps
  "save"      → autosave interval, offline calculation cap
```

---

### F-05: Save System Local-First

**Source ADR**: ADR-0008 (`adr-0008-firebase-local-first-save.md`) — Status: Accepted

#### Required Patterns

- Local `user://savegame.json` is the authoritative save store — always read/write local first
- `SaveSystem` must be able to complete a full save/load cycle with no network connection
- Firebase operations must be wrapped in async functions with error handling that does not block the main thread
- Auto-save must be triggered by a timer (interval from `balance.json`) AND by the `save_requested` EventBus signal
- Save file must be written with `FileAccess` in JSON format (not `ResourceSaver` or `ConfigFile`)
- On load: always load from local file first; sync from Firebase only if local file is absent or corrupted
- Firebase sync must emit `save_completed(true/false)` when it finishes (success or failure)

#### Forbidden Patterns

- Requiring a network connection at game launch — the game must be fully playable offline
- Using Firebase as the primary save store (local file is primary; Firebase is secondary)
- Blocking the main thread on any Firebase I/O:
  ```gdscript
  await firebase.save(data)  # ❌ if this blocks main thread execution
  ```
- Using Godot's `ResourceSaver` or `ConfigFile` for save data — must use `FileAccess` + JSON
- Storing save data in `ProjectSettings` or autoload variable state only (not persisted to disk)

#### Interface Contracts

```
SaveSystem public API:
  save_game() -> void          # writes local file, queues Firebase sync
  load_game() -> Dictionary    # reads local file, returns save dict
  get_save_version() -> int    # returns schema version for migration

SaveSystem emits:
  EventBus.save_completed(success: bool)
  EventBus.load_completed(success: bool)

SaveSystem responds to:
  EventBus.save_requested → triggers save_game()
```

---

## Core Layer Rules

### C-01: RabbitData Ownership

**Source ADR**: ADR-0005 (`adr-0005-rabbitdata-resource.md`) — Status: Accepted

#### Required Patterns

- `RabbitData` must extend `Resource` (not `Node`, not `RefCounted` directly):
  ```gdscript
  class_name RabbitData
  extends Resource
  ```
- Only `RabbitSystem` may write to `RabbitData` fields — all other systems are read-only
- `RabbitSystem` must expose a typed API for all state mutations:
  ```gdscript
  func apply_feeding(rabbit: RabbitData, amount: float) -> void
  func apply_aging(rabbit: RabbitData, delta: float) -> void
  func apply_stat_decay(rabbit: RabbitData, delta: float) -> void
  ```
- After any state mutation, `RabbitSystem` must emit the appropriate EventBus signal
- `RabbitData` resources are stored in `GameState` — retrieved by ID, not by node reference
- Rabbit identity is established by a UUID string field `id: String` set at birth

#### Forbidden Patterns

- Direct field mutation of `RabbitData` from any script other than `RabbitSystem`:
  ```gdscript
  # In genetics_system.gd:
  rabbit.hunger = 0.0  # ❌ forbidden — call RabbitSystem.apply_feeding() instead
  ```
- `RabbitData` extending `Node2D` or any Node subclass:
  ```gdscript
  class_name RabbitData
  extends Node2D  # ❌ forbidden — must extend Resource
  ```
- Storing rabbits as scene nodes in the scene tree — they are data objects only
- Creating `RabbitData` instances outside of `RabbitSystem.create_rabbit()`

#### Interface Contracts

```
RabbitData fields (read-only from all systems except RabbitSystem):
  id: String                  # UUID, set at birth, never changes
  display_name: String
  rarity: String              # "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"
  life_stage: String          # "Baby" | "Adult" | "Elder"
  hunger: float               # 0.0–1.0
  happiness: float            # 0.0–1.0
  health: float               # 0.0–1.0
  cleanliness: float          # 0.0–1.0
  genotype: Dictionary        # allele pairs per gene locus
  birth_time: float           # Unix timestamp
  age_seconds: float          # elapsed since birth
  hutch_id: String            # current hutch assignment, "" if none
  is_on_expedition: bool
  expedition_return_time: float

RabbitSystem public write API:
  create_rabbit(genotype: Dictionary, rarity: String) -> RabbitData
  apply_feeding(rabbit: RabbitData, amount: float) -> void
  apply_stat_decay(rabbit: RabbitData, delta: float) -> void
  apply_aging(rabbit: RabbitData, delta: float) -> void
  send_on_expedition(rabbit: RabbitData, location: String, duration: float) -> void
  return_from_expedition(rabbit: RabbitData) -> void
  dismantle(rabbit: RabbitData) -> Dictionary  # returns gene fragments
```

---

### C-02: Genetics Breeding Purity

**Source ADR**: ADR-0006 (`adr-0006-genetics-allele-model.md`) — Status: Accepted

#### Required Patterns

- `breed(parent_a: RabbitData, parent_b: RabbitData, rng_seed: int) -> RabbitData` must be a **pure function** — given the same inputs and seed, it must always produce the same output
- Parent `RabbitData` objects must be read but never modified by `breed()` or any genetics function
- `get_breed_preview(parent_a: RabbitData, parent_b: RabbitData) -> Dictionary` must be **fully deterministic with no RNG** — it returns probability tables, not outcomes
- Allele keys must be strings: `"dominant"` and `"recessive"` (not integers 0/1)
- Mutation rates must be loaded from `balance.json` (see F-04 rules)
- Genotype is represented as a `Dictionary` of locus keys to allele pair arrays:
  ```gdscript
  # Example genotype structure:
  {
    "coat_color": ["brown", "white"],
    "ear_shape": ["lop", "erect"],
    "pattern": ["spotted", "solid"]
  }
  ```
- The offspring `RabbitData` must be created via `RabbitSystem.create_rabbit()` — not instantiated directly inside GeneticsSystem

#### Forbidden Patterns

- Modifying parent genomes inside `breed()`:
  ```gdscript
  func breed(a: RabbitData, b: RabbitData, seed: int) -> RabbitData:
      a.genotype["coat_color"][0] = "mutated"  # ❌ forbidden — parent mutation
  ```
- Hardcoded mutation rates inside `GeneticsSystem`:
  ```gdscript
  const MUTATION_CHANCE: float = 0.03  # ❌ forbidden — load from balance.json
  ```
- Integer allele keys:
  ```gdscript
  genotype = {0: [1, 0]}  # ❌ forbidden — use string keys
  ```
- RNG calls inside `get_breed_preview()`:
  ```gdscript
  func get_breed_preview(...) -> Dictionary:
      if randf() < 0.5:  # ❌ forbidden — preview must be deterministic, no RNG
  ```
- Creating offspring without going through `RabbitSystem.create_rabbit()`

#### Interface Contracts

```
GeneticsSystem public API:
  breed(parent_a: RabbitData, parent_b: RabbitData, rng_seed: int) -> RabbitData
    # Pure function. Does NOT mutate parents. Creates offspring via RabbitSystem.
    # Emits EventBus.breeding_completed(offspring) after RabbitSystem.create_rabbit().

  get_breed_preview(parent_a: RabbitData, parent_b: RabbitData) -> Dictionary
    # No RNG. Returns probability tables per locus.
    # Return format: { "coat_color": { "brown": 0.75, "white": 0.25 }, ... }

  calculate_rarity(genotype: Dictionary) -> String
    # Deterministic. Returns one of: "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"
```

---

### C-03: Idle Production Statelessness

**Source ADR**: ADR-0007 (`adr-0007-idle-production-offline.md`) — Status: Accepted

#### Required Patterns

- `IdleProductionSystem` must be **stateless** — it takes inputs and returns an `EarningsReport`, it does not hold or modify game state
- The system must never call `EconomyManager.add()` or any method on `EconomyManager` directly
- The caller (GameState or a bridge layer) is responsible for applying the `EarningsReport` to the economy
- `floor()` for coin rounding must be applied **once, at the very end** of the calculation — not per-multiplicand
- Only rabbits with `life_stage == "Adult"` or `life_stage == "Elder"` count as productive
- Offline earnings calculation must respect the cap from `balance.json` (`"idle"."offline_cap_hours"`)

#### Required formula structure:

```gdscript
func calculate_earnings(
    rabbits: Array[RabbitData],
    hutch_tier: int,
    elapsed_seconds: float,
    balance: Dictionary
) -> EarningsReport:
    var productive_rabbits := rabbits.filter(func(r): return r.life_stage in ["Adult", "Elder"])
    var raw_total: float = 0.0
    for rabbit in productive_rabbits:
        # ... calculate per-rabbit contribution (float math, no floor here)
        raw_total += rabbit_contribution
    var report := EarningsReport.new()
    report.coins = floor(raw_total)  # ← single floor(), applied here only
    return report
```

#### Forbidden Patterns

- Calling `EconomyManager` from inside `IdleProductionSystem`:
  ```gdscript
  # Inside IdleProductionSystem:
  EconomyManager.add_coins(earnings)  # ❌ forbidden — system must be stateless
  ```
- Applying `floor()` inside the per-rabbit loop (premature rounding):
  ```gdscript
  raw_total += floor(rabbit_coins)  # ❌ forbidden — floor once at the end only
  ```
- Counting Baby-stage rabbits as productive:
  ```gdscript
  for rabbit in all_rabbits:  # ❌ forbidden — must filter to Adult+Elder
  ```
- Hardcoded production rates — all rates from `balance.json`
- Holding mutable state between calls (e.g., a running total that persists across frames)

#### Interface Contracts

```gdscript
class_name EarningsReport
extends RefCounted

var coins: int           # floor() applied, ready to add to EconomyManager
var source_rabbits: int  # count of productive rabbits that contributed
var elapsed_seconds: float
var was_capped: bool     # true if offline time exceeded balance.json cap

# IdleProductionSystem public API:
func calculate_earnings(
    rabbits: Array[RabbitData],
    hutch_tier: int,
    elapsed_seconds: float,
    balance: Dictionary
) -> EarningsReport

func calculate_offline_earnings(
    rabbits: Array[RabbitData],
    hutch_tier: int,
    offline_since: float,      # Unix timestamp of last session
    balance: Dictionary
) -> EarningsReport
```

---

## Cross-Layer Rules

These rules apply regardless of which system or layer a story targets.

### No Direct Cross-System Calls

Systems may only communicate via EventBus signals. Direct method calls between autoloads are forbidden except:
- During the boot sequence (ADR-0001 defines the exceptions)
- `SaveSystem` → `GameState.load_from_save()` on boot

### No Hardcoded Balance Values

Applies everywhere in `src/`. Any numeric value that affects gameplay balance must come from `balance.json`. This includes:
- Stat decay rates
- Production rates
- Mutation chances
- Rarity thresholds
- Cost values
- Time durations

### Typing Everywhere

All `src/` code must have explicit type annotations on all variables, parameters, and return types. No exceptions for "quick" scripts or test helpers.

### RabbitData Is Read-Only Outside RabbitSystem

Any code that reads `RabbitData` fields is fine. Any code that writes `RabbitData` fields outside of `RabbitSystem` is a production defect.

---

## Performance Guardrails

These are hard limits that apply to all implementations. Violations flag as blockers in code review.

| Metric | Limit | Source |
|--------|-------|--------|
| Draw calls per frame | < 50 | technical-preferences.md |
| Simultaneous `GPUParticles2D` nodes | ≤ 14 | Art Bible Section 8 |
| Visible rabbits per scene | ≤ 24 | technical-preferences.md (Cosmic hutch max) |
| Target framerate (desktop) | 60 FPS | technical-preferences.md |
| Target framerate (mobile) | 30 FPS stable | technical-preferences.md |
| Frame budget | 16.6ms (60fps) / 33ms (30fps) | technical-preferences.md |
| Memory ceiling | 256MB RAM on mobile | technical-preferences.md |
| Sprite atlas | Single atlas, rabbit sprites packed | technical-preferences.md |
| Blocking I/O on main thread | Never | ADR-0008 |
| Firebase on boot (blocking) | Never | ADR-0008 |

### Draw Call Budget Allocation (worst case ~37–43)

| Budget Item | Draw Calls |
|-------------|------------|
| Rabbit sprites (24 max, atlased) | 2–3 |
| Hutch exteriors (max 8 visible) | 4–6 |
| Background layers (parallax, 3–4) | 3–4 |
| Floating collection icons (max 8) | 1–2 |
| UI overlay (CanvasLayer) | 4–8 |
| VFX / particles (max 14 nodes) | 6–12 |
| HUD / header elements | 2–4 |
| Misc (shadows, indicators) | 2–4 |
| **Worst-case total** | **~37–43** |

---

## Signal Registry

Complete list of all 23 EventBus signals. All must be defined in `src/core/event_bus.gd`.

```gdscript
# Rabbit lifecycle
signal rabbit_born(rabbit: RabbitData)
signal rabbit_fed(rabbit: RabbitData, amount: float)
signal rabbit_happiness_changed(rabbit: RabbitData, new_value: float)
signal rabbit_health_changed(rabbit: RabbitData, new_value: float)
signal rabbit_cleanliness_changed(rabbit: RabbitData, new_value: float)
signal rabbit_stage_changed(rabbit: RabbitData, new_stage: String)
signal rabbit_died(rabbit: RabbitData)
signal rabbit_sent_on_expedition(rabbit: RabbitData, location: String)
signal rabbit_returned_from_expedition(rabbit: RabbitData, rewards: Dictionary)

# Breeding
signal breeding_started(parent_a: RabbitData, parent_b: RabbitData)
signal breeding_completed(offspring: RabbitData)

# Economy
signal coins_earned(amount: float, source: String)
signal coins_spent(amount: float, reason: String)
signal gems_spent(amount: int, reason: String)
signal hutch_upgraded(hutch_id: String, new_tier: int)

# Progression
signal player_level_up(new_level: int)
signal achievement_unlocked(achievement_id: String)
signal season_changed(new_season: String)

# Save/Load
signal save_requested()
signal save_completed(success: bool)
signal load_completed(success: bool)

# Session
signal offline_earnings_calculated(report: Dictionary)
signal game_ready()
```

---

*Control Manifest v2026-05-18 — Generated from ADR-0001 through ADR-0008*
*Update this file whenever an ADR is revised or a new ADR is accepted.*
*Stories must embed this manifest version date. Mismatches trigger `/story-readiness` review.*
