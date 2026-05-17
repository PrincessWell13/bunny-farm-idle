# Story 002: Overlay Stack — push_overlay / pop_overlay

> **Epic**: SceneManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-ui-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Autoload Boot Sequence and GameState Ownership
**ADR Decision Summary**: SceneManager owns the active scene stack and transition state. Overlays (Breeding panel, Shop, Guild) are pushed on top of the main farm view and popped when dismissed. The overlay stack is independent of the active scene — the main farm scene stays in the tree while overlays are layered over it.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Overlay nodes are loaded via synchronous `load()` and added as children of `get_tree().root` above the active scene. `queue_free()` is used to remove overlays. No post-cutoff APIs required.

**Control Manifest Rules (Foundation layer)**:
- Forbidden: `upward_direct_method_calls` — no Presentation-layer method calls from SceneManager
- Required: `pop_overlay()` on an empty stack must be a no-op, not a crash

---

## Acceptance Criteria

*From GDD section 7 (5-tab navigation with overlay panels) and ADR-0001:*

- [ ] `func push_overlay(path: String) -> void` exists; loads the scene at `path` and adds it above the current active scene
- [ ] `func pop_overlay() -> void` exists; removes and frees the top overlay from the stack
- [ ] `_overlay_stack: Array[Node]` tracks all active overlays in push order
- [ ] After `push_overlay(path)`, the overlay node is on top of the active scene in the scene tree
- [ ] `pop_overlay()` on an empty stack is a no-op (does not crash)
- [ ] `pop_overlay()` removes only the top overlay; other overlays and the active scene remain
- [ ] `goto_scene()` (from story-001) clears all overlays when transitioning to a new scene (overlay stack is reset on scene change)
- [ ] GdUnit4: `push_overlay` → overlay in tree; `pop_overlay` → overlay freed and removed from stack
- [ ] GdUnit4: `pop_overlay` on empty stack → no error; stack remains empty
- [ ] GdUnit4: push 2 overlays, pop 1 → one overlay remains

---

## Implementation Notes

*Derived from ADR-0001 and GDD overlay navigation pattern:*

### Overlay stack additions to SceneManager

```gdscript
var _overlay_stack: Array[Node] = []

func push_overlay(path: String) -> void:
    var packed: PackedScene = load(path) as PackedScene
    var overlay: Node = packed.instantiate()
    get_tree().root.add_child(overlay)
    _overlay_stack.append(overlay)

func pop_overlay() -> void:
    if _overlay_stack.is_empty():
        return
    var top: Node = _overlay_stack.pop_back()
    if is_instance_valid(top):
        top.queue_free()
```

### Clearing overlays on scene change

`goto_scene()` must clear the overlay stack before transitioning to prevent orphaned overlays when the player navigates to a new main screen:

```gdscript
func goto_scene(path: String) -> void:
    _clear_overlays()
    if is_instance_valid(_active_scene):
        _active_scene.queue_free()
    var packed: PackedScene = load(path) as PackedScene
    _active_scene = packed.instantiate()
    get_tree().root.add_child(_active_scene)

func _clear_overlays() -> void:
    for overlay in _overlay_stack:
        if is_instance_valid(overlay):
            overlay.queue_free()
    _overlay_stack.clear()
```

### Overlay z-ordering
Overlays added after the active scene are rendered on top naturally in Godot's node order. No explicit z-index manipulation is required for the Foundation layer — visual ordering refinements (CanvasLayer, z_index) are Presentation layer scope.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `goto_scene` and `get_current_scene` core methods — must be DONE first
- Story 003: `EventBus.nav_tab_pressed` routing that triggers `push_overlay` for specific tabs
- Presentation layer: CanvasLayer z-ordering, transition animations, dimming backdrop for overlays

---

## QA Test Cases

**AC-1 (push_overlay adds to tree and stack)**:
- Given: SceneManager with active scene; minimal overlay scene at `tests/helpers/minimal_scene.tscn`
- When: `push_overlay("res://tests/helpers/minimal_scene.tscn")` called
- Then: overlay is a child of scene tree root; `_overlay_stack.size() == 1`

**AC-2 (pop_overlay removes top overlay)**:
- Given: one overlay pushed
- When: `pop_overlay()` called
- Then: overlay node is freed (`is_instance_valid` returns false); `_overlay_stack.size() == 0`

**AC-3 (pop_overlay on empty stack is no-op)**:
- Given: fresh SceneManager; no overlays pushed
- When: `pop_overlay()` called
- Then: no error; `_overlay_stack.size() == 0`

**AC-4 (push 2, pop 1 — only top removed)**:
- Given: two overlays pushed (A then B)
- When: `pop_overlay()` called
- Then: B is freed; A is still valid and in tree; `_overlay_stack.size() == 1`

**AC-5 (goto_scene clears all overlays)**:
- Given: two overlays pushed; references saved
- When: `goto_scene("res://tests/helpers/minimal_scene.tscn")` called
- Then: both overlay references are freed; `_overlay_stack.size() == 0`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/scene_manager_overlay_test.gd` — must exist and pass

```
tests/unit/core/scene_manager_overlay_test.gd
  test_push_overlay_adds_to_stack_and_tree()
  test_pop_overlay_removes_top_overlay()
  test_pop_overlay_empty_stack_is_no_op()
  test_push_two_pop_one_leaves_first_overlay()
  test_goto_scene_clears_overlay_stack()
```

**Note**: `tests/helpers/minimal_scene.tscn` created in story-001 is reused here.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **Story 001 must be DONE** — `goto_scene()` and `SceneManager` class must exist before overlay methods can be added
- Unlocks: Story 003 (nav routing calls `push_overlay` for Breeding/Shop/Guild tabs)

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 10/10 passing
**Deviations**: `goto_scene()` (story-001 file) modified to add `_clear_overlays()` call — required by AC-7, intentional cross-story modification; TR-ui-004 not in tr-registry.yaml; control manifest missing — known infrastructure gaps
**Test Evidence**: Logic: `tests/unit/core/scene_manager_overlay_test.gd` — 5 test functions
**Code Review**: Skipped — Lean mode
