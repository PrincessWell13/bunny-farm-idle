# Story 003: Boot Launch + nav_tab_pressed Routing

> **Epic**: SceneManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-ui-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (SceneManager boot role), ADR-0003 (EventBus signal consumption pattern)
**ADR Decision Summary**: SceneManager `_ready()` launches the main farm scene after all autoloads are initialised. It connects to `EventBus.nav_tab_pressed` to route each tab to the correct scene or overlay — without holding a reference to the HUD. Tab values are currently `int` (placeholder — `HUD.NavTab` enum is added when HUD epic story-001 is done).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `call_deferred("goto_scene", path)` is used in `_ready()` to defer scene loading until after the current frame — required because SceneManager `_ready()` runs before the main SceneTree frame begins processing. `EventBus.nav_tab_pressed.connect(callable)` — callable-based, no string connect. Both patterns stable in 4.4–4.6.

**Control Manifest Rules (Foundation layer)**:
- Required: callable-based `connect()` — no string-based `connect("signal_name", ...)`
- Required: `call_deferred` for scene launch in `_ready()` — prevents SceneTree frame-order issues
- Forbidden: `upward_direct_method_calls` — SceneManager must not call HUD or Presentation-layer methods

---

## Acceptance Criteria

*From GDD section 7 (≤2 taps via bottom nav bar, 5-tab layout) and ADR-0001 boot sequence + ADR-0003 signal pattern:*

- [ ] `SceneManager._ready()` calls `goto_scene("res://src/ui/screens/main_farm.tscn")` via `call_deferred` (deferred to avoid SceneTree frame-order issues)
- [ ] `SceneManager._ready()` connects to `EventBus.nav_tab_pressed` using callable syntax
- [ ] Tab 0 (Farm) routes to `goto_scene("res://src/ui/screens/main_farm.tscn")`
- [ ] Tab 1 (Breeding) routes to `push_overlay("res://src/ui/screens/breeding_screen.tscn")`
- [ ] Tab 2 (Guild) routes to `push_overlay("res://src/ui/screens/guild_screen.tscn")`
- [ ] Tab 3 (Shop) routes to `push_overlay("res://src/ui/screens/shop_screen.tscn")`
- [ ] Tab 4 (Quest) routes to `push_overlay("res://src/ui/screens/quest_screen.tscn")`
- [ ] No string-based `connect("nav_tab_pressed", ...)` — callable syntax only
- [ ] GdUnit4: emit `EventBus.nav_tab_pressed(0)` → `goto_scene` is triggered (not `push_overlay`)
- [ ] GdUnit4: emit `EventBus.nav_tab_pressed(1)` → `push_overlay` is triggered for breeding path
- [ ] GdUnit4: unknown tab value → no crash; no scene change

---

## Implementation Notes

*Derived from ADR-0001 boot sequence and ADR-0003 connect/emit pattern:*

### _ready() boot and signal connection

```gdscript
func _ready() -> void:
    EventBus.nav_tab_pressed.connect(_on_nav_tab_pressed)
    call_deferred("goto_scene", "res://src/ui/screens/main_farm.tscn")
```

`call_deferred` defers `goto_scene` to the next idle frame — required because `_ready()` for autoload #6 runs before the SceneTree begins its normal processing loop. Without `call_deferred`, adding scene children during `_ready()` can produce subtle SceneTree ordering issues.

### Tab routing

```gdscript
const _SCENE_PATHS: Dictionary = {
    0: "res://src/ui/screens/main_farm.tscn",
}

const _OVERLAY_PATHS: Dictionary = {
    1: "res://src/ui/screens/breeding_screen.tscn",
    2: "res://src/ui/screens/guild_screen.tscn",
    3: "res://src/ui/screens/shop_screen.tscn",
    4: "res://src/ui/screens/quest_screen.tscn",
}

func _on_nav_tab_pressed(tab: int) -> void:
    if _SCENE_PATHS.has(tab):
        goto_scene(_SCENE_PATHS[tab])
    elif _OVERLAY_PATHS.has(tab):
        push_overlay(_OVERLAY_PATHS[tab])
    # Unknown tab values are silently ignored — no crash
```

### Tab value placeholder
`nav_tab_pressed` is currently typed as `int` in EventBus (placeholder). When HUD epic story-001 is done, update the type to `HUD.NavTab` enum and replace integer literals here with enum values. This story uses integer constants directly — document this as a known forward-reference.

### Path constants
Scene and overlay paths are defined as Dictionary constants (not hardcoded inline) so they're visible in one place and easy to update when the Presentation layer scene paths are finalised.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `goto_scene` and `get_current_scene` implementation
- Story 002: `push_overlay` / `pop_overlay` stack
- HUD epic: defines the `HUD.NavTab` enum — update tab type references when that story is DONE
- Presentation layer: actual `main_farm.tscn`, `breeding_screen.tscn`, etc. scene files — those are created by the Presentation layer epics. Scene files do not need to exist for this story's logic tests.

---

## QA Test Cases

**AC-1 (Farm tab routes to goto_scene)**:
- Given: EventBus registered; SceneManager instantiated (story-001 + story-002 done)
- When: `EventBus.nav_tab_pressed.emit(0)`
- Then: `get_current_scene()` changes (goto_scene was called); `_overlay_stack` is cleared

**AC-2 (Breeding tab routes to push_overlay)**:
- Given: EventBus registered; SceneManager ready
- When: `EventBus.nav_tab_pressed.emit(1)`
- Then: `_overlay_stack.size()` increases by 1 (push_overlay was called)
- Note: The actual .tscn file doesn't need to exist for the routing logic test — use a spy/mock that intercepts `push_overlay` calls, or verify via stack size if a test overlay scene is available

**AC-3 (Unknown tab value — no crash)**:
- Given: EventBus registered; SceneManager ready
- When: `EventBus.nav_tab_pressed.emit(99)`
- Then: no error; scene and overlay state unchanged

**AC-4 (No string-based connect)**:
- Given: `src/core/scene_manager.gd` source file
- When: grep for `connect("`
- Then: no matches found (all connects use callable syntax)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/scene_manager_routing_test.gd` — must exist and pass

```
tests/integration/core/scene_manager_routing_test.gd
  test_farm_tab_triggers_goto_scene()
  test_breeding_tab_triggers_push_overlay()
  test_unknown_tab_value_does_not_crash()
  test_no_string_based_connect_in_scene_manager()
```

**Testing pattern**: `Engine.register_singleton("EventBus", ...)` to make EventBus accessible in headless GdUnit4 — same pattern as `economy_manager_signal_test.gd`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **Story 001 DONE** (`goto_scene` must exist) and **Story 002 DONE** (`push_overlay` must exist)
- Unlocks: SceneManager epic COMPLETE — Presentation layer epics can begin implementing actual screen scenes

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 11/11 passing
**Deviations**: TR-ui-004 not in tr-registry.yaml (known infrastructure gap); control-manifest.md missing (known gap); nav_tab_pressed typed as int placeholder pending HUD.NavTab enum (documented forward-reference)
**Test Evidence**: Integration: `tests/integration/core/scene_manager_routing_test.gd` — 4 test functions
**Code Review**: Skipped — Lean mode
