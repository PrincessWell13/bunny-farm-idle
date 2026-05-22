## Unit tests for SeasonSystem — story-001 (clock) and story-002 (multipliers).
## Season clock state injected directly. EventBus mocked via Engine.register_singleton.
## Story: production/epics/season-system/story-001-season-clock.md
extends GdUnitTestSuite

const SeasonSystemScript := preload("res://src/core/season_system.gd")

const EPSILON: float = 0.001

## Test multipliers matching the GDD: Spring fertility, Summer growth, Autumn harvest, Winter offline.
const TEST_MULTIPLIER_TABLE: Array = [
	{ "production_mult": 1.0, "fertility_mult": 1.3, "growth_mult": 1.0, "offline_mult": 1.0 },
	{ "production_mult": 1.0, "fertility_mult": 1.0, "growth_mult": 1.2, "offline_mult": 1.0 },
	{ "production_mult": 1.5, "fertility_mult": 1.0, "growth_mult": 1.0, "offline_mult": 1.0 },
	{ "production_mult": 1.0, "fertility_mult": 1.0, "growth_mult": 1.0, "offline_mult": 1.3 },
]


class MockEventBus:
	var last_season_emitted: int = -1
	var season_changed_count: int = 0
	signal season_changed(new_season: int)
	func _init() -> void:
		season_changed.connect(_on_season_changed)
	func _on_season_changed(s: int) -> void:
		last_season_emitted = s
		season_changed_count += 1


var _system: Node
var _mock_eb: MockEventBus
var _orig_eb: Object = null


func before_test() -> void:
	_mock_eb = MockEventBus.new()
	_orig_eb = Engine.get_singleton("EventBus") if Engine.has_singleton("EventBus") else null
	if Engine.has_singleton("EventBus"):
		Engine.unregister_singleton("EventBus")
	Engine.register_singleton("EventBus", _mock_eb)
	_system = SeasonSystemScript.new()
	# Inject fast test values — bypasses balance.json I/O
	_system._seconds_per_day = 10.0
	_system._days_per_season = 3
	_system._multiplier_table = TEST_MULTIPLIER_TABLE.duplicate(true)


func after_test() -> void:
	_system.free()
	_system = null
	if Engine.has_singleton("EventBus"):
		Engine.unregister_singleton("EventBus")
	if _orig_eb != null:
		Engine.register_singleton("EventBus", _orig_eb)
	_orig_eb = null


## AC-1: get_current_season() returns SPRING (0) initially.
func test_season_system_initial_season_is_spring() -> void:
	assert_int(_system.get_current_season()).is_equal(SeasonSystem.SPRING)


## AC-2: Day advances when accumulated seconds >= seconds_per_day.
func test_season_system_day_advances_on_full_day_tick() -> void:
	# Arrange — _seconds_per_day = 10.0, _day_within_season starts at 0

	# Act
	_system._on_tick(10.0)

	# Assert
	assert_int(_system._day_within_season).is_equal(1)
	assert_float(_system._elapsed_seconds).is_equal_approx(0.0, EPSILON)


## AC-2b: Sub-day precision preserved (accumulator subtracts, not zeros).
func test_season_system_sub_day_precision_preserved() -> void:
	# Arrange — _seconds_per_day = 10.0

	# Act
	_system._on_tick(11.5)

	# Assert
	assert_int(_system._day_within_season).is_equal(1)
	assert_float(_system._elapsed_seconds).is_equal_approx(1.5, EPSILON)


## AC-3: Season advances when day_within_season reaches days_per_season.
func test_season_system_season_advances_at_day_boundary() -> void:
	# Arrange — _days_per_season = 3; push to day 2
	_system._day_within_season = 2

	# Act — one more day tick (10 seconds = 1 day)
	_system._on_tick(10.0)

	# Assert
	assert_int(_system._current_season).is_equal(SeasonSystem.SUMMER)
	assert_int(_system._day_within_season).is_equal(0)


## AC-4: Season wraps from WINTER back to SPRING.
func test_season_system_winter_wraps_to_spring() -> void:
	# Arrange
	_system._current_season = SeasonSystem.WINTER
	_system._day_within_season = 2  # one more day will advance season

	# Act
	_system._on_tick(10.0)

	# Assert
	assert_int(_system._current_season).is_equal(SeasonSystem.SPRING)


## AC-5: season_changed emitted with correct new season on season boundary.
func test_season_system_season_changed_signal_emitted_with_correct_value() -> void:
	# Arrange — at day 2 of 3, one tick triggers Summer
	_system._day_within_season = 2

	# Act
	_system._on_tick(10.0)

	# Assert
	assert_int(_mock_eb.last_season_emitted).is_equal(SeasonSystem.SUMMER)
	assert_int(_mock_eb.season_changed_count).is_equal(1)


## AC-7: get_current_season() is pure read — season unchanged after repeated calls.
func test_season_system_get_current_season_is_pure_read() -> void:
	# Arrange
	_system._current_season = SeasonSystem.AUTUMN

	# Act
	_system.get_current_season()
	_system.get_current_season()
	_system.get_current_season()

	# Assert
	assert_int(_system._current_season).is_equal(SeasonSystem.AUTUMN)


## Story-002 AC-2: Spring multipliers match GDD spec.
func test_season_system_spring_multipliers_match_gdd() -> void:
	# Arrange
	_system._current_season = SeasonSystem.SPRING

	# Act
	var mults: Dictionary = _system.get_active_multipliers()

	# Assert
	assert_float(mults["fertility_mult"]).is_equal_approx(1.3, EPSILON)
	assert_float(mults["production_mult"]).is_equal_approx(1.0, EPSILON)


## Story-002 AC-4: Autumn production_mult = 1.5 per ADR-0007.
func test_season_system_autumn_production_mult_is_1_5() -> void:
	# Arrange
	_system._current_season = SeasonSystem.AUTUMN

	# Act
	var mults: Dictionary = _system.get_active_multipliers()

	# Assert
	assert_float(mults["production_mult"]).is_equal_approx(1.5, EPSILON)


## Story-002 AC-6: Empty multiplier table returns neutral multipliers without crash.
func test_season_system_empty_table_returns_neutral_multipliers() -> void:
	# Arrange
	_system._multiplier_table.clear()

	# Act
	var mults: Dictionary = _system.get_active_multipliers()

	# Assert
	assert_float(mults["production_mult"]).is_equal_approx(1.0, EPSILON)
	assert_float(mults["fertility_mult"]).is_equal_approx(1.0, EPSILON)


## Story-002 AC-3: Summer growth_mult = 1.2 per GDD spec.
func test_season_system_summer_growth_mult_is_1_2() -> void:
	# Arrange
	_system._current_season = SeasonSystem.SUMMER

	# Act
	var mults: Dictionary = _system.get_active_multipliers()

	# Assert
	assert_float(mults["growth_mult"]).is_equal_approx(1.2, EPSILON)
	assert_float(mults["production_mult"]).is_equal_approx(1.0, EPSILON)
	assert_float(mults["fertility_mult"]).is_equal_approx(1.0, EPSILON)
	assert_float(mults["offline_mult"]).is_equal_approx(1.0, EPSILON)


## Story-002 AC-5: Winter offline_mult = 1.3 per GDD spec.
func test_season_system_winter_offline_mult_is_1_3() -> void:
	# Arrange
	_system._current_season = SeasonSystem.WINTER

	# Act
	var mults: Dictionary = _system.get_active_multipliers()

	# Assert
	assert_float(mults["offline_mult"]).is_equal_approx(1.3, EPSILON)
	assert_float(mults["production_mult"]).is_equal_approx(1.0, EPSILON)
	assert_float(mults["fertility_mult"]).is_equal_approx(1.0, EPSILON)
	assert_float(mults["growth_mult"]).is_equal_approx(1.0, EPSILON)


## Story-002 AC-8: get_active_multipliers() is a pure read — _current_season unchanged after repeated calls.
func test_season_system_get_active_multipliers_is_pure_read() -> void:
	# Arrange
	_system._current_season = SeasonSystem.SUMMER

	# Act — call 3 times to confirm no side effects
	var mults_a: Dictionary = _system.get_active_multipliers()
	var mults_b: Dictionary = _system.get_active_multipliers()
	var mults_c: Dictionary = _system.get_active_multipliers()

	# Assert — season unchanged; all three calls return identical values
	assert_int(_system._current_season).is_equal(SeasonSystem.SUMMER)
	assert_float(mults_a["growth_mult"]).is_equal_approx(mults_b["growth_mult"], EPSILON)
	assert_float(mults_b["growth_mult"]).is_equal_approx(mults_c["growth_mult"], EPSILON)
