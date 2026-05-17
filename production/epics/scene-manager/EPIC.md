# Epic: SceneManager

> **Layer**: Foundation
> **GDD**: design/gdd/bunny-farm-idle-master.md
> **Architecture Module**: `src/core/scene_manager.gd`
> **Status**: Ready
> **Control Manifest Version**: pending — run `/create-control-manifest` to assign
> **Stories**: Not yet created — run `/create-stories scene-manager`

## Overview

SceneManager is autoload #6 — the last to initialise, so it launches the first scene only after all data is loaded from SaveSystem. It owns the active scene stack and transition state, handles async scene loading to avoid hitches, and manages overlay screens (breeding panel, shop, guild) that push/pop over the main farm view. The HUD's bottom nav bar dispatches `nav_tab_pressed` signals that SceneManager consumes to drive navigation.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | SceneManager is autoload #6; launches first scene via `goto_scene()` in `_ready()`; all other autoloads guaranteed ready | LOW |
| ADR-0003: EventBus Signals | Listens to `nav_tab_pressed` from HUD; calls `goto_scene()` or `push_overlay()` accordingly | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-ui-004 | ≤2 taps for frequent actions | ADR-0003 ✅ (nav_tab_pressed routes scenes) |

> ⚠️ Untraced: `ResourceLoader.load_threaded_request()` async API — verify in Godot 4.6 before implementing async scene loading. Engine risk: HIGH for this specific API.

## Key Interfaces

```gdscript
class_name SceneManager extends Node

func goto_scene(path: String) -> void       # replace current scene (async)
func push_overlay(path: String) -> void     # add overlay over current scene
func pop_overlay() -> void                  # remove top overlay
func get_current_scene() -> Node            # returns active scene root
```

## Engine Verification Required

- `ResourceLoader.load_threaded_request()` + `load_threaded_get_status()` + `load_threaded_get()` — verify these async scene loading APIs are stable in Godot 4.6 before implementing the async path. Fallback: synchronous `load()` with a loading screen Node.

## Forbidden Patterns (from Architecture Registry)

- `calling_later_autoload_in_ready` — not applicable (SceneManager is last autoload); but must not call any non-autoload system in `_ready()`
- `upward_direct_method_calls` — SceneManager may not call Presentation methods; HUD signals via EventBus only

## Definition of Done

This epic is complete when:
- [ ] All stories are implemented, reviewed, and closed via `/story-done`
- [ ] `SceneManager` autoload registered as #6 in Godot Project Settings
- [ ] `goto_scene("res://src/ui/screens/main_farm.tscn")` transitions without hitches on target Android device
- [ ] `push_overlay()` / `pop_overlay()` manage overlay stack correctly
- [ ] `nav_tab_pressed` signal routes to correct scene/overlay (GdUnit4 + manual test)
- [ ] Async scene loading verified working in exported Android build (manual test)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [goto_scene + get_current_scene](story-001-goto-scene.md) | Integration | Complete | ADR-0001 |
| 002 | [Overlay Stack — push_overlay / pop_overlay](story-002-overlay-stack.md) | Logic | Complete | ADR-0001 |
| 003 | [Boot Launch + nav_tab_pressed Routing](story-003-boot-nav-routing.md) | Integration | Complete | ADR-0001 + ADR-0003 |

## Next Step

Run `/dev-story production/epics/scene-manager/story-001-goto-scene.md` to begin implementation.
