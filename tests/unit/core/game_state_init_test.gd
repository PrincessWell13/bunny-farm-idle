## Tests that GameState initialises with correct field values and mark_dirty() works.
## Story: production/epics/game-state/story-001-data-structure.md
extends GdUnitTestSuite

const GameStateScript := preload("res://src/core/game_state.gd")

var _game_state: Node

func before_test() -> void:
	_game_state = GameStateScript.new()
	add_child(_game_state)

func after_test() -> void:
	_game_state.queue_free()
	_game_state = null


## AC-1/AC-2: All collection fields start empty; scalar fields start at zero/null.
func test_fields_have_correct_initial_values() -> void:
	assert_int(_game_state.rabbits.size()).is_equal(0)
	assert_int(_game_state.hutches.size()).is_equal(0)
	assert_int(_game_state.prestige_count).is_equal(0)
	assert_int(_game_state.collection_registry.size()).is_equal(0)
	assert_int(_game_state.active_expeditions.size()).is_equal(0)
	assert_int(_game_state.last_save_timestamp).is_equal(0)
	assert_bool(_game_state.pending_offline_report == null).is_true()


## AC-6: is_dirty must start false so the first mark_dirty() call is meaningful.
func test_is_dirty_starts_false() -> void:
	assert_bool(_game_state.is_dirty).is_false()


## AC-3: settings default dictionary has all 4 required keys with correct values.
func test_settings_default_dict_is_correct() -> void:
	assert_float(_game_state.settings.get("font_scale", -1.0)).is_equal(1.0)
	assert_int(_game_state.settings.get("colorblind_mode", -1)).is_equal(0)
	assert_bool(_game_state.settings.get("simplified_mode", true)).is_false()
	assert_bool(_game_state.settings.get("dark_mode", true)).is_false()


## AC-4/AC-7: mark_dirty() transitions is_dirty from false to true.
func test_mark_dirty_sets_is_dirty_true() -> void:
	assert_bool(_game_state.is_dirty).is_false()
	_game_state.mark_dirty()
	assert_bool(_game_state.is_dirty).is_true()


## AC-4 edge: calling mark_dirty() twice is idempotent.
func test_mark_dirty_is_idempotent() -> void:
	_game_state.mark_dirty()
	_game_state.mark_dirty()
	assert_bool(_game_state.is_dirty).is_true()


## AC-5: the forbidden pattern `is_dirty = true` appears exactly once in the source
## file — inside mark_dirty() and nowhere else.
func test_no_direct_is_dirty_assignment_outside_mark_dirty() -> void:
	var file := FileAccess.open("res://src/core/game_state.gd", FileAccess.READ)
	assert_bool(file != null).is_true()
	var content: String = file.get_as_text()
	file.close()
	assert_int(content.count("is_dirty = true")).is_equal(1)
