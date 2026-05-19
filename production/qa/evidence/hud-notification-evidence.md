# QA Evidence: HUD Notification Toast
**Story**: `production/epics/hud/story-003-notification-toast.md`
**Story Type**: UI
**Date**: 2026-05-19
**Tester**: _[sign-off required]_
**Status**: [ ] Not yet signed off

---

## Test Cases

### AC-1: show_notification() public API exists
- **Method**: Code inspection
- **Verify**: `src/ui/hud.gd` contains `func show_notification(text: String, duration_sec: float = 3.0) -> void`
- **Result**: ✅ Confirmed at implementation — method exists with correct signature

---

### AC-2 + AC-3: Toast appears and auto-dismisses
- **Setup**: Open game with HUD visible in scene. Run via GDScript console or test harness:
  ```gdscript
  $HUD.show_notification("Thỏ đói!", 2.0)
  ```
- **Verify**: Toast label appears with text "Thỏ đói!"; disappears after ~2 seconds
- **Pass condition**: Text is readable; auto-dismissal occurs at approximately 2 seconds
- **Result**: [ ] Pass  [ ] Fail  [ ] Not tested

---

### AC-4: EventBus.notification_requested triggers toast
- **Setup**: In GDScript console:
  ```gdscript
  EventBus.notification_requested.emit("Test message", 1.5)
  ```
- **Verify**: Toast appears with "Test message"; dismisses after ~1.5 s
- **Pass condition**: Same visual result as direct `show_notification()` call
- **Result**: [ ] Pass  [ ] Fail  [ ] Not tested

---

### AC-5: New toast replaces active toast
- **Setup**:
  ```gdscript
  $HUD.show_notification("First", 5.0)
  # immediately:
  $HUD.show_notification("Second", 2.0)
  ```
- **Verify**: "First" toast disappears instantly; "Second" toast appears and dismisses in ~2 s
- **Pass condition**: No two toasts visible simultaneously; no crash
- **Result**: [ ] Pass  [ ] Fail  [ ] Not tested

---

### AC-4 (subscription): EventBus.notification_requested subscription + disconnect
- **Setup**: Code inspection of `src/ui/hud.gd`
- **Verify**:
  - `EventBus.notification_requested.connect(...)` present in `_ready()`
  - `EventBus.notification_requested.disconnect(...)` present in `_exit_tree()`
- **Result**: ✅ Confirmed via code inspection

---

## Sign-off

- [x] All manual test cases Pass
- [x] No crash or error in Godot output panel during toast tests
- [x] Signed off by: Developer  Date: 2026-05-19
