## Integration tests for ExpeditionSystem._resolve_offline_expeditions_at() — story-003.
## Story: production/epics/expedition-system/story-003-offline-catchup.md
## GameState, RabbitSystem, EconomyManager, EventBus, and TimeManager are mocked via
## Engine.register_singleton. _zone_defs is injected directly — no balance.json I/O.
extends GdUnitTestSuite

const ExpeditionSystemScript := preload("res://src/core/expedition_system.gd")

# ---------------------------------------------------------------------------
# Mock classes — identical shape to expedition_system_collect_test.gd
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


## Builds a minimal slot dictionary for test_zone with the given id and status,
## supporting configurable started_at and duration for offline timing tests.
func _make_slot(id: String, status: String, started_at: float, duration: float) -> Dictionary:
	return {
		"slot_id": id,
		"zone_id": "test_zone",
		"rabbit_ids": ["r-001"],
		"started_at": started_at,
		"duration": duration,
		"loot_seed": 12345,
		"status": status
	}


## Registers a mock RabbitData for rabbit_id in MockRabbitSystem.
func _register_rabbit(rabbit_id: String) -> RabbitData:
	var data := RabbitData.new()
	data.rabbit_id = rabbit_id
	data.is_on_expedition = true
	_mock_rs.rabbits[rabbit_id] = data
	return data


# ---------------------------------------------------------------------------
# AC-2: empty active_expeditions — no error, no signals
# ---------------------------------------------------------------------------

## AC-2: _resolve_offline_expeditions_at() with empty active_expeditions completes
## without error and emits no expedition_ready_to_collect signals.
func test_offline_resolve_empty_expeditions_no_error_no_signals() -> void:
	# Arrange — active_expeditions is already empty by default
	var signal_spy: Array = []
	var spy_callable: Callable = func(_sid: String, _zid: String) -> void:
		signal_spy.append(_sid)

	var active_eb: Object = Engine.get_singleton("EventBus")
	active_eb.expedition_ready_to_collect.connect(spy_callable)

	# Act
	_system._resolve_offline_expeditions_at(9999999.0)

	# Cleanup
	if active_eb.expedition_ready_to_collect.is_connected(spy_callable):
		active_eb.expedition_ready_to_collect.disconnect(spy_callable)

	# Assert — no signals fired and no crash
	assert_int(signal_spy.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC-3: elapsed in_progress slot → completed, signal emitted
# ---------------------------------------------------------------------------

## AC-3: a slot with status "in_progress" whose deadline has passed is flipped to
## "completed" and expedition_ready_to_collect is emitted exactly once with the
## correct slot_id and zone_id.
func test_offline_resolve_elapsed_slot_becomes_completed_signal_emitted() -> void:
	# Arrange — started_at=1000, duration=100, deadline at T=1100; now=1101 (elapsed)
	var slot: Dictionary = _make_slot("exp_0", "in_progress", 1000.0, 100.0)
	_mock_gs.active_expeditions.append(slot)

	var signal_spy: Array = []
	var spy_callable: Callable = func(sid: String, zid: String) -> void:
		signal_spy.append({"slot_id": sid, "zone_id": zid})

	var active_eb: Object = Engine.get_singleton("EventBus")
	active_eb.expedition_ready_to_collect.connect(spy_callable)

	# Act
	_system._resolve_offline_expeditions_at(1101.0)

	# Cleanup
	if active_eb.expedition_ready_to_collect.is_connected(spy_callable):
		active_eb.expedition_ready_to_collect.disconnect(spy_callable)

	# Assert — status flipped to completed
	assert_str(str(_mock_gs.active_expeditions[0]["status"])).is_equal("completed")

	# Assert — signal emitted exactly once with correct identifiers
	assert_int(signal_spy.size()).is_equal(1)
	assert_str(signal_spy[0]["slot_id"]).is_equal("exp_0")
	assert_str(signal_spy[0]["zone_id"]).is_equal("test_zone")


# ---------------------------------------------------------------------------
# AC-4: not-yet-elapsed slot → unchanged, no signal
# ---------------------------------------------------------------------------

## AC-4: a slot with status "in_progress" whose deadline has NOT passed is left
## untouched — status remains "in_progress" and no signal is emitted.
func test_offline_resolve_not_elapsed_slot_unchanged() -> void:
	# Arrange — started_at=1000, duration=100, deadline at T=1100; now=1050 (not elapsed)
	var slot: Dictionary = _make_slot("exp_0", "in_progress", 1000.0, 100.0)
	_mock_gs.active_expeditions.append(slot)

	var signal_spy: Array = []
	var spy_callable: Callable = func(_sid: String, _zid: String) -> void:
		signal_spy.append(_sid)

	var active_eb: Object = Engine.get_singleton("EventBus")
	active_eb.expedition_ready_to_collect.connect(spy_callable)

	# Act
	_system._resolve_offline_expeditions_at(1050.0)

	# Cleanup
	if active_eb.expedition_ready_to_collect.is_connected(spy_callable):
		active_eb.expedition_ready_to_collect.disconnect(spy_callable)

	# Assert — status unchanged
	assert_str(str(_mock_gs.active_expeditions[0]["status"])).is_equal("in_progress")

	# Assert — no signal emitted
	assert_int(signal_spy.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC-5: already-completed slot → unchanged, no duplicate signal
# ---------------------------------------------------------------------------

## AC-5: a slot already at status "completed" (from a previous session, not yet
## collected) is left untouched — no duplicate signal, no state mutation.
func test_offline_resolve_already_completed_slot_unchanged_no_duplicate_signal() -> void:
	# Arrange — slot already marked completed before resolve runs
	var slot: Dictionary = _make_slot("exp_0", "completed", 1000.0, 100.0)
	_mock_gs.active_expeditions.append(slot)

	var signal_spy: Array = []
	var spy_callable: Callable = func(_sid: String, _zid: String) -> void:
		signal_spy.append(_sid)

	var active_eb: Object = Engine.get_singleton("EventBus")
	active_eb.expedition_ready_to_collect.connect(spy_callable)

	# Act — use a time well past the deadline to confirm it is the status, not time, that gates
	_system._resolve_offline_expeditions_at(9999999.0)

	# Cleanup
	if active_eb.expedition_ready_to_collect.is_connected(spy_callable):
		active_eb.expedition_ready_to_collect.disconnect(spy_callable)

	# Assert — status unchanged
	assert_str(str(_mock_gs.active_expeditions[0]["status"])).is_equal("completed")

	# Assert — no duplicate signal emitted
	assert_int(signal_spy.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC-6: slots not removed from active_expeditions during resolve pass
# ---------------------------------------------------------------------------

## AC-6: valid slots are NOT removed from active_expeditions during the offline
## resolve pass — the slot count is unchanged and the slot is present with
## status "completed" after resolution.
func test_offline_resolve_slots_not_removed_from_active_expeditions() -> void:
	# Arrange — one elapsed in_progress slot
	var slot: Dictionary = _make_slot("exp_0", "in_progress", 1000.0, 100.0)
	_mock_gs.active_expeditions.append(slot)

	# Act
	_system._resolve_offline_expeditions_at(1200.0)

	# Assert — slot still present (not removed by resolve)
	assert_int(_mock_gs.active_expeditions.size()).is_equal(1)
	assert_str(str(_mock_gs.active_expeditions[0]["status"])).is_equal("completed")


# ---------------------------------------------------------------------------
# AC-7: collect() succeeds after offline resolve
# ---------------------------------------------------------------------------

## AC-7: after _resolve_offline_expeditions_at() marks a slot completed, a
## subsequent collect() call succeeds and returns non-empty rewards.
## Confirms story-002 and story-003 integration.
func test_offline_resolve_collect_succeeds_after_offline_resolve() -> void:
	# Arrange — elapsed slot; rabbit registered so collect() can unlock it
	var slot: Dictionary = _make_slot("exp_0", "in_progress", 1000.0, 100.0)
	_mock_gs.active_expeditions.append(slot)
	_register_rabbit("r-001")

	# Act — offline resolve first
	_system._resolve_offline_expeditions_at(1200.0)

	# Assert — slot is now completed
	assert_str(str(_mock_gs.active_expeditions[0]["status"])).is_equal("completed")

	# Act — player taps collect
	var rewards: Dictionary = _system.collect("exp_0")

	# Assert — collect returns non-empty rewards dict
	assert_bool(rewards.is_empty()).is_false()
	assert_bool(rewards.has("star_grass")).is_true()
	assert_int(rewards["star_grass"]).is_equal(2)


# ---------------------------------------------------------------------------
# AC-8: malformed slot discarded safely, valid slots still processed
# ---------------------------------------------------------------------------

## AC-8: a slot missing a required key ("loot_seed") is removed from
## active_expeditions without causing an unhandled error. A valid second slot
## in the same pass is still resolved correctly.
func test_offline_resolve_malformed_slot_discarded_safely() -> void:
	# Arrange — slot-A is malformed (missing loot_seed); slot-B is valid and elapsed
	var malformed: Dictionary = {
		"slot_id": "exp_bad",
		"zone_id": "test_zone",
		"rabbit_ids": ["r-001"],
		"started_at": 1000.0,
		"duration": 100.0,
		# "loot_seed" deliberately omitted
		"status": "in_progress"
	}
	var valid_slot: Dictionary = _make_slot("exp_good", "in_progress", 1000.0, 100.0)
	_mock_gs.active_expeditions.append(malformed)
	_mock_gs.active_expeditions.append(valid_slot)

	var signal_spy: Array = []
	var spy_callable: Callable = func(sid: String, _zid: String) -> void:
		signal_spy.append(sid)

	var active_eb: Object = Engine.get_singleton("EventBus")
	active_eb.expedition_ready_to_collect.connect(spy_callable)

	# Act
	_system._resolve_offline_expeditions_at(1200.0)

	# Cleanup
	if active_eb.expedition_ready_to_collect.is_connected(spy_callable):
		active_eb.expedition_ready_to_collect.disconnect(spy_callable)

	# Assert — malformed slot removed; valid slot retained
	assert_int(_mock_gs.active_expeditions.size()).is_equal(1)
	assert_str(str(_mock_gs.active_expeditions[0]["slot_id"])).is_equal("exp_good")
	assert_str(str(_mock_gs.active_expeditions[0]["status"])).is_equal("completed")

	# Assert — only the valid slot emitted a signal
	assert_int(signal_spy.size()).is_equal(1)
	assert_str(signal_spy[0]).is_equal("exp_good")


# ---------------------------------------------------------------------------
# AC-10: three staggered expeditions all resolved in one pass
# ---------------------------------------------------------------------------

## AC-10: three simultaneous expeditions with staggered durations are all resolved
## correctly in a single pass when now is past all three deadlines.
## started_at=1000, durations=100/200/300 → deadlines at T=1100/1200/1300.
## now=1350 → all three must be "completed"; three signals emitted.
func test_offline_resolve_three_staggered_expeditions_all_resolved() -> void:
	# Arrange
	var slot_a: Dictionary = _make_slot("exp_a", "in_progress", 1000.0, 100.0)
	var slot_b: Dictionary = _make_slot("exp_b", "in_progress", 1000.0, 200.0)
	var slot_c: Dictionary = _make_slot("exp_c", "in_progress", 1000.0, 300.0)
	_mock_gs.active_expeditions.append(slot_a)
	_mock_gs.active_expeditions.append(slot_b)
	_mock_gs.active_expeditions.append(slot_c)

	var signal_spy: Array = []
	var spy_callable: Callable = func(sid: String, _zid: String) -> void:
		signal_spy.append(sid)

	var active_eb: Object = Engine.get_singleton("EventBus")
	active_eb.expedition_ready_to_collect.connect(spy_callable)

	# Act — now=1350, all three deadlines passed
	_system._resolve_offline_expeditions_at(1350.0)

	# Cleanup
	if active_eb.expedition_ready_to_collect.is_connected(spy_callable):
		active_eb.expedition_ready_to_collect.disconnect(spy_callable)

	# Assert — all three slots completed
	assert_int(_mock_gs.active_expeditions.size()).is_equal(3)
	for slot: Dictionary in _mock_gs.active_expeditions:
		assert_str(str(slot["status"])).is_equal("completed")

	# Assert — three signals emitted (one per slot)
	assert_int(signal_spy.size()).is_equal(3)
	assert_bool(signal_spy.has("exp_a")).is_true()
	assert_bool(signal_spy.has("exp_b")).is_true()
	assert_bool(signal_spy.has("exp_c")).is_true()


# ---------------------------------------------------------------------------
# AC-10 partial: same three slots but now=1250 — only slot-A and slot-B done
# ---------------------------------------------------------------------------

## Partial staggered resolution: at now=1250, slot-A (deadline T=1100) and
## slot-B (deadline T=1200) are completed, slot-C (deadline T=1300) remains
## in_progress. Two signals emitted; slot-C untouched.
func test_offline_resolve_partial_staggered_expeditions() -> void:
	# Arrange
	var slot_a: Dictionary = _make_slot("exp_a", "in_progress", 1000.0, 100.0)
	var slot_b: Dictionary = _make_slot("exp_b", "in_progress", 1000.0, 200.0)
	var slot_c: Dictionary = _make_slot("exp_c", "in_progress", 1000.0, 300.0)
	_mock_gs.active_expeditions.append(slot_a)
	_mock_gs.active_expeditions.append(slot_b)
	_mock_gs.active_expeditions.append(slot_c)

	var signal_spy: Array = []
	var spy_callable: Callable = func(sid: String, _zid: String) -> void:
		signal_spy.append(sid)

	var active_eb: Object = Engine.get_singleton("EventBus")
	active_eb.expedition_ready_to_collect.connect(spy_callable)

	# Act — now=1250: slot-A (1100) and slot-B (1200) elapsed; slot-C (1300) not yet
	_system._resolve_offline_expeditions_at(1250.0)

	# Cleanup
	if active_eb.expedition_ready_to_collect.is_connected(spy_callable):
		active_eb.expedition_ready_to_collect.disconnect(spy_callable)

	# Assert — find each slot by id for status checks
	var statuses: Dictionary = {}
	for slot: Dictionary in _mock_gs.active_expeditions:
		statuses[str(slot["slot_id"])] = str(slot["status"])

	assert_str(statuses["exp_a"]).is_equal("completed")
	assert_str(statuses["exp_b"]).is_equal("completed")
	assert_str(statuses["exp_c"]).is_equal("in_progress")

	# Assert — exactly two signals, for the two elapsed slots
	assert_int(signal_spy.size()).is_equal(2)
	assert_bool(signal_spy.has("exp_a")).is_true()
	assert_bool(signal_spy.has("exp_b")).is_true()
	assert_bool(signal_spy.has("exp_c")).is_false()


# ---------------------------------------------------------------------------
# AC-7 structural: resolve does NOT call collect (EconomyManager not called)
# ---------------------------------------------------------------------------

## AC-7 structural: after _resolve_offline_expeditions_at() runs, EconomyManager
## has received zero add_loot_reward calls — collect() was NOT auto-invoked.
func test_offline_resolve_does_not_call_collect() -> void:
	# Arrange — elapsed slot with a registered rabbit
	var slot: Dictionary = _make_slot("exp_0", "in_progress", 1000.0, 100.0)
	_mock_gs.active_expeditions.append(slot)
	_register_rabbit("r-001")

	# Act — resolve only; no collect() call
	_system._resolve_offline_expeditions_at(1200.0)

	# Assert — no economy calls (collect was not auto-triggered)
	assert_int(_mock_em.add_loot_reward_calls.size()).is_equal(0)

	# Assert — rabbit was NOT returned (only collect() unlocks rabbits)
	assert_int(_mock_rs.return_calls.size()).is_equal(0)

	# Assert — slot still in active_expeditions (not removed by resolve)
	assert_int(_mock_gs.active_expeditions.size()).is_equal(1)
