## Unit tests for FoodSystem inventory schema — story-001.
## Story: production/epics/food-system/story-001-inventory-schema.md
## GameState is mocked via Engine.register_singleton. _food_defs injected directly.
extends GdUnitTestSuite

const TEST_FOOD_DEFS: Dictionary = {
	"grass":       { "max_stack": 99 },
	"carrot":      { "max_stack": 99 },
	"star_carrot": { "max_stack": 99 },
}
const TEST_MAX_STACK: int = 99


class MockGameState:
	var food_inventory: Dictionary = {}
	func mark_dirty() -> void:
		pass
	func _reset_state() -> void:
		food_inventory = {}


var _system: FoodSystem
var _mock_gs: MockGameState
var _owned_gs: bool = false


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_owned_gs = not Engine.has_singleton("GameState")
	if _owned_gs:
		Engine.register_singleton("GameState", _mock_gs)
	_system = FoodSystem.new()
	_system._food_defs = TEST_FOOD_DEFS.duplicate(true)
	_system._default_max_stack = TEST_MAX_STACK


func after_test() -> void:
	_system.free()
	_system = null
	if _owned_gs:
		Engine.unregister_singleton("GameState")


## AC-1: food_inventory initialises empty after _reset_state().
func test_food_system_inventory_initialises_empty_after_reset() -> void:
	# Arrange
	_mock_gs.food_inventory["grass"] = 5

	# Act
	_mock_gs._reset_state()

	# Assert
	assert_bool(_mock_gs.food_inventory.is_empty()).is_true()


## AC-2: get_inventory() returns a copy, not a reference.
func test_food_system_get_inventory_returns_copy_not_reference() -> void:
	# Arrange
	_mock_gs.food_inventory["grass"] = 5

	# Act
	var copy: Dictionary = _system.get_inventory()
	copy["grass"] = 99

	# Assert — original untouched
	assert_int(_mock_gs.food_inventory["grass"]).is_equal(5)


## AC-2 extra: get_inventory() reflects the current inventory state.
func test_food_system_get_inventory_reflects_current_state() -> void:
	# Arrange
	_system._add_to_inventory("carrot", 10)

	# Act
	var inv: Dictionary = _system.get_inventory()

	# Assert
	assert_int(inv.get("carrot", 0)).is_equal(10)


## AC-3: unknown food_id is rejected and not written to inventory.
func test_food_system_add_unknown_food_id_is_rejected() -> void:
	# Arrange — _food_defs has only grass, carrot, star_carrot

	# Act
	_system._add_to_inventory("unknown_food", 1)

	# Assert
	assert_bool(_mock_gs.food_inventory.has("unknown_food")).is_false()


## AC-4: deduct below zero returns false and leaves quantity unchanged.
func test_food_system_deduct_below_zero_returns_false_and_no_change() -> void:
	# Arrange
	_mock_gs.food_inventory["grass"] = 0

	# Act
	var result: bool = _system._deduct_from_inventory("grass", 1)

	# Assert
	assert_bool(result).is_false()
	assert_int(_mock_gs.food_inventory["grass"]).is_equal(0)


## AC-4 extra: successful deduct returns true and decrements quantity.
func test_food_system_deduct_valid_quantity_returns_true_and_decrements() -> void:
	# Arrange
	_mock_gs.food_inventory["carrot"] = 5

	# Act
	var result: bool = _system._deduct_from_inventory("carrot", 3)

	# Assert
	assert_bool(result).is_true()
	assert_int(_mock_gs.food_inventory["carrot"]).is_equal(2)


## AC-5: add beyond max_stack clamps to max_stack, excess discarded.
func test_food_system_add_beyond_max_stack_clamps_to_max_stack() -> void:
	# Arrange
	_mock_gs.food_inventory["grass"] = 97

	# Act
	_system._add_to_inventory("grass", 5)

	# Assert — clamped to 99, not 102
	assert_int(_mock_gs.food_inventory["grass"]).is_equal(99)
