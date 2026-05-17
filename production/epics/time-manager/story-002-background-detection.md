# Story 002: Background Detection — was_backgrounded() Flag

> **Epic**: TimeManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Blocked Reason

**BLOCKED: ADR-0007 is Proposed** — run `/architecture-decision` to advance it to Accepted.

ADR-0007 (Idle Production + Offline Catch-Up Calculation) defines the `was_backgrounded()` flag semantics and specifies which multiplier IdleProductionSystem applies in each case (backgrounded vs killed). Until ADR-0007 is Accepted, the exact behaviour contract for this story is undefined.

---

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-idle-004` (item-based offline modifiers — pending ADR-0007)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Idle Production + Offline Catch-Up Calculation
**ADR Decision Summary**: Background multiplier (0.75) applies when `TimeManager.was_backgrounded()` returns true. TimeManager records app-backgrounded state via `NOTIFICATION_APPLICATION_PAUSED`; the flag is cleared by `NOTIFICATION_APPLICATION_FOCUS_IN`. SaveSystem reads `was_backgrounded()` during boot to pass to `IdleProductionSystem.calculate_offline_earnings()`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `NOTIFICATION_APPLICATION_PAUSED` is the correct notification for app backgrounding on mobile in Godot 4.x. `NOTIFICATION_WM_WINDOW_FOCUS_OUT` covers desktop. Both must be handled. `_notification(what: int)` override is the standard pattern.

**Control Manifest Rules (Foundation layer)**:
- Forbidden: `calling_later_autoload_in_ready` — TimeManager may not call autoloads #3–#6
- Forbidden: `upward_direct_method_calls` — TimeManager may not call Core, Feature, or Presentation methods

---

## Acceptance Criteria

*To be finalised after ADR-0007 is Accepted. Provisional criteria:*

- [ ] `func was_backgrounded() -> bool` exists on TimeManager
- [ ] `_notification(what: int)` override sets `_backgrounded = true` on `NOTIFICATION_APPLICATION_PAUSED`
- [ ] `_notification(what: int)` override sets `_backgrounded = false` on `NOTIFICATION_APPLICATION_FOCUS_IN`
- [ ] `was_backgrounded()` returns `false` on fresh instantiation
- [ ] GdUnit4: `was_backgrounded()` is `false` by default
- [ ] GdUnit4: after simulating the pause notification, `was_backgrounded()` is `true`
- [ ] GdUnit4: after simulating focus-in notification, `was_backgrounded()` is `false` again

---

## Implementation Notes

*Provisional — must be re-read after ADR-0007 is Accepted:*

```gdscript
var _backgrounded: bool = false

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED:
        _backgrounded = true
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        _backgrounded = false

func was_backgrounded() -> bool:
    return _backgrounded
```

The flag is sticky — once set `true` (by backgrounding), it stays `true` until the next foreground event. IdleProductionSystem reads it during boot (after `mark_session_start`) to decide which reward multiplier to apply, then calls `TimeManager._backgrounded = false` — or more likely, the flag is reset by a dedicated `reset_backgrounded()` method whose exact signature is defined by ADR-0007.

---

## Out of Scope

*Handled by neighbouring stories or epics:*

- Story 001: core time tracking, mark_session_start, tick signal
- IdleProductionSystem: consuming the `was_backgrounded()` flag and selecting reward multipliers — Feature layer
- ADR-0007: the decision itself — must be written before this story can be implemented

---

## QA Test Cases

*To be finalised after ADR-0007 is Accepted. Provisional cases:*

**AC-1 (default false)**:
- Given: TimeManager freshly instantiated
- When: `was_backgrounded()` called immediately
- Then: returns `false`

**AC-2 (pause notification sets true)**:
- Given: TimeManager instantiated; `_backgrounded` is `false`
- When: `_notification(NOTIFICATION_APPLICATION_PAUSED)` called
- Then: `was_backgrounded()` returns `true`

**AC-3 (focus-in clears flag)**:
- Given: TimeManager in backgrounded state (`_backgrounded == true`)
- When: `_notification(NOTIFICATION_APPLICATION_FOCUS_IN)` called
- Then: `was_backgrounded()` returns `false`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/time_manager_background_test.gd` — must exist and pass

```
tests/unit/core/time_manager_background_test.gd
  test_was_backgrounded_false_by_default()
  test_pause_notification_sets_backgrounded_true()
  test_focus_in_notification_clears_backgrounded_flag()
```

**Status**: [x] `tests/unit/core/time_manager_background_test.gd` — 6 test functions

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 7/7 passing
**Deviations**: Added `reset_backgrounded()` public method — not in original AC but specified in Implementation Notes; consistent with ADR-0007 SaveSystem consumption pattern.
**Test Evidence**: Logic — `tests/unit/core/time_manager_background_test.gd` ✅ (6 test functions)
**Code Review**: Skipped — Lean mode

---

## Dependencies

- Depends on: **Story 001 must be DONE** + **ADR-0007 must be Accepted**
- Unlocks: IdleProductionSystem epic (Feature layer) — needs `was_backgrounded()` to select offline multiplier
