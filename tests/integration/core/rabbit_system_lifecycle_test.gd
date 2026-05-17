## Integration tests for RabbitSystem lifecycle state machine: stage advance + rabbit_matured signal.
## Story: production/epics/rabbit-system/story-004-lifecycle.md
## MockEventBus tracks rabbit_matured emissions. Time-based tests use birth_timestamp=0 (epoch).
extends GdUnitTestSuite


class MockGameState:
	var rabbits: Array[RabbitData] = []
	var dirty: bool = false
	func mark_dirty() -> void:
		dirty = true


class MockEventBus:
	signal rabbit_matured(rabbit_id: String, new_stage: int)


var _system: RabbitSystem
var _mock_gs: MockGameState
var _mock_eb: MockEventBus
var _matured_calls: Array = []  # Array of [rabbit_id: String, new_stage: int]
var _owned_gs: bool = false
var _owned_eb: bool = false


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_mock_eb = MockEventBus.new()
	_owned_gs = false
	_owned_eb = false
	if not Engine.has_singleton("GameState"):
		Engine.register_singleton("GameState", _mock_gs)
		_owned_gs = true
	if not Engine.has_singleton("EventBus"):
		Engine.register_singleton("EventBus", _mock_eb)
		_owned_eb = true
	var active_eb: Object = Engine.get_singleton("EventBus")
	if active_eb != null:
		active_eb.rabbit_matured.connect(_on_matured)
	_system = RabbitSystem.new()
	_system._baby_to_juvenile_threshold = 100.0
	_system._juvenile_to_adult_threshold = 100.0
	_system._adult_lifespan_seconds = 1    # 1 second — birth_timestamp=0 always exceeds this
	_system._elder_duration_seconds = 1
	_matured_calls.clear()


func after_test() -> void:
	var active_eb: Object = Engine.get_singleton("EventBus")
	if active_eb != null and active_eb.rabbit_matured.is_connected(_on_matured):
		active_eb.rabbit_matured.disconnect(_on_matured)
	_system.free()
	_system = null
	if _owned_gs:
		Engine.unregister_singleton("GameState")
	elif Engine.has_singleton("GameState"):
		(Engine.get_singleton("GameState") as GameState).rabbits.clear()
	if _owned_eb:
		Engine.unregister_singleton("EventBus")


func _on_matured(rabbit_id: String, new_stage: int) -> void:
	_matured_calls.append([rabbit_id, new_stage])


func _make_rabbit(stage: RabbitData.RabbitStage = RabbitData.RabbitStage.BABY, growth: float = 0.0) -> RabbitData:
	var data := RabbitData.new()
	data.stage = stage
	data.growth_progress = growth
	_system.add_rabbit(data)
	return data


## AC-1: BABY advances to JUVENILE when growth_progress reaches threshold.
func test_baby_advances_to_juvenile_at_threshold() -> void:
	var rabbit := _make_rabbit(RabbitData.RabbitStage.BABY, 100.0)
	_system._check_stage_advance(rabbit)
	assert_int(rabbit.stage).is_equal(RabbitData.RabbitStage.JUVENILE)


## AC-2: BABY does NOT advance when below threshold.
func test_baby_does_not_advance_below_threshold() -> void:
	var rabbit := _make_rabbit(RabbitData.RabbitStage.BABY, 50.0)
	_system._check_stage_advance(rabbit)
	assert_int(rabbit.stage).is_equal(RabbitData.RabbitStage.BABY)
	assert_int(_matured_calls.size()).is_equal(0)


## AC-3: rabbit_matured emitted with correct rabbit_id and new_stage on BABY→JUVENILE.
func test_stage_advance_emits_rabbit_matured_with_correct_args() -> void:
	var rabbit := _make_rabbit(RabbitData.RabbitStage.BABY, 100.0)
	_system._check_stage_advance(rabbit)
	assert_int(_matured_calls.size()).is_equal(1)
	assert_str(_matured_calls[0][0]).is_equal(rabbit.rabbit_id)
	assert_int(_matured_calls[0][1]).is_equal(RabbitData.RabbitStage.JUVENILE)


## AC-4: SANCTUARY rabbit is not advanced further and emits no signal.
func test_sanctuary_rabbit_does_not_advance() -> void:
	var rabbit := _make_rabbit(RabbitData.RabbitStage.SANCTUARY)
	_system._check_stage_advance(rabbit)
	assert_int(rabbit.stage).is_equal(RabbitData.RabbitStage.SANCTUARY)
	assert_int(_matured_calls.size()).is_equal(0)


## AC-5: growth_progress resets to 0.0 after BABY→JUVENILE advance.
func test_growth_progress_resets_on_advance() -> void:
	var rabbit := _make_rabbit(RabbitData.RabbitStage.BABY, 100.0)
	_system._check_stage_advance(rabbit)
	assert_float(rabbit.growth_progress).is_equal(0.0)


## AC-3 (time-based): ADULT advances to ELDER when lifespan has elapsed.
func test_adult_advances_to_elder_when_lifespan_elapsed() -> void:
	var rabbit := _make_rabbit(RabbitData.RabbitStage.ADULT)
	rabbit.birth_timestamp = 0  # epoch 0 — current time always > 0 + 1 second threshold
	_system._check_stage_advance(rabbit)
	assert_int(rabbit.stage).is_equal(RabbitData.RabbitStage.ELDER)


## AC-3 (time-based): ELDER advances to SANCTUARY when combined duration has elapsed.
func test_elder_advances_to_sanctuary_when_duration_elapsed() -> void:
	var rabbit := _make_rabbit(RabbitData.RabbitStage.ELDER)
	rabbit.birth_timestamp = 0
	_system._check_stage_advance(rabbit)
	assert_int(rabbit.stage).is_equal(RabbitData.RabbitStage.SANCTUARY)
