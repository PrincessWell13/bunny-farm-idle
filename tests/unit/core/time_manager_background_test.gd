## Unit tests for TimeManager background detection — Story 002.
## Verifies was_backgrounded() flag, NOTIFICATION_APPLICATION_PAUSED, and
## NOTIFICATION_APPLICATION_FOCUS_IN handling.
extends GdUnitTestSuite

var _tm: TimeManager


func before_test() -> void:
	_tm = TimeManager.new()


func after_test() -> void:
	_tm.free()
	_tm = null


## AC-1 / AC-4: was_backgrounded() returns false on fresh instantiation.
func test_time_manager_background_false_by_default() -> void:
	assert_bool(_tm.was_backgrounded()).is_false()


## AC-2: NOTIFICATION_APPLICATION_PAUSED sets _backgrounded = true.
func test_time_manager_pause_notification_sets_backgrounded_true() -> void:
	_tm._notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_bool(_tm.was_backgrounded()).is_true()


## AC-3: NOTIFICATION_APPLICATION_FOCUS_IN clears _backgrounded to false.
func test_time_manager_focus_in_notification_clears_backgrounded_flag() -> void:
	_tm._notification(NOTIFICATION_APPLICATION_PAUSED)
	_tm._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_bool(_tm.was_backgrounded()).is_false()


## reset_backgrounded() explicitly clears the flag (for SaveSystem consumption pattern).
func test_time_manager_reset_backgrounded_clears_flag() -> void:
	_tm._notification(NOTIFICATION_APPLICATION_PAUSED)
	_tm.reset_backgrounded()
	assert_bool(_tm.was_backgrounded()).is_false()


## Calling focus-in when already false is a no-op (idempotent).
func test_time_manager_focus_in_when_not_backgrounded_is_noop() -> void:
	_tm._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_bool(_tm.was_backgrounded()).is_false()


## Multiple pauses do not get stuck — last notification wins.
func test_time_manager_repeated_pause_stays_true() -> void:
	_tm._notification(NOTIFICATION_APPLICATION_PAUSED)
	_tm._notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_bool(_tm.was_backgrounded()).is_true()
