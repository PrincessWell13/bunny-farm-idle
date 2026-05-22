## Unit tests for SaveSystem._load_local() and _write_local() — Story 002.
## Uses a redirected _save_path (temp file) for deterministic test isolation.
extends GdUnitTestSuite

const SaveSystemScript := preload("res://src/core/save_system.gd")
const TEMP_PATH: String = "user://test_save_system_002_temp.json"

var _system: Node


func before_test() -> void:
	_system = SaveSystemScript.new()
	_system._save_path = TEMP_PATH
	_cleanup_temp_file()


func after_test() -> void:
	_cleanup_temp_file()
	_system = null


func _cleanup_temp_file() -> void:
	if FileAccess.file_exists(TEMP_PATH):
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.remove("test_save_system_002_temp.json")


## AC-1: _load_local() returns {} when file does not exist.
func test_load_local_returns_empty_dict_when_file_absent() -> void:
	var result: Dictionary = _system._load_local()
	assert_bool(result.is_empty()).is_true()


## AC-1 edge: calling twice when absent still returns {}.
func test_load_local_returns_empty_dict_on_repeated_calls_when_absent() -> void:
	var first: Dictionary = _system._load_local()
	var second: Dictionary = _system._load_local()
	assert_bool(first.is_empty()).is_true()
	assert_bool(second.is_empty()).is_true()


## AC-2: _load_local() returns {} when file contains malformed JSON.
func test_load_local_returns_empty_dict_on_corrupted_file() -> void:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	file.store_string("not valid json {{{")
	file.close()
	var result: Dictionary = _system._load_local()
	assert_bool(result.is_empty()).is_true()


## AC-3: round-trip — _write_local then _load_local returns original fields.
func test_write_local_then_load_local_round_trip() -> void:
	_system._write_local({"prestige_count": 3, "last_save_timestamp": 99999})
	var result: Dictionary = _system._load_local()
	assert_int(result["prestige_count"]).is_equal(3)
	assert_int(result["last_save_timestamp"]).is_equal(99999)


## AC-4: _write_local() adds _version field equal to 1 to the written JSON.
func test_write_local_adds_version_field() -> void:
	_system._write_local({})
	var result: Dictionary = _system._load_local()
	assert_int(result["_version"]).is_equal(1)


## AC-5: written file is independently parseable by JSON.parse_string().
func test_written_json_is_parseable() -> void:
	_system._write_local({"carrot_coin": 500})
	var file := FileAccess.open(TEMP_PATH, FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	assert_bool(parsed != null).is_true()
	assert_bool(parsed is Dictionary).is_true()


## _write_local() does not mutate the caller's dictionary.
func test_write_local_does_not_mutate_caller_dict() -> void:
	var original: Dictionary = {"carrot_coin": 100}
	_system._write_local(original)
	assert_bool(original.has("_version")).is_false()
	assert_bool(original.has("_comment")).is_false()
