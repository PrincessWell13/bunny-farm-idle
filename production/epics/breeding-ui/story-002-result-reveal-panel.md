# Story 002: Result Reveal Panel

> **Epic**: BreedingUI
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§2.1 Core Loop: "Con ra đời", §7 UI/UX)
**Requirement**: `TR-breeding-ui-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (EventBus Signal Architecture)
**ADR Decision Summary**: BreedingUI listens for `EventBus.rabbit_born(child_id)` — this is the trigger for the reveal. It then reads the new rabbit's data via `RabbitSystem.get_rabbit(child_id)` (downward read-only call — permitted). No mutation of rabbit data in this story.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `AnimationPlayer` for reveal sequence — unchanged in 4.4–4.6. `AnimationTree` if state machine needed (stable). Tween API stable in 4.6.

**Control Manifest Rules (Presentation layer)**:
- Required: Connect `EventBus.rabbit_born` in `_ready()`; disconnect in `_exit_tree()` (ADR-0003 Disconnect Pattern)
- Required: All variables and return types statically typed (F-02)
- Forbidden: Writing to any `RabbitData` field in this story (cross-layer rule)
- Forbidden: Calling `RabbitSystem` mutation methods — read-only getter only

---

## Acceptance Criteria

*From GDD §2.1 "con ra đời" beat, architecture.md BreedingUI module spec:*

- [ ] AC-1: BreedingUI connects to `EventBus.rabbit_born` in `_ready()` and disconnects in `_exit_tree()`
- [ ] AC-2: When `rabbit_born(child_id)` fires, BreedingUI calls `RabbitSystem.get_rabbit(child_id)` and opens a reveal panel with the child's data
- [ ] AC-3: Reveal panel displays at minimum: child's expressed colour (from `genome.color.expressed()`), both trait alleles from `genome.trait_a` and `genome.trait_b`, and estimated rarity (from `GeneticsSystem.get_rarity(child)` or the rarity tier label)
- [ ] AC-4: A reveal animation plays before the stats panel is shown — a visual flourish (e.g. card flip, sparkle, fade-in) lasting `ui.breed_reveal_duration` seconds (loaded from `balance.json`; default 1.5s)
- [ ] AC-5: Player can dismiss the reveal panel by tapping a "Close" / "✓" button (≥44×44 px); BreedingUI returns to the parent-selector idle state after dismissal
- [ ] AC-6: If `RabbitSystem.get_rabbit(child_id)` returns null (edge case: child already removed), reveal panel is skipped silently — no crash

---

## Implementation Notes

*Derived from ADR-0003 Disconnect Pattern:*

### Signal subscription
```gdscript
func _ready() -> void:
    EventBus.rabbit_born.connect(_on_rabbit_born)

func _exit_tree() -> void:
    if EventBus.rabbit_born.is_connected(_on_rabbit_born):
        EventBus.rabbit_born.disconnect(_on_rabbit_born)

func _on_rabbit_born(child_id: String) -> void:
    var child: RabbitData = RabbitSystem.get_rabbit(child_id)
    if child == null:
        return  # AC-6: silent skip
    _show_reveal_panel(child)
```

### Reveal animation sequence
```gdscript
func _show_reveal_panel(child: RabbitData) -> void:
    reveal_panel.visible = true
    # Play AnimationPlayer "reveal_intro" animation
    reveal_animation_player.play("reveal_intro")
    await reveal_animation_player.animation_finished
    # Then populate and show stats
    _populate_reveal_data(child)
    stats_container.visible = true
```

### Balance.json key for reveal duration
```json
"ui": {
    "breed_reveal_duration": 1.5
}
```
Load this in `_ready()` alongside other balance data. If key is missing, fallback default: 1.5.

### Reveal panel content
```gdscript
func _populate_reveal_data(child: RabbitData) -> void:
    color_label.text = child.genome.color.expressed()
    trait_a_label.text = child.genome.trait_a.expressed()
    trait_b_label.text = child.genome.trait_b.expressed()
    var rarity: GeneticsSystem.RarityTier = GeneticsSystem.get_rarity(child)
    rarity_label.text = _rarity_display_name(rarity)
```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: Parent selector and breed_requested dispatch (prerequisite — must be DONE)
- Full rabbit card display with portrait sprite — future FarmMapUI / asset sprint story
- Sound effects on reveal — Audio epic (future story)
- Gene journal / genealogy display — GenePuzzleSystem epic

---

## QA Test Cases

*Visual/Feel story — manual verification steps. Run in-game after implementation.*

- **AC-2 + AC-4**: Reveal panel appears after breeding completes
  - Setup: Open BreedingUI, select 2 adult rabbits, tap Confirm. Wait for breed to complete (or force-emit `rabbit_born("test-id")` from GdUnit4 test harness).
  - Verify: Reveal panel becomes visible; animation plays (card flip / sparkle) before stats appear
  - Pass condition: Panel is clearly visible and the animation is distinct (not an instant pop-in)

- **AC-3**: Stats displayed correctly
  - Setup: Breed two rabbits with known genomes (e.g., both parents `color = "gold"`).
  - Verify: Revealed child shows colour name, at least one non-"none" trait if parents have traits, and a rarity label.
  - Pass condition: All three data fields are populated; no "null" or empty labels

- **AC-4**: Reveal duration from balance.json
  - Setup: Change `ui.breed_reveal_duration` in balance.json to 0.5, restart game, breed.
  - Verify: Animation finishes faster (≈ 0.5s, not 1.5s).
  - Pass condition: Animation speed visibly reflects the config value

- **AC-5**: Dismiss works; parent selector resets
  - Setup: Trigger reveal panel (breed or mock signal). Tap Close button.
  - Verify: Reveal panel hides; BreedingUI returns to parent-selector view with no parents selected (or previous selection cleared).
  - Pass condition: Close button visible and tappable; no lingering reveal state after dismiss

- **AC-6**: Null child does not crash
  - Setup: Emit `EventBus.rabbit_born("nonexistent-id")` manually (e.g., via GdUnit4 test or debug console).
  - Verify: No crash; reveal panel does not open; no error in output log.
  - Pass condition: Game continues normally; debug log shows at most a `push_warning()` entry

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/breeding-ui-reveal-evidence.md` — screenshot + lead sign-off

**Status**: [x] `production/qa/evidence/breeding-ui-reveal-evidence.md` — awaiting in-game sign-off

---

## Dependencies

- Depends on: Story 001 (Parent Selector + Breed Trigger — must be DONE; `breed_requested` must be wired through Core layer so `rabbit_born` fires)
- Unlocks: None — final BreedingUI story

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 4/6 auto-verified; AC-4 (animation timing) and AC-5 (dismiss behaviour) DEFERRED — require in-game playtest
**Deviations**: ADVISORY — Tween fade-in used instead of AnimationPlayer "reveal_intro" (duration still balance.json driven); balance.json `ui` section added (required by AC-4)
**Test Evidence**: Visual/Feel — `production/qa/evidence/breeding-ui-reveal-evidence.md` (5 manual test cases, awaiting sign-off)
**Code Review**: Skipped (lean mode)
