# ADR-0001: Autoload Boot Sequence and GameState Ownership

## Status
Accepted

## Date
2026-05-16

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — autoload system unchanged in 4.4–4.6 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm autoload order in Project Settings → Autoloads matches the sequence defined here before first playtest build |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0003 (EventBus signal architecture depends on EventBus being first autoload), ADR-0007 (Firebase/SaveSystem depends on GameState and SaveSystem order), ADR-0005 (RabbitData immutability depends on GameState being data owner) |
| **Blocks** | All implementation epics — no code can be written until boot order is accepted |
| **Ordering Note** | This ADR must be the first Accepted ADR. All others assume it. |

## Context

### Problem Statement
Godot registers autoloads in Project Settings in a user-defined order, and each autoload's `_ready()` runs in that sequence. There is no runtime enforcement of dependencies — any autoload can call any other at init time, silently causing null-reference crashes if the callee hasn't initialised yet. We need to define exactly which autoloads exist, what each one owns, and the guaranteed initialisation sequence so all other systems can safely depend on earlier autoloads.

### Constraints
- Godot 4.6 autoload order is set in Project Settings → Globals → Autoloads, not in code
- Autoloads are singletons accessible via their registered name from anywhere in the project
- All autoloads are loaded before any scene's `_ready()` runs — their own `_ready()` calls happen in registration order
- Maximum 6 autoloads to keep boot overhead minimal and ownership clear

### Requirements
- Must support real-time stat decay (TimeManager drives 1-second tick)
- Must support offline catch-up on resume (TimeManager → IdleProductionSystem)
- Must support 4-currency economy accessible from any system (EconomyManager)
- Must support full game state serialisation and cloud sync (GameState + SaveSystem)
- Must support async scene loading and screen transitions (SceneManager)
- Must support decoupled cross-system signalling (EventBus)

## Decision

Six specialised autoloads are registered in Godot Project Settings in the following fixed order. No system may call an autoload that appears later in this list during its own `_ready()`.

```
Autoload Registration Order (Project Settings → Globals → Autoloads):
  1. EventBus       res://src/core/event_bus.gd
  2. TimeManager    res://src/core/time_manager.gd
  3. EconomyManager res://src/core/economy_manager.gd
  4. GameState      res://src/core/game_state.gd
  5. SaveSystem     res://src/core/save_system.gd
  6. SceneManager   res://src/core/scene_manager.gd
```

### Ownership Rules

| Autoload | Exclusively Owns | May Read From |
|----------|-----------------|---------------|
| `EventBus` | Signal definitions — nothing else | Nothing |
| `TimeManager` | Last-seen Unix timestamp, current time, offline delta, in-game day counter | `Time` singleton only |
| `EconomyManager` | 4-currency ledgers (Carrot Coin, Star Dust, Crystal Gem, Gene Fragment) | `EventBus` (emit only) |
| `GameState` | Complete persistent player data tree (rabbits, hutches, collection, prestige count, settings) | `EventBus`, `EconomyManager` (reads balances on save) |
| `SaveSystem` | Serialisation logic, save file path, Firebase sync queue | `GameState` (data source), `FirebaseAdapter` (injected, not autoloaded) |
| `SceneManager` | Active scene stack, transition state, loading screen | `ResourceLoader` |

### Boot Sequence

```
App launch
  ↓
Autoloads initialise in order (1 → 6):
  EventBus._ready()        # registers all signal definitions; no dependencies
  TimeManager._ready()     # records session-start timestamp; starts 1-sec timer
  EconomyManager._ready()  # initialises ledgers to zeroes; waits for GameState load
  GameState._ready()       # allocates data tree; does NOT load data yet
  SaveSystem._ready()      # calls load_game() → populates GameState from disk/cloud
                           # calls TimeManager.mark_session_start() → offline delta calculated
                           # calls IdleProductionSystem.apply_offline_earnings() [call_deferred]
  SceneManager._ready()    # goto_scene("res://src/ui/screens/main_farm.tscn")
  ↓
First scene _ready() runs — all autoloads guaranteed initialised
```

### GameState Data Tree Shape

```gdscript
# GameState owns this structure — populated by SaveSystem.load_game()
var rabbits: Array[RabbitData] = []
var hutches: Array[HutchData] = []
var prestige_count: int = 0
var collection_registry: Dictionary = {}   # species_id → discovered: bool
var active_expeditions: Array[Dictionary] = []
var settings: Dictionary = {
    "font_scale": 1.0,
    "colorblind_mode": 0,
    "simplified_mode": false,
    "dark_mode": false,
}
var last_save_timestamp: int = 0
var is_dirty: bool = false   # set true by any mutation; triggers save on next idle frame
```

### Dirty-Flag Save Strategy
Any system that mutates GameState data calls `GameState.mark_dirty()`. SaveSystem polls `is_dirty` every 30 seconds and on app background/quit. This avoids redundant saves while ensuring no progress is lost.

### Architecture Diagram

```
┌──────────────────────────────────────────────────────┐
│ Autoload Boot Order                                  │
│                                                      │
│  1. EventBus    ←── all signals defined here         │
│       ↓                                              │
│  2. TimeManager ←── clock starts, offline delta      │
│       ↓                                              │
│  3. EconomyManager ←── currency ledgers at zero      │
│       ↓                                              │
│  4. GameState   ←── data tree allocated (empty)      │
│       ↓                                              │
│  5. SaveSystem  ←── populates GameState from disk    │
│       ↓               calls mark_session_start()     │
│  6. SceneManager ←── launches first scene            │
│       ↓                                              │
│  [Scene _ready() — all autoloads guaranteed ready]   │
└──────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative B: Single monolithic GameState autoload
- **Description**: One large `GameState` autoload owns currencies, time, save/load, scene management, and all player data.
- **Pros**: Simple — one node to reference for everything.
- **Cons**: God Object. Untestable. Any change to time logic risks breaking save logic. Impossible to unit test EconomyManager without loading the entire save system.
- **Rejection Reason**: Violates single-responsibility. Genetics and idle math formulas require isolated unit tests — a monolithic GameState makes that impossible.

### Alternative C: No autoloads except EventBus — bootstrap scene
- **Description**: A dedicated `Bootstrap.tscn` scene initialises all systems as child nodes, passing references via dependency injection.
- **Pros**: More testable; systems receive injected dependencies rather than calling globals.
- **Cons**: Every scene loaded directly (e.g., during development) needs its own bootstrap. Scene-to-scene transitions require re-initialising or preserving the bootstrap node. Increases complexity for a mobile idle game with simple scene needs.
- **Rejection Reason**: Complexity cost not justified. Mobile idle game needs globally accessible systems; no local multiplayer or split-screen context would benefit from scene-local system instances.

## Consequences

### Positive
- Guaranteed initialisation order — any system's `_ready()` can safely call any autoload without null-reference risk
- Clear ownership boundaries — one obvious place to mutate player data (GameState via its methods)
- Testable in isolation — each autoload can be instantiated standalone in GdUnit4 tests
- SceneManager is last in boot order, so scenes only launch after all data is loaded

### Negative
- Autoload order is set in Project Settings (UI only) — not enforced by code. A developer adding a new autoload in the wrong position breaks boot order silently.
- GameState is a global mutable object — any script can bypass `mark_dirty()`. Requires team discipline.

### Risks
- **Risk**: Developer adds a 7th autoload between SaveSystem and SceneManager, causing SceneManager to launch before data is loaded.
  - **Mitigation**: This ADR is the source of truth. Any addition to the autoload list requires updating this ADR and reviewing boot dependencies.
- **Risk**: SaveSystem.load_game() fails (corrupted file) and GameState remains empty — game launches with zeroed state.
  - **Mitigation**: SaveSystem detects empty/corrupted saves and emits `new_game_started` signal. SceneManager routes to tutorial scene in that case.

## GDD Requirements Addressed

| GDD Requirement ID | Requirement | How This ADR Addresses It |
|--------------------|-------------|--------------------------|
| TR-save-001 | Full game state serialisation/deserialisation | GameState owns the data tree; SaveSystem owns serialisation. Clear separation of concerns. |
| TR-idle-002 | Offline delta calculated and applied on app resume | TimeManager.mark_session_start() called by SaveSystem during boot — delta available before any scene runs. |
| TR-economy-001 | 4-currency system accessible to all game systems | EconomyManager is autoload #3 — globally accessible, initialises before GameState so it's ready for SaveSystem to populate balances. |
| TR-prestige-002 | Selective reset (keep some data, wipe rest) | GameState.prestige_reset(keep: Dictionary) is the sole entry point for resetting state. One place to update when prestige rules change. |

## Performance Implications
- **CPU**: 6 autoloads at ~0.01ms each on boot — negligible
- **Memory**: GameState data tree at max capacity (24 rabbits × full hutch set) estimated <500KB — well within 256MB mobile budget
- **Load Time**: SaveSystem reads one local JSON file (~50KB max). Acceptable on all target hardware. Cloud sync is async and does not block boot.
- **Network**: None at boot. Firebase sync is non-blocking after first scene launches.

## Migration Plan
Greenfield project — no migration required. On first implementation: create each `.gd` file in `src/core/`, then register all 6 in Project Settings → Globals → Autoloads in the specified order.

## Validation Criteria
- [ ] App launches without null-reference errors in all 6 autoloads' `_ready()` calls
- [ ] `GameState.rabbits.size()` returns correct value in `SceneManager._ready()` (not zero after a save exists)
- [ ] `TimeManager.get_offline_delta()` returns correct elapsed seconds when app is closed and reopened
- [ ] `EconomyManager.get_balance(CARROT_COIN)` returns saved value (not zero) after load
- [ ] GdUnit4 test: each autoload instantiates in isolation with no dependency errors

## Related Decisions
- ADR-0002 (pending): Signal-based inter-system communication via EventBus
- ADR-0003 (pending): GDScript over C# — language choice affects autoload file paths
- ADR-0007 (pending): Firebase local-first save — SaveSystem cloud sync strategy
- `docs/architecture/architecture.md` — Section: Initialisation Order
