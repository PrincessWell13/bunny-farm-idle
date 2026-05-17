## Integration tests for SaveSystem boot sequence — Story 005.
## Tests load_game() / save_game() with injected GameState, TimeManager, and MockFirebaseAdapter.
extends GdUnitTestSuite

const TEMP_PATH: String = "user://test_save_system_005_temp.json"

var _system: SaveSystem
var _game_state: GameState
var _time_manager: TimeManager
var _adapter: MockFirebaseAdapter


func before_test() -> void:
	_game_state = GameState.new()
	_time_manager = TimeManager.new()
	_adapter = MockFirebaseAdapter.new()
	_system = SaveSystem.new()
	_system._game_state = _game_state
	_system._time_manager = _time_manager
	_system._save_path = TEMP_PATH
	_cleanup_temp()


func after_test() -> void:
	_cleanup_temp()
	_system = null
	_game_state = null
	_time_manager = null
	_adapter = null


func _cleanup_temp() -> void:
	if FileAccess.file_exists(TEMP_PATH):
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.remove("test_save_system_005_temp.json")


## AC: load_game with _firebase == null loads local only without crash.
func test_load_game_with_null_firebase_loads_local_only() -> void:
	_system._write_local({"prestige_count": 7, "last_save_timestamp": 100})
	await _system.load_game()
	assert_int(_game_state.prestige_count).is_equal(7)


## AC: load_game with MockFirebaseAdapter (signed in, newer cloud) calls fetch_save and uses cloud data.
func test_load_game_with_mock_firebase_calls_fetch_save() -> void:
	_system._write_local({"prestige_count": 1, "last_save_timestamp": 100})
	_adapter.mock_signed_in = true
	_adapter.mock_save_data = {"prestige_count": 5, "last_save_timestamp": 999}
	_system._firebase = _adapter
	await _system.load_game()
	assert_int(_game_state.prestige_count).is_equal(5)


## AC: save_game() resets GameState.is_dirty to false.
func test_save_game_resets_is_dirty() -> void:
	_system._firebase = _adapter
	_adapter.mock_signed_in = false
	_game_state.mark_dirty()
	_system.save_game()
	assert_bool(_game_state.is_dirty).is_false()


## AC: save_game() calls firebase.push_save_async when signed in.
func test_save_game_pushes_to_firebase_when_signed_in() -> void:
	_adapter.mock_signed_in = true
	_system._firebase = _adapter
	_system.save_game()
	assert_bool(_adapter.last_pushed.is_empty()).is_false()


## AC: save_game() skips firebase.push when not signed in.
func test_save_game_skips_firebase_when_not_signed_in() -> void:
	_adapter.mock_signed_in = false
	_system._firebase = _adapter
	_system.save_game()
	assert_bool(_adapter.last_pushed.is_empty()).is_true()


## inject_firebase() stores the adapter in _firebase.
func test_inject_firebase_stores_adapter() -> void:
	_system.inject_firebase(_adapter)
	assert_bool(_system._firebase == _adapter).is_true()
