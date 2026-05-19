# ADR-0011: Expedition System — Async Timer with Unix Timestamp Storage

## Status
Accepted

## Date
2026-05-19

## Last Verified
2026-05-19

## Decision Makers
Technical Director, Gameplay Programmer

## Summary
The ExpeditionSystem schedules long-running (30 min – 48 h) async tasks where a
subset of rabbits is sent to a zone, returns after a fixed duration, and grants
loot when the player taps Collect. Timers are stored as Unix timestamps inside
`GameState.active_expeditions` (Array of Dictionaries), with loot pre-rolled at
start via a deterministic seed. This mirrors the FoodSystem pattern (ADR-0009)
and inherits offline catch-up "for free" by comparing `Time.get_unix_time_from_system()`
against each slot's `started_at + duration` at boot.

## Engine Compatibility
| Field | Value |
|-------|-------|
| Engine | Godot 4.6 |
| Domain | Feature (gameplay system) |
| Knowledge Risk | LOW |
| References Consulted | Godot 4.6 docs (`Time`, `RandomNumberGenerator`), ADR-0009 (FoodSystem), ADR-0007 (IdleProduction), `docs/engine-reference/godot/VERSION.md` |
| Post-Cutoff APIs Used | None — uses `Time.get_unix_time_from_system()` and `RandomNumberGenerator`, both stable since 4.0 |
| Verification Required | Offline catch-up unit test, deterministic loot roll test, save/load round-trip test |

## ADR Dependencies
| Field | Value |
|-------|-------|
| Depends On | ADR-0001 (Autoload boot order), ADR-0003 (EventBus signals), ADR-0004 (balance.json data-driven config), ADR-0007 (Offline delta from last_save_timestamp), ADR-0009 (FoodSystem timer pattern) |
| Enables | Sprint-02 story "Expedition MVP", future "Auto-Send" QoL feature, Prestige unlock gate (Rabbit Universe zone) |
| Blocks | None — all dependencies are accepted |
| Ordering Note | ExpeditionSystem autoload registers AFTER `RabbitSystem` and `EconomyManager` because `collect()` calls both. It also calls `_resolve_offline_expeditions()` via `call_deferred` in `_ready()` so SaveSystem has loaded GameState first. |

## Context

### Problem Statement
The game requires five expedition zones with durations ranging from 30 minutes to
48 hours. The player sends 1–5 adult rabbits to a zone, waits real time, and
collects loot on return. The system must:
- Survive app quit / device reboot (durations exceed any single play session).
- Resolve expeditions that finished while the app was backgrounded.
- Produce deterministic loot so an expedition resolved offline grants the same
  rewards a player would have seen had they been online when it completed.
- Integrate with RabbitSystem so rabbits are locked while away (cannot breed,
  cannot be sent on a second expedition).
- Be data-driven — zones, durations, and loot tables defined in `balance.json`.

### Current State
- `GameState.active_expeditions: Array = []` exists as an empty placeholder.
- No ExpeditionSystem autoload exists yet.
- `balance.json` has a `prestige` section but no `expeditions` section.
- `RabbitSystem` has no `is_on_expedition` flag or lock semantics.

### Constraints
- Mobile target — minimum tick cost; cannot poll all expeditions every frame.
- Memory budget 256 MB — `active_expeditions` is unbounded in principle but
  practically capped at ~5 concurrent slots (one per zone).
- No third-party addons (technical-preferences.md).
- All balance values in `balance.json` (ADR-0004); no hardcoded durations.
- Cross-system communication via EventBus (ADR-0003).
- Persistent state lives in GameState; SaveSystem serialises it (ADR-0001).

### Requirements
- R1: Expeditions persist across app quit and resume correctly.
- R2: Offline-elapsed expeditions are marked completed at boot but NOT auto-collected.
- R3: Loot is deterministic given `(loot_seed, zone_id)`.
- R4: Rabbits on an expedition are unavailable to breeding and to other expeditions.
- R5: Zone definitions, durations, and loot tables are externally configurable.
- R6: System emits signals for UI consumption (sent / completed / returned).

## Decision

Adopt the **Unix-timestamp slot model** identical in shape to ADR-0009's
FoodSystem plots. Each active expedition is a Dictionary stored in
`GameState.active_expeditions`. Loot is pre-rolled at `start_expedition()` time
by generating a `loot_seed: int`; the actual item roll happens at `collect()`
time using that seed against the zone's loot table from `balance.json`.
Completion is detected by an `_on_tick()` handler subscribed to `TimeManager.tick`
that flips `status` from `"in_progress"` to `"completed"`. Offline-elapsed
expeditions are resolved by a single `_resolve_offline_expeditions()` pass at
boot — no recursion, no replay.

### Architecture

```
┌───────────────────┐    tick     ┌──────────────────────┐
│   TimeManager     │────────────▶│  ExpeditionSystem    │
└───────────────────┘             │                      │
                                  │  - start_expedition()│
┌───────────────────┐  read/write │  - collect()         │
│   GameState       │◀───────────▶│  - _on_tick()        │
│  .active_expeditions            │  - _resolve_offline_ │
└───────────────────┘             │      expeditions()   │
                                  └──────┬──────┬────────┘
                                         │      │
                          add(item)      │      │  return_from_expedition()
                                         ▼      ▼
                                 ┌──────────────┐ ┌──────────────┐
                                 │ EconomyMgr   │ │ RabbitSystem │
                                 └──────────────┘ └──────────────┘
                                         ▲
                                         │ emit
                                 ┌───────┴──────┐
                                 │   EventBus   │
                                 └──────────────┘
```

Slot dictionary schema:

```gdscript
{
    "slot_id": "exp_4f3a9b...",       # UUID v4 string
    "zone_id": "near_forest",
    "rabbit_ids": ["r_001", "r_002"], # String IDs into RabbitSystem
    "started_at": 1747670400.0,       # Unix seconds (float)
    "duration": 1800.0,               # seconds, copied from balance.json
    "loot_seed": 8472619,             # int, pre-rolled at start for determinism
    "status": "in_progress"           # "in_progress" | "completed"
}
```

### Key Interfaces

```gdscript
# ExpeditionSystem.gd  (autoload)
extends Node

signal expedition_started(slot_id: String, zone_id: String)
signal expedition_completed(slot_id: String, zone_id: String)
signal expedition_collected(slot_id: String, rewards: Dictionary)

func start_expedition(zone_id: String, rabbit_ids: Array[String]) -> bool
func collect(slot_id: String) -> Dictionary
func get_active_slots() -> Array
func get_slot(slot_id: String) -> Dictionary

# private
func _on_tick(_delta: float) -> void
func _resolve_offline_expeditions() -> void
func _roll_loot(zone_id: String, loot_seed: int) -> Dictionary
func _validate_requirements(zone_id: String, rabbit_ids: Array[String]) -> bool
```

EventBus signals (added to EventBus autoload):

```gdscript
signal rabbit_sent_on_expedition(slot_id: String, zone_id: String, rabbit_ids: Array)
signal rabbit_returned_from_expedition(slot_id: String, zone_id: String, rabbit_ids: Array)
signal expedition_ready_to_collect(slot_id: String, zone_id: String)
```

### Implementation Guidelines

- **slot_id generation**: `"exp_" + str(Time.get_unix_time_from_system()).md5_text().substr(0, 12)` — collision-resistant enough for ≤5 concurrent slots; deterministic for tests when time is mocked.
- **loot_seed generation**: `randi()` at start_expedition time, stored in the slot.
- **_roll_loot()**: instantiate a fresh `RandomNumberGenerator`, set `rng.seed = loot_seed`, then weighted-sample the zone's `loot_table` array from `balance.json`. Quantity per drop is `rng.randi_range(quantity_min, quantity_max)`. The same `(zone_id, loot_seed)` MUST always produce the same rewards dict.
- **Tick cost**: `_on_tick` iterates `active_expeditions` only — bounded at ~5 items, O(n) is fine. Do NOT walk all rabbits.
- **Status transition emits once**: when `_on_tick` flips a slot from `in_progress` to `completed`, emit `EventBus.expedition_ready_to_collect` exactly once. The status field is the latch.
- **Validation in start_expedition**:
  - Zone exists in balance.json.
  - `rabbit_ids.size() >= min_rabbits` for the zone.
  - All rabbits exist in RabbitSystem, are Adult stage, are not on another expedition, are not currently breeding.
  - If `required_trait` is set, all rabbits must have that trait.
  - If `requires_prestige` is set, `GameState.prestige_count >= required value`.
  - On any failure: return `false`, emit nothing, mutate nothing.
- **collect() on incomplete slot**: returns `{}` (empty dict) and logs a warning. UI must check `status == "completed"` before calling.
- **RabbitSystem coupling**: ExpeditionSystem does NOT mutate rabbit state directly. It calls `RabbitSystem.send_on_expedition(rabbit_id, slot_id)` and `RabbitSystem.return_from_expedition(rabbit_id)`. RabbitSystem owns the `is_on_expedition` flag.
- **Save format**: `active_expeditions` is serialised as-is by SaveSystem (Array of Dictionaries — all values JSON-safe primitives).
- **Offline resolution**: in `_resolve_offline_expeditions()`, walk `active_expeditions` once. For each slot with `status == "in_progress"` and `Time.get_unix_time_from_system() >= started_at + duration`, set `status = "completed"` and emit `expedition_ready_to_collect`. Do NOT call `collect()` — the player must tap.
- **Autoload registration order**: append after EconomyManager in `project.godot` autoload list. Verify boot order: EventBus → TimeManager → EconomyManager → GameState → SaveSystem → SceneManager → **ExpeditionSystem** → RabbitSystem (RabbitSystem reads `active_expeditions` for its own `is_on_expedition` derivation — see Migration Plan).

## Alternatives Considered

### Alternative 1: Godot `Timer` nodes per expedition
Spawn a `Timer` node per active expedition with `wait_time = duration`.
- **Rejected because**: Timers do not persist across app quit. The system would
  need a parallel timestamp mechanism for offline catch-up anyway, doubling the
  state model. Also wastes a SceneTree node per slot.

### Alternative 2: Single global tick counter
Store remaining seconds on each slot and decrement on tick.
- **Rejected because**: Drifts during pause/background. A 24-hour expedition
  with 30 fps ticks accumulates float error. Requires extra logic to reconcile
  `remaining_seconds` with wall clock at resume. The Unix-timestamp approach
  computes remaining time from `(started_at + duration) - now` on demand, with
  no drift.

### Alternative 3: Resolve loot at start, store result dict
Pre-compute the rewards dict at `start_expedition()` and store it in the slot.
- **Rejected because**: Tying loot identity to a `loot_seed` instead of a baked
  result lets us re-roll deterministically if loot tables are rebalanced
  mid-flight (`balance.json` change), and keeps the slot dict ~50% smaller.
  It also means QA can replay any expedition outcome from the seed alone.

## Consequences

### Positive
- Offline catch-up is one comparison per slot at boot — no replay loop.
- Save format is trivially serialisable (primitive types, no node references).
- Loot is deterministic and replayable from `loot_seed` alone.
- No per-frame cost; tick cost is O(active slots) ≤ ~5.
- Pattern matches FoodSystem (ADR-0009), reducing cognitive load for programmers.

### Negative
- Slot dictionaries are loosely typed (Dictionary, not a typed Resource class).
  Mitigated by a single accessor helper `get_slot()` and constants for key names.
- Loot tables now live in two places conceptually: `balance.json` (the table)
  and the `loot_seed` (the roll). Documentation must make clear that changing
  a loot table mid-expedition WILL change the roll result for any not-yet-
  collected expedition. This is intentional (live-tuning friendly) but
  surprising.

### Neutral
- RabbitSystem gains an `is_on_expedition` field. This is a coupling point but
  ownership is clean (RabbitSystem owns the flag, ExpeditionSystem requests
  toggles).
- balance.json grows by an `expeditions` section (~80 lines for 5 zones).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Loot table edits invalidate in-flight loot determinism guarantees | MEDIUM | LOW | Document that loot tables are part of the live-tunable surface; re-rolls on table change are acceptable and expected. |
| Player clock manipulation grants infinite loot | MEDIUM | MEDIUM | Clamp `now - started_at` to `[0, duration * 2]` at resolve time. Long-term: SaveSystem already stores `last_save_timestamp`; reject `now < last_save_timestamp - 60s` as clock rewind. (Separate hardening ticket — not blocking.) |
| Rabbit deleted while on expedition (edge case via debug tools) | LOW | LOW | `collect()` filters `rabbit_ids` by existence before calling `RabbitSystem.return_from_expedition()`. Missing rabbits are silently skipped with a warning. |
| Save corruption produces malformed slot dict | LOW | MEDIUM | `_resolve_offline_expeditions()` validates each slot has the 7 required keys; malformed slots are logged and discarded. |
| Concurrent `collect()` calls (double-tap) double-grant loot | LOW | HIGH | First operation in `collect()` is to remove the slot from `active_expeditions`. Second call sees no slot and returns `{}`. |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|----------------|--------|
| Per-tick CPU | 0 | < 0.05 ms (5 slot comparisons) | 16.6 ms frame |
| Boot-time offline resolve | 0 | < 5 ms for 5 slots | 2 s cold boot |
| GameState save size | baseline | +~1 KB (5 slots × ~200 bytes) | 256 MB RAM |
| Draw calls | 0 | 0 (no rendering owned by system) | < 50 |
| Allocations per `collect()` | n/a | 1 RNG instance + rewards Dictionary | n/a |

## Migration Plan

1. Add `expeditions` section to `assets/data/balance.json` with the 5 zones and
   their loot tables. Loot tables are placeholder values pending designer pass —
   ExpeditionSystem must work with any well-formed table.
2. Add the three new signals to `EventBus.gd`.
3. Create `src/core/expedition_system.gd` and register as autoload after
   `EconomyManager`.
4. Extend `RabbitSystem` with `is_on_expedition: bool` on rabbit data,
   `send_on_expedition(rabbit_id, slot_id)`, and `return_from_expedition(rabbit_id)`.
   Update breeding-eligibility and expedition-eligibility checks to consult this
   flag.
5. Implement `_resolve_offline_expeditions()` first; gate behind a unit test
   that mocks `Time.get_unix_time_from_system()`.
6. Implement `start_expedition()`, then `_on_tick()`, then `collect()` in that
   order — each with a passing unit test before the next.
7. Update `tr-registry.yaml` to mark TR-expedition-001 as `status: active`
   (performed by `/architecture-review`, not by this ADR's author).
8. SaveSystem requires no changes — `active_expeditions` is already part of
   GameState's serialised state.

## Validation Criteria

- [ ] Unit: `start_expedition()` returns false and mutates nothing when zone min_rabbits is unmet.
- [ ] Unit: `start_expedition()` returns false when any rabbit is already on another expedition.
- [ ] Unit: `start_expedition()` returns false when zone has `required_trait` and any rabbit lacks it.
- [ ] Unit: `start_expedition()` returns false when zone has `requires_prestige` above current prestige_count.
- [ ] Unit: `_roll_loot(zone_id, seed)` returns identical Dictionary on repeated calls (determinism).
- [ ] Unit: `_on_tick()` flips status to "completed" exactly when `now >= started_at + duration`, not before.
- [ ] Unit: `_on_tick()` emits `expedition_ready_to_collect` exactly once per slot transition.
- [ ] Unit: `collect()` on an in_progress slot returns `{}` and does not mutate state.
- [ ] Unit: `collect()` on a completed slot grants rewards via EconomyManager and removes the slot.
- [ ] Unit: Double `collect()` on the same slot_id grants rewards exactly once.
- [ ] Integration: Save → quit → wait (mocked clock advance past duration) → load → slot status is "completed", loot not yet granted, signal fired once.
- [ ] Integration: Offline catch-up across 3 simultaneous expeditions with staggered durations resolves all correctly in one boot pass.
- [ ] Integration: Rabbits sent on expedition cannot be selected for breeding until returned.

## GDD Requirements Addressed

| GDD Req ID | GDD Section | Requirement | How This ADR Addresses It |
|------------|-------------|-------------|---------------------------|
| GDD-3.6.1 | §3.6 Expeditions | Five zones with durations 30 min – 48 h | Zone definitions externalised in `balance.json` under `expeditions.zones`; durations stored as Unix-second offsets per slot. |
| GDD-3.6.2 | §3.6 Expeditions | Rabbits sent on expedition are unavailable | RabbitSystem `is_on_expedition` flag set by `send_on_expedition()`, consulted by breeding eligibility. |
| GDD-3.6.3 | §3.6 Expeditions | Loot is granted on return / collect | `collect()` rolls loot from `loot_seed` and grants via `EconomyManager.add()`. |
| GDD-3.6.4 | §3.6 Expeditions | Expeditions continue while game is closed | Unix-timestamp model + `_resolve_offline_expeditions()` at boot. |
| GDD-3.6.5 | §3.6 Expeditions | Snow Mountain requires Sturdy trait | Zone `required_trait` field validated in `_validate_requirements()`. |
| GDD-3.6.6 | §3.6 Expeditions | Rabbit Universe unlocked after Prestige 1 | Zone `requires_prestige` field validated against `GameState.prestige_count`. |
| GDD-3.6.7 | §3.6 Expeditions | Player must actively collect (no auto-grant) | `_on_tick()` and `_resolve_offline_expeditions()` only set status to "completed"; rewards remain unowned until `collect()` is called. |
