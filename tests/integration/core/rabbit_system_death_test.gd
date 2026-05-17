## Integration tests for RabbitSystem death path: rabbit_died signal + roster removal.
## Story: production/epics/rabbit-system/story-005-death-signal.md
## Key invariant: remove_rabbit runs before emit — listener gets null from get_rabbit.
extends GdUnitTestSuite


class MockGameState:
	var rabbits: Array[RabbitData] = []
	var dirty: bool = false
	func mark_dirty() -> void:
		dirty = true


class MockEventBus:
	signal rabbit_died(rabbit_id: String)
	signal rabbit_matured(rabbit_id: String, new_stage: int)


var _system: RabbitSystem
var _mock_gs: MockGameState
var _mock_eb: MockEventBus
var _died_calls: Array[String] = []
var _get_rabbit_in_handler_result: Variant = "not_called"


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_mock_eb = MockEventBus.new()
	Engine.register_singleton("GameState", _mock_gs)
	Engine.register_singleton("EventBus", _mock_eb)
	_mock_eb.rabbit_died.connect(_on_died)
	_system = RabbitSystem.new()
	_died_calls.clear()
	_get_rabbit_in_handler_result = "not_called"


func after_test() -> void:
	_system.free()
	Engine.unregister_singleton("GameState")
	Engine.unregister_singleton("EventBus")


func _on_died(rabbit_id: String) -> void:
	_died_calls.append(rabbit_id)
	_get_rabbit_in_handler_result = _system.get_rabbit(rabbit_id)


func _make_rabbit(health: float = 100.0) -> RabbitData:
	var data := RabbitData.new()
	data.health = health
	_system.add_rabbit(data)
	return data


## AC-1: rabbit_died signal emitted with correct rabbit_id when health <= 0.
func test_check_death_emits_rabbit_died_when_health_zero() -> void:
	var rabbit := _make_rabbit(0.0)
	_system._check_death(rabbit)
	assert_int(_died_calls.size()).is_equal(1)
	assert_str(_died_calls[0]).is_equal(rabbit.rabbit_id)


## AC-2: rabbit removed from roster after _check_death.
func test_check_death_removes_rabbit_from_roster() -> void:
	var rabbit := _make_rabbit(0.0)
	var id := rabbit.rabbit_id
	_system._check_death(rabbit)
	assert_bool(_system.get_rabbit(id) == null).is_true()
	assert_int(_system.get_all_rabbits().size()).is_equal(0)


## AC-3: rabbit_died NOT emitted and rabbit stays in roster when health > 0.
func test_check_death_does_nothing_when_health_above_zero() -> void:
	var rabbit := _make_rabbit(50.0)
	_system._check_death(rabbit)
	assert_int(_died_calls.size()).is_equal(0)
	assert_bool(_system.get_rabbit(rabbit.rabbit_id) == null).is_false()


## AC-4: listener calling get_rabbit during rabbit_died handler receives null.
## Verifies remove_rabbit runs before emit (ADR-0005 ordering contract).
func test_listener_gets_null_from_get_rabbit_during_death_signal() -> void:
	var rabbit := _make_rabbit(0.0)
	_system._check_death(rabbit)
	assert_bool(_get_rabbit_in_handler_result == null).is_true()
