## Integration tests for FoodSystem offline plot resolution — story-004.
## Story: production/epics/food-system/story-004-offline-plot-resolution.md
## Verifies that _resolve_offline_plots() correctly handles plots that completed
## while the app was offline: one harvest per plot, no multi-tick overflow.
## GameState mocked via Engine.register_singleton; _food_defs injected directly.
extends GdUnitTestSuite

const TEST_FOOD_DEFS: Dictionary = {
	"grass":  { "seed_cost": 5,  "grow_time_seconds": 60.0,  "harvest_quantity": 3, "max_stack": 99 },
	"carrot": { "seed_cost": 15, "grow_time_seconds": 300.0, "harvest_quantity": 2, "max_stack": 99 },
}


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


func after_test() -> void:
	_system.free()
	_system = null
	if _owned_gs:
		Engine.unregister_singleton("GameState")


## AC-1: completed plot is removed, inventory updated, food_harvested emitted.
func test_food_system_offline_completed_plot_resolved() -> void:
	# Arrange — plot elapsed 120s, duration 60s (double overdue)
	var now: float = Time.get_unix_time_from_system()
	_mock_gs.farm_plots.append({
		"food_id": "grass",
		"started_at": now - 120.0,
		"duration": 60.0,
	})
	var signal_spy: Array = []
	EventBus.food_harvested.connect(func(fid: String, qty: int) -> void:
		signal_spy.append({ "food_id": fid, "quantity": qty })
	)

	# Act
	_system._resolve_offline_plots()

	# Cleanup
	EventBus.food_harvested.disconnect(EventBus.food_harvested.get_connections()[0]["callable"])

	# Assert
	assert_int(_mock_gs.farm_plots.size()).is_equal(0)
	assert_int(_mock_gs.food_inventory.get("grass", 0)).is_equal(3)
	assert_int(signal_spy.size()).is_equal(1)
	assert_str(signal_spy[0]["food_id"]).is_equal("grass")
	assert_int(signal_spy[0]["quantity"]).is_equal(3)


## AC-2: no multi-harvest overflow — 10× elapsed still yields exactly one harvest.
func test_food_system_offline_no_multi_harvest_overflow() -> void:
	# Arrange — elapsed = 600s, duration = 60s (10× overdue)
	var now: float = Time.get_unix_time_from_system()
	_mock_gs.farm_plots.append({
		"food_id": "grass",
		"started_at": now - 600.0,
		"duration": 60.0,
	})
	var signal_spy: Array = []
	EventBus.food_harvested.connect(func(fid: String, qty: int) -> void:
		signal_spy.append({ "food_id": fid, "quantity": qty })
	)

	# Act
	_system._resolve_offline_plots()

	# Cleanup
	EventBus.food_harvested.disconnect(EventBus.food_harvested.get_connections()[0]["callable"])

	# Assert — one harvest, not ten
	assert_int(_mock_gs.food_inventory.get("grass", 0)).is_equal(3)
	assert_int(signal_spy.size()).is_equal(1)


## AC-3: incomplete plot left untouched — elapsed < duration.
func test_food_system_offline_incomplete_plot_left_untouched() -> void:
	# Arrange — elapsed 30s, duration 60s (not done)
	var now: float = Time.get_unix_time_from_system()
	_mock_gs.farm_plots.append({
		"food_id": "carrot",
		"started_at": now - 30.0,
		"duration": 60.0,
	})

	# Act
	_system._resolve_offline_plots()

	# Assert
	assert_int(_mock_gs.farm_plots.size()).is_equal(1)
	assert_int(_mock_gs.food_inventory.get("carrot", 0)).is_equal(0)
	assert_int(_mock_gs.dirty_call_count).is_equal(0)


## AC-4: mixed plots — only completed ones resolved, incomplete left intact.
func test_food_system_offline_only_completed_plots_resolved() -> void:
	# Arrange
	var now: float = Time.get_unix_time_from_system()
	# Plot A: completed (grass, elapsed 90s > 60s)
	_mock_gs.farm_plots.append({ "food_id": "grass",  "started_at": now - 90.0,  "duration": 60.0 })
	# Plot B: not done (carrot, elapsed 10s < 300s)
	_mock_gs.farm_plots.append({ "food_id": "carrot", "started_at": now - 10.0, "duration": 300.0 })
	var signal_spy: Array = []
	EventBus.food_harvested.connect(func(fid: String, _qty: int) -> void:
		signal_spy.append(fid)
	)

	# Act
	_system._resolve_offline_plots()

	# Cleanup
	EventBus.food_harvested.disconnect(EventBus.food_harvested.get_connections()[0]["callable"])

	# Assert
	assert_int(_mock_gs.farm_plots.size()).is_equal(1)
	assert_str(str(_mock_gs.farm_plots[0]["food_id"])).is_equal("carrot")
	assert_int(_mock_gs.food_inventory.get("grass", 0)).is_equal(3)
	assert_int(_mock_gs.food_inventory.get("carrot", 0)).is_equal(0)
	assert_int(signal_spy.size()).is_equal(1)
	assert_str(signal_spy[0]).is_equal("grass")


## AC-5: calling resolve when no plots exist makes no mutations.
func test_food_system_offline_no_plots_no_mutations() -> void:
	# Arrange — empty farm_plots (simulates fresh game)

	# Act
	_system._resolve_offline_plots()

	# Assert
	assert_int(_mock_gs.farm_plots.size()).is_equal(0)
	assert_bool(_mock_gs.food_inventory.is_empty()).is_true()
	assert_int(_mock_gs.dirty_call_count).is_equal(0)


## AC-6: multiple offline-completed plots all resolved via reverse-index removal.
func test_food_system_offline_multiple_completed_plots_all_resolved() -> void:
	# Arrange — 3 elapsed plots (2 grass, 1 carrot)
	var now: float = Time.get_unix_time_from_system()
	_mock_gs.farm_plots.append({ "food_id": "grass",  "started_at": now - 200.0, "duration": 60.0 })
	_mock_gs.farm_plots.append({ "food_id": "carrot", "started_at": now - 500.0, "duration": 300.0 })
	_mock_gs.farm_plots.append({ "food_id": "grass",  "started_at": now - 150.0, "duration": 60.0 })
	var signal_count: int = 0
	EventBus.food_harvested.connect(func(_fid: String, _qty: int) -> void:
		signal_count += 1
	)

	# Act
	_system._resolve_offline_plots()

	# Cleanup
	EventBus.food_harvested.disconnect(EventBus.food_harvested.get_connections()[0]["callable"])

	# Assert — all 3 removed, 3 signals, correct inventory totals
	assert_int(_mock_gs.farm_plots.size()).is_equal(0)
	assert_int(signal_count).is_equal(3)
	assert_int(_mock_gs.food_inventory.get("grass", 0)).is_equal(6)   # 2 plots × 3 qty
	assert_int(_mock_gs.food_inventory.get("carrot", 0)).is_equal(2)  # 1 plot × 2 qty


## AC-2 edge: plot elapsed exactly at boundary (elapsed == duration) is resolved.
func test_food_system_offline_exact_boundary_elapsed_is_resolved() -> void:
	# Arrange — elapsed = duration exactly (boundary condition)
	var now: float = Time.get_unix_time_from_system()
	_mock_gs.farm_plots.append({
		"food_id": "grass",
		"started_at": now - 60.0,
		"duration": 60.0,
	})

	# Act
	_system._resolve_offline_plots()

	# Assert — >= boundary means this plot resolves
	assert_int(_mock_gs.farm_plots.size()).is_equal(0)
	assert_int(_mock_gs.food_inventory.get("grass", 0)).is_equal(3)
