# ADR-0003: Signal-Based Inter-System Communication via EventBus

## Status
Accepted

## Date
2026-05-16

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — Godot signal system unchanged in 4.4–4.6 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm callable-based `connect()` works correctly with typed signal parameters in GdUnit4 test environment |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (EventBus is autoload #1 — must boot first), ADR-0002 (all signal parameters must be statically typed) |
| **Enables** | All feature and presentation implementation epics |
| **Blocks** | All implementation epics until Accepted |
| **Ordering Note** | EventBus signal definitions should be written before any system that emits or consumes them |

## Context

### Problem Statement
The game has 16 systems across 5 architecture layers. Systems in lower layers must notify systems in higher layers when state changes (e.g., RabbitSystem must notify FarmMapUI when a rabbit's stats change). Direct method calls from lower layers to higher layers create circular dependencies, make unit testing impossible, and violate the no-upward-call layering rule. We need a single, explicit, auditable communication pattern for all cross-layer events.

### Constraints
- Architecture rule: no upward direct calls between layers — signals only
- GDScript typed callable syntax must be used — string-based `connect()` deprecated since 4.0
- EventBus is autoload #1 (ADR-0001) — all signal definitions must live there
- All signal parameters must be statically typed (ADR-0002)

### Requirements
- Must allow RabbitSystem (Core) to notify FarmMapUI (Presentation) without importing it
- Must allow any system to subscribe to any event without knowing which system produces it
- Must be testable: unit tests must be able to emit events and assert consumers responded
- Must be auditable: all cross-system events visible in one file

## Decision

**All cross-system communication uses typed signals defined on the `EventBus` autoload.** No system may call a method on a system in a higher layer directly. Within-layer calls and downward calls (Feature → Core read-only getters, Presentation → Core read-only getters) are permitted via direct method calls.

### Signal Naming Convention
All signals use **snake_case past-tense verbs** (completed action, not commands):
- ✅ `rabbit_born`, `breeding_completed`, `hutch_dirtied`
- ❌ `spawn_rabbit`, `on_breed`, `hutch_dirty_event`

### Emit Pattern
```gdscript
# In RabbitSystem — after adding a new rabbit:
EventBus.rabbit_born.emit(child.rabbit_id)
```

### Connect Pattern
```gdscript
# In FarmMapUI._ready():
EventBus.rabbit_born.connect(_on_rabbit_born)

func _on_rabbit_born(rabbit_id: String) -> void:
    _spawn_rabbit_sprite(rabbit_id)
```

### Disconnect Pattern
Consumers freed mid-session must disconnect in `_exit_tree()`:
```gdscript
func _exit_tree() -> void:
    EventBus.rabbit_born.disconnect(_on_rabbit_born)
```
Exception: autoloads and permanent scene roots that live the full session do not need to disconnect.

### Complete Signal Catalogue

```gdscript
# src/core/event_bus.gd
extends Node
# All cross-system signals. Every cross-layer signal defined here, nowhere else.

## Rabbit lifecycle
signal rabbit_born(rabbit_id: String)
signal rabbit_matured(rabbit_id: String, new_stage: RabbitData.RabbitStage)
signal rabbit_stat_changed(rabbit_id: String)
signal rabbit_died(rabbit_id: String)

## Economy
signal currency_changed(currency: EconomyManager.CurrencyType, new_balance: int, delta: int)

## Production
signal production_ticked(carrot_coin: int, star_dust: int)

## Breeding
signal breed_requested(parent_a_id: String, parent_b_id: String)
signal breeding_completed(child_id: String)

## Habitat
signal hutch_dirtied(hutch_id: String)
signal hutch_upgraded(hutch_id: String, new_level: int)
signal rabbit_assigned_to_hutch(rabbit_id: String, hutch_id: String)

## Expedition
signal expedition_completed(slot_id: int, loot_summary: String)

## Save / sync
signal save_requested()
signal save_synced()
signal new_game_started()

## UI navigation
signal nav_tab_pressed(tab: HUD.NavTab)
signal notification_requested(text: String, duration_sec: float)

## Events / seasons
signal season_changed(new_season: SeasonSystem.Season)
signal event_activated(event_id: String)
signal merchant_appeared()

## Prestige
signal prestige_executed(new_prestige_count: int)

## Guild (local actions only — Firebase state changes use polling, not signals)
signal guild_contribution_submitted(amount: int)
signal guild_boss_attacked(damage: int)
```

### What Is NOT in EventBus
- **Return-value requests**: If system A needs data from system B, it calls B's method directly (e.g., `GeneticsSystem.get_breed_preview(a, b)`). Signals are fire-and-forget.
- **Within-system events**: Internal state changes no other system cares about stay local.
- **Firebase/network callbacks**: Handled within Platform layer; translated to EventBus signals only if another system needs to react.

### Architecture Diagram

```
CORE                    EVENTBUS               FEATURE / PRESENTATION
────                    ────────               ──────────────────────
RabbitSystem
  .tick() hunger→0 ──► rabbit_stat_changed ──► FarmMapUI (updates sprite)

GeneticsSystem
  .breed() done ───► rabbit_born ───────────► FarmMapUI (spawn sprite)
                                    └───────► CollectionSystem (register)
                                    └───────► GenePuzzleSystem (check challenge)

EconomyManager
  .add() ──────────► currency_changed ──────► HUD (update label)
```

## Alternatives Considered

### Alternative B: Per-system node signals
- **Description**: Each system defines its own signals. Consumers get a reference to the producer node and connect directly.
- **Pros**: Signals co-located with the system that emits them.
- **Cons**: Consumers must hold a reference to the producer — FarmMapUI would need a reference to RabbitSystem, violating the no-upward-reference rule. Refactoring a system breaks all consumers.
- **Rejection Reason**: Creates the exact circular dependencies this pattern is designed to prevent.

### Alternative C: Shared state polling
- **Description**: Systems read `GameState` every tick and re-render if changed.
- **Pros**: No signal wiring; simpler for small systems.
- **Cons**: O(N×24) checks per second even when nothing changed. Non-deterministic timing. Untestable reactivity.
- **Rejection Reason**: Wastes CPU and is non-deterministic. An idle game UI must react at the moment state changes occur, not "sometime next frame."

## Consequences

### Positive
- No circular dependencies — producers never import consumers
- EventBus is a complete, auditable catalogue of all inter-system events
- Unit tests can emit signals directly without running the full game
- Adding a new consumer requires zero changes to the producer

### Negative
- Signal connections in `_ready()` are not statically checked — a typo in the callable name silently fails to connect (no compile error)
- `expedition_completed` uses `loot_summary: String` — if consumers need full loot data, they must call `ExpeditionSystem.collect()` directly or the signal payload must be expanded

### Risks
- **Risk**: Freed node receives signal call and crashes.
  - **Mitigation**: Any node freed mid-session must disconnect in `_exit_tree()`. Autoloads and permanent scene roots are exempt.
- **Risk**: EventBus grows unbounded.
  - **Mitigation**: Signals are only added when two or more separate systems need to react. Internal events stay local. `/architecture-review` checks this.

## GDD Requirements Addressed

| GDD Requirement ID | Requirement | How This ADR Addresses It |
|--------------------|-------------|--------------------------|
| TR-rabbit-001 | Hunger/Health decay notifies UI | `rabbit_stat_changed` allows FarmMapUI to update without RabbitSystem knowing about UI |
| TR-genetics-004 | Gene preview before breeding | `breed_requested` allows BreedingUI to dispatch the breed action without a direct upward call |
| TR-economy-001 | Currency changes reflected in HUD | `currency_changed` lets HUD react to any transaction without polling EconomyManager each frame |
| TR-ui-004 | ≤2 taps for frequent actions | `nav_tab_pressed` allows SceneManager to respond to HUD taps without HUD holding a SceneManager reference |

## Performance Implications
- **CPU**: Signal emission is O(connected_listeners). Max ~5 listeners per signal — negligible.
- **Memory**: ~60 signals × avg 3 connections = ~180 Callable entries. Immaterial.
- **Load Time**: No impact.
- **Network**: No impact.

## Migration Plan
Greenfield — write `src/core/event_bus.gd` with the full catalogue as the first source file in the project.

## Validation Criteria
- [ ] Every cross-layer communication goes through EventBus (code review gate — no `.gd` in `src/ui/` imports a Core class except for read-only calls)
- [ ] No string-based `connect("signal_name", ...)` calls in `src/`
- [ ] GdUnit4 test: emit `EventBus.rabbit_born("test-id")` → assert FarmMapUI spawned a sprite node
- [ ] GdUnit4 test: emit `EventBus.currency_changed(CARROT_COIN, 100, 50)` → assert HUD CC label shows 100

## Related Decisions
- ADR-0001: EventBus is autoload #1 — guaranteed to exist before any signal is emitted
- ADR-0002: All signal parameters are statically typed
- `docs/architecture/architecture.md` — Architecture Principles #2: "Data down, events up"
