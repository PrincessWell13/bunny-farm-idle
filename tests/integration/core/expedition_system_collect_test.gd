## Integration tests for ExpeditionSystem.collect() and _tick_at() — story-002.
## Story: production/epics/expedition-system/story-002-collect-loot.md
## GameState, RabbitSystem, EconomyManager, EventBus, and TimeManager are mocked via
## Engine.register_singleton. _zone_defs is injected directly — no balance.json I/O.
extends GdUnitTestSuite

const ExpeditionSystemScript := preload("res://src/core/expedition_system.gd")

# ---------------------------------------------------------------------------
# Mock classes
# ---------------------------------------------------------------------------

class MockGameState:
	var active_expeditions: Array = []
	var prestige_count: int = 0
	func mark_dirty() -> void:
		pass


class MockRabbitSystem:
	var return_calls: Array[String] = []
	var rabbits: Dictionary = {}

	func return_from_expedition(rabbit_id: String) -> void:
		return_calls.append(rabbit_id)
		if rabbits.has(rabbit_id):
			rabbits[rabbit_id].is_on_expedition = false

	func get_rabbit(rabbit_id: String) -> RabbitData:
		return rabbits.get(rabbit_id, null)


class MockEconomyManager:
	var add_loot_reward_calls: Array[Dictionary] = []

	func add_loot_reward(item_id: String, quantity: int) -> void:
		add_loot_reward_calls.append({"item_id": item_id, "quantity": quantity})


class MockEventBus:
	var expedition_collected_calls: Array[Dictionary] = []
	var expedition_ready_calls: Array[Dictionary] = []
	signal expedition_collected(slot_id: String, rewards: Dictionary)
	signal expedition_started(slot_id: String, zone_id: String)
	signal expedition_ready_to_collect(slot_id: String, zone_id: String)
	signal expedition_completed(slot_id: String, zone_id: String)


class MockTimeManager:
	signal tick(delta: float)


# ---------------------------------------------------------------------------
# Test zone definitions — injected directly, no balance.json I/O (ADR-0004 pattern)
# ---------------------------------------------------------------------------

## Single-item loot table with weight=100 and fixed quantity=2.
## _roll_loot("test_zone", any_seed) always returns {"star_grass": 2}.
const TEST_ZONE_DEFS: Dictionary = {
	"test_zone": {
		"zone_id": "test_zone",
		"duration_seconds": 100.0,
		"min_rabbits": 1,
		"max_rabbits": 5,
		"required_trait": null,
		"requires_prestige": 0,
		"loot_table": [
			{"item_id": "star_grass", "weight": 100, "quantity_min": 2, "quantity_max": 2}
		]
	}
}

# ---------------------------------------------------------------------------
# Test infrastructure
# ---------------------------------------------------------------------------

var _system: Node
var _mock_gs: MockGameState
var _mock_rs: MockRabbitSystem
var _mock_em: MockEconomyManager
var _mock_eb: MockEventBus
var _mock_tm: MockTimeManager

var _owned_gs: bool = false
var _owned_rs: bool = false
var _owned_em: bool = false
var _owned_eb: bool = false
var _owned_tm: bool = false


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_mock_rs = MockRabbitSystem.new()
	_mock_em = MockEconomyManager.new()
	_mock_eb = MockEventBus.new()
	_mock_tm = MockTimeManager.new()

	_owned_gs = not Engine.has_singleton("GameState")
	if _owned_gs:
		Engine.register_singleton("GameState", _mock_gs)

	_owned_rs = not Engine.has_singleton("RabbitSystem")
	if _owned_rs:
		Engine.register_singleton("RabbitSystem", _mock_rs)

	_owned_em = not Engine.has_singleton("EconomyManager")
	if _owned_em:
		Engine.register_singleton("EconomyManager", _mock_em)

	_owned_eb = not Engine.has_singleton("EventBus")
	if _owned_eb:
		Engine.register_singleton("EventBus", _mock_eb)

	_owned_tm = not Engine.has_singleton("TimeManager")
	if _owned_tm:
		Engine.register_singleton("TimeManager", _mock_tm)

	# Construct without _ready() to avoid balance.json I/O and TimeManager.tick connection.
	_system = ExpeditionSystemScript.new()

	# Inject test zone definitions directly.
	_system._zone_defs = TEST_ZONE_DEFS.duplicate(true)


func after_test() -> void:
	_system.free()
	_system = null

	if _owned_tm:
		Engine.unregister_singleton("TimeManager")
	if _owned_eb:
		Engine.unregister_singleton("EventBus")
	if _owned_em:
		Engine.unregister_singleton("EconomyManager")
	if _owned_rs:
		Engine.unregister_singleton("RabbitSystem")
	if _owned_gs:
		Engine.unregister_singleton("GameState")

	_mock_tm = null
	_mock_eb = null
	_mock_em = null
	_mock_rs = null
	_mock_gs = null


## Builds a minimal slot dictionary for test_zone with the given id and status.
func _make_slot(id: String, status: String) -> Dictionary:
	return {
		"slot_id": id,
		"zone_id": "test_zone",
		"rabbit_ids": ["r-001"],
		"started_at": 0.0,
		"duration": 100.0,
		"loot_seed": 12345,
		"status": status
	}


## Registers a mock RabbitData for r-001 in MockRabbitSystem.
func _register_rabbit(rabbit_id: String) -> RabbitData:
	var data := RabbitData.new()
	data.rabbit_id = rabbit_id
	data.is_on_expedition = true
	_mock_rs.rabbits[rabbit_id] = data
	return data


# ---------------------------------------------------------------------------
# AC-1: collect on unknown slot returns {} and emits push_warning
# ---------------------------------------------------------------------------

## AC-1: collect() returns {} when slot_id is not found in active_expeditions.
func test_collect_unknown_slot_returns_empty_dict() -> void:
	# Arrange — active_expeditions is empty

	# Act
	var result: Dictionary = _system.collect("does_not_exist")

	# Assert
	assert_int(result.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC-2: collect on in_progress slot returns {} without mutation
# ---------------------------------------------------------------------------

## AC-2: collect() returns {} and does not mutate state when slot status == "in_progress".
func test_collect_in_progress_slot_returns_empty_dict_no_mutation() -> void:
	# Arrange
	var slot: Dictionary = _make_slot("exp_0", "in_progress")
	_mock_gs.active_expeditions.append(slot)
	_register_rabbit("r-001")

	# Act
	var result: Dictionary = _system.collect("exp_0")

	# Assert — returns empty
	assert_int(result.size()).is_equal(0)

	# Assert — slot still present (no mutation)
	assert_int(_mock_gs.active_expeditions.size()).is_equal(1)
	assert_str(str(_mock_gs.active_expeditions[0]["status"])).is_equal("in_progress")

	# Assert — no rewards granted
	assert_int(_mock_em.add_loot_reward_calls.size()).is_equal(0)

	# Assert — no rabbits unlocked
	assert_int(_mock_rs.return_calls.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC-3: slot removed BEFORE expedition_collected is emitted
# ---------------------------------------------------------------------------

## AC-3: active_expeditions is empty at the moment expedition_collected fires.
func test_collect_slot_removed_before_signal_emitted() -> void:
	# Arrange
	var slot: Dictionary = _make_slot("exp_0", "completed")
	_mock_gs.active_expeditions.append(slot)
	_register_rabbit("r-001")

	var size_at_signal: int = -1
	var spy_callable: Callable = func(_sid: String, _rewards: Dictionary) -> void:
		size_at_signal = _mock_gs.active_expeditions.size()

	var active_eb: Object = Engine.get_singleton("EventBus")
	active_eb.expedition_collected.connect(spy_callable)

	# Act
	_system.collect("exp_0")

	# Cleanup
	if active_eb.expedition_collected.is_connected(spy_callable):
		active_eb.expedition_collected.disconnect(spy_callable)

	# Assert — slot was removed before the signal fired
	assert_int(size_at_signal).is_equal(0)


# ---------------------------------------------------------------------------
# AC-4: EconomyManager.add_loot_reward called for each loot item
# ---------------------------------------------------------------------------

## AC-4: collect() calls EconomyManager.add_loot_reward for each item in the rolled rewards.
func test_collect_calls_economy_manager_add() -> void:
	# Arrange
	var slot: Dictionary = _make_slot("exp_0", "completed")
	_mock_gs.active_expeditions.append(slot)
	_register_rabbit("r-001")

	# Act
	_system.collect("exp_0")

	# Assert — exactly one call for "star_grass" (single-item loot table, fixed qty=2)
	assert_int(_mock_em.add_loot_reward_calls.size()).is_equal(1)
	assert_str(_mock_em.add_loot_reward_calls[0]["item_id"]).is_equal("star_grass")
	assert_int(_mock_em.add_loot_reward_calls[0]["quantity"]).is_equal(2)


# ---------------------------------------------------------------------------
# AC-5: RabbitSystem.return_from_expedition called for every rabbit in slot
# ---------------------------------------------------------------------------

## AC-5: collect() calls RabbitSystem.return_from_expedition for every rabbit in the slot.
func test_collect_calls_rabbit_system_return() -> void:
	# Arrange
	var slot: Dictionary = _make_slot("exp_0", "completed")
	slot["rabbit_ids"] = ["r-001", "r-002"]
	_mock_gs.active_expeditions.append(slot)
	_register_rabbit("r-001")
	_register_rabbit("r-002")

	# Act
	_system.collect("exp_0")

	# Assert — both rabbits returned
	assert_int(_mock_rs.return_calls.size()).is_equal(2)
	assert_bool(_mock_rs.return_calls.has("r-001")).is_true()
	assert_bool(_mock_rs.return_calls.has("r-002")).is_true()


# ---------------------------------------------------------------------------
# AC-6: expedition_collected signal emitted exactly once after all mutations
# ---------------------------------------------------------------------------

## AC-6: collect() emits EventBus.expedition_collected exactly once, after rewards and returns.
func test_collect_emits_expedition_collected_signal() -> void:
	# Arrange
	var slot: Dictionary = _make_slot("exp_0", "completed")
	_mock_gs.active_expeditions.append(slot)
	_register_rabbit("r-001")

	var signal_spy: Array = []
	var spy_callable: Callable = func(sid: String, rewards: Dictionary) -> void:
		signal_spy.append({"slot_id": sid, "rewards": rewards})

	var active_eb: Object = Engine.get_singleton("EventBus")
	active_eb.expedition_collected.connect(spy_callable)

	# Act
	_system.collect("exp_0")

	# Cleanup
	if active_eb.expedition_collected.is_connected(spy_callable):
		active_eb.expedition_collected.disconnect(spy_callable)

	# Assert — exactly one emission with correct slot_id
	assert_int(signal_spy.size()).is_equal(1)
	assert_str(signal_spy[0]["slot_id"]).is_equal("exp_0")

	# Assert — rewards were already granted when signal fired (return_calls populated)
	assert_int(_mock_rs.return_calls.size()).is_equal(1)
	assert_int(_mock_em.add_loot_reward_calls.size()).is_equal(1)


# ---------------------------------------------------------------------------
# AC-7: collect returns non-empty dict on valid completed slot
# ---------------------------------------------------------------------------

## AC-7: collect() returns a non-empty Dictionary on a valid completed slot.
func test_collect_returns_non_empty_dict_on_success() -> void:
	# Arrange
	var slot: Dictionary = _make_slot("exp_0", "completed")
	_mock_gs.active_expeditions.append(slot)
	_register_rabbit("r-001")

	# Act
	var result: Dictionary = _system.collect("exp_0")

	# Assert
	assert_bool(result.is_empty()).is_false()
	assert_bool(result.has("star_grass")).is_true()
	assert_int(result["star_grass"]).is_equal(2)


# ---------------------------------------------------------------------------
# AC-8: second collect on same slot_id returns {} (double-collect guard)
# ---------------------------------------------------------------------------

## AC-8: second collect() on the same slot_id returns {} — slot was already removed.
func test_collect_double_collect_grants_rewards_once() -> void:
	# Arrange
	var slot: Dictionary = _make_slot("exp_0", "completed")
	_mock_gs.active_expeditions.append(slot)
	_register_rabbit("r-001")

	# Act
	var first: Dictionary = _system.collect("exp_0")
	var second: Dictionary = _system.collect("exp_0")

	# Assert — first collect succeeds
	assert_bool(first.is_empty()).is_false()

	# Assert — second collect returns empty (slot already gone)
	assert_int(second.size()).is_equal(0)

	# Assert — rewards granted exactly once
	assert_int(_mock_em.add_loot_reward_calls.size()).is_equal(1)
	assert_int(_mock_rs.return_calls.size()).is_equal(1)


# ---------------------------------------------------------------------------
# AC-9: _roll_loot is deterministic — same seed always same result
# ---------------------------------------------------------------------------

## AC-9: _roll_loot("test_zone", seed) returns identical results across three calls.
func test_roll_loot_deterministic_same_seed_same_result() -> void:
	# Arrange
	const SEED: int = 99999

	# Act — call three times with same inputs
	var result_a: Dictionary = _system._roll_loot("test_zone", SEED)
	var result_b: Dictionary = _system._roll_loot("test_zone", SEED)
	var result_c: Dictionary = _system._roll_loot("test_zone", SEED)

	# Assert — all three results are identical
	assert_bool(result_a == result_b).is_true()
	assert_bool(result_b == result_c).is_true()

	# Assert — result is the expected fixed quantity (weight=100, qty_min=qty_max=2)
	assert_bool(result_a.has("star_grass")).is_true()
	assert_int(result_a["star_grass"]).is_equal(2)


# ---------------------------------------------------------------------------
# AC-10: _tick_at flips status to completed when deadline is passed
# ---------------------------------------------------------------------------

## AC-10: _tick_at() with T < deadline leaves slot in_progress; T >= deadline flips to completed.
func test_tick_at_flips_status_when_deadline_passed() -> void:
	# Arrange — started_at=0.0, duration=100.0 → deadline at T=100.0
	var slot: Dictionary = _make_slot("exp_0", "in_progress")
	_mock_gs.active_expeditions.append(slot)

	# Act — tick before deadline (T=99.0)
	_system._tick_at(99.0)

	# Assert — still in_progress
	assert_str(str(_mock_gs.active_expeditions[0]["status"])).is_equal("in_progress")

	# Act — tick exactly at deadline (T=100.0)
	_system._tick_at(100.0)

	# Assert — now completed
	assert_str(str(_mock_gs.active_expeditions[0]["status"])).is_equal("completed")


# ---------------------------------------------------------------------------
# AC-11: _tick_at emits expedition_ready_to_collect exactly once per slot transition
# ---------------------------------------------------------------------------

## AC-11: expedition_ready_to_collect is emitted exactly once even when _tick_at is called
## multiple times after the deadline — status acts as the latch.
func test_tick_at_emits_ready_signal_exactly_once() -> void:
	# Arrange
	var slot: Dictionary = _make_slot("exp_0", "in_progress")
	_mock_gs.active_expeditions.append(slot)

	var signal_spy: Array = []
	var spy_callable: Callable = func(sid: String, _zid: String) -> void:
		signal_spy.append(sid)

	var active_eb: Object = Engine.get_singleton("EventBus")
	active_eb.expedition_ready_to_collect.connect(spy_callable)

	# Act — tick past deadline twice
	_system._tick_at(100.0)
	_system._tick_at(200.0)

	# Cleanup
	if active_eb.expedition_ready_to_collect.is_connected(spy_callable):
		active_eb.expedition_ready_to_collect.disconnect(spy_callable)

	# Assert — signal emitted exactly once (status latch prevents second emission)
	assert_int(signal_spy.size()).is_equal(1)
	assert_str(signal_spy[0]).is_equal("exp_0")


# ---------------------------------------------------------------------------
# AC-12: completed slot persists in active_expeditions until collect() removes it
# ---------------------------------------------------------------------------

## AC-12: _tick_at() does not remove completed slots — they persist until collect() is called.
func test_tick_at_completed_slot_persists_in_active_expeditions() -> void:
	# Arrange
	var slot: Dictionary = _make_slot("exp_0", "in_progress")
	_mock_gs.active_expeditions.append(slot)

	# Act — tick past deadline to flip to completed
	_system._tick_at(100.0)

	# Assert — slot still present in active_expeditions (not removed by _tick_at)
	assert_int(_mock_gs.active_expeditions.size()).is_equal(1)
	assert_str(str(_mock_gs.active_expeditions[0]["status"])).is_equal("completed")

	# Act — now collect() to verify it's the only thing that removes it
	_register_rabbit("r-001")
	_system.collect("exp_0")

	# Assert — slot removed only after collect()
	assert_int(_mock_gs.active_expeditions.size()).is_equal(0)
