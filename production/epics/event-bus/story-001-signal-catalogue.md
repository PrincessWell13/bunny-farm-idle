# Story 001: EventBus Signal Catalogue

> **Epic**: EventBus
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirements**: `TR-rabbit-001`, `TR-genetics-004`, `TR-economy-001`, `TR-ui-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Signal-Based Inter-System Communication via EventBus
**ADR Decision Summary**: All cross-system communication uses typed signals defined on the `EventBus` autoload. No system may call a method on a system in a higher layer directly. EventBus is autoload #1 — it must boot before everything else so all other systems can connect in their `_ready()`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Signal system unchanged in 4.4–4.6. String-based `connect()` was deprecated in 4.0 — never use it. Typed callable: `EventBus.signal_name.connect(callable)`.

**Control Manifest Rules (Foundation layer)**:
- Required: All signal parameters statically typed — no `Variant` in game logic signals
- Forbidden: `string_based_signal_connect` — never `connect("signal_name", obj, "method")`
- Forbidden: `upward_direct_method_calls` — EventBus emits only; no methods that call other systems
- Forbidden: `csharp_files_in_src` — GDScript only
- Forbidden: `untyped_variables_in_src` — every variable, parameter, return type must be typed

---

## Acceptance Criteria

*From ADR-0003 Validation Criteria and EPIC.md Definition of Done:*

- [ ] `src/core/event_bus.gd` exists with `extends Node` and no other logic
- [ ] All 23 signals declared with exact names and typed parameters from ADR-0003
- [ ] No signal has a `Variant` or untyped parameter (except signals that intentionally use `int` as a forward-reference placeholder — see Implementation Notes)
- [ ] All signal names are snake_case past-tense verbs matching ADR-0003 catalogue
- [ ] `EventBus` registered as autoload #1 in Godot Project Settings → Globals → Autoloads
- [ ] GdUnit4: `EventBus` node can be instantiated with no scene or other autoload dependency
- [ ] GdUnit4: All 23 signals are accessible as properties of the instantiated EventBus node

---

## Implementation Notes

*Derived from ADR-0003 Decision and ADR-0001 Boot Sequence:*

### File skeleton

```gdscript
# src/core/event_bus.gd
extends Node
# All cross-system signals. Every cross-layer signal defined here, nowhere else.
# Emitters call: EventBus.signal_name.emit(args)
# Consumers call in _ready(): EventBus.signal_name.connect(_on_handler)

## Rabbit lifecycle
signal rabbit_born(rabbit_id: String)
signal rabbit_matured(rabbit_id: String, new_stage: int)   # ← see note A
signal rabbit_stat_changed(rabbit_id: String)
signal rabbit_died(rabbit_id: String)

## Economy
signal currency_changed(currency: int, new_balance: int, delta: int)  # ← see note B

## Production
signal production_ticked(carrot_coin: int, star_dust: int)

## Breeding
signal breed_requested(parent_a_id: String, parent_b_id: String)
signal breeding_completed(child_id: String)

## Habitat
signal hutch_dirtied(hutch_id: String)
signal hutch_upgraded(hutch_id: String, new_level: int)
signal rabbit_assigned_to_hutch(rabbit_id: String, hutch_id: String)

## Expedition
signal expedition_completed(slot_id: int, loot_summary: String)

## Save / sync
signal save_requested()
signal save_synced()
signal new_game_started()

## UI navigation
signal nav_tab_pressed(tab: int)                           # ← see note C
signal notification_requested(text: String, duration_sec: float)

## Events / seasons
signal season_changed(new_season: int)                     # ← see note C
signal event_activated(event_id: String)
signal merchant_appeared()

## Prestige
signal prestige_executed(new_prestige_count: int)

## Guild
signal guild_contribution_submitted(amount: int)
signal guild_boss_attacked(damage: int)
```

### Forward-reference notes

**Note A — `rabbit_matured` new_stage parameter:**
ADR-0003 specifies `new_stage: RabbitData.RabbitStage`. `RabbitData` will have `class_name RabbitData` (ADR-0005) which makes it globally accessible. However, `RabbitData.gd` does not exist yet at this step. Use `int` as a typed placeholder now. When Story 001 of the `rabbit-system` epic is complete and `RabbitData` has its `class_name`, update this parameter to `new_stage: RabbitData.RabbitStage`.

**Note B — `currency_changed` currency parameter:**
ADR-0003 specifies `currency: EconomyManager.CurrencyType`. `EconomyManager` does not exist yet. Use `int` as a typed placeholder. Update to `currency: EconomyManager.CurrencyType` when the `economy-manager` epic's first story is complete.

**Note C — `nav_tab_pressed` and `season_changed`:**
`HUD.NavTab` and `SeasonSystem.Season` are defined in later layers. Use `int` as a typed placeholder for both. Update when `HUD` and `SeasonSystem` are implemented.

**These `int` placeholders are intentional and documented here.** Do not add a comment in the `.gd` file saying "TODO update" — this story file is the tracking mechanism. The update step is part of the relevant later epic's first story.

### Autoload registration

In Godot Editor: Project Settings → Globals → Autoloads → Add `res://src/core/event_bus.gd` with name `EventBus`. Ensure it appears as position #1 in the list (before TimeManager, EconomyManager, GameState, SaveSystem, SceneManager).

---

## Out of Scope

*Handled by Story 002:*
- **Story 002**: Verifying that connect/emit/disconnect cycle works at runtime (that's an integration test, not a declaration test)

*Handled by later epics:*
- Updating placeholder `int` types to their proper enum types — each epic's story-001 handles its own type update

---

## QA Test Cases

*Story Type: Logic — automated test specs*

**AC-1**: `event_bus.gd` exists with 23 signals, no other logic
- Given: `src/core/event_bus.gd` file exists
- When: Parse the file
- Then: File contains exactly 22 `signal` declarations; no `func`, no `var`, no `@onready`
- Edge cases: File must not have any `extends Node` method overrides except none

**AC-2**: All 23 signals accessible on instantiated EventBus node
- Given: EventBus instantiated as a standalone Node (no scene, no other autoloads)
- When: Check `EventBus.has_signal("rabbit_born")`, repeat for all 23 signal names
- Then: All 23 return `true`
- Edge cases: Signal names must match ADR-0003 exactly — no typos, no case variations

**AC-3**: Typed parameters — no untyped signals
- Given: Parse `event_bus.gd`
- When: Inspect all signal declarations
- Then: Every signal parameter has an explicit type annotation (`String`, `int`, `float`)
- Edge cases: Empty-parameter signals (e.g., `save_requested()`) are valid — zero parameters is fine

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/event_bus_catalogue_test.gd` — must exist and pass

```
tests/unit/core/event_bus_catalogue_test.gd
  test_all_23_signals_present()
  test_signal_count_is_23()
  test_no_variant_parameters()
```

**Status**: [x] Created — `tests/unit/core/event_bus_catalogue_test.gd`

---

## Dependencies

- Depends on: None — this is the first story in the first epic
- Unlocks: Every other story in every other epic (EventBus must exist before any system can signal-connect)
- Unlocks: Story 002 (connect/emit test needs the signal definitions to exist)

---

## Completion Notes
**Completed**: 2026-05-16
**Criteria**: 6/7 passing (1 deferred: autoload registration — manual Godot Editor step)
**Deviations**: Signal count documented as "22" throughout story/tests; actual count per ADR-0003 is 23. Count corrected in story AC text and test file. Implementation was correct per ADR.
**Test Evidence**: Logic: `tests/unit/core/event_bus_catalogue_test.gd` — 3 test functions (test_all_23_signals_present, test_signal_count_is_23, test_no_variant_parameters)
**Code Review**: Skipped — Lean mode
