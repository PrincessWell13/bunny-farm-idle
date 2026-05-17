## Tests for GameState.prestige_reset() selective wipe behaviour.
## Story: production/epics/game-state/story-002-prestige-reset.md
extends GdUnitTestSuite

const GameStateScript := preload("res://src/core/game_state.gd")

var _game_state: Node

func before_test() -> void:
	_game_state = GameStateScript.new()
	add_child(_game_state)

func after_test() -> void:
	_game_state.queue_free()
	_game_state = null


## AC-2: empty keep dict wipes all resetable fields.
func test_empty_keep_clears_all_resetable_fields() -> void:
	_game_state.rabbits = [{"id": "r1"}, {"id": "r2"}]
	_game_state.hutches = [{"id": "h1"}]
	_game_state.active_expeditions = [{"slot": 0}]
	_game_state.collection_registry = {"common_white": true}

	_game_state.prestige_reset({})

	assert_int(_game_state.rabbits.size()).is_equal(0)
	assert_int(_game_state.hutches.size()).is_equal(0)
	assert_int(_game_state.active_expeditions.size()).is_equal(0)
	assert_int(_game_state.collection_registry.size()).is_equal(0)


## AC-3: prestige_count increments by 1 regardless of keep contents.
func test_prestige_count_increments_on_reset() -> void:
	assert_int(_game_state.prestige_count).is_equal(0)
	_game_state.prestige_reset({})
	assert_int(_game_state.prestige_count).is_equal(1)


## AC-3 edge: multiple resets accumulate prestige_count.
func test_multiple_resets_accumulate_prestige_count() -> void:
	_game_state.prestige_reset({})
	_game_state.prestige_reset({})
	assert_int(_game_state.prestige_count).is_equal(2)


## AC-4: keep dict with "rabbits" preserves those rabbits.
func test_keep_dict_preserves_specified_rabbits() -> void:
	var legendary := {"id": "legendary-1", "is_legendary": true}
	_game_state.rabbits = [{"id": "common-1"}, legendary]

	_game_state.prestige_reset({"rabbits": [legendary]})

	assert_int(_game_state.rabbits.size()).is_equal(1)
	assert_str(_game_state.rabbits[0].get("id", "")).is_equal("legendary-1")


## AC-4: keep dict with unrecognised key is silently ignored — no crash.
func test_unknown_keep_key_is_ignored() -> void:
	_game_state.prestige_reset({"unknown_field": [1, 2, 3]})
	assert_int(_game_state.prestige_count).is_equal(1)


## AC-5: settings survive prestige_reset unchanged.
func test_settings_survive_prestige_reset() -> void:
	_game_state.settings["font_scale"] = 2.0
	_game_state.prestige_reset({})
	assert_float(_game_state.settings.get("font_scale", -1.0)).is_equal(2.0)


## AC-5: last_save_timestamp survives prestige_reset unchanged.
func test_last_save_timestamp_survives_prestige_reset() -> void:
	_game_state.last_save_timestamp = 99999
	_game_state.prestige_reset({})
	assert_int(_game_state.last_save_timestamp).is_equal(99999)


## AC-6 + AC-9: is_dirty is true after prestige_reset (mark_dirty called internally).
func test_is_dirty_true_after_prestige_reset() -> void:
	assert_bool(_game_state.is_dirty).is_false()
	_game_state.prestige_reset({})
	assert_bool(_game_state.is_dirty).is_true()
