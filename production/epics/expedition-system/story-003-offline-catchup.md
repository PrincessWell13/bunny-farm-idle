# Story 003: _resolve_offline_expeditions — Boot-Time Catch-Up

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
**ADR Decision Summary**: `_resolve_offline_expeditions()` is called via `call_deferred` in `_ready()`, guaranteeing SaveSystem has restored `GameState` before it runs. It walks `active_expeditions` once. For each slot with `status == "in_progress"` where `Time.get_unix_time_from_system() >= started_at + duration`, it sets `status = "completed"` and emits `EventBus.expedition_ready_to_collect`. It does NOT call `collect()` — the player must tap Collect. Malformed slots (missing required keys) are logged and discarded. This pattern mirrors ADR-0007 (IdleProduction offline catch-up) and ADR-0009 (FoodSystem plot offline resolution).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `call_deferred("_resolve_offline_expeditions")` defers the method to the end of the current frame, after all `_ready()` calls have completed. This is the same pattern used by FoodSystem (ADR-0009). `Time.get_unix_time_from_system()` at boot gives the real-world wall clock — no drift risk. No post-cutoff APIs required.

**Control Manifest Rules (Feature layer)**:
- Required: statically typed parameters and return types on all public methods (F-02)
- Required: `call_deferred` used for `_resolve_offline_expeditions()` in `_ready()` so SaveSystem has loaded GameState first (ADR-0011 boot ordering — F-01)
- Required: cross-system communication only via EventBus signals (F-03)
- Required: emit signals only AFTER state change is complete (F-03)
- Required: `_resolve_offline_expeditions()` must NOT call `collect()` — players must actively collect (GDD-3.6.7)
- Forbidden: auto-granting loot at boot time (GDD-3.6.7 explicit requirement: "Player must actively collect")
- Forbidden: calling `_resolve_offline_expeditions()` directly from `_ready()` without `call_deferred` — SaveSystem must have run first
- Forbidden: removing slots during the offline resolve pass — only status mutation and signal emission

---

## Acceptance Criteria

1. `_resolve_offline_expeditions()` is called via `call_deferred` in `ExpeditionSystem._ready()`, not directly — ensuring SaveSystem has restored `GameState.active_expeditions` before the pass runs
2. When called with an empty `GameState.active_expeditions`, the method completes without error and emits no signals
3. For each slot with `status == "in_progress"` where `now >= started_at + duration` (where `now = Time.get_unix_time_from_system()`), the slot's `status` is set to `"completed"` and `EventBus.expedition_ready_to_collect(slot_id, zone_id)` is emitted exactly once
4. Slots with `status == "in_progress"` where `now < started_at + duration` (not yet elapsed) are left untouched — `status` remains `"in_progress"` and no signal is emitted for those slots
5. Slots already at `status == "completed"` (completed in a previous session but not yet collected) are left untouched — no duplicate signal, no state mutation
6. Slots are NOT removed from `GameState.active_expeditions` during this pass — they remain for the player to collect via the `collect()` call
7. `_resolve_offline_expeditions()` does NOT call `collect()` on any slot — loot is not granted at boot
8. A slot missing any of the 7 required keys (`slot_id`, `zone_id`, `rabbit_ids`, `started_at`, `duration`, `loot_seed`, `status`) is logged via `push_warning` and removed from `active_expeditions` — it does not cause an unhandled error
9. After `_resolve_offline_expeditions()`, all previously-in-progress-now-elapsed slots have `status == "completed"` — a subsequent `collect()` call on each will succeed
10. Three simultaneous expeditions with staggered start times and durations are all resolved correctly in a single pass — no slot is missed, no slot is double-processed

---

## Implementation Notes

*Derived from ADR-0011 Implementation Guidelines:*

### _resolve_offline_expeditions implementation

```gdscript
func _resolve_offline_expeditions() -> void:
    var now: float = Time.get_unix_time_from_system()
    var required_keys: Array[String] = [
        KEY_SLOT_ID, KEY_ZONE_ID, KEY_RABBIT_IDS,
        KEY_STARTED_AT, KEY_DURATION, KEY_LOOT_SEED, KEY_STATUS
    ]

    # Iterate backwards to allow safe removal of malformed slots
    var i: int = GameState.active_expeditions.size() - 1
    while i >= 0:
        var slot: Dictionary = GameState.active_expeditions[i]

        # Validate slot has all required keys
        var is_valid: bool = true
        for key: String in required_keys:
            if not slot.has(key):
                push_warning("ExpeditionSystem: malformed slot at index %d missing key '%s' — discarding" % [i, key])
                is_valid = false
                break

        if not is_valid:
            GameState.active_expeditions.remove_at(i)
            i -= 1
            continue

        # Only process in_progress slots
        if slot[KEY_STATUS] == STATUS_IN_PROGRESS:
            var elapsed_end: float = float(slot[KEY_STARTED_AT]) + float(slot[KEY_DURATION])
            if now >= elapsed_end:
                slot[KEY_STATUS] = STATUS_COMPLETED
                EventBus.expedition_ready_to_collect.emit(
                    str(slot[KEY_SLOT_ID]),
                    str(slot[KEY_ZONE_ID])
                )

        i -= 1
```

### _ready connection (complete)

```gdscript
func _ready() -> void:
    _load_balance_data()
    TimeManager.tick.connect(_on_tick)
    call_deferred("_resolve_offline_expeditions")
```

### Testing approach for offline resolution

Unit tests must mock `Time.get_unix_time_from_system()` to avoid real-time dependency. GdUnit4 supports this via method replacement or injecting a callable. Example test setup:

```gdscript
# In the test file, inject fake time by temporarily patching the system
# OR pass `now` as a parameter to a testable internal helper:

# Recommended: extract a testable helper that accepts `now` explicitly
func _resolve_offline_expeditions_at(now: float) -> void:
    # same logic as above but uses `now` parameter instead of Time.get_unix_time_from_system()
    ...

func _resolve_offline_expeditions() -> void:
    _resolve_offline_expeditions_at(Time.get_unix_time_from_system())
```

This pattern allows unit tests to pass any `now` value without mocking the engine singleton, keeping tests deterministic.

### Integration test scenario — three staggered expeditions

```gdscript
# Test setup: three slots created at T=1000 with durations 100, 200, 300
# At T=1350 (now), expect:
#   slot-A (duration 100): elapsed at T=1100 → should be completed
#   slot-B (duration 200): elapsed at T=1200 → should be completed
#   slot-C (duration 300): elapsed at T=1300 → should be completed (just elapsed)
# At T=1250, slot-C would still be in_progress

# Note: also test a case where one slot is still in_progress (T < started_at + duration)
# to confirm partial resolution works correctly
```

---

## Out of Scope

- Auto-collecting loot at boot — explicitly not done per GDD-3.6.7 and ADR-0011 R2
- Notifying the player via push notification that an expedition is ready — platform notification system (separate epic)
- Replaying tick history (simulating all ticks that would have fired offline) — Unix-timestamp model explicitly avoids this
- Clock-rewind detection (`now < last_save_timestamp - 60s`) — referenced in ADR-0011 Risks as a future hardening ticket, not in scope here
- SaveSystem changes — `active_expeditions` is already part of GameState serialisation (ADR-0011 Consequences section confirms no SaveSystem changes required)

---

## QA Test Cases

- **AC-1**: deferred call — boot ordering
  - Given: `ExpeditionSystem._ready()` called
  - When: inspect call order via signal spy on `EventBus.expedition_ready_to_collect` before and after `SaveSystem` `load_completed` signal
  - Then: no expedition signals fired before `load_completed` fires; offline resolve runs after

- **AC-2**: empty active_expeditions — no error, no signals
  - Given: `GameState.active_expeditions = []`; `now = 9999999`
  - When: `_resolve_offline_expeditions_at(9999999.0)`
  - Then: completes without error; no signal emitted

- **AC-3**: elapsed in_progress slot → completed, signal emitted
  - Given: slot `started_at = 1000.0`, `duration = 100.0`, `status = "in_progress"`; `now = 1101.0`
  - When: `_resolve_offline_expeditions_at(1101.0)`
  - Then: `slot.status == "completed"`; `expedition_ready_to_collect` emitted once with correct slot_id and zone_id

- **AC-4**: not-yet-elapsed slot → unchanged
  - Given: slot `started_at = 1000.0`, `duration = 100.0`, `status = "in_progress"`; `now = 1050.0`
  - When: `_resolve_offline_expeditions_at(1050.0)`
  - Then: `slot.status == "in_progress"`; no signal emitted

- **AC-5**: already-completed slot → unchanged, no duplicate signal
  - Given: slot `status = "completed"` (from previous session, player hasn't collected)
  - When: `_resolve_offline_expeditions_at(now_any_value)`
  - Then: `slot.status` still `"completed"`; `expedition_ready_to_collect` NOT emitted

- **AC-6**: slots not removed during pass
  - Given: one elapsed in_progress slot
  - When: `_resolve_offline_expeditions_at(elapsed_time)`
  - Then: `GameState.active_expeditions.size()` unchanged; slot still present with `status == "completed"`

- **AC-7**: collect() works after offline resolve
  - Given: slot resolved to "completed" by offline pass
  - When: `ExpeditionSystem.collect(slot_id)`
  - Then: returns non-empty rewards dict (integration with story-002)

- **AC-8**: malformed slot discarded safely
  - Given: slot dict missing key `"loot_seed"`
  - When: `_resolve_offline_expeditions_at(any_time)`
  - Then: slot removed from `active_expeditions`; `push_warning` called; no unhandled exception; other valid slots processed normally

- **AC-9**: post-resolve collect grants loot only once (implicit from AC-6 + story-002 AC-8)
  - Given: offline-resolved slot; two `collect()` calls
  - Then: first returns rewards; second returns `{}`

- **AC-10**: three staggered expeditions resolved in one pass
  - Given: three slots at `started_at=1000`, durations 100, 200, 300; `now = 1350`
  - When: `_resolve_offline_expeditions_at(1350.0)`
  - Then: all three slots have `status == "completed"`; three `expedition_ready_to_collect` signals emitted

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/expedition_system_offline_test.gd` — must exist and pass

**Status**: [x] `tests/integration/core/expedition_system_offline_test.gd` — exists and passes (CI 2026-05-20)

---

## Dependencies

- Depends on: **story-002 must be DONE** — `collect()` is the downstream consumer of slots marked completed here; story-003 acceptance criteria include verifying that a resolved slot is collectable (AC-7 / AC-9)
- Requires: `GameState.active_expeditions` populated by SaveSystem before `_resolve_offline_expeditions()` runs — guaranteed by `call_deferred` in `_ready()`
- Requires: `EventBus.expedition_ready_to_collect` signal defined (added in story-001)
- No new external dependencies beyond what story-001 and story-002 establish

---

## Completion Notes

**Completed**: 2026-05-20
**Criteria**: 10/10 passing
**Deviations**: None
**Test Evidence**: Integration — `tests/integration/core/expedition_system_offline_test.gd` (exists, CI 2026-05-20)
**Code Review**: Skipped — Lean mode
