# Story 001: start_expedition — Slot Model and Rabbit Locking

> **Epic**: ExpeditionSystem
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.6 — Hệ thống Expedition)
**Requirement**: `TR-expedition-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0011 Accepted ✅

**ADR Governing Implementation**: ADR-0011 (ExpeditionSystem Async Timer with Unix Timestamp Storage)
**ADR Decision Summary**: `start_expedition(zone_id, rabbit_ids)` validates zone requirements and rabbit availability, creates a slot dictionary with `started_at = Time.get_unix_time_from_system()`, pre-rolls `loot_seed = randi()`, appends the slot to `GameState.active_expeditions`, and calls `RabbitSystem.send_on_expedition(rabbit_id, slot_id)` for each assigned rabbit. All zone definitions and requirements are read from `balance.json` under the `expeditions` key. On any validation failure the function returns `false` and mutates nothing.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Time.get_unix_time_from_system()` and `RandomNumberGenerator` are stable since Godot 4.0 — no post-cutoff APIs required. `randi()` is the global-scope shorthand for a default RNG; the loot seed is stored as `int` (fits a 32-bit random value). `call_deferred` used in `_ready()` for offline resolution is standard Godot pattern.

**Control Manifest Rules (Feature layer)**:
- Required: statically typed parameters and return types on all public methods (F-02)
- Required: all zone definitions, durations, and loot weights loaded from `balance.json` at `_ready()` via `_load_balance_data()` (F-04)
- Required: cross-system communication only via EventBus signals (F-03)
- Required: ExpeditionSystem must NOT write `RabbitData` fields directly — call `RabbitSystem.send_on_expedition()` which owns the `is_on_expedition` flag (C-01)
- Required: emit signals only AFTER state change is complete (F-03)
- Required: new autoload registered in `project.godot` after `EconomyManager`, before `RabbitSystem` — per ADR-0011 ordering note
- Forbidden: hardcoded zone IDs, durations, or loot weights in `expedition_system.gd` (F-04)
- Forbidden: direct mutation of `GameState.active_expeditions` from outside `ExpeditionSystem`
- Forbidden: `ExpeditionSystem` writing to any `RabbitData` field (C-01)

**Prerequisite**: `assets/data/balance.json` must have an `expeditions` section before implementing this story. Add the section first. Required shape:

```json
"expeditions": {
  "zones": [
    {
      "zone_id": "near_forest",
      "display_name": "Rừng Gần",
      "duration_seconds": 1800,
      "min_rabbits": 1,
      "max_rabbits": 5,
      "required_trait": null,
      "requires_prestige": 0,
      "loot_table": [
        { "item_id": "star_grass", "weight": 60, "quantity_min": 1, "quantity_max": 3 },
        { "item_id": "herb", "weight": 40, "quantity_min": 1, "quantity_max": 2 }
      ]
    },
    {
      "zone_id": "east_meadow",
      "display_name": "Đồng Cỏ Phía Đông",
      "duration_seconds": 7200,
      "min_rabbits": 2,
      "max_rabbits": 5,
      "required_trait": null,
      "requires_prestige": 0,
      "loot_table": [
        { "item_id": "special_carrot", "weight": 50, "quantity_min": 1, "quantity_max": 2 },
        { "item_id": "coin_bag_x3", "weight": 50, "quantity_min": 1, "quantity_max": 1 }
      ]
    },
    {
      "zone_id": "snow_mountain",
      "display_name": "Núi Tuyết",
      "duration_seconds": 28800,
      "min_rabbits": 3,
      "max_rabbits": 5,
      "required_trait": "Sturdy",
      "requires_prestige": 0,
      "loot_table": [
        { "item_id": "mystery_mushroom", "weight": 60, "quantity_min": 1, "quantity_max": 1 },
        { "item_id": "blueprint", "weight": 40, "quantity_min": 1, "quantity_max": 1 }
      ]
    },
    {
      "zone_id": "ancient_lands",
      "display_name": "Vùng Đất Cổ",
      "duration_seconds": 86400,
      "min_rabbits": 5,
      "max_rabbits": 5,
      "required_trait": null,
      "requires_prestige": 0,
      "loot_table": [
        { "item_id": "golden_apple", "weight": 60, "quantity_min": 1, "quantity_max": 1 },
        { "item_id": "legendary_shard", "weight": 40, "quantity_min": 1, "quantity_max": 1 }
      ]
    },
    {
      "zone_id": "rabbit_universe",
      "display_name": "Vũ trụ Thỏ",
      "duration_seconds": 172800,
      "min_rabbits": 1,
      "max_rabbits": 5,
      "required_trait": null,
      "requires_prestige": 1,
      "loot_table": [
        { "item_id": "cosmic_gene", "weight": 50, "quantity_min": 1, "quantity_max": 1 },
        { "item_id": "ultra_shard", "weight": 50, "quantity_min": 1, "quantity_max": 1 }
      ]
    }
  ]
}
```

---

## Acceptance Criteria

1. `start_expedition(zone_id: String, rabbit_ids: Array[String]) -> bool` returns `false` and mutates nothing when `zone_id` does not exist in the `expeditions.zones` array in `balance.json`
2. `start_expedition()` returns `false` and mutates nothing when `rabbit_ids.size() < zone.min_rabbits`
3. `start_expedition()` returns `false` and mutates nothing when any `rabbit_id` in `rabbit_ids` does not resolve to a known rabbit via `RabbitSystem.get_rabbit()`
4. `start_expedition()` returns `false` and mutates nothing when any rabbit's `life_stage` is not `"Adult"`
5. `start_expedition()` returns `false` and mutates nothing when any rabbit has `is_on_expedition == true`
6. `start_expedition()` returns `false` and mutates nothing when the zone has a non-null `required_trait` and any rabbit lacks that trait in its genotype
7. `start_expedition()` returns `false` and mutates nothing when the zone has `requires_prestige > 0` and `GameState.prestige_count` is below that value
8. On all validation passes, `start_expedition()` appends exactly one slot dictionary to `GameState.active_expeditions` with keys: `slot_id`, `zone_id`, `rabbit_ids`, `started_at`, `duration`, `loot_seed`, `status`
9. The appended slot has `status == "in_progress"`, `started_at` equal to `Time.get_unix_time_from_system()` at call time (within ±1 second tolerance in tests), `duration` equal to the zone's `duration_seconds` from `balance.json`, and `loot_seed` as a non-zero int
10. `start_expedition()` calls `RabbitSystem.send_on_expedition(rabbit_id, slot_id)` for every rabbit ID in `rabbit_ids` after appending the slot
11. `start_expedition()` emits `EventBus.expedition_started(slot_id, zone_id)` exactly once after all state mutations are complete
12. `start_expedition()` returns `true` on a fully valid call

---

## Implementation Notes

*Derived from ADR-0011 Implementation Guidelines:*

### ExpeditionSystem autoload skeleton

```gdscript
# src/core/expedition_system.gd
extends Node

# Slot key constants — prevents typo drift across the system
const KEY_SLOT_ID := "slot_id"
const KEY_ZONE_ID := "zone_id"
const KEY_RABBIT_IDS := "rabbit_ids"
const KEY_STARTED_AT := "started_at"
const KEY_DURATION := "duration"
const KEY_LOOT_SEED := "loot_seed"
const KEY_STATUS := "status"
const STATUS_IN_PROGRESS := "in_progress"
const STATUS_COMPLETED := "completed"

var _zone_defs: Dictionary = {}  # zone_id -> zone dict

func _ready() -> void:
    _load_balance_data()
    TimeManager.tick.connect(_on_tick)
    call_deferred("_resolve_offline_expeditions")

func _load_balance_data() -> void:
    var file := FileAccess.open("res://assets/data/balance.json", FileAccess.READ)
    var data: Dictionary = JSON.parse_string(file.get_as_text())
    file.close()
    for zone: Dictionary in data["expeditions"]["zones"]:
        _zone_defs[zone["zone_id"]] = zone
```

### start_expedition implementation

```gdscript
func start_expedition(zone_id: String, rabbit_ids: Array[String]) -> bool:
    if not _validate_requirements(zone_id, rabbit_ids):
        return false

    var zone: Dictionary = _zone_defs[zone_id]
    var slot_id: String = "exp_" + str(Time.get_unix_time_from_system()).md5_text().substr(0, 12)

    var slot: Dictionary = {
        KEY_SLOT_ID: slot_id,
        KEY_ZONE_ID: zone_id,
        KEY_RABBIT_IDS: rabbit_ids.duplicate(),
        KEY_STARTED_AT: Time.get_unix_time_from_system(),
        KEY_DURATION: float(zone["duration_seconds"]),
        KEY_LOOT_SEED: randi(),
        KEY_STATUS: STATUS_IN_PROGRESS
    }

    GameState.active_expeditions.append(slot)

    for rabbit_id: String in rabbit_ids:
        RabbitSystem.send_on_expedition(rabbit_id, slot_id)

    EventBus.expedition_started.emit(slot_id, zone_id)
    return true
```

### _validate_requirements implementation

```gdscript
func _validate_requirements(zone_id: String, rabbit_ids: Array[String]) -> bool:
    if not _zone_defs.has(zone_id):
        return false

    var zone: Dictionary = _zone_defs[zone_id]

    if rabbit_ids.size() < int(zone["min_rabbits"]):
        return false

    var required_prestige: int = int(zone.get("requires_prestige", 0))
    if required_prestige > 0 and GameState.prestige_count < required_prestige:
        return false

    var required_trait: String = str(zone.get("required_trait", ""))

    for rabbit_id: String in rabbit_ids:
        var rabbit: RabbitData = RabbitSystem.get_rabbit(rabbit_id)
        if rabbit == null:
            return false
        if rabbit.life_stage != "Adult":
            return false
        if rabbit.is_on_expedition:
            return false
        if required_trait != "" and required_trait != "null":
            # Check both trait slots in the genotype
            var has_trait: bool = false
            for locus: String in ["trait1", "trait2"]:
                if rabbit.genotype.get(locus, {}).get("dominant", "") == required_trait:
                    has_trait = true
                    break
            if not has_trait:
                return false

    return true
```

### RabbitSystem stubs required by this story

This story requires the following methods to exist on `RabbitSystem`. They may be stubs initially:

```gdscript
# In src/core/rabbit_system.gd — add these if not present:
func send_on_expedition(rabbit_id: String, slot_id: String) -> void:
    var rabbit: RabbitData = get_rabbit(rabbit_id)
    if rabbit == null:
        push_warning("RabbitSystem.send_on_expedition: unknown rabbit '%s'" % rabbit_id)
        return
    rabbit.is_on_expedition = true
    # expedition_slot_id may be added to RabbitData if needed for UI display

func get_rabbit(rabbit_id: String) -> RabbitData:
    return GameState.rabbits.get(rabbit_id, null)
```

### EventBus signals to add

Add these three signals to `src/core/event_bus.gd`:

```gdscript
signal expedition_started(slot_id: String, zone_id: String)
signal expedition_completed(slot_id: String, zone_id: String)
signal expedition_collected(slot_id: String, rewards: Dictionary)
```

Also add the three signals named in ADR-0011 (for UI layer consumption):

```gdscript
signal rabbit_sent_on_expedition(slot_id: String, zone_id: String, rabbit_ids: Array)
signal rabbit_returned_from_expedition(slot_id: String, zone_id: String, rabbit_ids: Array)
signal expedition_ready_to_collect(slot_id: String, zone_id: String)
```

Note: the existing Control Manifest signal registry (`rabbit_sent_on_expedition(rabbit: RabbitData, location: String)`) uses a different signature. The ADR-0011 signals use slot-level parameters instead. Both sets may coexist — the existing signal covers individual rabbit tracking; the new set covers slot-level expedition state. Confirm with technical-director if the old signal should be superseded.

---

## Out of Scope

- `collect()` and loot resolution — covered in story-002
- Offline catch-up pass — covered in story-003
- `_on_tick()` slot completion detection — covered in story-002 (tick polling is needed to drive status to "completed", which collect() reads)
- UI for zone selection or expedition slot display — UI layer stories
- RabbitSystem `is_breeding` guard in `_validate_requirements` — the breeding flag check ("cannot be sent on expedition if currently breeding") is a follow-up hardening ticket; the `is_on_expedition` guard is sufficient for MVP

---

## QA Test Cases

- **AC-1**: invalid zone_id returns false without state mutation
  - Given: `GameState.active_expeditions = []`; valid adult rabbits exist
  - When: `ExpeditionSystem.start_expedition("unknown_zone", ["r-001"])`
  - Then: returns `false`; `active_expeditions.size() == 0`; no EventBus signal emitted

- **AC-2**: too few rabbits returns false
  - Given: zone "east_meadow" requires min 2 rabbits
  - When: `start_expedition("east_meadow", ["r-001"])` (only 1 rabbit)
  - Then: returns `false`; `active_expeditions.size() == 0`

- **AC-3**: unknown rabbit_id returns false
  - Given: `RabbitSystem.get_rabbit("phantom")` returns null
  - When: `start_expedition("near_forest", ["phantom"])`
  - Then: returns `false`; no slot appended

- **AC-4**: non-Adult rabbit returns false
  - Given: rabbit "r-001" has `life_stage == "Baby"`
  - When: `start_expedition("near_forest", ["r-001"])`
  - Then: returns `false`; rabbit `is_on_expedition` unchanged

- **AC-5**: already-on-expedition rabbit returns false
  - Given: rabbit "r-001" has `is_on_expedition == true`
  - When: `start_expedition("near_forest", ["r-001"])`
  - Then: returns `false`; no new slot appended

- **AC-6**: missing required trait returns false
  - Given: zone "snow_mountain" requires `required_trait == "Sturdy"`; rabbit lacks it
  - When: `start_expedition("snow_mountain", ["r-001", "r-002", "r-003"])`
  - Then: returns `false`; no slot appended

- **AC-7**: prestige gate returns false
  - Given: zone "rabbit_universe" has `requires_prestige == 1`; `GameState.prestige_count == 0`
  - When: `start_expedition("rabbit_universe", ["r-001"])`
  - Then: returns `false`

- **AC-8**: valid call appends correct slot structure
  - Given: zone "near_forest"; rabbit "r-001" is Adult, not on expedition
  - When: `start_expedition("near_forest", ["r-001"])`
  - Then: returns `true`; `active_expeditions.size() == 1`; slot has all 7 required keys; `status == "in_progress"`; `duration == 1800.0`; `loot_seed != 0`

- **AC-9**: valid call locks rabbit
  - Given: as above
  - When: `start_expedition("near_forest", ["r-001"])`
  - Then: `RabbitSystem.get_rabbit("r-001").is_on_expedition == true`

- **AC-10**: valid call emits expedition_started signal once
  - Given: EventBus signal spy attached to `expedition_started`
  - When: `start_expedition("near_forest", ["r-001"])`
  - Then: signal emitted exactly once with matching `slot_id` and `zone_id`

- **AC-11 / AC-12**: returns true on success (implicit in AC-8)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/expedition_system_start_test.gd` — must exist and pass

**Status**: [ ] `tests/unit/core/expedition_system_start_test.gd` — not yet written

---

## Dependencies

- No expedition story dependencies
- Requires: `RabbitSystem.get_rabbit(rabbit_id)`, `RabbitSystem.send_on_expedition(rabbit_id, slot_id)` — stubs acceptable at story time, must be real implementations before Integration test gate
- Requires: `balance.json` `expeditions` section added (prerequisite — see Context section above)
- Requires: EventBus signals `expedition_started`, `expedition_completed`, `expedition_collected`, `expedition_ready_to_collect` added to `src/core/event_bus.gd`
- Requires: `ExpeditionSystem` registered as autoload in `project.godot` after `EconomyManager` (ADR-0011 ordering)
- Unlocks: story-002 (collect depends on slots created here)

---

## Completion Notes

**Completed**: —
**Criteria**: /12 passing
**Deviations**: —
**Test Evidence**: —
**Code Review**: —
