## Unit tests for RabbitSystem.feed_rabbit: stat restoration and clamping.
## Story: production/epics/rabbit-system/story-006-feed-rabbit.md
## GameState mocked via Engine.register_singleton. Food effect values injected directly.
extends GdUnitTestSuite


class MockGameState:
	var rabbits: Array[RabbitData] = []
	var dirty: bool = false
	func mark_dirty() -> void:
		dirty = true


var _system: RabbitSystem
var _mock_gs: MockGameState
var _owned_gs: bool = false


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_owned_gs = false
	if not Engine.has_singleton("GameState"):
		Engine.register_singleton("GameState", _mock_gs)
		_owned_gs = true
	_system = RabbitSystem.new()
	_system._grass_hunger_restore = 30.0
	_system._carrot_hunger_restore = 40.0
	_system._carrot_growth_bonus = 10.0
	_system._star_carrot_growth_bonus = 25.0
	_system._star_carrot_happiness_bonus = 10.0


func after_test() -> void:
	_system.free()
	_system = null
	if _owned_gs:
		Engine.unregister_singleton("GameState")
	elif Engine.has_singleton("GameState"):
		Engine.get_singleton("GameState").rabbits.clear()


func _make_rabbit(hunger: float = 50.0, growth: float = 0.0, happiness: float = 60.0) -> String:
	var data := RabbitData.new()
	data.hunger = hunger
	data.growth_progress = growth
	data.happiness = happiness
	return _system.add_rabbit(data)


## AC-1: grass increases hunger by _grass_hunger_restore.
func test_feed_grass_increases_hunger() -> void:
	var id := _make_rabbit(50.0)
	var result := _system.feed_rabbit(id, RabbitSystem.FoodItem.new("grass"))
	assert_bool(result).is_true()
	assert_float(_system.get_rabbit(id).hunger).is_equal_approx(80.0, 0.001)


## AC-2: carrot increases hunger and growth_progress.
func test_feed_carrot_increases_hunger_and_growth() -> void:
	var id := _make_rabbit(50.0, 20.0)
	_system.feed_rabbit(id, RabbitSystem.FoodItem.new("carrot"))
	var rabbit := _system.get_rabbit(id)
	assert_float(rabbit.hunger).is_equal_approx(90.0, 0.001)
	assert_float(rabbit.growth_progress).is_equal_approx(30.0, 0.001)


## AC-3: hunger clamps at 100.0 on overflow.
func test_feed_clamps_hunger_at_100() -> void:
	var id := _make_rabbit(90.0)
	_system.feed_rabbit(id, RabbitSystem.FoodItem.new("carrot"))  # +40 would give 130
	assert_float(_system.get_rabbit(id).hunger).is_equal(100.0)


## AC-4: returns false for unknown rabbit_id — no crash.
func test_feed_returns_false_for_unknown_rabbit() -> void:
	var result := _system.feed_rabbit("phantom-id", RabbitSystem.FoodItem.new("grass"))
	assert_bool(result).is_false()


## AC-5: star_carrot increases growth_progress and happiness.
func test_feed_star_carrot_increases_growth_and_happiness() -> void:
	var id := _make_rabbit(50.0, 40.0, 60.0)
	_system.feed_rabbit(id, RabbitSystem.FoodItem.new("star_carrot"))
	var rabbit := _system.get_rabbit(id)
	assert_float(rabbit.growth_progress).is_equal_approx(65.0, 0.001)
	assert_float(rabbit.happiness).is_equal_approx(70.0, 0.001)
