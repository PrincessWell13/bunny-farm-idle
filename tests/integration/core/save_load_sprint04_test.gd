## Integration tests for SaveSystem round-trip — Sprint-04 fields (C04-06).
## Verifies food_inventory, farm_plots, and active_expeditions survive serialise/populate.
## Injects GameState and TimeManager for isolation — no autoload access.
extends GdUnitTestSuite

var _system: SaveSystem
var _game_state: GameState
var _time_manager: TimeManager


func before_test() -> void:
	_game_state = GameState.new()
	_time_manager = TimeManager.new()
	_system = SaveSystem.new()
	_system._game_state = _game_state
	_system._time_manager = _time_manager


func after_test() -> void:
	_system = null
	_game_state = null
	_time_manager = null


## AC-1 + AC-5: food_inventory is present in serialised output and round-trips correctly.
func test_serialise_includes_food_inventory_key() -> void:
	_game_state.food_inventory = {"grass": 10, "carrot": 3}
	var data: Dictionary = _system._serialise_game_state()
	assert_bool(data.has("food_inventory")).is_true()
	assert_int((data["food_inventory"] as Dictionary).get("grass", 0)).is_equal(10)
	assert_int((data["food_inventory"] as Dictionary).get("carrot", 0)).is_equal(3)


## AC-2 + AC-6: farm_plots is present in serialised output and round-trips correctly.
func test_serialise_includes_farm_plots_key() -> void:
	_game_state.farm_plots = [
		{"food_id": "carrot", "started_at": 1000, "duration": 300.0},
		{"food_id": "grass",  "started_at": 1500, "duration": 60.0},
	]
	var data: Dictionary = _system._serialise_game_state()
	assert_bool(data.has("farm_plots")).is_true()
	var plots: Array = data["farm_plots"] as Array
	assert_int(plots.size()).is_equal(2)
	assert_str((plots[0] as Dictionary).get("food_id", "")).is_equal("carrot")


## AC-3 + AC-5: _populate_game_state restores food_inventory from save data.
func test_populate_restores_food_inventory() -> void:
	var save_data: Dictionary = {
		"food_inventory": {"grass": 5, "star_carrot": 1},
		"farm_plots": [],
		"active_expeditions": [],
	}
	_system._populate_game_state(save_data)
	assert_int(_game_state.food_inventory.get("grass", 0)).is_equal(5)
	assert_int(_game_state.food_inventory.get("star_carrot", 0)).is_equal(1)


## AC-4 + AC-6: _populate_game_state restores farm_plots from save data.
func test_populate_restores_farm_plots() -> void:
	var plot: Dictionary = {"food_id": "carrot", "started_at": 9999, "duration": 300.0}
	var save_data: Dictionary = {
		"food_inventory": {},
		"farm_plots": [plot],
		"active_expeditions": [],
	}
	_system._populate_game_state(save_data)
	assert_int(_game_state.farm_plots.size()).is_equal(1)
	assert_str((_game_state.farm_plots[0] as Dictionary).get("food_id", "")).is_equal("carrot")
	assert_int((_game_state.farm_plots[0] as Dictionary).get("started_at", 0)).is_equal(9999)


## AC-5 full round-trip: food_inventory survives serialise → wipe → populate intact.
func test_round_trip_food_inventory_all_keys_preserved() -> void:
	_game_state.food_inventory = {"grass": 7, "carrot": 2, "star_carrot": 0}
	var data: Dictionary = _system._serialise_game_state()
	_game_state.food_inventory = {}
	_system._populate_game_state(data)
	assert_int(_game_state.food_inventory.get("grass", -1)).is_equal(7)
	assert_int(_game_state.food_inventory.get("carrot", -1)).is_equal(2)
	assert_int(_game_state.food_inventory.get("star_carrot", -1)).is_equal(0)


## AC-6 full round-trip: farm_plots survive serialise → wipe → populate intact.
func test_round_trip_farm_plots_all_fields_preserved() -> void:
	_game_state.farm_plots = [
		{"food_id": "grass", "started_at": 5000, "duration": 60.0},
	]
	var data: Dictionary = _system._serialise_game_state()
	_game_state.farm_plots = []
	_system._populate_game_state(data)
	assert_int(_game_state.farm_plots.size()).is_equal(1)
	var restored: Dictionary = _game_state.farm_plots[0] as Dictionary
	assert_str(restored.get("food_id", "")).is_equal("grass")
	assert_int(restored.get("started_at", 0)).is_equal(5000)
	assert_float(restored.get("duration", 0.0)).is_equal(60.0)


## AC-7: active_expeditions round-trip preserves all slot fields.
func test_round_trip_active_expeditions_slot_fields_preserved() -> void:
	_game_state.active_expeditions = [
		{
			"slot_id": "exp_0",
			"zone_id": "near_forest",
			"rabbit_ids": ["r1", "r2"],
			"started_at": 12345,
			"duration_seconds": 1800,
			"loot_seed": 42,
			"status": "in_progress",
		}
	]
	var data: Dictionary = _system._serialise_game_state()
	_game_state.active_expeditions = []
	_system._populate_game_state(data)
	assert_int(_game_state.active_expeditions.size()).is_equal(1)
	var slot: Dictionary = _game_state.active_expeditions[0] as Dictionary
	assert_str(slot.get("slot_id", "")).is_equal("exp_0")
	assert_str(slot.get("zone_id", "")).is_equal("near_forest")
	assert_int(slot.get("started_at", 0)).is_equal(12345)
	assert_int(slot.get("loot_seed", 0)).is_equal(42)
	assert_str(slot.get("status", "")).is_equal("in_progress")


## AC-8: _populate_game_state({}) sets food_inventory={} and farm_plots=[] without crash.
func test_populate_empty_dict_defaults_food_and_plots_no_crash() -> void:
	_game_state.food_inventory = {"grass": 99}
	_game_state.farm_plots = [{"food_id": "carrot", "started_at": 0, "duration": 60.0}]
	_system._populate_game_state({})
	assert_int(_game_state.food_inventory.size()).is_equal(0)
	assert_int(_game_state.farm_plots.size()).is_equal(0)
