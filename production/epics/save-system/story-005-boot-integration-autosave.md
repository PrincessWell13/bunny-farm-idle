# Story 005: Boot Integration + Auto-Save Timer

> **Epic**: SaveSystem
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Blocked Reason

**BLOCKED: ADR-0008 is Proposed** — run `/architecture-decision retrofit docs/architecture/adr-0008-firebase-local-first-save.md` to promote it to Accepted.

ADR-0008 defines `_ready()` calling `load_game()`, the 30-second auto-save interval (`SAVE_INTERVAL_SECONDS = 30.0`), and the `NOTIFICATION_APPLICATION_PAUSED` → `save_game()` behaviour. ADR-0001 defines SaveSystem's position as autoload #5 and the call to `TimeManager.mark_session_start()`.

---

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-save-001`, `TR-save-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (boot sequence + mark_session_start call), ADR-0008 (auto-save interval, notification handling, inject_firebase)
**ADR Decision Summary**: `SaveSystem._ready()` calls `load_game()` synchronously at boot, then starts a 30-second auto-save Timer. `_notification()` triggers `save_game()` on `NOTIFICATION_APPLICATION_PAUSED`. `inject_firebase(adapter)` is called by SceneManager after `_ready()` completes. `GameState.is_dirty` is reset to `false` after each `save_game()` (the one permitted direct assignment).

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `NOTIFICATION_APPLICATION_PAUSED` fires on mobile app backgrounding in Godot 4.x. `NOTIFICATION_WM_WINDOW_FOCUS_OUT` fires on desktop. Both should trigger save. `Timer` auto-save pattern is identical to TimeManager's tick timer.

**Control Manifest Rules (Foundation layer)**:
- Forbidden: `calling_later_autoload_in_ready` — SaveSystem (autoload #5) must not call SceneManager (autoload #6) in `_ready()`
- Required: `GameState.is_dirty = false` is the ONLY permitted direct assignment to `is_dirty` — in `save_game()` only

---

## Acceptance Criteria

*From ADR-0001 Boot Sequence and ADR-0008 SaveSystem Responsibilities:*

- [ ] `SaveSystem._ready()` calls `load_game()` immediately
- [ ] `SaveSystem._ready()` starts an internal Timer with `wait_time = SAVE_INTERVAL_SECONDS` (30.0) that calls `save_game()` on timeout
- [ ] `func load_game() -> void` exists; calls `_load_local()`, optionally `_firebase.fetch_save()` (only if `_firebase != null and _firebase.is_signed_in()`), then `_resolve_conflict()`, then `_populate_game_state()`
- [ ] `func save_game() -> void` exists; calls `_serialise_game_state()`, sets `last_save_timestamp`, calls `_write_local()`, sets `GameState.is_dirty = false`, optionally calls `_firebase.push_save_async()` (only if firebase signed in)
- [ ] `func inject_firebase(adapter: FirebaseAdapter) -> void` exists; stores adapter in `_firebase`
- [ ] `_notification(NOTIFICATION_APPLICATION_PAUSED)` calls `save_game()`
- [ ] `_notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)` calls `save_game()` (desktop fallback)
- [ ] GdUnit4 integration: `load_game()` with `MockFirebaseAdapter` (signed in) loads both local and calls `fetch_save()`
- [ ] GdUnit4 integration: `load_game()` with `_firebase == null` loads local only, no crash
- [ ] GdUnit4: `save_game()` sets `GameState.is_dirty = false` after saving

---

## Implementation Notes

*Derived from ADR-0008 SaveSystem Responsibilities and ADR-0001 Boot Sequence:*

```gdscript
class_name SaveSystem extends Node

const SAVE_PATH: String = "user://savegame.json"
const SAVE_INTERVAL_SECONDS: float = 30.0

var _firebase: FirebaseAdapter = null

func _ready() -> void:
    load_game()
    _start_auto_save_timer()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
        save_game()

func _start_auto_save_timer() -> void:
    var timer := Timer.new()
    timer.wait_time = SAVE_INTERVAL_SECONDS
    timer.autostart = true
    timer.timeout.connect(save_game)
    add_child(timer)

func inject_firebase(adapter: FirebaseAdapter) -> void:
    _firebase = adapter

func load_game() -> void:
    var local_data: Dictionary = _load_local()
    var cloud_data: Dictionary = {}
    if _firebase != null and _firebase.is_signed_in():
        cloud_data = await _firebase.fetch_save()
    var save_data: Dictionary = _resolve_conflict(local_data, cloud_data)
    _populate_game_state(save_data)

func save_game() -> void:
    var data: Dictionary = _serialise_game_state()
    data["last_save_timestamp"] = int(Time.get_unix_time_from_system())
    _write_local(data)
    GameState.is_dirty = false  # permitted: SaveSystem is save-state owner
    if _firebase != null and _firebase.is_signed_in():
        _firebase.push_save_async(data)
```

### Test approach

The `load_game()` function uses `await` for Firebase. In GdUnit4, `MockFirebaseAdapter.fetch_save()` should be synchronous (return immediately). The test must `await` or use `call_deferred` if GdUnit4 requires sync-only assertions.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `FirebaseAdapter` + `MockFirebaseAdapter`
- Story 002: `_load_local()` / `_write_local()`
- Story 003: `_serialise_game_state()` / `_populate_game_state()`
- Story 004: `_resolve_conflict()`
- `SceneManager._ready()` calling `inject_firebase()` — SceneManager epic

---

## QA Test Cases

**AC-1 (load_game with null firebase loads local only)**:
- Given: SaveSystem with `_firebase == null`; local file contains `{"prestige_count": 7}`
- When: `load_game()` called
- Then: `GameState.prestige_count == 7`; no crash

**AC-2 (load_game with MockFirebaseAdapter calls fetch_save)**:
- Given: `MockFirebaseAdapter` injected (`mock_signed_in = true`, `mock_save_data = {"prestige_count": 5}`); local data has older timestamp
- When: `load_game()` called
- Then: `adapter.fetch_save()` was called; `GameState` reflects cloud data (prestige_count == 5)

**AC-3 (save_game resets is_dirty)**:
- Given: `GameState.mark_dirty()` called (is_dirty = true); `MockFirebaseAdapter` injected
- When: `save_game()` called
- Then: `GameState.is_dirty == false`

**AC-4 (save_game pushes to firebase when signed in)**:
- Given: `MockFirebaseAdapter` with `mock_signed_in = true`
- When: `save_game()` called
- Then: `adapter.last_pushed` is non-empty

**AC-5 (save_game skips firebase when not signed in)**:
- Given: `MockFirebaseAdapter` with `mock_signed_in = false`
- When: `save_game()` called
- Then: `adapter.last_pushed` remains `{}`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/save_system_boot_test.gd` — must exist and pass

```
tests/integration/core/save_system_boot_test.gd
  test_load_game_with_null_firebase_loads_local_only()
  test_load_game_with_mock_firebase_calls_fetch_save()
  test_save_game_resets_is_dirty()
  test_save_game_pushes_to_firebase_when_signed_in()
  test_save_game_skips_firebase_when_not_signed_in()
  test_inject_firebase_stores_adapter()
```

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **Stories 001, 002, 003, 004 all DONE** — this story wires them all together
- Unlocks: SceneManager epic (`inject_firebase()` must exist before SceneManager can call it)

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 10/10 passing
**Deviations**: None
**Test Evidence**: Integration — `tests/integration/core/save_system_boot_test.gd` (6 test functions)
**Code Review**: Skipped — Lean mode
