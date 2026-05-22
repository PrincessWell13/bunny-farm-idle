# Story 002: collect — Loot Roll and Rabbit Unlock

> **Epic**: ExpeditionSystem
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.6 — Hệ thống Expedition)
**Requirement**: `TR-expedition-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0011 Accepted ✅

**ADR Governing Implementation**: ADR-0011 (ExpeditionSystem Async Timer with Unix Timestamp Storage)
**ADR Decision Summary**: `collect(slot_id)` resolves loot by instantiating a fresh `RandomNumberGenerator`, seeding it with the slot's pre-rolled `loot_seed`, and weighted-sampling the zone's `loot_table` from `balance.json`. The slot is REMOVED from `GameState.active_expeditions` BEFORE emitting rewards — this is the double-collect guard. After removal, `EconomyManager.add()` grants each reward item, and `RabbitSystem.return_from_expedition(rabbit_id)` is called for every rabbit in the slot. `collect()` returns `{}` (empty dict) and logs a warning if called on an `in_progress` slot. `_on_tick()` detects elapsed duration and flips status to `"completed"` exactly once, emitting `EventBus.expedition_ready_to_collect`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RandomNumberGenerator` with explicit `.seed` assignment is stable since Godot 4.0. `rng.randi_range(min, max)` for quantity rolls. No post-cutoff APIs required. `_on_tick` subscribes to `TimeManager.tick` signal using callable syntax.

**Control Manifest Rules (Feature layer)**:
- Required: statically typed parameters and return types on all public methods (F-02)
- Required: loot table weights and item definitions loaded from `balance.json` (F-04)
- Required: cross-system communication only via EventBus signals; `collect()` grants rewards by calling `EconomyManager.add()` — this is an explicit boot-order exception per ADR-0011 (F-03)
- Required: emit signals only AFTER state change is complete; slot must be removed BEFORE rewards signal (F-03)
- Required: `collect()` must call `RabbitSystem.return_from_expedition(rabbit_id)` — ExpeditionSystem never writes RabbitData directly (C-01)
- Forbidden: calling `collect()` from `_on_tick()` or `_resolve_offline_expeditions()` — player must tap
- Forbidden: hardcoded loot item IDs or weights in `expedition_system.gd` (F-04)
- Forbidden: emitting `expedition_ready_to_collect` more than once per slot transition (status field is the latch)

---

## Acceptance Criteria

1. `collect(slot_id: String) -> Dictionary` returns `{}` and logs a warning (via `push_warning`) when `slot_id` does not exist in `GameState.active_expeditions`
2. `collect()` returns `{}` and does not mutate any state when the resolved slot has `status == "in_progress"`
3. `collect()` removes the slot from `GameState.active_expeditions` as its FIRST mutation before any reward or signal emission
4. After slot removal, `collect()` calls `EconomyManager.add(item_id, quantity)` for each item in the loot roll result
5. After granting rewards, `collect()` calls `RabbitSystem.return_from_expedition(rabbit_id)` for every `rabbit_id` in the removed slot's `rabbit_ids` array
6. `collect()` emits `EventBus.expedition_collected(slot_id, rewards_dict)` once after all mutations are complete
7. `collect()` returns the rewards dictionary (non-empty for a valid completed slot)
8. Calling `collect()` twice with the same `slot_id` grants rewards exactly once — the second call returns `{}` because the slot is already removed (double-collect guard)
9. `_roll_loot(zone_id, loot_seed)` returns an identical rewards dictionary on repeated calls with the same inputs (determinism requirement from ADR-0011 R3)
10. `_on_tick(_delta: float)` flips a slot from `"in_progress"` to `"completed"` when `Time.get_unix_time_from_system() >= slot.started_at + slot.duration`
11. `_on_tick()` emits `EventBus.expedition_ready_to_collect(slot_id, zone_id)` exactly once per slot on the tick where status is first flipped to `"completed"` — subsequent ticks for the same completed slot emit nothing
12. A slot with `status == "completed"` persists in `GameState.active_expeditions` until `collect()` is called — it is not removed by `_on_tick()`

---

## Implementation Notes

*Derived from ADR-0011 Implementation Guidelines:*

### collect implementation

```gdscript
func collect(slot_id: String) -> Dictionary:
    # Find the slot index
    var slot_index: int = -1
    for i: int in range(GameState.active_expeditions.size()):
        if GameState.active_expeditions[i][KEY_SLOT_ID] == slot_id:
            slot_index = i
            break

    if slot_index == -1:
        push_warning("ExpeditionSystem.collect: slot_id '%s' not found" % slot_id)
        return {}

    var slot: Dictionary = GameState.active_expeditions[slot_index]

    if slot[KEY_STATUS] != STATUS_COMPLETED:
        push_warning("ExpeditionSystem.collect: slot '%s' is still in_progress" % slot_id)
        return {}

    # CRITICAL: remove slot FIRST — double-collect guard
    GameState.active_expeditions.remove_at(slot_index)

    # Roll loot using the pre-stored seed
    var rewards: Dictionary = _roll_loot(slot[KEY_ZONE_ID], slot[KEY_LOOT_SEED])

    # Grant rewards via EconomyManager
    for item_id: String in rewards:
        EconomyManager.add(item_id, rewards[item_id])

    # Unlock rabbits
    for rabbit_id: String in slot[KEY_RABBIT_IDS]:
        if RabbitSystem.get_rabbit(rabbit_id) != null:
            RabbitSystem.return_from_expedition(rabbit_id)
        else:
            push_warning("ExpeditionSystem.collect: rabbit '%s' missing at return" % rabbit_id)

    EventBus.expedition_collected.emit(slot_id, rewards)
    return rewards
```

### _roll_loot implementation

```gdscript
func _roll_loot(zone_id: String, loot_seed: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = loot_seed

    var zone: Dictionary = _zone_defs[zone_id]
    var loot_table: Array = zone["loot_table"]

    # Weighted selection
    var total_weight: int = 0
    for entry: Dictionary in loot_table:
        total_weight += int(entry["weight"])

    var roll: int = rng.randi_range(0, total_weight - 1)
    var cumulative: int = 0
    var selected: Dictionary = loot_table[0]
    for entry: Dictionary in loot_table:
        cumulative += int(entry["weight"])
        if roll < cumulative:
            selected = entry
            break

    var quantity: int = rng.randi_range(int(selected["quantity_min"]), int(selected["quantity_max"]))

    return { str(selected["item_id"]): quantity }
```

### _on_tick implementation

```gdscript
func _on_tick(_delta: float) -> void:
    var now: float = Time.get_unix_time_from_system()
    for slot: Dictionary in GameState.active_expeditions:
        if slot[KEY_STATUS] == STATUS_IN_PROGRESS:
            if now >= slot[KEY_STARTED_AT] + slot[KEY_DURATION]:
                slot[KEY_STATUS] = STATUS_COMPLETED
                EventBus.expedition_ready_to_collect.emit(slot[KEY_SLOT_ID], slot[KEY_ZONE_ID])
```

### RabbitSystem stubs required by this story

```gdscript
# In src/core/rabbit_system.gd — add if not present:
func return_from_expedition(rabbit_id: String) -> void:
    var rabbit: RabbitData = get_rabbit(rabbit_id)
    if rabbit == null:
        push_warning("RabbitSystem.return_from_expedition: unknown rabbit '%s'" % rabbit_id)
        return
    rabbit.is_on_expedition = false
```

### EconomyManager.add interface expected

`EconomyManager.add(item_id: String, quantity: int) -> void` — adds the given quantity of `item_id` to the player's inventory or currency balance. If this method does not yet exist with this exact signature, stub it before implementing this story.

---

## Out of Scope

- Offline catch-up (marking slots completed at boot) — covered in story-003
- UI showing "Ready to collect" badge — UI layer story
- Multi-item loot rolls (current design picks exactly one item per expedition) — future enhancement if desired
- `EconomyManager.add()` implementation — owned by economy-system epic
- Tick-rate configuration (how often `TimeManager.tick` fires) — owned by TimeManager / ADR-0007

---

## QA Test Cases

- **AC-1**: unknown slot_id returns empty dict
  - Given: `GameState.active_expeditions = []`
  - When: `ExpeditionSystem.collect("unknown-slot")`
  - Then: returns `{}`; `push_warning` called; no EconomyManager or RabbitSystem calls

- **AC-2**: in_progress slot returns empty dict
  - Given: slot exists with `status == "in_progress"`
  - When: `collect(slot_id)`
  - Then: returns `{}`; slot still present in `active_expeditions`

- **AC-3**: slot removed before rewards emitted
  - Given: completed slot; spy on `active_expeditions.size()` within `EventBus.expedition_collected` handler
  - When: `collect(slot_id)`
  - Then: at the point the signal fires, `active_expeditions` no longer contains the slot

- **AC-4**: rewards granted via EconomyManager
  - Given: completed slot for zone "near_forest"; loot_seed produces "star_grass" × 2 (verifiable by running `_roll_loot` with same seed)
  - When: `collect(slot_id)`
  - Then: `EconomyManager.add("star_grass", 2)` called exactly once

- **AC-5**: rabbits unlocked after collect
  - Given: slot with `rabbit_ids: ["r-001", "r-002"]`; both rabbits have `is_on_expedition == true`
  - When: `collect(slot_id)`
  - Then: `RabbitSystem.return_from_expedition` called for both; `get_rabbit("r-001").is_on_expedition == false`

- **AC-6**: expedition_collected emitted with correct payload
  - Given: completed slot; EventBus signal spy
  - When: `collect(slot_id)`
  - Then: `expedition_collected` emitted once; payload `slot_id` matches; `rewards` dict is non-empty

- **AC-7**: returns non-empty dict on success (implicit from AC-6)

- **AC-8**: double-collect guard
  - Given: completed slot
  - When: `collect(slot_id)` called twice in succession
  - Then: first call returns non-empty dict; second call returns `{}`; `EconomyManager.add` called only once total

- **AC-9**: _roll_loot determinism
  - Given: zone "near_forest"; `loot_seed = 8472619`
  - When: `_roll_loot("near_forest", 8472619)` called 3 times
  - Then: all three calls return identical dictionaries

- **AC-10**: _on_tick flips status at correct time
  - Given: slot with `started_at = T`, `duration = 100.0`; mock clock at `T + 99`
  - When: `_on_tick(0.0)` called
  - Then: `slot.status` still `"in_progress"`
  - When: clock advanced to `T + 100`; `_on_tick(0.0)` called again
  - Then: `slot.status == "completed"`; `expedition_ready_to_collect` emitted once

- **AC-11**: _on_tick emits signal exactly once per slot
  - Given: slot flipped to completed on tick N
  - When: `_on_tick(0.0)` called again on tick N+1
  - Then: `expedition_ready_to_collect` NOT emitted again (status already "completed", guard skips it)

- **AC-12**: completed slot persists until collect
  - Given: slot flipped to "completed" by _on_tick
  - When: player does NOT call collect
  - Then: slot remains in `active_expeditions` across save/load cycle

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/expedition_system_collect_test.gd` — must exist and pass

**Status**: [x] `tests/integration/core/expedition_system_collect_test.gd` — exists and passes (CI 2026-05-20)

---

## Dependencies

- Depends on: **story-001 must be DONE** — `collect()` reads slot dictionaries created by `start_expedition()`; `_on_tick()` polls the same `GameState.active_expeditions` array
- Requires: `RabbitSystem.return_from_expedition(rabbit_id)` method
- Requires: `EconomyManager.add(item_id, quantity)` method
- Requires: `TimeManager.tick` signal (ExpeditionSystem connects `_on_tick` to it in `_ready()`)
- Unlocks: story-003 (offline catch-up uses the same status-flip logic validated here)

---

## Completion Notes

**Completed**: 2026-05-20
**Criteria**: 12/12 passing
**Deviations**: None
**Test Evidence**: Integration — `tests/integration/core/expedition_system_collect_test.gd` (exists, CI 2026-05-20)
**Code Review**: Skipped — Lean mode
