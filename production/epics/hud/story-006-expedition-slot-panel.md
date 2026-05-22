# Story 006: Expedition Slot Panel

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.6 ExpeditionSystem, §7 UI/UX)
**Requirement**: `TR-hud-005`, `TR-ui-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

> ⚠️ TR-hud-005 is not yet in `tr-registry.yaml`. Add it when running `/architecture-review rtm`.
> Stable ID reserved: `TR-hud-005` — "Expedition slot panel with real-time slot countdowns and player-initiated COLLECT action"

**ADR Governing Implementation**: ADR-0003 (EventBus Signal Architecture), ADR-0011 (ExpeditionSystem Async Timer)
**ADR Decision Summary**: The expedition panel subscribes to `EventBus.expedition_started`, `EventBus.expedition_ready_to_collect`, and `EventBus.expedition_collected` to drive slot state — never polls `GameState.active_expeditions` on tick. On COLLECT tap, the panel calls `ExpeditionSystem.collect(slot_id)` — it does NOT grant rewards itself. Countdown derived from `slot.started_at + slot.duration - Time.get_unix_time_from_system()`. `collect()` must NOT be called from the timer — only from player tap (ADR-0011 R2).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Time.get_unix_time_from_system()` stable since Godot 4.0. No post-cutoff APIs required. Signal pattern for slot state transitions is standard.

**Control Manifest Rules (Presentation layer)**:
- Required: Subscribe to `expedition_started`, `expedition_ready_to_collect`, `expedition_collected` in `_ready()`; disconnect all in `_exit_tree()` (F-03)
- Required: All variables and return types statically typed (F-02)
- Required: COLLECT action calls `ExpeditionSystem.collect(slot_id)` only — never grants rewards directly
- Forbidden: Calling `ExpeditionSystem.collect()` from a Timer or `_process()` — player tap only (ADR-0011 R2)
- Forbidden: Polling `GameState.active_expeditions` on every frame
- Guardrail: Panel accessible within ≤ 2 taps from main screen (TR-ui-004); all tap targets ≥ 44×44 px

---

## Acceptance Criteria

1. Expedition panel is accessible from the main screen within ≤ 2 taps (TR-ui-004)
2. Empty expedition slots display a "Send Expedition" call-to-action
3. When `EventBus.expedition_started(slot_id, zone_id)` fires, the corresponding slot renders with a countdown timer showing remaining time derived from `slot.started_at + slot.duration - now`
4. The countdown decrements in real time (at least once per second)
5. When `EventBus.expedition_ready_to_collect(slot_id, zone_id)` fires, the slot transitions to a "COLLECT" state — countdown replaced by a COLLECT button
6. Tapping COLLECT calls `ExpeditionSystem.collect(slot_id)` — not triggered by a timer or automatically
7. When `EventBus.expedition_collected(slot_id, rewards)` fires, the slot clears back to empty state
8. A toast notification or loot display appears after collect (can reuse `HUD.show_notification()`)
9. At boot, `GameState.active_expeditions` is read once to initialise slot states — slots already completed by offline resolve show COLLECT immediately

---

## Implementation Notes

*Derived from ADR-0003 and ADR-0011:*

```gdscript
# In src/ui/hud.gd or a child ExpeditionPanel:
func _ready() -> void:
    EventBus.expedition_started.connect(_on_expedition_started)
    EventBus.expedition_ready_to_collect.connect(_on_expedition_ready)
    EventBus.expedition_collected.connect(_on_expedition_collected)
    _init_from_game_state()

func _exit_tree() -> void:
    EventBus.expedition_started.disconnect(_on_expedition_started)
    EventBus.expedition_ready_to_collect.disconnect(_on_expedition_ready)
    EventBus.expedition_collected.disconnect(_on_expedition_collected)

func _init_from_game_state() -> void:
    for slot: Dictionary in GameState.active_expeditions:
        var slot_id: String = slot.get("slot_id", "")
        var status: String = slot.get("status", "")
        if status == "completed":
            _set_slot_collect(slot_id)
        elif status == "in_progress":
            _set_slot_countdown(slot_id, slot)

func _on_collect_tapped(slot_id: String) -> void:
    ExpeditionSystem.collect(slot_id)
    # Result arrives via expedition_collected signal
```

**Countdown display**: Derive remaining seconds as `int(slot.started_at + slot.duration - Time.get_unix_time_from_system())`. Use `_process(delta)` or a one-second `Timer` to update the display. The displayed timer is cosmetic — the actual completion is authoritative from the `expedition_ready_to_collect` signal.

**Loot display**: After `expedition_collected(slot_id, rewards)` fires, call `HUD.show_notification("Expedition returned: %s" % str(rewards))` or render the rewards dict in a simple popup. The exact format is flexible — the QA check is that some feedback is visible.

---

## Out of Scope

- Zone selection UI (choosing where to send rabbits) — future Feature layer story
- Rabbit assignment UI (choosing which rabbits to send) — future story
- Push notification when expedition is ready (platform notification system) — separate epic
- Multi-item loot display — current collect() returns a single-item dict; display as-is

---

## QA Test Cases

*Manual verification steps (UI story):*

- **AC-1**: Accessibility
  - Setup: Launch game to main screen
  - Verify: Expedition panel reachable in ≤ 2 taps
  - Pass condition: Panel opens without more than 2 navigation actions

- **AC-2**: Empty slot call-to-action
  - Setup: No active expeditions in save
  - Verify: Empty slots show "Send Expedition" or equivalent
  - Pass condition: Actionable element present on all empty slots

- **AC-3 + AC-4**: Active slot countdown
  - Setup: Start an expedition via `ExpeditionSystem.start_expedition()`; observe panel
  - Verify: Slot shows countdown timer; timer decrements every second
  - Pass condition: Countdown visible and decreasing over 5+ seconds

- **AC-5**: COLLECT state transition
  - Setup: Wait for or simulate an expedition completing (trigger `expedition_ready_to_collect`)
  - Verify: Slot transitions from countdown to COLLECT button
  - Pass condition: COLLECT button visible; countdown replaced

- **AC-6**: Tap-to-collect
  - Setup: Slot in COLLECT state; tap it
  - Verify: `ExpeditionSystem.collect()` called; `expedition_collected` signal fires; loot notification shown
  - Pass condition: Rewards visible; slot clears

- **AC-7**: Slot clears after collect
  - Setup: As above
  - Verify: Slot returns to empty state after `expedition_collected` fires
  - Pass condition: No residual COLLECT button after collection

- **AC-8**: Loot notification
  - Setup: Collect a completed expedition
  - Verify: Toast or loot popup appears briefly
  - Pass condition: Some visible feedback about rewards received

- **AC-9**: Boot state init
  - Setup: Start game with a save containing a completed-but-uncollected expedition
  - Verify: Panel shows COLLECT immediately at launch (not a countdown)
  - Pass condition: Offline-resolved slots show COLLECT without waiting for signal

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/s05-09-expedition-panel-evidence.md`
- Screenshots of panel in each state: empty, active with countdown, COLLECT
- Confirmation that tap-to-collect fires `ExpeditionSystem.collect()` and shows loot feedback

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: expedition-system/story-001, story-002 must be Complete (ExpeditionSystem backend must be functional)
- Unlocks: S05-13 (mid-game playtests require expedition UI to show progress)

---

## Completion Notes
**Completed**: 2026-05-20
**Criteria**: 8/9 passing (AC-1 deferred — structural/navigation, out of scope for scripts)
**Deviations**: ADVISORY — `hud` export typed as `Control` with runtime cast to `HUD` to avoid Presentation→class_name circular dependency. Functionally equivalent; null HUD is silent no-op.
**Test Evidence**: None yet — create `production/qa/evidence/s05-09-expedition-panel-evidence.md` before sprint QA sign-off
**Code Review**: Skipped — Lean mode
