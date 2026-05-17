## Unit tests for SceneManager overlay stack: push_overlay, pop_overlay, _clear_overlays.
## Story: production/epics/scene-manager/story-002-overlay-stack.md
## _overlay_stack is accessed directly — GDScript _ prefix is convention, not enforced.
extends GdUnitTestSuite

const SceneManagerScript := preload("res://src/core/scene_manager.gd")
const MINIMAL_SCENE_PATH := "res://tests/helpers/minimal_scene.tscn"

var _scene_manager: Node


func before_test() -> void:
	_scene_manager = SceneManagerScript.new()
	add_child(_scene_manager)


func after_test() -> void:
	# goto_scene triggers _clear_overlays — frees all overlays before teardown.
	_scene_manager.goto_scene(MINIMAL_SCENE_PATH)
	var current: Node = _scene_manager.get_current_scene()
	if is_instance_valid(current):
		current.queue_free()
	if is_instance_valid(_scene_manager):
		_scene_manager.queue_free()
	_scene_manager = null


## AC-1: push_overlay loads the scene, adds it to the tree, and appends to stack.
func test_push_overlay_adds_to_stack_and_tree() -> void:
	_scene_manager.push_overlay(MINIMAL_SCENE_PATH)
	assert_int(_scene_manager._overlay_stack.size()).is_equal(1)
	var overlay: Node = _scene_manager._overlay_stack[0]
	assert_bool(overlay.is_inside_tree()).is_true()


## AC-2: pop_overlay removes the top overlay from the stack.
func test_pop_overlay_removes_top_overlay() -> void:
	_scene_manager.push_overlay(MINIMAL_SCENE_PATH)
	_scene_manager.pop_overlay()
	assert_int(_scene_manager._overlay_stack.size()).is_equal(0)


## AC-3: pop_overlay on an empty stack is a no-op — no crash, stack stays empty.
func test_pop_overlay_empty_stack_is_no_op() -> void:
	_scene_manager.pop_overlay()
	assert_int(_scene_manager._overlay_stack.size()).is_equal(0)


## AC-4: pushing two overlays then popping one removes only the top; first remains valid.
func test_push_two_pop_one_leaves_first_overlay() -> void:
	_scene_manager.push_overlay(MINIMAL_SCENE_PATH)
	var first_overlay: Node = _scene_manager._overlay_stack[0]
	_scene_manager.push_overlay(MINIMAL_SCENE_PATH)
	_scene_manager.pop_overlay()
	assert_int(_scene_manager._overlay_stack.size()).is_equal(1)
	assert_bool(is_instance_valid(first_overlay)).is_true()
	assert_bool(first_overlay.is_inside_tree()).is_true()


## AC-5: goto_scene clears the entire overlay stack before transitioning.
func test_goto_scene_clears_overlay_stack() -> void:
	_scene_manager.push_overlay(MINIMAL_SCENE_PATH)
	_scene_manager.push_overlay(MINIMAL_SCENE_PATH)
	_scene_manager.goto_scene(MINIMAL_SCENE_PATH)
	assert_int(_scene_manager._overlay_stack.size()).is_equal(0)
