## Unit tests for RabbitSystem stat decay: hunger/cleanliness/health/happiness per tick.
## Story: production/epics/rabbit-system/story-003-stat-decay.md
## Balance values injected directly — no balance.json file I/O in unit tests.
extends GdUnitTestSuite

const RabbitSystemScript := preload("res://src/core/rabbit_system.gd")


class MockGameState:
	var rabbits: Array[RabbitData] = []
	var dirty: bool = false
	func mark_dirty() -> void:
		dirty = true


var _system: Node
var _mock_gs: MockGameState
var _orig_gs: Object = null


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_orig_gs = Engine.get_singleton("GameState") if Engine.has_singleton("GameState") else null
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")
	Engine.register_singleton("GameState", _mock_gs)
	_system = RabbitSystemScript.new()
	_system._hunger_decay_rate = 0.5
	_system._health_decay_when_starving = 1.0
	_system._cleanliness_decay_rate = 0.1
	_system._happiness_decay_rate = 0.2


func after_test() -> void:
	_system.free()
	_system = null
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")
	if _orig_gs != null:
		Engine.register_singleton("GameState", _orig_gs)
	_orig_gs = null


## AC-1: hunger decreases by decay_rate × delta each tick.
func test_tick_rabbit_decreases_hunger_by_rate_times_delta() -> void:
	var rabbit := RabbitData.new()
	rabbit.hunger = 100.0
	_system._tick_rabbit(rabbit, 1.0)
	assert_float(rabbit.hunger).is_equal_approx(99.5, 0.001)


## AC-1 edge: zero delta leaves hunger unchanged.
func test_tick_rabbit_zero_delta_leaves_hunger_unchanged() -> void:
	var rabbit := RabbitData.new()
	rabbit.hunger = 100.0
	_system._tick_rabbit(rabbit, 0.0)
	assert_float(rabbit.hunger).is_equal(100.0)


## AC-2: health decreases when hunger is at 0 (starving).
func test_tick_rabbit_health_decays_when_starving() -> void:
	var rabbit := RabbitData.new()
	rabbit.hunger = 0.0
	rabbit.health = 80.0
	_system._tick_rabbit(rabbit, 1.0)
	assert_float(rabbit.health).is_equal_approx(79.0, 0.001)


## AC-3: health NOT decreased when hunger > 0.
func test_tick_rabbit_health_stable_when_not_starving() -> void:
	var rabbit := RabbitData.new()
	rabbit.hunger = 50.0
	rabbit.health = 80.0
	_system._tick_rabbit(rabbit, 1.0)
	assert_float(rabbit.health).is_equal(80.0)


## AC-4: hunger clamps at 0.0 — no negative values.
func test_tick_rabbit_hunger_clamps_at_zero() -> void:
	var rabbit := RabbitData.new()
	rabbit.hunger = 0.3
	_system._tick_rabbit(rabbit, 1.0)  # would reduce by 0.5, giving -0.2 without clamp
	assert_float(rabbit.hunger).is_equal(0.0)


## AC-5: cleanliness decreases each tick.
func test_tick_rabbit_decreases_cleanliness() -> void:
	var rabbit := RabbitData.new()
	rabbit.cleanliness = 100.0
	_system._tick_rabbit(rabbit, 1.0)
	assert_float(rabbit.cleanliness).is_equal_approx(99.9, 0.001)


## AC-6: _load_balance_data uses defaults and does not crash when balance.json is absent.
func test_load_balance_data_retains_defaults_when_file_absent() -> void:
	var expected: float = _system._hunger_decay_rate
	_system._load_balance_data()  # balance.json absent in test env → push_error + return
	assert_float(_system._hunger_decay_rate).is_equal(expected)
