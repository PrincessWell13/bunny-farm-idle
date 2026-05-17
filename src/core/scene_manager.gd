## SceneManager — owns scene transitions and the overlay stack.
## Autoload #6 (last). All prior autoloads are guaranteed ready before _ready() runs.
## goto_scene() is called via call_deferred in _ready() to avoid SceneTree frame-order
## issues at boot. See ADR-0001 for boot sequence and ownership rules.
class_name SceneManager extends Node

const _SCENE_PATHS: Dictionary = {
	0: "res://src/ui/screens/main_farm.tscn",
}

## Tabs 1-4 push overlays over the active scene rather than replacing it.
## Update tab keys to HUD.NavTab enum values when HUD epic story-001 is done.
const _OVERLAY_PATHS: Dictionary = {
	1: "res://src/ui/screens/breeding_screen.tscn",
	2: "res://src/ui/screens/guild_screen.tscn",
	3: "res://src/ui/screens/shop_screen.tscn",
	4: "res://src/ui/screens/quest_screen.tscn",
}

var _active_scene: Node = null
var _overlay_stack: Array[Node] = []


func _ready() -> void:
	EventBus.nav_tab_pressed.connect(_on_nav_tab_pressed)
	call_deferred("goto_scene", "res://src/ui/screens/main_farm.tscn")

## Replaces the current active scene with the scene loaded from path (synchronous).
## Clears all overlays, then frees the previous active scene before adding the new one.
## Note: async ResourceLoader upgrade is deferred — verify API in Godot 4.6 docs first.
func goto_scene(path: String) -> void:
	_clear_overlays()
	if is_instance_valid(_active_scene):
		_active_scene.queue_free()
	var packed: PackedScene = load(path) as PackedScene
	_active_scene = packed.instantiate()
	get_tree().root.add_child(_active_scene)

## Returns the current active scene root node, or null if no scene has been loaded yet.
func get_current_scene() -> Node:
	return _active_scene

## Loads the scene at path and pushes it as an overlay above the current active scene.
func push_overlay(path: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	var overlay: Node = packed.instantiate()
	get_tree().root.add_child(overlay)
	_overlay_stack.append(overlay)

## Removes and frees the top overlay. No-op if the overlay stack is empty.
func pop_overlay() -> void:
	if _overlay_stack.is_empty():
		return
	var top: Node = _overlay_stack.pop_back()
	if is_instance_valid(top):
		top.queue_free()

func _clear_overlays() -> void:
	for overlay in _overlay_stack:
		if is_instance_valid(overlay):
			overlay.queue_free()
	_overlay_stack.clear()


func _on_nav_tab_pressed(tab: int) -> void:
	if _SCENE_PATHS.has(tab):
		goto_scene(_SCENE_PATHS[tab])
	elif _OVERLAY_PATHS.has(tab):
		push_overlay(_OVERLAY_PATHS[tab])
