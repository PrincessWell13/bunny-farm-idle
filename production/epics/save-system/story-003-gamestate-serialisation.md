# Story 003: GameState Serialise/Deserialise Round-Trip

> **Epic**: SaveSystem
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Blocked Reason

**BLOCKED: ADR-0005 is Proposed AND ADR-0008 is Proposed.**

- ADR-0005 defines `_rabbit_to_dict()` / `_dict_to_rabbit()` field-by-field serialisation contract. Until Accepted, the `RabbitData` schema may change.
- ADR-0008 defines `_serialise_game_state()` and `_populate_game_state()` structure and the full JSON schema.

Both must be Accepted before this story can be implemented.

---

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-save-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (boot sequence), ADR-0005 (RabbitData serialisation), ADR-0008 (save format + GameState mapping)
**ADR Decision Summary**: `_serialise_game_state()` produces the full JSON schema defined in ADR-0008. `_populate_game_state()` is the inverse: it reads the schema and writes to GameState fields. `_rabbit_to_dict()` / `_dict_to_rabbit()` follow the explicit field mapping from ADR-0005. `TimeManager.mark_session_start(last_save_timestamp)` and `TimeManager.set_game_epoch(epoch)` are called after `_populate_game_state()`.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `JSON.stringify()` / `JSON.parse_string()` are stable. `Resource` properties are NOT auto-serialised by Godot's JSON class — `_rabbit_to_dict()` must iterate typed fields explicitly (per ADR-0005 warning).

**Control Manifest Rules (Foundation layer)**:
- Required: `mark_dirty()` must be called after `_populate_game_state()` resets GameState
- Forbidden: direct `is_dirty = true` assignment except in `save_game()` where it is reset to `false`

---

## Acceptance Criteria

*From ADR-0008 Save Format + ADR-0005 Serialisation Contract:*

- [ ] `func _serialise_game_state() -> Dictionary` exists; returns full save schema as per ADR-0008
- [ ] Serialised dict includes: `last_save_timestamp`, `prestige_count`, `rabbits` (array), `hutches` (array), `collection_registry`, `active_expeditions`, `economy` (dict), `settings` (dict)
- [ ] `func _populate_game_state(data: Dictionary) -> void` exists; writes all schema fields to GameState
- [ ] `_populate_game_state({})` (first boot / empty data) sets GameState to defaults without crash
- [ ] `func _rabbit_to_dict(rabbit: RabbitData) -> Dictionary` exists; serialises all 15 RabbitData fields per ADR-0005 schema
- [ ] `func _dict_to_rabbit(d: Dictionary) -> RabbitData` exists; reconstructs all 15 fields
- [ ] After `_populate_game_state()`, `TimeManager.mark_session_start(data["last_save_timestamp"])` is called
- [ ] After `_populate_game_state()`, `TimeManager.set_game_epoch(data.get("game_epoch", now))` is called
- [ ] GdUnit4 integration: round-trip — serialise GameState with 2 test rabbits → write → read → populate → both rabbits present with correct field values
- [ ] GdUnit4: `_populate_game_state({})` → GameState fields are defaults, no crash

---

## Implementation Notes

*Derived from ADR-0008 Save Format and ADR-0005 Serialisation Contract:*

### _serialise_game_state()

Returns the full save schema from ADR-0008:
```gdscript
func _serialise_game_state() -> Dictionary:
    return {
        "last_save_timestamp": GameState.last_save_timestamp,
        "prestige_count": GameState.prestige_count,
        "rabbits": GameState.rabbits.map(func(r) -> Dictionary: return _rabbit_to_dict(r)),
        "hutches": GameState.hutches.map(func(h) -> Dictionary: return _hutch_to_dict(h)),
        "collection_registry": GameState.collection_registry.duplicate(),
        "active_expeditions": GameState.active_expeditions.duplicate(),
        "economy": _serialise_economy(),
        "settings": GameState.settings.duplicate(),
    }
```

### _populate_game_state()

Reads schema and writes to GameState. Safe defaults via `.get(key, default)`:
```gdscript
func _populate_game_state(data: Dictionary) -> void:
    GameState.prestige_count = data.get("prestige_count", 0)
    GameState.collection_registry = data.get("collection_registry", {})
    GameState.active_expeditions = data.get("active_expeditions", [])
    GameState.settings = data.get("settings", GameState.settings)
    GameState.last_save_timestamp = data.get("last_save_timestamp", 0)
    var raw_rabbits: Array = data.get("rabbits", [])
    GameState.rabbits = raw_rabbits.map(func(d) -> RabbitData: return _dict_to_rabbit(d))
    # hutches: deferred until HabitatSystem epic defines HutchData
    _populate_economy(data.get("economy", {}))
    GameState.mark_dirty()
    TimeManager.mark_session_start(GameState.last_save_timestamp)
    TimeManager.set_game_epoch(data.get("game_epoch", int(Time.get_unix_time_from_system())))
```

### _rabbit_to_dict() / _dict_to_rabbit()

Full 15-field mapping from ADR-0005. Do not use `inst_to_dict()` — Resource properties are not auto-included.

### HutchData serialisation

`_hutch_to_dict()` / `_dict_to_hutch()` are forward-referenced with empty implementations until HabitatSystem epic defines `HutchData`. Use `Array` (untyped) for `hutches` field in this story.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `FirebaseAdapter` + `MockFirebaseAdapter`
- Story 002: `_load_local()` / `_write_local()` — this story calls them but does not implement them
- Story 004: `_resolve_conflict()` — this story receives already-resolved data
- Story 005: `_ready()` boot wiring — this story's methods are called by story 005

---

## QA Test Cases

**AC-1 (round-trip: two rabbits preserved)**:
- Given: GameState with 2 `RabbitData` instances (`rabbit_id: "r1"`, `rabbit_id: "r2"`); `MockFirebaseAdapter` injected
- When: `_serialise_game_state()` called → result passed to `_populate_game_state()`
- Then: `GameState.rabbits.size() == 2`; first rabbit's `rabbit_id == "r1"`
- Edge cases: empty rabbits array → round-trip produces empty array

**AC-2 (empty data → defaults)**:
- Given: GameState with defaults; `_populate_game_state({})` called
- Then: no crash; `GameState.prestige_count == 0`; `GameState.rabbits.size() == 0`

**AC-3 (prestige_count preserved)**:
- Given: `GameState.prestige_count = 5`
- When: serialise → populate
- Then: `GameState.prestige_count == 5`

**AC-4 (mark_dirty called after populate)**:
- Given: `GameState.is_dirty == false` before `_populate_game_state()`
- When: `_populate_game_state({})` called
- Then: `GameState.is_dirty == true`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/save_system_round_trip_test.gd` — must exist and pass

```
tests/integration/core/save_system_round_trip_test.gd
  test_round_trip_preserves_two_rabbits()
  test_round_trip_preserves_empty_rabbit_array()
  test_round_trip_preserves_prestige_count()
  test_round_trip_preserves_collection_registry()
  test_populate_with_empty_dict_uses_defaults_no_crash()
  test_populate_calls_mark_dirty()
```

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **Story 001 DONE** + **Story 002 DONE** + **ADR-0005 Accepted** + **ADR-0008 Accepted**
- Unlocks: Story 005 (boot sequence calls `_populate_game_state()`)

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 10/10 passing
**Deviations**: None. _gs()/_tm() injectable helpers added for test isolation — consistent with existing _firebase injection pattern.
**Test Evidence**: Integration — `tests/integration/core/save_system_round_trip_test.gd` (6 test functions)
**Code Review**: Skipped — Lean mode
