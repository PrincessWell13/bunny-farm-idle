# Story 007: Prestige Button

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§5 PrestigeSystem, §7 UI/UX)
**Requirement**: `TR-hud-006`, `TR-ui-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

> ⚠️ TR-hud-006 is not yet in `tr-registry.yaml`. Add it when running `/architecture-review rtm`.
> Stable ID reserved: `TR-hud-006` — "Prestige button with can_prestige() eligibility gate, confirmation dialog, and execute_prestige() trigger"

**ADR Governing Implementation**: ADR-0003 (EventBus Signal Architecture), ADR-0001 (Autoload Boot Sequence)
**ADR Decision Summary**: The prestige button reads `PrestigeSystem.can_prestige()` to determine its enabled/disabled visual state. It subscribes to relevant state-change signals (`currency_changed`, `rabbit_born`, `breeding_completed`) to re-evaluate eligibility reactively. On tap, it shows a confirmation dialog before calling `PrestigeSystem.execute_prestige()`. The HUD never calls `GameState.prestige_reset()` directly — that is owned by PrestigeSystem.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `ConfirmationDialog` node is stable in Godot 4.x. Button `disabled` property is standard. No post-cutoff APIs required.

**Control Manifest Rules (Presentation layer)**:
- Required: Button eligibility re-evaluated by calling `PrestigeSystem.can_prestige()` — never reading `GameState.prestige_count` directly in HUD
- Required: Confirmation dialog shown before `execute_prestige()` is called — never skip the dialog
- Required: All variables and return types statically typed (F-02)
- Forbidden: Calling `GameState.prestige_reset()` from HUD — only `PrestigeSystem.execute_prestige()` is the valid entry point
- Forbidden: Granting any rewards or modifying any game state from the button handler — delegate entirely to PrestigeSystem
- Guardrail: Button tap target ≥ 44×44 px; accessible within ≤ 2 taps (TR-ui-004)

---

## Acceptance Criteria

1. A prestige button is accessible in the HUD/prestige view within ≤ 2 taps from the main screen (TR-ui-004)
2. On `_ready()` and after any state-change signal that could affect eligibility, the button calls `PrestigeSystem.can_prestige()` and updates its visual state (enabled vs disabled/grayed)
3. The button is visually distinct when disabled (grayed, reduced opacity, or equivalent) vs when enabled
4. Tapping a disabled button does nothing — `execute_prestige()` is not called, no dialog shown
5. Tapping an enabled button shows a confirmation dialog ("Prestige now? Your coins and rabbits will reset.")
6. Confirming the dialog calls `PrestigeSystem.execute_prestige()` — no other HUD code mutates game state
7. Cancelling the dialog returns to normal HUD state without calling `execute_prestige()`
8. After a successful prestige (`execute_prestige()` completes), the button re-evaluates eligibility and becomes disabled again (prestige_count just incremented; Legendary rabbit requirement no longer met until next breeding cycle)
9. The button re-evaluates eligibility reactively when relevant signals fire — it does not require a full scene reload to update state

---

## Implementation Notes

*Derived from ADR-0003:*

```gdscript
# In src/ui/hud.gd or a child PrestigeButton node:
@onready var _prestige_btn: Button = $PrestigeButton
@onready var _confirm_dialog: ConfirmationDialog = $PrestigeConfirmDialog

func _ready() -> void:
    EventBus.rabbit_born.connect(_on_state_changed)
    EventBus.breeding_completed.connect(_on_state_changed)
    EventBus.currency_changed.connect(_on_state_changed)
    _prestige_btn.pressed.connect(_on_prestige_tapped)
    _confirm_dialog.confirmed.connect(_on_prestige_confirmed)
    _refresh_prestige_button()

func _exit_tree() -> void:
    EventBus.rabbit_born.disconnect(_on_state_changed)
    EventBus.breeding_completed.disconnect(_on_state_changed)
    EventBus.currency_changed.disconnect(_on_state_changed)

func _on_state_changed(_args: Variant = null) -> void:
    _refresh_prestige_button()

func _refresh_prestige_button() -> void:
    _prestige_btn.disabled = not PrestigeSystem.can_prestige()

func _on_prestige_tapped() -> void:
    if not PrestigeSystem.can_prestige():
        return
    _confirm_dialog.popup_centered()

func _on_prestige_confirmed() -> void:
    PrestigeSystem.execute_prestige()
    _refresh_prestige_button()
```

**ConfirmationDialog text**: Set `_confirm_dialog.dialog_text` to a localisation-friendly string in the scene or via script. Suggested text: "Prestige now? Your coins and farm will reset, but you will earn a permanent production bonus."

**Reactive eligibility**: The signals listed in `_ready()` are the most common state-change triggers for prestige eligibility. If a new signal is added that can change eligibility (e.g., a Legendary rabbit dying), add it here. When in doubt, add the signal subscription.

---

## Out of Scope

- Prestige rewards display / bonus summary screen — future UI story
- Prestige count display in HUD header — separate HUD element story
- CollectionSystem completion % display — depends on CollectionSystem ADR (not yet written)

---

## QA Test Cases

*Manual verification steps (UI story):*

- **AC-1**: Accessibility
  - Setup: Launch game to main screen
  - Verify: Prestige button reachable in ≤ 2 taps
  - Pass condition: Button found without more than 2 navigation actions

- **AC-2 + AC-3**: Eligibility visual state
  - Setup: State where `can_prestige()` returns false (no Legendary rabbit, or count at cap)
  - Verify: Button is visually grayed or disabled
  - Pass condition: Button appearance clearly indicates unavailability

- **AC-4**: Disabled button does nothing
  - Setup: Button in disabled state; tap it
  - Verify: No dialog appears; no game state changes
  - Pass condition: Silent no-op

- **AC-5**: Confirmation dialog
  - Setup: Arrange game state so `can_prestige()` returns true (requires Legendary rabbit — may need a dev shortcut); tap button
  - Verify: Confirmation dialog appears with appropriate text
  - Pass condition: Dialog visible with confirm and cancel options

- **AC-6**: Confirm executes prestige
  - Setup: As above; confirm the dialog
  - Verify: `PrestigeSystem.execute_prestige()` called; `GameState.prestige_count` increments; coins reset
  - Pass condition: Game state reflects post-prestige reset

- **AC-7**: Cancel does nothing
  - Setup: Dialog open; tap Cancel
  - Verify: Dialog closes; game state unchanged; prestige_count unchanged
  - Pass condition: No state mutation on cancel

- **AC-8**: Button disables after prestige
  - Setup: Complete a prestige; observe button state
  - Verify: Button returns to disabled (no Legendary rabbit immediately post-reset)
  - Pass condition: Button grayed after successful prestige

- **AC-9**: Reactive re-evaluation
  - Setup: Game running with button disabled; trigger breeding that produces a Legendary rabbit
  - Verify: Button updates to enabled WITHOUT requiring scene reload
  - Pass condition: Button state changes within 1 frame of the qualifying signal firing

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/s05-10-prestige-button-evidence.md`
- Screenshot of button in disabled (no Legendary) and enabled (eligible) states
- Screenshot of confirmation dialog
- Confirmation that `execute_prestige()` is called on confirm and not on cancel

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: prestige-system/story-001 (can_prestige + execute_prestige must be Complete — they are ✅)
- Depends on: prestige-system/story-002 (prestige bonus wired — Complete ✅)
- Unlocks: S05-13 (mid-game playtests require prestige button to test the prestige loop)
