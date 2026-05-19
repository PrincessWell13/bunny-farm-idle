# Story 001: Parent Selector + Breed Trigger

> **Epic**: BreedingUI
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§2.1 Core Loop, §3.2 Genetics, §7 UI/UX)
**Requirement**: `TR-breeding-ui-001`, `TR-genetics-004`, `TR-ui-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (EventBus Signal Architecture), ADR-0006 (Genetics Allele Model)
**ADR Decision Summary**: BreedingUI dispatches `EventBus.breed_requested(parent_a_id, parent_b_id)` — never calls `GeneticsSystem.breed()` directly. Downward read-only calls (`RabbitSystem.get_all_rabbits()`, `GeneticsSystem.get_breed_preview()`) are permitted. The preview display reads the `BreedPreview` resource returned by `get_breed_preview()`.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `SubViewport` for probability chart — verify this approach is correct in Godot 4.6 before implementing. Alternative: use `TextureProgressBar` or a custom `_draw()` on a `Control` node. Dual-focus system (4.6): touch-only UI — use `MOUSE_FILTER_STOP` on interactive elements, `MOUSE_FILTER_IGNORE` on decorative ones.

**Control Manifest Rules (Presentation layer)**:
- Required: All cross-layer communication via EventBus signals — never call Core/Feature methods that mutate state (F-03)
- Required: All variables and function signatures statically typed (F-02)
- Forbidden: Calling `GeneticsSystem.breed()` from any Presentation file (ADR-0003)
- Forbidden: Writing to any `RabbitData` field — read-only access only (cross-layer rule)
- Guardrail: All interactive touch targets ≥ 44×44 px (technical-preferences.md)
- Guardrail: Breeding screen opens within 2 taps from main screen (TR-ui-004)

---

## Acceptance Criteria

*From GDD §2.1 / §3.2 / §7, and architecture.md BreedingUI module spec:*

- [ ] AC-1: Screen populates a scrollable rabbit list with all rabbits where `stage == RabbitData.RabbitStage.ADULT`; rabbits in other stages (BABY, JUVENILE, ELDER, SANCTUARY) are filtered out
- [ ] AC-2: Player selects parent A by tapping a rabbit card (first tap); a second tap on a different adult rabbit selects parent B — both selections happen within the same screen (≤2 taps from screen open per TR-ui-004)
- [ ] AC-3: After both parents are selected, `GeneticsSystem.get_breed_preview(parent_a, parent_b)` is called and the returned `BreedPreview` data is reflected in a preview panel (shows at minimum: `estimated_rarity`, `mutation_chance`, colour probability for the most likely outcome)
- [ ] AC-4: The Breed/Confirm button is enabled only when two *different* adult rabbits are selected; it is disabled (and shows explanatory text) when 0 or 1 adult is available, or when the same rabbit is selected as both parents
- [ ] AC-5: Tapping Confirm dispatches `EventBus.breed_requested(parent_a_id, parent_b_id)` with the correct IDs; no call to `GeneticsSystem.breed()` is made anywhere in `breeding_ui.gd`
- [ ] AC-6: All interactive elements (rabbit cards, confirm button, close button) have a minimum touch target of 44×44 px
- [ ] AC-7: BreedingUI never writes to any `RabbitData` field — it only reads via `RabbitSystem` getters
- [ ] AC-8: Deselecting a parent (tapping the selected card again, or tapping a third card to swap) works correctly and the preview updates

---

## Implementation Notes

*Derived from ADR-0003 and ADR-0006 Implementation Guidelines:*

### Screen structure (`BreedingUI.tscn`)
```
BreedingUI (Control, MOUSE_FILTER_IGNORE)
├─ Header (label "Breeding Lab", close button)
├─ RabbitGrid (GridContainer — scrollable, populates from RabbitSystem)
│   └─ RabbitCard (scene per rabbit — shows sprite, name, rarity badge)
├─ PreviewPanel (VBoxContainer — hidden until both parents selected)
│   ├─ RarityLabel (Label)
│   ├─ MutationLabel (Label)
│   └─ ColorChart (Control — simple display of top color probability)
└─ BreedButton (Button, MOUSE_FILTER_STOP, min_size 44×44)
```

### Data flow pattern (read-only downward calls permitted)
```gdscript
func _ready() -> void:
    _populate_rabbit_list()          # calls RabbitSystem.get_all_rabbits()

func _on_rabbit_card_tapped(rabbit_id: String) -> void:
    # assign to _parent_a_id / _parent_b_id
    if _parent_a_id != "" and _parent_b_id != "":
        _update_preview()            # calls GeneticsSystem.get_breed_preview(a, b)

func _on_breed_button_pressed() -> void:
    EventBus.breed_requested.emit(_parent_a_id, _parent_b_id)
    # NO: GeneticsSystem.breed(a, b)  ← FORBIDDEN
```

### Rabbit list filter
Only ADULT rabbits are shown. Filter from `RabbitSystem.get_all_rabbits()`:
```gdscript
var adults: Array[RabbitData] = RabbitSystem.get_all_rabbits().filter(
    func(r: RabbitData) -> bool:
        return r.stage == RabbitData.RabbitStage.ADULT
)
```

### Preview panel population
`BreedPreview` from ADR-0006:
- `estimated_rarity: RarityTier` → show as colour-coded label
- `mutation_chance: float` → show as percentage string
- `color_probabilities: Dictionary` → show top-probability colour name

### Disable conditions for Breed button
```gdscript
func _update_breed_button() -> void:
    var can_breed: bool = (
        _parent_a_id != "" and
        _parent_b_id != "" and
        _parent_a_id != _parent_b_id
    )
    breed_button.disabled = not can_breed
```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Result reveal animation (plays after `rabbit_born` signal fires — separate story)
- `GeneticsSystem.breed()` actual implementation — already done in GeneticsSystem epic
- `EventBus.breed_requested` handler in `GeneticsSystem`/`RabbitSystem` — wired in Core layer, not here
- Rabbit stat display in breeding cards (full rabbit card design — future UI story)

---

## QA Test Cases

*Integration story — automated test specs. Developer implements against these.*

- **AC-1**: Adult filter — only ADULT rabbits shown
  - Given: `RabbitSystem` mock returns roster of [BABY, ADULT, ADULT, JUVENILE] rabbits
  - When: BreedingUI populates rabbit list
  - Then: Exactly 2 cards rendered; BABY and JUVENILE not present
  - Edge cases: 0 adults → list empty, button disabled with message; 1 adult → button disabled

- **AC-4**: Breed button disabled without valid pair
  - Given: Fresh BreedingUI with 0 adults
  - When: Screen opens
  - Then: `breed_button.disabled == true`
  - Given: 1 adult selected as parent A, no parent B
  - Then: `breed_button.disabled == true`
  - Given: Same rabbit ID selected as both A and B
  - Then: `breed_button.disabled == true`

- **AC-5**: breed_requested signal emitted on confirm — no breed() call
  - Given: Two different adult rabbits selected (IDs "a001", "a002")
  - When: Confirm button pressed
  - Then: `EventBus.breed_requested` emitted with ("a001", "a002")
  - Then: No call to `GeneticsSystem.breed()` occurs (assert via mock spy)
  - Edge cases: signal emitted with correct parent order (A then B, not reversed)

- **AC-3 + AC-8**: Preview updates on parent selection change
  - Given: parent A = rabbit "a001", parent B = rabbit "a002"
  - When: `get_breed_preview(a001, a002)` returns a mock `BreedPreview`
  - Then: PreviewPanel shows the preview's `estimated_rarity` and `mutation_chance`
  - Given: Player taps "a002" card again (deselect)
  - Then: Preview panel clears; button re-disables

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ui/breeding_ui_breed_trigger_test.gd` — must exist and pass (or equivalent playtest doc if headless Godot UI testing proves infeasible)

**Status**: [x] `tests/integration/ui/breeding_ui_breed_trigger_test.gd` — 11 test functions

---

## Dependencies

- Depends on: GeneticsSystem epic (all stories DONE — `GeneticsSystem.get_breed_preview()` must exist)
- Depends on: RabbitSystem epic (story-001 DONE — `RabbitSystem.get_all_rabbits()` must exist)
- Depends on: EventBus story-001 DONE — `breed_requested` signal must be defined
- Unlocks: Story 002 (Result Reveal Panel — subscribes to `rabbit_born` which fires after `breed_requested` is handled)

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 8/8 passing
**Deviations**: ADVISORY — `parent_a_id`/`parent_b_id` public (not prefixed `_`) for test access; `44` in Vector2(44,44) is a hardcoded UI constant (not gameplay value)
**Test Evidence**: Integration — `tests/integration/ui/breeding_ui_breed_trigger_test.gd` (11 test functions)
**Code Review**: Skipped (lean mode)
