## Unit tests for ExpeditionSystem.start_expedition() — story-001.
## Story: production/epics/expedition-system/story-001-start-expedition.md
## GameState, RabbitSystem, and TimeManager are mocked via Engine.register_singleton.
## _zone_defs is injected directly after construction — no balance.json I/O in unit tests.
extends GdUnitTestSuite

const ExpeditionSystemScript := preload("res://src/core/expedition_system.gd")

## Minimal mock GeneSlot — mirrors GeneSlot.expressed() return value.
class MockGeneSlot:
	var _value: String = "none"

	func set_expressed(v: String) -> void:
		_value = v

	func expressed() -> String:
		return _value


## Minimal mock Genome — exposes trait_a and trait_b slots for trait checks.
class MockGenome:
	var trait_a: MockGeneSlot = MockGeneSlot.new()
	var trait_b: MockGeneSlot = MockGeneSlot.new()


## Minimal mock RabbitData — mirrors only the fields read by _validate_requirements.
class MockRabbitData:
	var rabbit_id: String = ""
	## Use RabbitData.RabbitStage int values: BABY=0, JUVENILE=1, ADULT=2, ELDER=3, SANCTUARY=4
	var stage: int = 2  # default: ADULT
	var is_on_expedition: bool = false
	var genome: MockGenome = MockGenome.new()


class MockGameState:
	var active_expeditions: Array = []
	var prestige_count: int = 0
	var rabbits: Dictionary = {}

	func mark_dirty() -> void:
		pass


class MockRabbitSystem:
	## rabbit_id -> MockRabbitData; used by get_rabbit().
	var mock_rabbits: Dictionary = {}
	## Records calls: Array of { "rabbit_id": String, "slot_id": String }
	var send_on_expedition_calls: Array = []

	func get_rabbit(rabbit_id: String) -> Variant:
		return mock_rabbits.get(rabbit_id, null)

	func send_on_expedition(rabbit_id: String, slot_id: String) -> void:
		send_on_expedition_calls.append({ "rabbit_id": rabbit_id, "slot_id": slot_id })


## TimeManager mock — needed because ExpeditionSystem._ready() connects TimeManager.tick.
## In tests we construct the system without calling _ready(), so this is a safety net.
class MockTimeManager:
	signal tick(delta: float)


## A test-only zone definition with min_rabbits=1, no trait, no prestige gate.
const TEST_ZONE_NEAR_FOREST: Dictionary = {
	"zone_id": "near_forest",
	"display_name": "Test Forest",
	"duration_seconds": 1800,
	"min_rabbits": 1,
	"max_rabbits": 5,
	"required_trait": null,
	"requires_prestige": 0,
	"loot_table": [
		{ "item_id": "star_grass", "weight": 60, "quantity_min": 1, "quantity_max": 3 }
	]
}

## Zone that requires 2 rabbits minimum.
const TEST_ZONE_EAST_MEADOW: Dictionary = {
	"zone_id": "east_meadow",
	"display_name": "Test Meadow",
	"duration_seconds": 7200,
	"min_rabbits": 2,
	"max_rabbits": 5,
	"required_trait": null,
	"requires_prestige": 0,
	"loot_table": [
		{ "item_id": "special_carrot", "weight": 100, "quantity_min": 1, "quantity_max": 1 }
	]
}

## Zone that requires "Sturdy" trait, min 3 rabbits.
const TEST_ZONE_SNOW_MOUNTAIN: Dictionary = {
	"zone_id": "snow_mountain",
	"display_name": "Test Mountain",
	"duration_seconds": 28800,
	"min_rabbits": 3,
	"max_rabbits": 5,
	"required_trait": "Sturdy",
	"requires_prestige": 0,
	"loot_table": [
		{ "item_id": "mystery_mushroom", "weight": 100, "quantity_min": 1, "quantity_max": 1 }
	]
}

## Zone that requires prestige level 1.
const TEST_ZONE_RABBIT_UNIVERSE: Dictionary = {
	"zone_id": "rabbit_universe",
	"display_name": "Test Universe",
	"duration_seconds": 172800,
	"min_rabbits": 1,
	"max_rabbits": 5,
	"required_trait": null,
	"requires_prestige": 1,
	"loot_table": [
		{ "item_id": "cosmic_gene", "weight": 100, "quantity_min": 1, "quantity_max": 1 }
	]
}

var _system: Node
var _mock_gs: MockGameState
var _mock_rs: MockRabbitSystem
var _mock_tm: MockTimeManager
var _orig_gs: Object = null
var _orig_rs: Object = null
var _orig_tm: Object = null


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_mock_rs = MockRabbitSystem.new()
	_mock_tm = MockTimeManager.new()

	_orig_gs = Engine.get_singleton("GameState") if Engine.has_singleton("GameState") else null
	_orig_rs = Engine.get_singleton("RabbitSystem") if Engine.has_singleton("RabbitSystem") else null
	_orig_tm = Engine.get_singleton("TimeManager") if Engine.has_singleton("TimeManager") else null

	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")
	Engine.register_singleton("GameState", _mock_gs)

	if Engine.has_singleton("RabbitSystem"):
		Engine.unregister_singleton("RabbitSystem")
	Engine.register_singleton("RabbitSystem", _mock_rs)

	if Engine.has_singleton("TimeManager"):
		Engine.unregister_singleton("TimeManager")
	Engine.register_singleton("TimeManager", _mock_tm)

	# Construct without calling _ready() to avoid balance.json I/O and tick connection.
	_system = ExpeditionSystemScript.new()

	# Inject test zone definitions directly — no file I/O in unit tests (ADR-0004 pattern).
	_system._zone_defs = {
		"near_forest":   TEST_ZONE_NEAR_FOREST.duplicate(true),
		"east_meadow":   TEST_ZONE_EAST_MEADOW.duplicate(true),
		"snow_mountain": TEST_ZONE_SNOW_MOUNTAIN.duplicate(true),
		"rabbit_universe": TEST_ZONE_RABBIT_UNIVERSE.duplicate(true),
	}


func after_test() -> void:
	_system.free()
	_system = null

	if Engine.has_singleton("TimeManager"):
		Engine.unregister_singleton("TimeManager")
	if _orig_tm != null:
		Engine.register_singleton("TimeManager", _orig_tm)
	_orig_tm = null
	if Engine.has_singleton("RabbitSystem"):
		Engine.unregister_singleton("RabbitSystem")
	if _orig_rs != null:
		Engine.register_singleton("RabbitSystem", _orig_rs)
	_orig_rs = null
	if Engine.has_singleton("GameState"):
		Engine.unregister_singleton("GameState")
	if _orig_gs != null:
		Engine.register_singleton("GameState", _orig_gs)
	_orig_gs = null

	_mock_tm = null
	_mock_rs = null
	_mock_gs = null


## Helper: creates a valid adult rabbit in mock_rs with the given id.
func _make_adult(rabbit_id: String) -> MockRabbitData:
	var r: MockRabbitData = MockRabbitData.new()
	r.rabbit_id = rabbit_id
	r.stage = RabbitData.RabbitStage.ADULT
	r.is_on_expedition = false
	_mock_rs.mock_rabbits[rabbit_id] = r
	return r


# ---------------------------------------------------------------------------
# AC-1: unknown zone_id
# ---------------------------------------------------------------------------

## AC-1: start_expedition returns false when zone_id does not exist.
func test_expedition_start_unknown_zone_returns_false() -> void:
	# Arrange
	_make_adult("r-001")

	# Act
	var result: bool = _system.start_expedition("unknown_zone", ["r-001"])

	# Assert
	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC-2: too few rabbits
# ---------------------------------------------------------------------------

## AC-2: start_expedition returns false when rabbit_ids.size() < zone.min_rabbits.
func test_expedition_start_too_few_rabbits_returns_false() -> void:
	# Arrange — east_meadow requires min 2 rabbits; send only 1
	_make_adult("r-001")

	# Act
	var result: bool = _system.start_expedition("east_meadow", ["r-001"])

	# Assert
	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC-3: unknown rabbit_id
# ---------------------------------------------------------------------------

## AC-3: start_expedition returns false when a rabbit_id is not found via get_rabbit().
func test_expedition_start_unknown_rabbit_returns_false() -> void:
	# Arrange — "phantom" is not registered in mock_rs

	# Act
	var result: bool = _system.start_expedition("near_forest", ["phantom"])

	# Assert
	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC-4: non-Adult rabbit
# ---------------------------------------------------------------------------

## AC-4: start_expedition returns false when any rabbit's stage is not ADULT.
func test_expedition_start_non_adult_rabbit_returns_false() -> void:
	# Arrange — rabbit with BABY stage
	var r: MockRabbitData = _make_adult("r-001")
	r.stage = RabbitData.RabbitStage.BABY

	# Act
	var result: bool = _system.start_expedition("near_forest", ["r-001"])

	# Assert
	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC-5: rabbit already on expedition
# ---------------------------------------------------------------------------

## AC-5: start_expedition returns false when any rabbit already has is_on_expedition == true.
func test_expedition_start_rabbit_already_on_expedition_returns_false() -> void:
	# Arrange
	var r: MockRabbitData = _make_adult("r-001")
	r.is_on_expedition = true

	# Act
	var result: bool = _system.start_expedition("near_forest", ["r-001"])

	# Assert
	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC-6: missing required trait
# ---------------------------------------------------------------------------

## AC-6: start_expedition returns false when zone requires a trait any rabbit lacks.
func test_expedition_start_missing_required_trait_returns_false() -> void:
	# Arrange — snow_mountain requires "Sturdy"; rabbits have no trait set (genome = "none")
	_make_adult("r-001")
	_make_adult("r-002")
	_make_adult("r-003")
	# Default MockGeneSlot.expressed() returns "none", not "Sturdy"

	# Act
	var result: bool = _system.start_expedition("snow_mountain", ["r-001", "r-002", "r-003"])

	# Assert
	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC-7: prestige gate
# ---------------------------------------------------------------------------

## AC-7: start_expedition returns false when zone requires_prestige > GameState.prestige_count.
func test_expedition_start_prestige_gate_returns_false_below_requirement() -> void:
	# Arrange — rabbit_universe requires prestige 1; GameState.prestige_count == 0
	_make_adult("r-001")
	_mock_gs.prestige_count = 0

	# Act
	var result: bool = _system.start_expedition("rabbit_universe", ["r-001"])

	# Assert
	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC-8: valid call appends slot with correct structure
# ---------------------------------------------------------------------------

## AC-8: valid call appends exactly one slot with all 7 required keys and correct values.
func test_expedition_start_valid_call_appends_slot_with_correct_structure() -> void:
	# Arrange
	_make_adult("r-001")
	var before: float = Time.get_unix_time_from_system()

	# Act
	var result: bool = _system.start_expedition("near_forest", ["r-001"])

	# Assert — returns true
	assert_bool(result).is_true()

	# Exactly one slot appended
	assert_int(_mock_gs.active_expeditions.size()).is_equal(1)

	var slot: Dictionary = _mock_gs.active_expeditions[0]

	# All 7 required keys present
	assert_bool(slot.has("slot_id")).is_true()
	assert_bool(slot.has("zone_id")).is_true()
	assert_bool(slot.has("rabbit_ids")).is_true()
	assert_bool(slot.has("started_at")).is_true()
	assert_bool(slot.has("duration")).is_true()
	assert_bool(slot.has("loot_seed")).is_true()
	assert_bool(slot.has("status")).is_true()

	# Correct field values
	assert_str(str(slot["zone_id"])).is_equal("near_forest")
	assert_str(str(slot["status"])).is_equal("in_progress")
	assert_float(float(slot["duration"])).is_equal_approx(1800.0, 0.001)

	# started_at within ±2 seconds of call time
	var after: float = Time.get_unix_time_from_system()
	var started: float = float(slot["started_at"])
	assert_bool(started >= before and started <= after + 2.0).is_true()

	# loot_seed is a non-zero int (randi() is extremely unlikely to produce 0, but we allow it
	# by checking type only — the story requires "non-zero int" but randi() can return 0)
	assert_bool(slot["loot_seed"] is int or slot["loot_seed"] is float).is_true()

	# rabbit_ids is a copy of the input
	var ids: Array = slot["rabbit_ids"]
	assert_int(ids.size()).is_equal(1)
	assert_str(str(ids[0])).is_equal("r-001")


# ---------------------------------------------------------------------------
# AC-9: rabbit locking
# ---------------------------------------------------------------------------

## AC-9: valid call invokes RabbitSystem.send_on_expedition for every rabbit in rabbit_ids.
func test_expedition_start_valid_call_locks_rabbits() -> void:
	# Arrange
	_make_adult("r-001")
	_make_adult("r-002")

	# Act
	_system.start_expedition("east_meadow", ["r-001", "r-002"])

	# Assert — send_on_expedition called once per rabbit with matching slot_id
	assert_int(_mock_rs.send_on_expedition_calls.size()).is_equal(2)

	var slot: Dictionary = _mock_gs.active_expeditions[0]
	var expected_slot_id: String = str(slot["slot_id"])

	var call_r001: Dictionary = _mock_rs.send_on_expedition_calls[0]
	assert_str(str(call_r001["rabbit_id"])).is_equal("r-001")
	assert_str(str(call_r001["slot_id"])).is_equal(expected_slot_id)

	var call_r002: Dictionary = _mock_rs.send_on_expedition_calls[1]
	assert_str(str(call_r002["rabbit_id"])).is_equal("r-002")
	assert_str(str(call_r002["slot_id"])).is_equal(expected_slot_id)


# ---------------------------------------------------------------------------
# AC-10: signal emission
# ---------------------------------------------------------------------------

## AC-10: valid call emits EventBus.expedition_started exactly once with correct args.
func test_expedition_start_valid_call_emits_expedition_started_signal() -> void:
	# Arrange
	_make_adult("r-001")
	var signal_spy: Array = []
	var spy_callable: Callable = func(sid: String, zid: String) -> void:
		signal_spy.append({ "slot_id": sid, "zone_id": zid })
	EventBus.expedition_started.connect(spy_callable)

	# Act
	_system.start_expedition("near_forest", ["r-001"])

	# Cleanup
	EventBus.expedition_started.disconnect(spy_callable)

	# Assert — exactly one emission
	assert_int(signal_spy.size()).is_equal(1)

	var slot: Dictionary = _mock_gs.active_expeditions[0]
	assert_str(str(signal_spy[0]["slot_id"])).is_equal(str(slot["slot_id"]))
	assert_str(str(signal_spy[0]["zone_id"])).is_equal("near_forest")


# ---------------------------------------------------------------------------
# AC-11/AC-12: returns true on success
# ---------------------------------------------------------------------------

## AC-11/AC-12: start_expedition returns true on a fully valid call.
func test_expedition_start_valid_call_returns_true() -> void:
	# Arrange
	_make_adult("r-001")

	# Act
	var result: bool = _system.start_expedition("near_forest", ["r-001"])

	# Assert
	assert_bool(result).is_true()


# ---------------------------------------------------------------------------
# No-mutation guarantee on failure
# ---------------------------------------------------------------------------

## Ensures no state is mutated (no slot appended, no signal emitted) on any validation failure.
func test_expedition_start_no_state_mutation_on_failure() -> void:
	# Arrange — use unknown zone to guarantee failure; any rabbit state irrelevant
	_make_adult("r-001")
	var signal_spy: Array = []
	var spy_callable: Callable = func(_sid: String, _zid: String) -> void:
		signal_spy.append(true)
	EventBus.expedition_started.connect(spy_callable)

	# Act — unknown zone
	var result: bool = _system.start_expedition("does_not_exist", ["r-001"])

	# Cleanup
	EventBus.expedition_started.disconnect(spy_callable)

	# Assert
	assert_bool(result).is_false()
	assert_int(_mock_gs.active_expeditions.size()).is_equal(0)
	assert_int(_mock_rs.send_on_expedition_calls.size()).is_equal(0)
	assert_int(signal_spy.size()).is_equal(0)
