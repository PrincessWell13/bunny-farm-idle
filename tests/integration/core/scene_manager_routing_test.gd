## Integration tests for SceneManager boot launch and nav_tab_pressed routing.
## Story: production/epics/scene-manager/story-003-boot-nav-routing.md
## MockSceneManager overrides goto_scene/push_overlay to record calls instead of loading
## .tscn files — which don't exist yet (Presentation layer is not built).
## The mock is NOT added to the tree so _ready() does not fire and pre-populate goto_calls.
extends GdUnitTestSuite

const EventBusScript := preload("res://src/core/event_bus.gd")


## Records routing calls without loading real scene files.
class MockSceneManager extends SceneManager:
	var goto_calls: Array[String] = []
	var overlay_calls: Array[String] = []

	func goto_scene(path: String) -> void:
		goto_calls.append(path)

	func push_overlay(path: String) -> void:
		overlay_calls.append(path)


var _event_bus: Node
var _scene_manager: MockSceneManager
var _owned_event_bus: bool = false


func before_test() -> void:
	_owned_event_bus = false
	if Engine.has_singleton("EventBus"):
		_event_bus = Engine.get_singleton("EventBus")
	else:
		_event_bus = EventBusScript.new()
		Engine.register_singleton("EventBus", _event_bus)
		add_child(_event_bus)
		_owned_event_bus = true
	## Not added to the scene tree — avoids _ready() firing and pre-populating goto_calls.
	## The signal connection below gives it the same routing wiring _ready() would provide.
	_scene_manager = MockSceneManager.new()
	_event_bus.nav_tab_pressed.connect(_scene_manager._on_nav_tab_pressed)


func after_test() -> void:
	if is_instance_valid(_event_bus) and _event_bus.nav_tab_pressed.is_connected(_scene_manager._on_nav_tab_pressed):
		_event_bus.nav_tab_pressed.disconnect(_scene_manager._on_nav_tab_pressed)
	if is_instance_valid(_scene_manager):
		_scene_manager.free()
	_scene_manager = null
	if _owned_event_bus:
		Engine.unregister_singleton("EventBus")
		if is_instance_valid(_event_bus):
			_event_bus.queue_free()
	_event_bus = null


## AC-1: Tab 0 (Farm) routes to goto_scene with main_farm path, not push_overlay.
func test_farm_tab_triggers_goto_scene() -> void:
	_event_bus.nav_tab_pressed.emit(0)
	assert_int(_scene_manager.goto_calls.size()).is_equal(1)
	assert_str(_scene_manager.goto_calls[0]).is_equal("res://src/ui/screens/main_farm.tscn")
	assert_int(_scene_manager.overlay_calls.size()).is_equal(0)


## AC-2: Tab 1 (Breeding) routes to push_overlay with breeding path, not goto_scene.
func test_breeding_tab_triggers_push_overlay() -> void:
	_event_bus.nav_tab_pressed.emit(1)
	assert_int(_scene_manager.overlay_calls.size()).is_equal(1)
	assert_str(_scene_manager.overlay_calls[0]).is_equal("res://src/ui/screens/breeding_screen.tscn")
	assert_int(_scene_manager.goto_calls.size()).is_equal(0)


## AC-3: Unrecognised tab value produces no error and leaves routing state unchanged.
func test_unknown_tab_value_does_not_crash() -> void:
	_event_bus.nav_tab_pressed.emit(99)
	assert_int(_scene_manager.goto_calls.size()).is_equal(0)
	assert_int(_scene_manager.overlay_calls.size()).is_equal(0)


## AC-4: scene_manager.gd uses callable syntax only — no deprecated string-based connect.
func test_no_string_based_connect_in_scene_manager() -> void:
	var source := FileAccess.open("res://src/core/scene_manager.gd", FileAccess.READ)
	assert_bool(source != null).is_true()
	var content := source.get_as_text()
	source.close()
	assert_bool(content.find('connect("nav_tab_pressed"') >= 0).is_false()
