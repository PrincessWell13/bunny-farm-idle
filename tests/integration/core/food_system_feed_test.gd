## Integration tests for FoodSystem.feed_rabbit() — story-002.
## Story: production/epics/food-system/story-002-feed-rabbit.md
## GameState and RabbitSystem mocked via Engine.register_singleton.
extends GdUnitTestSuite

const TEST_FOOD_DEFS: Dictionary = {
	"grass":  { "max_stack": 99 },
	"carrot": { "max_stack": 99 },
}


class MockGameState:
	var food_inventory: Dictionary = {}
	var dirty_call_count: int = 0
	func mark_dirty() -> void:
		dirty_call_count += 1
	func _reset_state() -> void:
		food_inventory = {}
		dirty_call_count = 0


class MockRabbitSystem:
	## rabbit_id -> true (presence). Null return from get_rabbit means unknown rabbit.
	var _known_rabbits: Dictionary = {}
	## Ordered list of rabbit_ids passed to feed_rabbit.
	var feed_calls: Array = []
	## Controls what feed_rabbit returns; set to false to simulate rejection.
	var feed_return_value: bool = true

	func get_rabbit(rabbit_id: String) -> Variant:
		return _known_rabbits.get(rabbit_id, null)

	func feed_rabbit(rabbit_id: String, _food_type: String) -> bool:
		feed_calls.append(rabbit_id)
		return feed_return_value


var _system: FoodSystem
var _mock_gs: MockGameState
var _mock_rs: MockRabbitSystem


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_mock_rs = MockRabbitSystem.new()
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")
	Engine.register_singleton("GameState", _mock_gs)
	if Engine.has_singleton("RabbitSystem"):
		Engine.unregister_singleton("RabbitSystem")
	Engine.register_singleton("RabbitSystem", _mock_rs)
	_system = FoodSystem.new()
	_system._food_defs = TEST_FOOD_DEFS.duplicate(true)
	_system._default_max_stack = 99


func after_test() -> void:
	_system.free()
	_system = null
	if Engine.has_singleton("RabbitSystem"):
		Engine.unregister_singleton("RabbitSystem")
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")


## AC-1/AC-2: returns false when food_id absent from inventory.
func test_food_system_feed_rabbit_returns_false_when_food_not_in_inventory() -> void:
	# Arrange
	_mock_gs.food_inventory = {}
	_mock_rs._known_rabbits["r1"] = true

	# Act
	var result: bool = _system.feed_rabbit("r1", "grass")

	# Assert
	assert_bool(result).is_false()
	assert_bool(_mock_gs.food_inventory.has("grass")).is_false()
	assert_int(_mock_rs.feed_calls.size()).is_equal(0)


## AC-1: returns false when food quantity is zero (present but depleted).
func test_food_system_feed_rabbit_returns_false_when_food_quantity_is_zero() -> void:
	# Arrange
	_mock_gs.food_inventory["grass"] = 0
	_mock_rs._known_rabbits["r1"] = true

	# Act
	var result: bool = _system.feed_rabbit("r1", "grass")

	# Assert
	assert_bool(result).is_false()
	assert_int(_mock_gs.food_inventory["grass"]).is_equal(0)
	assert_int(_mock_rs.feed_calls.size()).is_equal(0)


## AC-2: returns false for unknown rabbit_id — no inventory deduction.
func test_food_system_feed_rabbit_returns_false_for_unknown_rabbit_id() -> void:
	# Arrange — rabbit not registered in MockRabbitSystem
	_mock_gs.food_inventory["grass"] = 3

	# Act
	var result: bool = _system.feed_rabbit("phantom-id", "grass")

	# Assert
	assert_bool(result).is_false()
	assert_int(_mock_gs.food_inventory.get("grass", 0)).is_equal(3)
	assert_int(_mock_rs.feed_calls.size()).is_equal(0)


## AC-3/AC-6: deducts exactly 1 unit and returns true on success.
func test_food_system_feed_rabbit_deducts_inventory_on_success() -> void:
	# Arrange
	_mock_gs.food_inventory["grass"] = 3
	_mock_rs._known_rabbits["r1"] = true
	_mock_rs.feed_return_value = true

	# Act
	var result: bool = _system.feed_rabbit("r1", "grass")

	# Assert
	assert_bool(result).is_true()
	assert_int(_mock_gs.food_inventory["grass"]).is_equal(2)


## AC-4/AC-5: rollback restores inventory when RabbitSystem rejects the feed.
func test_food_system_feed_rabbit_rolls_back_on_rabbit_system_rejection() -> void:
	# Arrange
	_mock_gs.food_inventory["carrot"] = 2
	_mock_rs._known_rabbits["r1"] = true
	_mock_rs.feed_return_value = false

	# Act
	var result: bool = _system.feed_rabbit("r1", "carrot")

	# Assert
	assert_bool(result).is_false()
	assert_int(_mock_gs.food_inventory["carrot"]).is_equal(2)


## AC-3: RabbitSystem.feed_rabbit called with the correct rabbit_id.
func test_food_system_feed_rabbit_calls_rabbit_system_with_correct_rabbit_id() -> void:
	# Arrange
	_mock_gs.food_inventory["grass"] = 3
	_mock_rs._known_rabbits["r1"] = true
	_mock_rs.feed_return_value = true

	# Act
	_system.feed_rabbit("r1", "grass")

	# Assert
	assert_int(_mock_rs.feed_calls.size()).is_equal(1)
	assert_str(_mock_rs.feed_calls[0]).is_equal("r1")


## AC-7: mark_dirty called on success; not called when rabbit not found (no inventory touch).
func test_food_system_feed_rabbit_marks_dirty_on_success_not_when_rabbit_unknown() -> void:
	# Arrange — success case
	_mock_gs.food_inventory["grass"] = 1
	_mock_rs._known_rabbits["r1"] = true
	_mock_rs.feed_return_value = true

	# Act — success
	_system.feed_rabbit("r1", "grass")
	var dirty_on_success: int = _mock_gs.dirty_call_count

	# Reset for failure case
	_mock_gs.dirty_call_count = 0
	_mock_gs.food_inventory["grass"] = 1

	# Act — failure (unknown rabbit)
	_system.feed_rabbit("no-such-rabbit", "grass")
	var dirty_on_failure: int = _mock_gs.dirty_call_count

	# Assert
	assert_int(dirty_on_success).is_greater(0)
	assert_int(dirty_on_failure).is_equal(0)
