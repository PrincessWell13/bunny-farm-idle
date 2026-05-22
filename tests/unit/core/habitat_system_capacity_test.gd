## Unit tests for HabitatSystem.get_capacity() — level-based slot count lookup.
## Story: production/epics/habitat-system/story-005-capacity-levels.md
## GameState is mocked via Engine.register_singleton. _capacity_table injected directly.
extends GdUnitTestSuite

## Reference capacity table matching balance.json: index 0 = level 1 ... index 5 = level 6.
const TEST_CAPACITY_TABLE: Array = [4, 8, 12, 16, 20, 24]
const FALLBACK_CAPACITY_TABLE: Array = [4]


class MockGameState:
	var hutches: Array = []
	func mark_dirty() -> void:
		pass


var _system: HabitatSystem
var _mock_gs: MockGameState


func before_test() -> void:
	_mock_gs = MockGameState.new()
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")
	Engine.register_singleton("GameState", _mock_gs)
	_system = HabitatSystem.new()
	_system._capacity_table = TEST_CAPACITY_TABLE.duplicate()


func after_test() -> void:
	_system.free()
	_system = null
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")


func _make_hutch(id: String, level: int) -> HutchData:
	var h := HutchData.new()
	h.hutch_id = id
	h.level = level
	_mock_gs.hutches.append(h)
	return h


## AC-4: Level-1 hutch returns 4 (capacity_table[0]).
func test_capacity_level_1_hutch_returns_4() -> void:
	# Arrange
	_make_hutch("h1", 1)

	# Act
	var capacity: int = _system.get_capacity("h1")

	# Assert
	assert_int(capacity).is_equal(4)


## AC-5: Max-level hutch returns 24 (last entry in test table = index 5 = level 6).
func test_capacity_max_level_hutch_returns_24() -> void:
	# Arrange — level 6 is the last in TEST_CAPACITY_TABLE
	_make_hutch("h_max", 6)

	# Act
	var capacity: int = _system.get_capacity("h_max")

	# Assert
	assert_int(capacity).is_equal(24)


## AC-6: Unknown hutch_id returns 0.
func test_capacity_unknown_hutch_id_returns_zero() -> void:
	# Arrange — no hutch added to mock GameState

	# Act
	var capacity: int = _system.get_capacity("nonexistent")

	# Assert
	assert_int(capacity).is_equal(0)


## AC-7: Out-of-bounds level returns max capacity without crashing.
func test_capacity_oob_level_returns_max_no_crash() -> void:
	# Arrange — level 999 is far beyond the table
	_make_hutch("h_oob", 999)

	# Act
	var capacity: int = _system.get_capacity("h_oob")

	# Assert — last valid entry is 24
	assert_int(capacity).is_equal(24)


## AC-8: Missing balance.json key falls back to [4]; level-1 hutch still returns 4.
func test_capacity_fallback_table_returns_4_for_level_1() -> void:
	# Arrange — replace table with the fallback (simulates missing balance.json key)
	_system._capacity_table = FALLBACK_CAPACITY_TABLE.duplicate()
	_make_hutch("h1", 1)

	# Act
	var capacity: int = _system.get_capacity("h1")

	# Assert
	assert_int(capacity).is_equal(4)


## AC-9: Increasing hutch level preserves occupants (level change doesn't clear occupants).
func test_capacity_level_upgrade_preserves_occupants() -> void:
	# Arrange
	var hutch := _make_hutch("h1", 1)
	hutch.occupants.append("r1")
	hutch.occupants.append("r2")

	# Act — simulate upgrade by setting level directly
	hutch.level = 2
	var new_capacity: int = _system.get_capacity("h1")

	# Assert — occupants untouched, new capacity reflects level 2
	assert_int(hutch.occupants.size()).is_equal(2)
	assert_bool(hutch.occupants.has("r1")).is_true()
	assert_int(new_capacity).is_equal(8)  # capacity_table[1]


## AC-10: No state mutation — hutch.level unchanged after repeated calls.
func test_capacity_no_state_mutation_on_repeated_calls() -> void:
	# Arrange
	_make_hutch("h1", 2)

	# Act
	_system.get_capacity("h1")
	_system.get_capacity("h1")
	var hutch: HutchData = _mock_gs.hutches[0]
	_system.get_capacity("h1")

	# Assert
	assert_int(hutch.level).is_equal(2)


## AC-3: Level lookup uses hutch.level - 1 as index (verify mid-level).
func test_capacity_level_3_returns_correct_table_entry() -> void:
	# Arrange — level 3 maps to index 2 in TEST_CAPACITY_TABLE → 12
	_make_hutch("h3", 3)

	# Act
	var capacity: int = _system.get_capacity("h3")

	# Assert
	assert_int(capacity).is_equal(12)
