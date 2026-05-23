## HabitatSystem — exclusive owner of hutch occupancy state.
## Only this file may write to HutchData.occupants (ADR-0010).
## Reads GameState.hutches; uses RabbitSystem write API for rabbit.hutch_id.
## Cleanliness decay fires each TimeManager.tick for all occupied hutches (ADR-0010).
extends Node

## Cleanliness decay rate per second loaded from balance.json "habitat.cleanliness_decay_per_second".
## GDScript-side fallback only — balance.json value always wins at runtime.
var _decay_rate: float = 0.001

## Ordered array of cleanliness tier Dicts: [{min, production_mult, fertility_mult}, ...].
## Loaded from balance.json "habitat.cleanliness_thresholds" at _ready(). Highest min first.
## Fallback is a single neutral entry so get_hutch_bonuses() always returns valid data.
var _cleanliness_thresholds: Array = [{"min": 0.0, "production_mult": 1.0, "fertility_mult": 1.0}]

## Capacity per level: index 0 = level 1, index 1 = level 2, etc.
## Loaded from balance.json "habitat.capacity_by_level". Fallback is [4] (minimum viable).
var _capacity_table: Array = [4]


func _ready() -> void:
	_load_balance_data()
	var tm: Node = _time_mgr()
	if tm != null:
		tm.tick.connect(_on_tick)


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


## Resolves TimeManager via Engine singleton first to allow test-time mock injection.
func _time_mgr() -> Node:
	if Engine.has_singleton("TimeManager"):
		return Engine.get_singleton("TimeManager")
	return get_node_or_null("/root/TimeManager")


## Loads habitat balance values from balance.json. Falls back to defaults on failure.
## Both keys are loaded independently — a missing key logs an error but does not
## prevent the other key from loading.
func _load_balance_data() -> void:
	var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
	if text.is_empty():
		push_error("HabitatSystem: balance.json not found — using defaults")
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("HabitatSystem: balance.json parse failed — using defaults")
		return
	var data: Dictionary = parsed as Dictionary
	var habitat: Dictionary = data.get("habitat", {}) as Dictionary
	if habitat.has("cleanliness_decay_per_second"):
		_decay_rate = float(habitat["cleanliness_decay_per_second"])
	else:
		push_error("HabitatSystem: balance.json missing habitat.cleanliness_decay_per_second — using default")
	if habitat.has("cleanliness_thresholds"):
		_cleanliness_thresholds = habitat["cleanliness_thresholds"] as Array
	else:
		push_error("HabitatSystem: balance.json missing habitat.cleanliness_thresholds — using neutral fallback")
	if habitat.has("capacity_by_level"):
		_capacity_table = habitat["capacity_by_level"] as Array
	else:
		push_error("HabitatSystem: balance.json missing habitat.capacity_by_level — using fallback [4]")


## Ticked by TimeManager.tick each second. Decays cleanliness on all occupied hutches.
## Empty hutches are skipped. GameState.mark_dirty() called once after all updates.
func _on_tick(delta: float) -> void:
	var gs: Node = _gs()
	var eb: Node = _event_bus()
	for hutch: HutchData in gs.hutches:
		if hutch.occupants.is_empty():
			continue
		hutch.cleanliness -= _decay_rate * delta
		hutch.cleanliness = clampf(hutch.cleanliness, 0.0, 1.0)
		eb.hutch_cleanliness_changed.emit(hutch.hutch_id, hutch.cleanliness)
	gs.mark_dirty()


func assign_rabbit(rabbit_id: String, hutch_id: String) -> bool:
	var rs: Node = _rabbit_sys()
	var rabbit: RabbitData = rs.get_rabbit(rabbit_id)
	if rabbit == null:
		return false

	var hutch: HutchData = _find_hutch(hutch_id)
	if hutch == null:
		return false

	if hutch.occupants.size() >= get_capacity(hutch_id):
		return false

	if _is_rabbit_assigned(rabbit_id):
		return false

	hutch.occupants.append(rabbit_id)
	rs.set_hutch_id(rabbit_id, hutch_id)
	_gs().mark_dirty()
	_event_bus().rabbit_assigned_to_hutch.emit(rabbit_id, hutch_id)
	return true


func remove_rabbit(rabbit_id: String) -> bool:
	var gs: Node = _gs()
	var rs: Node = _rabbit_sys()
	var eb: Node = _event_bus()
	for hutch: HutchData in gs.hutches:
		var idx: int = hutch.occupants.find(rabbit_id)
		if idx != -1:
			hutch.occupants.remove_at(idx)
			rs.set_hutch_id(rabbit_id, "")
			gs.mark_dirty()
			eb.rabbit_assigned_to_hutch.emit(rabbit_id, "")
			return true
	return false


## Returns cleanliness-derived production and fertility multipliers for a hutch.
## Iterates _cleanliness_thresholds (highest min first) and returns the first
## tier where hutch.cleanliness >= tier.min. Pure read — no state mutation.
## Returns neutral { production_mult: 1.0, fertility_mult: 1.0 } if hutch not found.
func get_hutch_bonuses(hutch_id: String) -> Dictionary:
	var hutch: HutchData = _find_hutch(hutch_id)
	if hutch == null:
		return {"production_mult": 1.0, "fertility_mult": 1.0}
	for threshold: Dictionary in _cleanliness_thresholds:
		if hutch.cleanliness >= (threshold["min"] as float):
			return {
				"production_mult": threshold["production_mult"] as float,
				"fertility_mult": threshold["fertility_mult"] as float
			}
	return {"production_mult": 1.0, "fertility_mult": 1.0}


## Returns max rabbit slot count for a hutch by level. Lookup is _capacity_table[level - 1].
## Returns 0 with push_warning() if hutch_id not found.
## Returns max capacity with push_warning() if hutch level exceeds table size (no crash).
func get_capacity(hutch_id: String) -> int:
	var hutch: HutchData = _find_hutch(hutch_id)
	if hutch == null:
		push_warning("HabitatSystem.get_capacity: hutch_id '%s' not found" % hutch_id)
		return 0
	var index: int = hutch.level - 1
	if index < 0 or index >= _capacity_table.size():
		push_warning("HabitatSystem.get_capacity: level %d out of range for hutch '%s'" % [hutch.level, hutch_id])
		return _capacity_table[_capacity_table.size() - 1] as int
	return _capacity_table[index] as int


func _find_hutch(hutch_id: String) -> HutchData:
	for hutch: HutchData in _gs().hutches:
		if hutch.hutch_id == hutch_id:
			return hutch
	return null


func _is_rabbit_assigned(rabbit_id: String) -> bool:
	for hutch: HutchData in _gs().hutches:
		if hutch.occupants.has(rabbit_id):
			return true
	return false
