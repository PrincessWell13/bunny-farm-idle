## ExpeditionSystem — owns all mutations to GameState.active_expeditions (ADR-0011).
## Sole mutator of active expedition slots. Rabbits locked via RabbitSystem.send_on_expedition().
## Zone definitions loaded from balance.json at _ready(). Offline catch-up via
## _resolve_offline_expeditions() deferred from _ready() (story-003).
##
## Public API:
##   start_expedition(zone_id, rabbit_ids) -> bool  — validate, create slot, lock rabbits
##   get_active_slots() -> Array                    — snapshot copy of active_expeditions
##   get_slot(slot_id) -> Dictionary                — find one slot by slot_id; {} if not found
##   collect(slot_id) -> Dictionary                 — story-002: grant loot, remove slot
extends Node

## Slot dictionary key constants — prevents typo drift across the system (ADR-0011).
const KEY_SLOT_ID    := &"slot_id"
const KEY_ZONE_ID    := &"zone_id"
const KEY_RABBIT_IDS := &"rabbit_ids"
const KEY_STARTED_AT := &"started_at"
const KEY_DURATION   := &"duration"
const KEY_LOOT_SEED  := &"loot_seed"
const KEY_STATUS     := &"status"

const STATUS_IN_PROGRESS := "in_progress"
const STATUS_COMPLETED   := "completed"

## Zone definition cache populated by _load_balance_data(). zone_id -> zone Dictionary.
var _zone_defs: Dictionary = {}

## Monotonic counter for slot IDs — simpler and more testable than timestamp-hash approach.
var _next_slot_id: int = 0


func _ready() -> void:
	_load_balance_data()
	var tm: Node = _time_mgr()
	if tm != null:
		tm.tick.connect(_on_tick)
	call_deferred(&"_resolve_offline_expeditions")


func _exit_tree() -> void:
	var tm: Node = _time_mgr()
	if tm != null and tm.tick.is_connected(_on_tick):
		tm.tick.disconnect(_on_tick)


## Resolves GameState via Engine singleton first to allow test-time mock injection.
func _gs() -> Node:
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	return get_node_or_null("/root/GameState")


## Resolves EventBus via Engine singleton first to allow test-time mock injection.
func _event_bus() -> Node:
	if Engine.has_singleton("EventBus"):
		return Engine.get_singleton("EventBus")
	return get_node_or_null("/root/EventBus")


## Resolves RabbitSystem via Engine singleton first to allow test-time mock injection.
func _rabbit_sys() -> Node:
	if Engine.has_singleton("RabbitSystem"):
		return Engine.get_singleton("RabbitSystem")
	return get_node_or_null("/root/RabbitSystem")


## Resolves EconomyManager via Engine singleton first to allow test-time mock injection.
func _economy_mgr() -> Node:
	if Engine.has_singleton("EconomyManager"):
		return Engine.get_singleton("EconomyManager")
	return get_node_or_null("/root/EconomyManager")


## Resolves TimeManager via Engine singleton first to allow test-time mock injection.
func _time_mgr() -> Node:
	if Engine.has_singleton("TimeManager"):
		return Engine.get_singleton("TimeManager")
	return get_node_or_null("/root/TimeManager")


## Reads the expeditions section of balance.json and populates _zone_defs.
## Emits push_error on missing or malformed data; falls back to empty defs.
## Pattern mirrors FoodSystem._load_balance_data() (ADR-0004).
func _load_balance_data() -> void:
	var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
	if text.is_empty():
		push_error("ExpeditionSystem: balance.json not found — _zone_defs empty")
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("ExpeditionSystem: balance.json parse failed — _zone_defs empty")
		return
	var data: Dictionary = parsed as Dictionary
	var expeditions: Dictionary = data.get("expeditions", {}) as Dictionary
	if not expeditions.has("zones"):
		push_error("ExpeditionSystem: balance.json missing expeditions.zones — _zone_defs empty")
		return
	for zone: Dictionary in expeditions["zones"]:
		_zone_defs[zone["zone_id"]] = zone


## Validates requirements, creates an expedition slot, locks rabbits, and emits
## expedition_started. Returns true on success, false on any validation failure.
## On failure: emits nothing and mutates nothing (ADR-0011).
##
## Example:
##   var ok: bool = ExpeditionSystem.start_expedition("near_forest", ["r_001", "r_002"])
func start_expedition(zone_id: String, rabbit_ids: Array[String]) -> bool:
	if not _validate_requirements(zone_id, rabbit_ids):
		return false

	var zone: Dictionary = _zone_defs[zone_id]
	var slot_id: String = "exp_%d" % _next_slot_id
	_next_slot_id += 1

	var slot: Dictionary = {
		KEY_SLOT_ID:    slot_id,
		KEY_ZONE_ID:    zone_id,
		KEY_RABBIT_IDS: rabbit_ids.duplicate(),
		KEY_STARTED_AT: Time.get_unix_time_from_system(),
		KEY_DURATION:   float(zone["duration_seconds"]),
		KEY_LOOT_SEED:  randi(),
		KEY_STATUS:     STATUS_IN_PROGRESS,
	}

	_gs().active_expeditions.append(slot)

	var rs: Node = _rabbit_sys()
	for rabbit_id: String in rabbit_ids:
		rs.send_on_expedition(rabbit_id, slot_id)

	_event_bus().expedition_started.emit(slot_id, zone_id)
	return true


## Returns a snapshot copy of all active expedition slots (read-only).
func get_active_slots() -> Array:
	return _gs().active_expeditions.duplicate()


## Returns the slot dictionary for slot_id, or {} if not found.
##
## Example:
##   var slot: Dictionary = ExpeditionSystem.get_slot("exp_0")
func get_slot(slot_id: String) -> Dictionary:
	for slot: Dictionary in _gs().active_expeditions:
		if slot.get(KEY_SLOT_ID, "") == slot_id:
			return slot
	return {}


## Grants loot for a completed expedition slot and unlocks the assigned rabbits.
## Slot is removed BEFORE rewards are granted — this is the double-collect guard.
## Returns {} when slot_id is not found or slot status is not "completed".
##
## Example:
##   var rewards: Dictionary = ExpeditionSystem.collect("exp_0")
func collect(slot_id: String) -> Dictionary:
	var gs: Node = _gs()
	var slot_index: int = -1
	for i: int in range(gs.active_expeditions.size()):
		if gs.active_expeditions[i][KEY_SLOT_ID] == slot_id:
			slot_index = i
			break

	if slot_index == -1:
		push_warning("ExpeditionSystem.collect: slot_id '%s' not found" % slot_id)
		return {}

	var slot: Dictionary = gs.active_expeditions[slot_index]

	if slot[KEY_STATUS] != STATUS_COMPLETED:
		push_warning("ExpeditionSystem.collect: slot '%s' is still in_progress" % slot_id)
		return {}

	# CRITICAL: remove slot FIRST — double-collect guard (ADR-0011)
	gs.active_expeditions.remove_at(slot_index)

	# Roll loot using the pre-stored seed
	var rewards: Dictionary = _roll_loot(str(slot[KEY_ZONE_ID]), int(slot[KEY_LOOT_SEED]))

	# Grant rewards via EconomyManager (add_loot_reward routes string item_id to CurrencyType)
	var em: Node = _economy_mgr()
	for item_id: String in rewards:
		em.add_loot_reward(item_id, rewards[item_id])

	# Unlock rabbits
	var rs: Node = _rabbit_sys()
	for rabbit_id: String in slot[KEY_RABBIT_IDS]:
		if rs.get_rabbit(rabbit_id) != null:
			rs.return_from_expedition(rabbit_id)
		else:
			push_warning("ExpeditionSystem.collect: rabbit '%s' missing at return" % rabbit_id)

	_event_bus().expedition_collected.emit(slot_id, rewards)
	return rewards


## Deterministically rolls loot for a zone using the given seed (ADR-0011 R3).
## Instantiates a fresh RNG seeded with loot_seed — same seed always produces same result.
## Returns a single-entry dictionary { item_id: quantity }.
func _roll_loot(zone_id: String, loot_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = loot_seed

	var zone: Dictionary = _zone_defs[zone_id]
	var loot_table: Array = zone["loot_table"]

	var total_weight: int = 0
	for entry: Dictionary in loot_table:
		total_weight += int(entry["weight"])

	var roll: int = rng.randi_range(0, total_weight - 1)
	var cumulative: int = 0
	var selected: Dictionary = loot_table[0]
	for entry: Dictionary in loot_table:
		cumulative += int(entry["weight"])
		if roll < cumulative:
			selected = entry
			break

	var quantity: int = rng.randi_range(int(selected["quantity_min"]), int(selected["quantity_max"]))
	return { str(selected["item_id"]): quantity }


## Polling handler connected to TimeManager.tick. Flips in_progress slots to
## completed when their wall-clock deadline has passed, emitting
## expedition_ready_to_collect exactly once per transition.
## Tick cost is O(active_expeditions) — bounded at ~5 slots (ADR-0011).
func _on_tick(_delta: float) -> void:
	_tick_at(Time.get_unix_time_from_system())


## Internal tick logic extracted for testability — called by _on_tick() with current time.
##
## Example:
##   _tick_at(Time.get_unix_time_from_system())
func _tick_at(now: float) -> void:
	var eb: Node = _event_bus()
	for slot: Dictionary in _gs().active_expeditions:
		if slot[KEY_STATUS] == STATUS_IN_PROGRESS:
			if now >= float(slot[KEY_STARTED_AT]) + float(slot[KEY_DURATION]):
				slot[KEY_STATUS] = STATUS_COMPLETED
				eb.expedition_ready_to_collect.emit(str(slot[KEY_SLOT_ID]), str(slot[KEY_ZONE_ID]))


## Called once via call_deferred from _ready() after SaveSystem has loaded
## GameState.active_expeditions. Marks any slot whose deadline already passed
## as completed and emits expedition_ready_to_collect. Does NOT auto-collect.
##
## Example:
##   call_deferred(&"_resolve_offline_expeditions")  # only from _ready()
func _resolve_offline_expeditions() -> void:
	_resolve_offline_expeditions_at(Time.get_unix_time_from_system())


## Testable inner implementation — accepts now so tests can avoid mocking Time singleton.
## Iterates backwards over GameState.active_expeditions for safe in-place removal of
## malformed slots (missing any of the 7 required keys).
## Valid in_progress slots whose deadline has passed are flipped to "completed" and
## EventBus.expedition_ready_to_collect is emitted. Does NOT call collect().
##
## Example:
##   _resolve_offline_expeditions_at(Time.get_unix_time_from_system())
func _resolve_offline_expeditions_at(now: float) -> void:
	var required_keys: Array[String] = [
		KEY_SLOT_ID, KEY_ZONE_ID, KEY_RABBIT_IDS,
		KEY_STARTED_AT, KEY_DURATION, KEY_LOOT_SEED, KEY_STATUS
	]

	var gs: Node = _gs()
	var eb: Node = _event_bus()
	var i: int = gs.active_expeditions.size() - 1
	while i >= 0:
		var slot: Dictionary = gs.active_expeditions[i]

		# Validate: discard malformed slots missing any required key.
		var is_valid: bool = true
		for key: String in required_keys:
			if not slot.has(key):
				push_warning("ExpeditionSystem: malformed slot at index %d missing key '%s' — discarding" % [i, key])
				is_valid = false
				break

		if not is_valid:
			gs.active_expeditions.remove_at(i)
			i -= 1
			continue

		# Only transition in_progress slots whose deadline has passed.
		if slot[KEY_STATUS] == STATUS_IN_PROGRESS:
			if now >= float(slot[KEY_STARTED_AT]) + float(slot[KEY_DURATION]):
				slot[KEY_STATUS] = STATUS_COMPLETED
				eb.expedition_ready_to_collect.emit(
					str(slot[KEY_SLOT_ID]),
					str(slot[KEY_ZONE_ID])
				)

		i -= 1


## Validates all preconditions for start_expedition without mutating state.
## Returns false on the first failing check; true only when all checks pass.
func _validate_requirements(zone_id: String, rabbit_ids: Array[String]) -> bool:
	# AC-1: zone must exist in balance.json
	if not _zone_defs.has(zone_id):
		return false

	var zone: Dictionary = _zone_defs[zone_id]

	# AC-2: rabbit count must meet zone minimum
	if rabbit_ids.size() < int(zone["min_rabbits"]):
		return false

	# AC-7: prestige gate
	var required_prestige: int = int(zone.get("requires_prestige", 0))
	if required_prestige > 0 and _gs().prestige_count < required_prestige:
		return false

	# Determine required trait (null in JSON becomes null in GDScript via JSON.parse_string)
	var required_trait_raw: Variant = zone.get("required_trait", null)
	var required_trait: String = ""
	if required_trait_raw != null:
		required_trait = str(required_trait_raw)
		if required_trait == "null":
			required_trait = ""

	# AC-3 / AC-4 / AC-5 / AC-6: per-rabbit checks
	var rs: Node = _rabbit_sys()
	for rabbit_id: String in rabbit_ids:
		var rabbit: RabbitData = rs.get_rabbit(rabbit_id)

		# AC-3: rabbit must exist
		if rabbit == null:
			return false

		# AC-4: rabbit must be Adult stage
		if rabbit.stage != RabbitData.RabbitStage.ADULT:
			return false

		# AC-5: rabbit must not already be on an expedition
		if rabbit.is_on_expedition:
			return false

		# AC-6: trait requirement check via Genome GeneSlot expressed alleles
		if required_trait != "":
			var has_trait: bool = false
			if rabbit.genome != null:
				if rabbit.genome.trait_a.expressed() == required_trait:
					has_trait = true
				elif rabbit.genome.trait_b.expressed() == required_trait:
					has_trait = true
			if not has_trait:
				return false

	return true
