## Unit tests for FoodSystem farm plot timers — story-003.
## Story: production/epics/food-system/story-003-farm-plot-timers.md
## GameState and EconomyManager mocked via Engine.register_singleton.
## Time is simulated by injecting a past started_at into plot dicts directly.
extends GdUnitTestSuite

## Food defs: seed_cost, grow_time_seconds, harvest_quantity, max_stack.
const TEST_FOOD_DEFS: Dictionary = {
	"grass":  { "seed_cost": 5,  "grow_time_seconds": 60.0,  "harvest_quantity": 3, "max_stack": 99 },
	"carrot": { "seed_cost": 15, "grow_time_seconds": 300.0, "harvest_quantity": 2, "max_stack": 99 },
}
const TEST_MAX_STACK: int = 99


class MockGameState:
	var food_inventory: Dictionary = {}
	var farm_plots: Array = []
	var dirty_call_count: int = 0
	func mark_dirty() -> void:
		dirty_call_count += 1
	func _reset_state() -> void:
		food_inventory = {}
		farm_plots = []
		dirty_call_count = 0


class MockEconomyManager:
	## Set to false to simulate insufficient funds.
	var spend_return_value: bool = true
	var spend_calls: Array = []  # Array of {currency, amount}

	## Mirrors the real EconomyManager.CurrencyType enum so the code can reference it.
	enum CurrencyType { CARROT_COIN, STAR_DUST, CRYSTAL_GEM, GENE_FRAGMENT }

	func spend(currency: CurrencyType, amount: int) -> bool:
		spend_calls.append({ "currency": currency, "amount": amount })
		return spend_return_value


var _system: FoodSystem
var _mock_gs: MockGameState
var _mock_em: MockEconomyManager


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_mock_em = MockEconomyManager.new()
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")
	Engine.register_singleton("GameState", _mock_gs)
	if Engine.has_singleton("EconomyManager"):
		Engine.unregister_singleton("EconomyManager")
	Engine.register_singleton("EconomyManager", _mock_em)
	_system = FoodSystem.new()
	_system._food_defs = TEST_FOOD_DEFS.duplicate(true)
	_system._default_max_stack = TEST_MAX_STACK


func after_test() -> void:
	_system.free()
	_system = null
	if Engine.has_singleton("EconomyManager"):
		Engine.unregister_singleton("EconomyManager")
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")


## AC-1: seed_plot calls EconomyManager.spend with correct coin cost.
func test_food_system_seed_plot_calls_spend_with_correct_cost() -> void:
	# Arrange
	_mock_em.spend_return_value = true

	# Act
	var result: bool = _system.seed_plot("grass")

	# Assert
	assert_bool(result).is_true()
	assert_int(_mock_em.spend_calls.size()).is_equal(1)
	assert_int(_mock_em.spend_calls[0]["amount"]).is_equal(5)


## AC-1: seed_plot returns false and adds no plot when spend fails.
func test_food_system_seed_plot_returns_false_when_spend_fails() -> void:
	# Arrange
	_mock_em.spend_return_value = false

	# Act
	var result: bool = _system.seed_plot("grass")

	# Assert
	assert_bool(result).is_false()
	assert_int(_mock_gs.farm_plots.size()).is_equal(0)


## AC-2: plot dict appended with correct food_id, duration, and started_at.
func test_food_system_seed_plot_appends_plot_with_correct_keys() -> void:
	# Arrange
	_mock_em.spend_return_value = true
	var before: float = Time.get_unix_time_from_system()

	# Act
	_system.seed_plot("grass")

	# Assert
	assert_int(_mock_gs.farm_plots.size()).is_equal(1)
	var plot: Dictionary = _mock_gs.farm_plots[0]
	assert_str(str(plot["food_id"])).is_equal("grass")
	assert_float(float(plot["duration"])).is_equal_approx(60.0, 0.001)
	var after: float = Time.get_unix_time_from_system()
	var started: float = float(plot["started_at"])
	assert_bool(started >= before and started <= after + 1.0).is_true()


## AC-3/AC-4: completed plot is removed and food_harvested emitted with correct values.
func test_food_system_tick_removes_completed_plot_and_emits_signal() -> void:
	# Arrange — plant a completed plot (started 61s ago, duration 60s)
	var now: float = Time.get_unix_time_from_system()
	_mock_gs.farm_plots.append({
		"food_id": "grass",
		"started_at": now - 61.0,
		"duration": 60.0,
	})
	var signal_spy: Array = []
	EventBus.food_harvested.connect(func(fid: String, qty: int) -> void:
		signal_spy.append({ "food_id": fid, "quantity": qty })
	)

	# Act
	_system._on_tick(1.0)

	# Cleanup signal
	EventBus.food_harvested.disconnect(EventBus.food_harvested.get_connections()[0]["callable"])

	# Assert
	assert_int(_mock_gs.farm_plots.size()).is_equal(0)
	assert_int(_mock_gs.food_inventory.get("grass", 0)).is_equal(3)
	assert_int(signal_spy.size()).is_equal(1)
	assert_str(signal_spy[0]["food_id"]).is_equal("grass")
	assert_int(signal_spy[0]["quantity"]).is_equal(3)


## AC-3: incomplete plot is left untouched on tick.
func test_food_system_tick_leaves_incomplete_plot_untouched() -> void:
	# Arrange — plot started 10s ago, duration 60s (not done)
	var now: float = Time.get_unix_time_from_system()
	_mock_gs.farm_plots.append({
		"food_id": "carrot",
		"started_at": now - 10.0,
		"duration": 60.0,
	})

	# Act
	_system._on_tick(1.0)

	# Assert
	assert_int(_mock_gs.farm_plots.size()).is_equal(1)
	assert_int(_mock_gs.food_inventory.get("carrot", 0)).is_equal(0)


## AC-4/AC-5: multiple plots tick independently — only elapsed one removed.
func test_food_system_tick_only_removes_elapsed_plots() -> void:
	# Arrange
	var now: float = Time.get_unix_time_from_system()
	# Plot A: completed (grass, elapsed 65s > 60s)
	_mock_gs.farm_plots.append({ "food_id": "grass",  "started_at": now - 65.0, "duration": 60.0 })
	# Plot B: not done (carrot, elapsed 10s < 300s)
	_mock_gs.farm_plots.append({ "food_id": "carrot", "started_at": now - 10.0, "duration": 300.0 })

	# Act
	_system._on_tick(1.0)

	# Assert
	assert_int(_mock_gs.farm_plots.size()).is_equal(1)
	assert_str(str(_mock_gs.farm_plots[0]["food_id"])).is_equal("carrot")
	assert_int(_mock_gs.food_inventory.get("grass", 0)).is_equal(3)
	assert_int(_mock_gs.food_inventory.get("carrot", 0)).is_equal(0)


## AC-6: reverse-index removal — 3 simultaneous completions all removed without panic.
func test_food_system_tick_removes_multiple_completed_plots_without_index_error() -> void:
	# Arrange — 3 elapsed plots
	var now: float = Time.get_unix_time_from_system()
	for _i: int in range(3):
		_mock_gs.farm_plots.append({ "food_id": "grass", "started_at": now - 120.0, "duration": 60.0 })

	# Act
	_system._on_tick(1.0)

	# Assert — all removed, 3 harvests × 3 quantity each
	assert_int(_mock_gs.farm_plots.size()).is_equal(0)
	assert_int(_mock_gs.food_inventory.get("grass", 0)).is_equal(9)


## AC-4: farm_plots_updated emitted when non-empty plots remain after tick.
func test_food_system_tick_emits_farm_plots_updated_when_plots_remain() -> void:
	# Arrange — one elapsed + one remaining
	var now: float = Time.get_unix_time_from_system()
	_mock_gs.farm_plots.append({ "food_id": "grass",  "started_at": now - 65.0, "duration": 60.0 })
	_mock_gs.farm_plots.append({ "food_id": "carrot", "started_at": now - 10.0, "duration": 300.0 })
	var updated_fired: bool = false
	EventBus.farm_plots_updated.connect(func() -> void: updated_fired = true)

	# Act
	_system._on_tick(1.0)

	# Cleanup
	EventBus.farm_plots_updated.disconnect(EventBus.farm_plots_updated.get_connections()[0]["callable"])

	# Assert
	assert_bool(updated_fired).is_true()


## AC-1: seed_plot with unknown food_id returns false and makes no change.
func test_food_system_seed_plot_unknown_food_id_returns_false() -> void:
	# Act
	var result: bool = _system.seed_plot("mystery_vegetable")

	# Assert
	assert_bool(result).is_false()
	assert_int(_mock_gs.farm_plots.size()).is_equal(0)
	assert_int(_mock_em.spend_calls.size()).is_equal(0)
