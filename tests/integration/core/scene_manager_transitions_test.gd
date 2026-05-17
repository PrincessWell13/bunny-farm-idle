## Integration tests for SceneManager goto_scene and get_current_scene.
## Story: production/epics/scene-manager/story-001-goto-scene.md
## Uses tests/helpers/minimal_scene.tscn — a bare Node scene for loading verification.
extends GdUnitTestSuite

const SceneManagerScript := preload("res://src/core/scene_manager.gd")
const MINIMAL_SCENE_PATH := "res://tests/helpers/minimal_scene.tscn"

var _scene_manager: Node


func before_test() -> void:
	_scene_manager = SceneManagerScript.new()
	add_child(_scene_manager)


func after_test() -> void:
	var current: Node = _scene_manager.get_current_scene()
	if is_instance_valid(current):
		current.queue_free()
	if is_instance_valid(_scene_manager):
		_scene_manager.queue_free()
	_scene_manager = null


## AC-3: get_current_scene() returns null before any goto_scene call.
func test_get_current_scene_returns_null_before_any_load() -> void:
	assert_object(_scene_manager.get_current_scene()).is_null()


## AC-6: goto_scene loads the scene and get_current_scene returns it inside the tree.
func test_goto_scene_loads_and_makes_active() -> void:
	_scene_manager.goto_scene(MINIMAL_SCENE_PATH)
	var current: Node = _scene_manager.get_current_scene()
	assert_object(current).is_not_null()
	assert_bool(current.is_inside_tree()).is_true()


## AC-7: calling goto_scene a second time replaces the scene with a new instance.
## Verifies replacement by checking that get_current_scene() returns a different
## Node reference than the first load — proves the scene was swapped, not reused.
func test_goto_scene_twice_replaces_active_scene() -> void:
	_scene_manager.goto_scene(MINIMAL_SCENE_PATH)
	var first_scene: Node = _scene_manager.get_current_scene()
	_scene_manager.goto_scene(MINIMAL_SCENE_PATH)
	var second_scene: Node = _scene_manager.get_current_scene()
	assert_bool(first_scene != second_scene).is_true()
	assert_object(second_scene).is_not_null()
