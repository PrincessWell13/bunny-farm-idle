## Unit tests for SaveSystem._resolve_conflict() — Story 004.
## Pure function tests — no I/O, no autoloads, no scene tree required.
extends GdUnitTestSuite

const SaveSystemScript := preload("res://src/core/save_system.gd")

var _system: Node


func before_test() -> void:
	_system = SaveSystemScript.new()


func after_test() -> void:
	_system = null


## AC-1: empty local → cloud wins.
func test_empty_local_returns_cloud() -> void:
	var cloud: Dictionary = {"last_save_timestamp": 100, "prestige_count": 1}
	var result: Dictionary = _system._resolve_conflict({}, cloud)
	assert_int(result["last_save_timestamp"]).is_equal(100)


## AC-2: empty cloud → local wins.
func test_empty_cloud_returns_local() -> void:
	var local: Dictionary = {"last_save_timestamp": 200, "prestige_count": 3}
	var result: Dictionary = _system._resolve_conflict(local, {})
	assert_int(result["last_save_timestamp"]).is_equal(200)
	assert_int(result["prestige_count"]).is_equal(3)


## AC-3: both empty → returns {} (first boot).
func test_both_empty_returns_empty() -> void:
	var result: Dictionary = _system._resolve_conflict({}, {})
	assert_bool(result.is_empty()).is_true()


## AC-4: local timestamp newer → local wins.
func test_local_newer_returns_local() -> void:
	var local: Dictionary = {"last_save_timestamp": 500, "prestige_count": 5}
	var cloud: Dictionary = {"last_save_timestamp": 300, "prestige_count": 2}
	var result: Dictionary = _system._resolve_conflict(local, cloud)
	assert_int(result["prestige_count"]).is_equal(5)


## AC-5: cloud timestamp newer → cloud wins.
func test_cloud_newer_returns_cloud() -> void:
	var local: Dictionary = {"last_save_timestamp": 300, "prestige_count": 2}
	var cloud: Dictionary = {"last_save_timestamp": 500, "prestige_count": 7}
	var result: Dictionary = _system._resolve_conflict(local, cloud)
	assert_int(result["prestige_count"]).is_equal(7)


## AC-6: equal timestamps → local wins (tie-break).
func test_equal_timestamps_returns_local() -> void:
	var local: Dictionary = {"last_save_timestamp": 400, "prestige_count": 2}
	var cloud: Dictionary = {"last_save_timestamp": 400, "prestige_count": 1}
	var result: Dictionary = _system._resolve_conflict(local, cloud)
	assert_int(result["prestige_count"]).is_equal(2)
