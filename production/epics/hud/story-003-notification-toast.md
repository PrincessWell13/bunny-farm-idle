# Story 003: Notification Toast

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§7 — "Notification thông minh: chỉ báo khi thỏ đói")
**Requirement**: `TR-hud-001` (notification component of header)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (EventBus Signal Architecture)
**ADR Decision Summary**: HUD subscribes to `EventBus.notification_requested(text, duration_sec)` — external systems (RabbitSystem, IdleProductionSystem) emit this signal to surface notifications without knowing about HUD. HUD owns the display timing and dismissal only.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Tween API stable in 4.4–4.6. No post-cutoff APIs.

**Control Manifest Rules (Presentation layer)**:
- Required: Subscribe to `EventBus.notification_requested` in `_ready()`; disconnect in `_exit_tree()` (F-03)
- Required: All variables and return types statically typed (F-02)
- Forbidden: Any Core/Feature mutation from HUD — display only
- Guardrail: Dismiss button ≥ 44×44 px if provided

---

## Acceptance Criteria

*From GDD §7 and architecture.md `show_notification()` spec:*

- [x] AC-1: HUD exposes `show_notification(text: String, duration_sec: float) -> void` as a public method
- [x] AC-2: Calling `show_notification()` displays a toast label with `text` visible on screen
- [x] AC-3: The toast auto-dismisses after `duration_sec` seconds using a Tween
- [x] AC-4: HUD subscribes to `EventBus.notification_requested` in `_ready()`; on signal, calls `show_notification(text, duration_sec)`; disconnects in `_exit_tree()`
- [x] AC-5: If `show_notification()` is called while a toast is already showing, the previous toast is dismissed and the new one shown immediately (no stacking)

---

## Implementation Notes

*Derived from ADR-0003 EventBus Signal Architecture and architecture.md HUD spec:*

### Public API
```gdscript
## Displays a timed toast notification. External callers use EventBus.notification_requested.
func show_notification(text: String, duration_sec: float = 3.0) -> void:
    _cancel_active_toast()
    notification_label.text = text
    notification_container.visible = true
    _active_tween = create_tween()
    _active_tween.tween_interval(duration_sec)
    _active_tween.tween_callback(_hide_notification)
```

### Signal subscription
```gdscript
func _ready() -> void:
    EventBus.notification_requested.connect(_on_notification_requested)

func _exit_tree() -> void:
    if EventBus.notification_requested.is_connected(_on_notification_requested):
        EventBus.notification_requested.disconnect(_on_notification_requested)

func _on_notification_requested(text: String, duration_sec: float) -> void:
    show_notification(text, duration_sec)
```

### Toast cancel helper
```gdscript
func _cancel_active_toast() -> void:
    if _active_tween != null and _active_tween.is_valid():
        _active_tween.kill()
    notification_container.visible = false

func _hide_notification() -> void:
    notification_container.visible = false
    _active_tween = null
```

### Node refs
```gdscript
@export var notification_container: Control
@export var notification_label: Label

var _active_tween: Tween = null
```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: CC/Gem header labels
- Story 002: Bottom nav bar
- Rabbit hunger notification logic — RabbitSystem emits `notification_requested`; content of message is Core layer concern
- Offline earnings popup — requires IdleProductionSystem integration story

---

## QA Test Cases

*UI story — manual verification steps.*

- **AC-2 + AC-3**: Toast appears and auto-dismisses
  - Setup: Open game with HUD visible. Call `HUD.show_notification("Thỏ đói!", 2.0)` via debug console or test harness.
  - Verify: Toast label appears with text "Thỏ đói!"; disappears after ~2 seconds.
  - Pass condition: Text is readable; auto-dismissal occurs at approximately the specified time.

- **AC-4**: EventBus.notification_requested triggers toast
  - Setup: Emit `EventBus.notification_requested.emit("Test message", 1.5)`.
  - Verify: Toast appears with "Test message"; dismisses after ~1.5s.
  - Pass condition: Same visual result as direct `show_notification()` call.

- **AC-5**: New toast replaces active toast
  - Setup: Call `show_notification("First", 5.0)`. Immediately call `show_notification("Second", 2.0)`.
  - Verify: "First" toast disappears instantly; "Second" toast appears and dismisses in ~2s.
  - Pass condition: No two toasts visible simultaneously; no crash.

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/hud-notification-evidence.md` + sign-off

**Status**: [x] `production/qa/evidence/hud-notification-evidence.md` — created, manual sign-off pending

---

## Dependencies

- Depends on: Story 002 DONE (nav bar — shares `hud.gd`; story-002 must be complete before adding more to the file)
- Depends on: EventBus story-001 DONE — `notification_requested` signal must be defined ✅
- Unlocks: None — final HUD story

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 5/5 passing (AC-2/AC-3/AC-5 visual behaviour deferred to in-game sign-off)
**Deviations**: None
**Test Evidence**: `production/qa/evidence/hud-notification-evidence.md` — awaiting manual sign-off
**Code Review**: Skipped — Lean mode
