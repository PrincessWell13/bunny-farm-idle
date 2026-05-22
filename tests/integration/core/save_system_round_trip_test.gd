## Integration tests for SaveSystem serialise/deserialise round-trip — Story 003.
## Injects GameState and TimeManager instances directly for isolation (no autoload dependency).
extends GdUnitTestSuite

const SaveSystemScript := preload("res://src/core/save_system.gd")
const GameStateScript := preload("res://src/core/game_state.gd")
const TimeManagerScript := preload("res://src/core/time_manager.gd")

var _system: Node
var _game_state: Node
var _time_manager: Node


func before_test() -> void:
	_game_state = GameStateScript.new()
	_time_manager = TimeManagerScript.new()
	_system = SaveSystemScript.new()
	_system._game_state = _game_state
	_system._time_manager = _time_manager


func after_test() -> void:
	_system = null
	_game_state = null
	_time_manager = null


func _make_rabbit(id: String) -> RabbitData:
	var r := RabbitData.new()
	r.rabbit_id = id
	r.display_name = "Test Rabbit " + id
	r.hunger = 80.0
	r.health = 90.0
	r.stage = RabbitData.RabbitStage.ADULT
	return r


## AC-1: round-trip preserves two rabbits — size and first rabbit_id match.
func test_round_trip_preserves_two_rabbits() -> void:
	_game_state.rabbits = [_make_rabbit("r1"), _make_rabbit("r2")]
	var data: Dictionary = _system._serialise_game_state()
	_game_state.rabbits = []
	_system._populate_game_state(data)
	assert_int(_game_state.rabbits.size()).is_equal(2)
	assert_str((_game_state.rabbits[0] as RabbitData).rabbit_id).is_equal("r1")


## AC-1 edge: empty rabbit array round-trips to empty array.
func test_round_trip_preserves_empty_rabbit_array() -> void:
	_game_state.rabbits = []
	var data: Dictionary = _system._serialise_game_state()
	_system._populate_game_state(data)
	assert_int(_game_state.rabbits.size()).is_equal(0)


## AC-3: prestige_count is preserved through full round-trip.
func test_round_trip_preserves_prestige_count() -> void:
	_game_state.prestige_count = 5
	var data: Dictionary = _system._serialise_game_state()
	_game_state.prestige_count = 0
	_system._populate_game_state(data)
	assert_int(_game_state.prestige_count).is_equal(5)


## collection_registry survives round-trip with correct bool values.
func test_round_trip_preserves_collection_registry() -> void:
	_game_state.collection_registry = {"white": true, "brown": false}
	var data: Dictionary = _system._serialise_game_state()
	_game_state.collection_registry = {}
	_system._populate_game_state(data)
	assert_bool(_game_state.collection_registry.get("white", false)).is_true()
	assert_bool(_game_state.collection_registry.get("brown", true)).is_false()


## AC-2: _populate_game_state({}) sets defaults without crash.
func test_populate_with_empty_dict_uses_defaults_no_crash() -> void:
	_system._populate_game_state({})
	assert_int(_game_state.prestige_count).is_equal(0)
	assert_int(_game_state.rabbits.size()).is_equal(0)


## AC-4: GameState.is_dirty is true after _populate_game_state().
func test_populate_calls_mark_dirty() -> void:
	_system._populate_game_state({})
	assert_bool(_game_state.is_dirty).is_true()
