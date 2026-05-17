# Story 001: Core Time Tracking — Offline Delta + Tick Signal

> **Epic**: TimeManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-idle-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Autoload Boot Sequence and GameState Ownership
**ADR Decision Summary**: TimeManager is autoload #2. It owns `offline_delta` and `last_seen_timestamp`. SaveSystem calls `mark_session_start(last_seen_timestamp)` at boot, passing the timestamp from the loaded save. TimeManager calculates elapsed offline time immediately and exposes it via `get_offline_delta()`. The 1-second tick signal is driven by an internal Timer node.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Use `Time.get_unix_time_from_system()` — `OS.get_unix_time()` was removed in Godot 4.4. The `Time` singleton is stable across 4.4–4.6. Internal Timer node via `add_child()` in `_ready()` is the standard pattern for periodic signals.

**Control Manifest Rules (Foundation layer)**:
- Required: `mark_dirty()` pattern is not applicable here (TimeManager owns no save-persistent data)
- Forbidden: `calling_later_autoload_in_ready` — may only call EventBus (autoload #1) in `_ready()`, never autoloads #3–#6
- Forbidden: `upward_direct_method_calls` — TimeManager may not call Core, Feature, or Presentation methods

---

## Acceptance Criteria

*From GDD idle production system and ADR-0001:*

- [ ] `class_name TimeManager extends Node` exists at `src/core/time_manager.gd`
- [ ] `signal tick(delta: float)` declared on TimeManager
- [ ] `_ready()` creates and starts an internal Timer that emits `tick` every 1.0 seconds
- [ ] `func mark_session_start(last_seen_timestamp: int) -> void` exists; stores the timestamp and calculates `_offline_delta` as `Time.get_unix_time_from_system() - last_seen_timestamp`
- [ ] `func get_offline_delta() -> float` returns the calculated offline delta (0.0 if `mark_session_start` not yet called)
- [ ] `func get_unix_time() -> int` returns `Time.get_unix_time_from_system()` as int
- [ ] `func get_current_day() -> int` returns `(Time.get_unix_time_from_system() - _game_epoch) / 86400` as int
- [ ] `func set_game_epoch(epoch: int) -> void` stores the epoch timestamp used by `get_current_day()`
- [ ] TimeManager instantiates in isolation with no dependency errors (no autoload required)
- [ ] GdUnit4: `get_offline_delta()` returns 0.0 before `mark_session_start` is called
- [ ] GdUnit4: `mark_session_start(past_timestamp)` produces positive `get_offline_delta()` > 0.0
- [ ] GdUnit4: `get_unix_time()` returns a plausible Unix timestamp (> 1_700_000_000)
- [ ] GdUnit4: `get_current_day()` returns 0 when called at the epoch second
- [ ] `Time.get_unix_time_from_system()` used — `OS.get_unix_time()` absent from source

---

## Implementation Notes

*Derived from ADR-0001 Implementation Guidelines:*

### Boot sequence role

SaveSystem calls `TimeManager.mark_session_start(GameState.last_save_timestamp)` immediately after loading the save. If no save exists (first boot), it passes `0` — TimeManager treats a `last_seen_timestamp` of `0` as "no prior session" and sets `_offline_delta = 0.0`.

### Tick Timer

The 1-second tick must fire on a reliable interval. Use an internal `Timer` node:

```gdscript
func _ready() -> void:
    var timer := Timer.new()
    timer.wait_time = 1.0
    timer.autostart = true
    timer.timeout.connect(_on_tick)
    add_child(timer)
```

The `tick` signal carries `delta` (always `1.0` in normal play, but passing the actual elapsed time leaves room for slow-device adaptation). Keep `delta` as `float` for future flexibility.

### Offline delta calculation

```gdscript
var _offline_delta: float = 0.0
var _game_epoch: int = 0

func mark_session_start(last_seen_timestamp: int) -> void:
    if last_seen_timestamp <= 0:
        _offline_delta = 0.0
        return
    _offline_delta = float(Time.get_unix_time_from_system() - last_seen_timestamp)
    if _offline_delta < 0.0:
        _offline_delta = 0.0  # clock skew guard

func get_offline_delta() -> float:
    return _offline_delta
```

### Day counter

`_game_epoch` is set once by SaveSystem via `set_game_epoch()`. For first-boot, SaveSystem sets epoch = current time. `get_current_day()` returns `(now - epoch) / 86400`.

### No EventBus dependency in _ready()

TimeManager does NOT emit signals to EventBus in `_ready()`. It only sets up the internal Timer. Downstream systems connect to `tick` directly or listen for EventBus signals that other systems emit in response to `tick`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `was_backgrounded()` flag — `NOTIFICATION_APPLICATION_PAUSED` handling — blocked on ADR-0007
- IdleProductionSystem: listening to `tick`, applying offline multipliers — Feature layer
- SaveSystem: the actual call to `mark_session_start()` — save-system epic

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these.*

**AC-1 (offline delta before mark_session_start)**:
- Given: TimeManager freshly instantiated
- When: `get_offline_delta()` called immediately
- Then: returns `0.0`
- Edge cases: calling multiple times before `mark_session_start` always returns `0.0`

**AC-2 (offline delta after mark_session_start)**:
- Given: TimeManager instantiated; `past_ts = Time.get_unix_time_from_system() - 3600` (1 hour ago)
- When: `mark_session_start(past_ts)` called
- Then: `get_offline_delta() >= 3600.0` (at least 1 hour)
- Edge cases: `mark_session_start(0)` → delta stays `0.0`; `mark_session_start` with future timestamp → delta clamped to `0.0`

**AC-3 (get_unix_time plausible)**:
- Given: TimeManager instantiated
- When: `get_unix_time()` called
- Then: result > `1_700_000_000` (timestamp after November 2023)
- Edge cases: called twice in quick succession → second result >= first result

**AC-4 (get_current_day at epoch)**:
- Given: TimeManager instantiated; `epoch = Time.get_unix_time_from_system()`
- When: `set_game_epoch(epoch)`, then `get_current_day()` called within the same second
- Then: returns `0`
- Edge cases: `set_game_epoch(epoch - 86400)` → `get_current_day()` returns `1`

**AC-5 (no OS.get_unix_time in source)**:
- Given: `src/core/time_manager.gd` source text
- When: grep for `OS.get_unix_time`
- Then: zero matches

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/time_manager_core_test.gd` — must exist and pass

```
tests/unit/core/time_manager_core_test.gd
  test_offline_delta_is_zero_before_mark_session_start()
  test_offline_delta_positive_after_mark_session_start_with_past_timestamp()
  test_mark_session_start_zero_timestamp_keeps_delta_zero()
  test_mark_session_start_future_timestamp_clamps_to_zero()
  test_get_unix_time_returns_plausible_timestamp()
  test_get_current_day_zero_at_epoch()
  test_get_current_day_one_day_after_epoch()
  test_no_deprecated_os_get_unix_time_in_source()
```

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **None** — TimeManager has no upstream story dependencies
- Unlocks: Story 002 (background detection) — and SaveSystem epic (needs mark_session_start to exist)

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 12/14 passing (2 deferred — tick firing at runtime requires game runtime; manual test per EPIC DoD)
**Deviations**: TR-idle-002 not in tr-registry.yaml (empty registry); control manifest not yet created; both are infrastructure gaps, not code issues
**Test Evidence**: Logic: `tests/unit/core/time_manager_core_test.gd` — 8 test functions
**Code Review**: Skipped — Lean mode
