## Unit tests for HabitatSystem assign_rabbit() / remove_rabbit() API.
## Story: production/epics/habitat-system/story-002-assign-remove-rabbit.md
## GameState, RabbitSystem, and EventBus are mocked via Engine.register_singleton.
extends GdUnitTestSuite


class MockGameState:
	var hutches: Array = []
	var dirty: bool = false
	func mark_dirty() -> void:
		dirty = true


class MockRabbitSystem:
	var _rabbits: Dictionary = {}
	func get_rabbit(rabbit_id: String) -> RabbitData:
		return _rabbits.get(rabbit_id, null) as RabbitData
	func set_hutch_id(rabbit_id: String, hutch_id: String) -> void:
		var r: RabbitData = _rabbits.get(rabbit_id, null) as RabbitData
		if r != null:
			r.hutch_id = hutch_id
	func add_rabbit(data: RabbitData) -> void:
		_rabbits[data.rabbit_id] = data


class MockEventBus:
	var last_rabbit_id: String = ""
	var last_hutch_id: String = ""
	var emit_count: int = 0
	signal rabbit_assigned_to_hutch(rabbit_id: String, hutch_id: String)
	func _init() -> void:
		rabbit_assigned_to_hutch.connect(_on_emitted)
	func _on_emitted(rid: String, hid: String) -> void:
		last_rabbit_id = rid
		last_hutch_id = hid
		emit_count += 1


var _system: HabitatSystem
var _mock_gs: MockGameState
var _mock_rs: MockRabbitSystem
var _mock_eb: MockEventBus
var _owned_gs: bool = false
var _owned_rs: bool = false
var _owned_eb: bool = false


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_mock_rs = MockRabbitSystem.new()
	_mock_eb = MockEventBus.new()
	_owned_gs = not Engine.has_singleton("GameState")
	_owned_rs = not Engine.has_singleton("RabbitSystem")
	_owned_eb = not Engine.has_singleton("EventBus")
	if _owned_gs:
		Engine.register_singleton("GameState", _mock_gs)
	if _owned_rs:
		Engine.register_singleton("RabbitSystem", _mock_rs)
	if _owned_eb:
		Engine.register_singleton("EventBus", _mock_eb)
	_system = HabitatSystem.new()


func after_test() -> void:
	_system.free()
	_system = null
	if _owned_gs:
		Engine.unregister_singleton("GameState")
	if _owned_rs:
		Engine.unregister_singleton("RabbitSystem")
	if _owned_eb:
		Engine.unregister_singleton("EventBus")


## Helpers

func _make_hutch(id: String) -> HutchData:
	var h := HutchData.new()
	h.hutch_id = id
	_mock_gs.hutches.append(h)
	return h


func _make_rabbit(id: String) -> RabbitData:
	var r := RabbitData.new()
	r.rabbit_id = id
	_mock_rs.add_rabbit(r)
	return r


## AC-1 / AC-5: assign_rabbit returns true when rabbit and hutch exist and hutch has room.
func test_assign_rabbit_valid_returns_true() -> void:
	# Arrange
	_make_hutch("hutch_01")
	_make_rabbit("rabbit_01")

	# Act
	var result: bool = _system.assign_rabbit("rabbit_01", "hutch_01")

	# Assert
	assert_bool(result).is_true()


## AC-2: assign_rabbit returns false when rabbit_id does not exist.
func test_assign_rabbit_unknown_rabbit_returns_false() -> void:
	# Arrange
	_make_hutch("hutch_01")

	# Act
	var result: bool = _system.assign_rabbit("ghost_rabbit", "hutch_01")

	# Assert
	assert_bool(result).is_false()


## AC-3: assign_rabbit returns false when hutch_id does not exist.
func test_assign_rabbit_unknown_hutch_returns_false() -> void:
	# Arrange
	_make_rabbit("rabbit_01")

	# Act
	var result: bool = _system.assign_rabbit("rabbit_01", "ghost_hutch")

	# Assert
	assert_bool(result).is_false()


## AC-3 (capacity): assign_rabbit returns false when hutch is at capacity (stub returns 4).
func test_assign_rabbit_at_capacity_returns_false() -> void:
	# Arrange
	var hutch := _make_hutch("hutch_01")
	hutch.occupants = ["r1", "r2", "r3", "r4"]  # fill to capacity=4
	_make_rabbit("rabbit_new")

	# Act
	var result: bool = _system.assign_rabbit("rabbit_new", "hutch_01")

	# Assert
	assert_bool(result).is_false()


## AC-4: assign_rabbit returns false when rabbit is already assigned to any hutch.
func test_assign_rabbit_already_assigned_returns_false() -> void:
	# Arrange
	var hutch_a := _make_hutch("hutch_a")
	hutch_a.occupants.append("rabbit_01")
	_make_hutch("hutch_b")
	_make_rabbit("rabbit_01")

	# Act
	var result: bool = _system.assign_rabbit("rabbit_01", "hutch_b")

	# Assert
	assert_bool(result).is_false()


## AC-5 (state): successful assign_rabbit adds rabbit_id to hutch.occupants.
func test_assign_rabbit_populates_occupants() -> void:
	# Arrange
	var hutch := _make_hutch("hutch_01")
	_make_rabbit("rabbit_01")

	# Act
	_system.assign_rabbit("rabbit_01", "hutch_01")

	# Assert
	assert_bool(hutch.occupants.has("rabbit_01")).is_true()


## AC-6: assign_rabbit emits rabbit_assigned_to_hutch with correct ids after state is updated.
func test_assign_rabbit_emits_signal_after_state() -> void:
	# Arrange
	_make_hutch("hutch_01")
	var rabbit := _make_rabbit("rabbit_01")

	# Act
	_system.assign_rabbit("rabbit_01", "hutch_01")

	# Assert — signal fired with correct arguments
	assert_str(_mock_eb.last_rabbit_id).is_equal("rabbit_01")
	assert_str(_mock_eb.last_hutch_id).is_equal("hutch_01")
	assert_int(_mock_eb.emit_count).is_equal(1)
	# State must already be written when signal fires (rabbit.hutch_id set)
	assert_str(rabbit.hutch_id).is_equal("hutch_01")


## AC-8 / AC-9: remove_rabbit returns true and clears occupant entry for existing assignment.
func test_remove_rabbit_valid_returns_true_and_clears_occupants() -> void:
	# Arrange
	var hutch := _make_hutch("hutch_01")
	hutch.occupants.append("rabbit_01")
	_make_rabbit("rabbit_01")

	# Act
	var result: bool = _system.remove_rabbit("rabbit_01")

	# Assert
	assert_bool(result).is_true()
	assert_bool(hutch.occupants.has("rabbit_01")).is_false()


## AC-8 (reject): remove_rabbit returns false when rabbit_id is not in any hutch.
func test_remove_rabbit_not_assigned_returns_false() -> void:
	# Arrange — hutch exists but rabbit is not in it
	_make_hutch("hutch_01")

	# Act
	var result: bool = _system.remove_rabbit("rabbit_01")

	# Assert
	assert_bool(result).is_false()


## AC-10: remove_rabbit emits rabbit_assigned_to_hutch with empty hutch_id string.
func test_remove_rabbit_emits_signal_with_empty_hutch_id() -> void:
	# Arrange
	var hutch := _make_hutch("hutch_01")
	hutch.occupants.append("rabbit_01")
	_make_rabbit("rabbit_01")

	# Act
	_system.remove_rabbit("rabbit_01")

	# Assert
	assert_str(_mock_eb.last_rabbit_id).is_equal("rabbit_01")
	assert_str(_mock_eb.last_hutch_id).is_equal("")
	assert_int(_mock_eb.emit_count).is_equal(1)
