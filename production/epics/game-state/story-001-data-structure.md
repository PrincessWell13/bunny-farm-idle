# Story 001: GameState Data Structure + Initialization

> **Epic**: GameState
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-save-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Autoload Boot Sequence and GameState Ownership
**ADR Decision Summary**: GameState is autoload #4. Its `_ready()` allocates the data tree empty — SaveSystem populates it from disk immediately after. `mark_dirty()` is the sole path to set `is_dirty = true`. No other system writes directly to GameState fields.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Autoload system unchanged in 4.4–4.6. Typed arrays (`Array[RabbitData]`) require the referenced class to exist at parse time — use `Array` for forward-referenced types until their source files exist.

**Control Manifest Rules (Foundation layer)**:
- Required: `mark_dirty()` is the sole entry point to set `is_dirty = true`
- Forbidden: `bypassing_mark_dirty` — never `GameState.is_dirty = true` directly (except SaveSystem resetting it to false)
- Forbidden: `direct_cross_system_state_write` — only GameState methods write GameState fields
- Forbidden: `upward_direct_method_calls` — GameState may not call Feature or Presentation methods

---

## Acceptance Criteria

*From ADR-0001 GameState Data Tree Shape and Dirty-Flag Save Strategy:*

- [ ] `src/core/game_state.gd` exists with `class_name GameState extends Node`
- [ ] All 9 fields declared with correct types: `rabbits`, `hutches`, `prestige_count`, `collection_registry`, `active_expeditions`, `settings`, `last_save_timestamp`, `is_dirty`, `pending_offline_report`
- [ ] `_ready()` initialises `settings` to the default dictionary: `{font_scale: 1.0, colorblind_mode: 0, simplified_mode: false, dark_mode: false}`
- [ ] `mark_dirty() -> void` sets `is_dirty = true` and nothing else
- [ ] No direct `is_dirty = true` assignment anywhere in `game_state.gd` outside `mark_dirty()`
- [ ] GdUnit4: GameState instantiates in isolation with no dependency errors; `is_dirty` starts `false`
- [ ] GdUnit4: `mark_dirty()` sets `is_dirty = true`

---

## Implementation Notes

*Derived from ADR-0001 GameState Data Tree Shape:*

### File skeleton

```gdscript
# src/core/game_state.gd
class_name GameState extends Node

## Complete persistent player data tree.
## Populated by SaveSystem.load_game() after _ready().
## All mutations must call mark_dirty() when done.

var rabbits: Array = []                     # forward-ref: update to Array[RabbitData] when rabbit-system story-001 is done
var hutches: Array = []                     # forward-ref: update to Array[HutchData] when habitat-system is created
var prestige_count: int = 0
var collection_registry: Dictionary = {}   # species_id (String) → discovered (bool)
var active_expeditions: Array[Dictionary] = []
var settings: Dictionary = {}
var last_save_timestamp: int = 0
var is_dirty: bool = false
var pending_offline_report: Variant = null  # forward-ref: update to EarningsReport when idle-production-system story-001 is done

func _ready() -> void:
    settings = {
        "font_scale": 1.0,
        "colorblind_mode": 0,
        "simplified_mode": false,
        "dark_mode": false,
    }

## Sets the dirty flag. SaveSystem polls this every 30 seconds and on background/quit.
## This is the ONLY valid way to mark state as needing a save.
func mark_dirty() -> void:
    is_dirty = true
```

### Forward-reference notes

- **`rabbits: Array`** — ADR-0001 specifies `Array[RabbitData]`. `RabbitData` will have `class_name RabbitData` (ADR-0005). Update this parameter when rabbit-system epic story-001 is complete.
- **`hutches: Array`** — `HutchData` is a Feature-layer type not yet defined. Update when habitat-system epic is created.
- **`pending_offline_report: Variant`** — ADR-0001/ADR-0008 specify `EarningsReport`. Update when idle-production-system epic story-001 is complete.

### What GameState does NOT do

- Does not load or save data — that is SaveSystem's responsibility
- Does not calculate anything — it is a pure data container
- Does not emit signals — callers that mutate data emit the relevant EventBus signal themselves

---

## Out of Scope

*Handled by neighbouring stories:*
- **Story 002**: `prestige_reset()` selective wipe behaviour
- **SaveSystem epic**: serialising and deserialising the data tree to/from JSON
- **Updating forward-ref types**: each downstream epic's story-001 handles its own type update

---

## QA Test Cases

*Story Type: Logic — automated test specs*

**AC-1 + AC-2**: All fields declared with correct initial values
- Given: `GameState` instantiated as a standalone Node
- When: Inspect all field values immediately after `_ready()`
- Then: `rabbits == []`, `hutches == []`, `prestige_count == 0`, `collection_registry == {}`, `active_expeditions == []`, `last_save_timestamp == 0`, `is_dirty == false`, `pending_offline_report == null`
- Edge cases: No field should throw a null-access on first read

**AC-3**: Settings default dictionary
- Given: GameState instantiated; `_ready()` has run
- When: Read `settings`
- Then: `settings["font_scale"] == 1.0`, `settings["colorblind_mode"] == 0`, `settings["simplified_mode"] == false`, `settings["dark_mode"] == false`
- Edge cases: Dict must have exactly these 4 keys (no extras)

**AC-4 + AC-7**: mark_dirty() sets is_dirty
- Given: `GameState` fresh instance; `is_dirty == false`
- When: `game_state.mark_dirty()`
- Then: `is_dirty == true`
- Edge cases: Calling `mark_dirty()` twice is idempotent (stays true)

**AC-5 + AC-6**: No direct is_dirty assignment in file
- Given: `src/core/game_state.gd` source file
- When: Grep for `is_dirty = true` outside of `mark_dirty()`
- Then: Zero matches (only match is inside `func mark_dirty()`)
- Edge cases: `is_dirty = false` IS allowed — SaveSystem resets it after save

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/game_state_init_test.gd` — must exist and pass

```
tests/unit/core/game_state_init_test.gd
  test_fields_have_correct_initial_values()
  test_settings_default_dict_is_correct()
  test_mark_dirty_sets_is_dirty_true()
  test_is_dirty_starts_false()
```

**Status**: [x] Created — `tests/unit/core/game_state_init_test.gd`

---

## Dependencies

- Depends on: None — no other Foundation system is required to parse this file (no typed forward-refs that cause parse errors at this stage)
- Unlocks: Story 002 (prestige_reset builds on the data structure defined here)
- Unlocks: SaveSystem epic (needs GameState fields to be defined before serialisation stories)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 7/7 passing
**Deviations**: TR-save-001 not in tr-registry.yaml (empty registry); control manifest missing
**Test Evidence**: Logic: `tests/unit/core/game_state_init_test.gd` — 6 test functions
**Code Review**: Skipped — Lean mode
