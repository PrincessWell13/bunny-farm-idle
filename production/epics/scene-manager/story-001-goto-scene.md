# Story 001: goto_scene + get_current_scene

> **Epic**: SceneManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-ui-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Autoload Boot Sequence and GameState Ownership
**ADR Decision Summary**: SceneManager is autoload #6 and owns the active scene stack and transition state. It uses `ResourceLoader` for scene loading and manages scenes as children of the SceneTree root. No other system may change the active scene directly.

**Engine**: Godot 4.6 | **Risk**: LOW (synchronous load path)
**Engine Notes**: Synchronous `load(path)` used for scene loading in this story — the async `ResourceLoader.load_threaded_request()` / `load_threaded_get_status()` / `load_threaded_get()` API is HIGH risk in Godot 4.6 (post-cutoff) and is deferred until verified against the Godot 4.6 docs. Async upgrade is out of scope for this story. `get_tree().root` is the correct parent for scene nodes in an autoload-managed architecture.

**Control Manifest Rules (Foundation layer)**:
- Forbidden: `calling_later_autoload_in_ready` — SceneManager is autoload #6 (last), so all prior autoloads are safe to call; but scenes and non-autoload systems are NOT yet ready during `_ready()`
- Forbidden: `upward_direct_method_calls` — SceneManager must not call Presentation-layer methods directly
- Required: synchronous `load()` only — async ResourceLoader not yet verified for Godot 4.6

---

## Acceptance Criteria

*From GDD section 7 (UI/UX) and ADR-0001 SceneManager Ownership:*

- [ ] `class_name SceneManager extends Node` exists at `src/core/scene_manager.gd`
- [ ] `func goto_scene(path: String) -> void` exists; loads the scene at `path` synchronously and makes it the active scene
- [ ] If a previous active scene exists when `goto_scene` is called, it is freed before the new scene is added
- [ ] `func get_current_scene() -> Node` exists; returns the currently active scene root node (or `null` if none loaded yet)
- [ ] After `goto_scene(path)` succeeds, `get_current_scene()` returns the newly loaded scene's root
- [ ] GdUnit4: `goto_scene` with a valid scene path → `get_current_scene()` is non-null and is in the scene tree
- [ ] GdUnit4: calling `goto_scene` a second time frees the first scene before adding the new one (no memory leak)
- [ ] `_ready()` does NOT call `goto_scene` in this story — boot launch is story-003 scope

---

## Implementation Notes

*Derived from ADR-0001 SceneManager Ownership and boot sequence:*

### Class structure

```gdscript
class_name SceneManager extends Node

var _active_scene: Node = null

func goto_scene(path: String) -> void:
    if is_instance_valid(_active_scene):
        _active_scene.queue_free()
    var packed: PackedScene = load(path) as PackedScene
    _active_scene = packed.instantiate()
    get_tree().root.add_child(_active_scene)

func get_current_scene() -> Node:
    return _active_scene
```

### Scene parenting
Scenes are added as children of `get_tree().root` (the SceneTree root Viewport), NOT as children of the SceneManager autoload node. This matches Godot's expected scene architecture and ensures the active scene renders correctly.

### Synchronous load rationale
`ResourceLoader.load_threaded_request()` is the preferred async API but carries HIGH engine risk in Godot 4.6 (post-cutoff, not verified in engine-reference docs). This story uses `load()` synchronously to stay on LOW-risk, stable API. A loading screen overlay (story-002 scope) hides the brief hitch on mobile. Async upgrade is a separate future story once the API is verified.

### queue_free vs remove_child
`queue_free()` is preferred over `remove_child()` + `free()` — it defers deletion to end of frame, avoiding use-after-free crashes if the old scene's signals are still in flight.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `push_overlay()` / `pop_overlay()` overlay stack
- Story 003: `_ready()` boot launch + `EventBus.nav_tab_pressed` routing
- Future async upgrade: `ResourceLoader.load_threaded_request()` — defer until API verified

---

## QA Test Cases

**AC-1 (goto_scene loads and makes active)**:
- Given: SceneManager node; a minimal test PackedScene resource exists at `tests/helpers/minimal_scene.tscn` (Node with no logic)
- When: `scene_manager.goto_scene("res://tests/helpers/minimal_scene.tscn")` called
- Then: `get_current_scene()` is non-null; `get_current_scene().is_inside_tree()` is true
- Edge cases: path to non-existent resource → GdScript load() returns null; SceneManager should not crash (doc note: invalid path handling is a follow-up)

**AC-2 (second goto_scene frees first)**:
- Given: first scene loaded via `goto_scene`; reference to first scene's root saved
- When: `goto_scene` called with a second scene path
- Then: first scene's root is freed (`is_instance_valid(first_root)` returns false); `get_current_scene()` returns second scene

**AC-3 (get_current_scene before any goto_scene)**:
- Given: fresh SceneManager node (no goto_scene called)
- When: `get_current_scene()` called
- Then: returns `null`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/scene_manager_transitions_test.gd` — must exist and pass

```
tests/integration/core/scene_manager_transitions_test.gd
  test_goto_scene_loads_and_makes_active()
  test_goto_scene_twice_frees_first_scene()
  test_get_current_scene_returns_null_before_any_load()
```

**Test helper required**: `tests/helpers/minimal_scene.tscn` — a PackedScene containing a single Node with no script. Create this file as part of the story implementation.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **None** — SceneManager class creation has no upstream story dependency
- Unlocks: Story 002 (overlay stack requires SceneManager class to exist), Story 003 (boot launch requires goto_scene)

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 8/8 passing
**Deviations**: TR-ui-004 not in tr-registry.yaml (empty registry); control manifest missing — both known infrastructure gaps
**Test Evidence**: Integration: `tests/integration/core/scene_manager_transitions_test.gd` — 3 test functions; `tests/helpers/minimal_scene.tscn` created as test helper
**Code Review**: Skipped — Lean mode
