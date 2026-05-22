## Unit tests for HabitatSystem cleanliness decay via _on_tick().
## Story: production/epics/habitat-system/story-003-cleanliness-decay.md
## GameState, EventBus are mocked via Engine.register_singleton.
## _decay_rate is injected directly after instantiation to avoid balance.json I/O.
extends GdUnitTestSuite

const HabitatSystemScript := preload("res://src/core/habitat_system.gd")

const EPSILON: float = 0.0001


class MockGameState:
	var hutches: Array = []
	var dirty_count: int = 0
	func mark_dirty() -> void:
		dirty_count += 1


class MockEventBus:
	var cleanliness_calls: Array = []  # Array of {hutch_id, cleanliness}
	signal hutch_cleanliness_changed(hutch_id: String, cleanliness: float)
	func _init() -> void:
		hutch_cleanliness_changed.connect(_on_cleanliness_changed)
	func _on_cleanliness_changed(id: String, val: float) -> void:
		cleanliness_calls.append({ "hutch_id": id, "cleanliness": val })


var _system: Node
var _mock_gs: MockGameState
var _mock_eb: MockEventBus
var _orig_gs: Object = null
var _orig_eb: Object = null


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_mock_eb = MockEventBus.new()
	_orig_gs = Engine.get_singleton("GameState") if Engine.has_singleton("GameState") else null
	_orig_eb = Engine.get_singleton("EventBus") if Engine.has_singleton("EventBus") else null
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")
	Engine.register_singleton("GameState", _mock_gs)
	if Engine.has_singleton("EventBus"):
		Engine.unregister_singleton("EventBus")
	Engine.register_singleton("EventBus", _mock_eb)
	_system = HabitatSystemScript.new()
	# Override decay rate for deterministic tests — bypasses balance.json
	_system._decay_rate = 0.1


func after_test() -> void:
	_system.free()
	_system = null
	if Engine.has_singleton("EventBus"):
		Engine.unregister_singleton("EventBus")
	if _orig_eb != null:
		Engine.register_singleton("EventBus", _orig_eb)
	_orig_eb = null
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")
	if _orig_gs != null:
		Engine.register_singleton("GameState", _orig_gs)
	_orig_gs = null


func _make_empty_hutch(id: String, cleanliness: float) -> HutchData:
	var h := HutchData.new()
	h.hutch_id = id
	h.cleanliness = cleanliness
	# occupants stays empty
	_mock_gs.hutches.append(h)
	return h


func _make_occupied_hutch(id: String, cleanliness: float) -> HutchData:
	var h := HutchData.new()
	h.hutch_id = id
	h.cleanliness = cleanliness
	h.occupants.append("rabbit_01")
	_mock_gs.hutches.append(h)
	return h


## AC-5: Empty hutch does not decay and emits no signal.
func test_cleanliness_empty_hutch_does_not_decay() -> void:
	# Arrange
	var hutch := _make_empty_hutch("h_empty", 0.9)

	# Act
	_system._on_tick(1.0)

	# Assert
	assert_float(hutch.cleanliness).is_equal_approx(0.9, EPSILON)
	assert_int(_mock_eb.cleanliness_calls.size()).is_equal(0)


## AC-6: Occupied hutch decays at the correct rate.
func test_cleanliness_occupied_hutch_decays_correctly() -> void:
	# Arrange
	var hutch := _make_occupied_hutch("h_occ", 0.5)

	# Act — decay_rate=0.1, delta=1.0 → expected 0.5 - 0.1 = 0.4
	_system._on_tick(1.0)

	# Assert
	assert_float(hutch.cleanliness).is_equal_approx(0.4, EPSILON)


## AC-7: Cleanliness clamps at 0.0 and does not go negative.
func test_cleanliness_clamps_at_zero() -> void:
	# Arrange — 0.05 - 0.1*1.0 = -0.05, must clamp to 0.0
	var hutch := _make_occupied_hutch("h_low", 0.05)

	# Act
	_system._on_tick(1.0)

	# Assert
	assert_float(hutch.cleanliness).is_equal_approx(0.0, EPSILON)


## AC-8: Decay does not push cleanliness above 1.0 (upper clamp enforced).
func test_cleanliness_upper_clamp_enforced() -> void:
	# Arrange — cleanliness starts at 1.0, decay should only decrease it
	var hutch := _make_occupied_hutch("h_full", 1.0)

	# Act
	_system._on_tick(1.0)

	# Assert — after decay cleanliness must be ≤ 1.0
	assert_float(hutch.cleanliness).is_less_equal(1.0)


## AC-9: Signal fires only for occupied hutches (not empty).
func test_cleanliness_signal_fired_only_for_occupied_hutch() -> void:
	# Arrange
	_make_empty_hutch("h_empty", 0.8)
	_make_occupied_hutch("h_occ", 0.6)

	# Act
	_system._on_tick(1.0)

	# Assert — exactly one signal, for the occupied hutch
	assert_int(_mock_eb.cleanliness_calls.size()).is_equal(1)
	assert_str(_mock_eb.cleanliness_calls[0]["hutch_id"]).is_equal("h_occ")


## AC-10: GameState.mark_dirty() called exactly once per tick regardless of hutch count.
func test_cleanliness_mark_dirty_called_once_per_tick() -> void:
	# Arrange — two occupied hutches
	_make_occupied_hutch("h1", 0.8)
	_make_occupied_hutch("h2", 0.7)

	# Act
	_system._on_tick(1.0)

	# Assert
	assert_int(_mock_gs.dirty_count).is_equal(1)


## AC-3: Missing balance.json key falls back to default without crashing.
## Tests that _load_balance_data() leaves _decay_rate at a non-zero safe default
## when the habitat section is absent. Uses a fresh HabitatSystem with no override.
func test_cleanliness_missing_balance_key_uses_safe_default() -> void:
	# Arrange — a fresh system whose _ready() we call manually with a mock
	# that has no balance.json at res:// path (unit test context).
	# We verify that _decay_rate is still > 0 (the GDScript-side fallback).
	var fresh_system: Node = HabitatSystemScript.new()
	# balance.json is not available in headless unit tests; _load_balance_data()
	# will push_error and return early, leaving the field at its default of 0.001.
	fresh_system._load_balance_data()

	# Assert — fallback value must be non-zero so decay still runs
	assert_float(fresh_system._decay_rate).is_greater(0.0)
	fresh_system.free()
