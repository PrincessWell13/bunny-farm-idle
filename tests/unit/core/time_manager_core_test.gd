## Tests for TimeManager core time tracking and offline delta calculation.
## Story: production/epics/time-manager/story-001-core-time-tracking.md
extends GdUnitTestSuite

const TimeManagerScript := preload("res://src/core/time_manager.gd")

var _time_manager: Node

func before_test() -> void:
	_time_manager = TimeManagerScript.new()
	add_child(_time_manager)

func after_test() -> void:
	_time_manager.queue_free()
	_time_manager = null


## AC-1: offline delta is 0.0 before mark_session_start is ever called.
func test_offline_delta_is_zero_before_mark_session_start() -> void:
	assert_float(_time_manager.get_offline_delta()).is_equal(0.0)


## AC-2: offline delta is positive after mark_session_start with a past timestamp.
func test_offline_delta_positive_after_mark_session_start_with_past_timestamp() -> void:
	var one_hour_ago: int = int(Time.get_unix_time_from_system()) - 3600
	_time_manager.mark_session_start(one_hour_ago)
	assert_float(_time_manager.get_offline_delta()).is_greater_equal(3600.0)


## AC-2 edge: mark_session_start(0) keeps delta at 0.0 (first boot).
func test_mark_session_start_zero_timestamp_keeps_delta_zero() -> void:
	_time_manager.mark_session_start(0)
	assert_float(_time_manager.get_offline_delta()).is_equal(0.0)


## AC-2 edge: mark_session_start with a future timestamp clamps delta to 0.0.
func test_mark_session_start_future_timestamp_clamps_to_zero() -> void:
	var future_ts: int = int(Time.get_unix_time_from_system()) + 9999
	_time_manager.mark_session_start(future_ts)
	assert_float(_time_manager.get_offline_delta()).is_equal(0.0)


## AC-3: get_unix_time returns a plausible Unix timestamp (after Nov 2023).
func test_get_unix_time_returns_plausible_timestamp() -> void:
	var ts: int = _time_manager.get_unix_time()
	assert_int(ts).is_greater(1_700_000_000)


## AC-4: get_current_day returns 0 when epoch is set to the current second.
func test_get_current_day_zero_at_epoch() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	_time_manager.set_game_epoch(now)
	assert_int(_time_manager.get_current_day()).is_equal(0)


## AC-4 edge: get_current_day returns 1 when epoch is exactly 86400 seconds ago.
func test_get_current_day_one_day_after_epoch() -> void:
	var one_day_ago: int = int(Time.get_unix_time_from_system()) - 86400
	_time_manager.set_game_epoch(one_day_ago)
	assert_int(_time_manager.get_current_day()).is_equal(1)


## AC-5: removed OS.get_unix_time() API is not used in the source file.
func test_no_deprecated_os_get_unix_time_in_source() -> void:
	var file := FileAccess.open("res://src/core/time_manager.gd", FileAccess.READ)
	assert_bool(file != null).is_true()
	var content: String = file.get_as_text()
	file.close()
	assert_bool(content.contains("OS.get_unix_time")).is_false()
