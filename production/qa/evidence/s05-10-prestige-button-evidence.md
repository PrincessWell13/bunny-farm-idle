# QA Evidence — S05-10 Prestige Button

**Story**: `production/epics/hud/story-007-prestige-button.md`
**Story Type**: UI
**Date**: 2026-05-22
**Reviewer**: gdscript-specialist

---

## AC Verification

| AC | Description | Status | Notes |
|----|-------------|--------|-------|
| AC-1 | Prestige button reachable in ≤ 2 taps | ADVISORY | Button is an `@export` on HUD — scene placement determines reachability. Story Out of Scope note: scene tscn layout is a separate task. |
| AC-2 | Button re-evaluates on `_ready()` and after state-change signals | PASS | `_refresh_prestige_button()` called at end of `_ready()` (prestige_button != null guard); also wired to `rabbit_born`, `breeding_completed`, `currency_changed`. |
| AC-3 | Button visually distinct when disabled | PASS | `prestige_button.modulate = Color(1,1,1,0.4)` when disabled; `Color.WHITE` when enabled. |
| AC-4 | Disabled button tap is a no-op | PASS | `_on_prestige_tapped()` early-returns if `not PrestigeSystem.can_prestige()`. |
| AC-5 | Tapping enabled button shows confirmation dialog | PASS | `prestige_confirm_dialog.popup_centered()` called from `_on_prestige_tapped()` when eligible. |
| AC-6 | Confirming dialog calls `execute_prestige()` | PASS | `_on_prestige_confirmed()` calls `PrestigeSystem.execute_prestige()` exclusively. |
| AC-7 | Cancelling dialog does nothing | PASS | Only `.confirmed` signal wired — cancel dismisses dialog without any callback. |
| AC-8 | Button disables after successful prestige | PASS | `_refresh_prestige_button()` called at end of `_on_prestige_confirmed()` — post-reset `can_prestige()` will be false (no Legendary rabbit). |
| AC-9 | Reactive re-evaluation without scene reload | PASS | `rabbit_born` and `breeding_completed` both connected to `_on_prestige_state_changed` → `_refresh_prestige_button()`. |

---

## Implementation Notes

- `prestige_button` and `prestige_confirm_dialog` are `@export` vars — null-guarded throughout.
  Scene `.tscn` must assign these exports before the button functions.
- Confirmation dialog text set in `_ready()`:
  > "Prestige now? Your coins and farm will reset, but you will earn a permanent production bonus."
- `currency_changed` also triggers `_refresh_prestige_button()` (piggy-backed on existing handler) to
  handle any edge case where currency conditions affect eligibility in the future.
- ADR-0003 compliance: HUD never calls `GameState.prestige_reset()` directly — only
  `PrestigeSystem.execute_prestige()` is the entry point.

---

## Manual Screenshot Checklist

*Pending in-game sign-off once scene is wired in Godot editor:*

- [ ] Screenshot: prestige button in **disabled** state (no Legendary rabbit)
- [ ] Screenshot: prestige button in **enabled** state (Legendary rabbit present)
- [ ] Screenshot: confirmation dialog visible after tapping enabled button
- [ ] Observation: `execute_prestige()` called on Confirm (check prestige_count in debugger)
- [ ] Observation: no state change on Cancel
