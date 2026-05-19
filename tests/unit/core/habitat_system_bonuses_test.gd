## Unit tests for HabitatSystem.get_hutch_bonuses() — cleanliness-derived multipliers.
## Story: production/epics/habitat-system/story-004-hutch-bonuses.md
## GameState is mocked via Engine.register_singleton. Thresholds are injected directly.
extends GdUnitTestSuite

const EPSILON: float = 0.0001

## Reference thresholds matching balance.json defaults — injected into _system directly.
const TEST_THRESHOLDS: Array = [
	{"min": 0.75, "production_mult": 1.2, "fertility_mult": 1.1},
	{"min": 0.40, "production_mult": 1.0, "fertility_mult": 1.0},
	{"min": 0.0,  "production_mult": 0.8, "fertility_mult": 0.9}
]

const NEUTRAL_THRESHOLDS: Array = [
	{"min": 0.0, "production_mult": 1.0, "fertility_mult": 1.0}
]


class MockGameState:
	var hutches: Array = []
	func mark_dirty() -> void:
		pass


var _system: HabitatSystem
var _mock_gs: MockGameState
var _owned_gs: bool = false


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_owned_gs = not Engine.has_singleton("GameState")
	if _owned_gs:
		Engine.register_singleton("GameState", _mock_gs)
	_system = HabitatSystem.new()
	_system._cleanliness_thresholds = TEST_THRESHOLDS.duplicate(true)


func after_test() -> void:
	_system.free()
	_system = null
	if _owned_gs:
		Engine.unregister_singleton("GameState")


func _make_hutch(id: String, cleanliness: float) -> HutchData:
	var h := HutchData.new()
	h.hutch_id = id
	h.cleanliness = cleanliness
	_mock_gs.hutches.append(h)
	return h


## AC-3: Unknown hutch_id returns neutral multipliers (no crash).
func test_bonuses_unknown_hutch_returns_neutral() -> void:
	# Arrange — empty hutch list

	# Act
	var result: Dictionary = _system.get_hutch_bonuses("nonexistent_hutch")

	# Assert
	assert_float(result.get("production_mult", 0.0)).is_equal_approx(1.0, EPSILON)
	assert_float(result.get("fertility_mult", 0.0)).is_equal_approx(1.0, EPSILON)


## AC-2: Return Dictionary always has exactly the two required keys.
func test_bonuses_return_has_required_keys() -> void:
	# Arrange
	_make_hutch("h1", 0.5)

	# Act
	var result: Dictionary = _system.get_hutch_bonuses("h1")

	# Assert
	assert_bool(result.has("production_mult")).is_true()
	assert_bool(result.has("fertility_mult")).is_true()
	assert_int(result.size()).is_equal(2)


## AC-6: Clean hutch (cleanliness >= 0.75) returns bonus multipliers.
func test_bonuses_clean_hutch_returns_bonus() -> void:
	# Arrange
	_make_hutch("h_clean", 0.9)

	# Act
	var result: Dictionary = _system.get_hutch_bonuses("h_clean")

	# Assert
	assert_float(result["production_mult"]).is_greater(1.0)
	assert_float(result["fertility_mult"]).is_greater_equal(1.0)


## AC-7: Dirty hutch (cleanliness < 0.40) returns penalty multipliers.
func test_bonuses_dirty_hutch_returns_penalty() -> void:
	# Arrange
	_make_hutch("h_dirty", 0.2)

	# Act
	var result: Dictionary = _system.get_hutch_bonuses("h_dirty")

	# Assert
	assert_float(result["production_mult"]).is_less(1.0)
	assert_float(result["fertility_mult"]).is_less(1.0)


## AC-8: Mid-range cleanliness (0.40 <= c < 0.75) returns neutral multipliers.
func test_bonuses_midrange_cleanliness_returns_neutral() -> void:
	# Arrange
	_make_hutch("h_mid", 0.55)

	# Act
	var result: Dictionary = _system.get_hutch_bonuses("h_mid")

	# Assert — mid tier in TEST_THRESHOLDS has both mults at 1.0
	assert_float(result["production_mult"]).is_equal_approx(1.0, EPSILON)
	assert_float(result["fertility_mult"]).is_equal_approx(1.0, EPSILON)


## AC-5: Boundary at 0.75 returns clean tier (inclusive).
func test_bonuses_boundary_at_0_75_returns_clean_tier() -> void:
	# Arrange
	_make_hutch("h_boundary", 0.75)

	# Act
	var result: Dictionary = _system.get_hutch_bonuses("h_boundary")

	# Assert — exactly 0.75 must match the clean tier (min: 0.75)
	assert_float(result["production_mult"]).is_equal_approx(1.2, EPSILON)


## AC-5: Boundary at 0.40 returns mid tier (inclusive).
func test_bonuses_boundary_at_0_40_returns_mid_tier() -> void:
	# Arrange
	_make_hutch("h_boundary_mid", 0.40)

	# Act
	var result: Dictionary = _system.get_hutch_bonuses("h_boundary_mid")

	# Assert — exactly 0.40 must match the mid tier (min: 0.40), not the dirty tier
	assert_float(result["production_mult"]).is_equal_approx(1.0, EPSILON)


## AC-10 / AC-11: Missing thresholds falls back to neutral; no state mutation.
func test_bonuses_neutral_fallback_and_no_mutation() -> void:
	# Arrange — replace thresholds with the neutral fallback (simulates missing balance key)
	_system._cleanliness_thresholds = NEUTRAL_THRESHOLDS.duplicate(true)
	var hutch := _make_hutch("h1", 0.6)

	# Act — call three times (AC-11: no mutation)
	var r1: Dictionary = _system.get_hutch_bonuses("h1")
	var r2: Dictionary = _system.get_hutch_bonuses("h1")
	var r3: Dictionary = _system.get_hutch_bonuses("h1")

	# Assert — all three calls return 1.0 production_mult (neutral fallback)
	assert_float(r1["production_mult"]).is_equal_approx(1.0, EPSILON)
	assert_float(r2["production_mult"]).is_equal_approx(1.0, EPSILON)
	assert_float(r3["production_mult"]).is_equal_approx(1.0, EPSILON)
	# Cleanliness must be unchanged after 3 calls (AC-11)
	assert_float(hutch.cleanliness).is_equal_approx(0.6, EPSILON)
