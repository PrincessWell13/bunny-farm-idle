## RabbitSystem — owns the rabbit population and enforces the immutability contract.
## Only methods in this file may write to RabbitData fields (ADR-0005).
## Backing store is GameState.rabbits (ADR-0001); internal dict provides O(1) lookup.
extends Node

var _rabbits: Dictionary = {}  # rabbit_id -> RabbitData

## Food effect magnitudes loaded from balance.json "food" section. GDScript-side fallbacks only.
var _grass_hunger_restore: float = 30.0
var _carrot_hunger_restore: float = 40.0
var _carrot_growth_bonus: float = 10.0
var _star_carrot_growth_bonus: float = 25.0
var _star_carrot_happiness_bonus: float = 10.0

## Stage advance thresholds loaded from balance.json "rabbit" section. GDScript-side fallbacks only.
var _baby_to_juvenile_threshold: float = 100.0
var _juvenile_to_adult_threshold: float = 100.0
var _adult_lifespan_seconds: int = 86400   # 24 hours
var _elder_duration_seconds: int = 43200   # 12 hours

## Decay rates loaded from balance.json "rabbit" section. GDScript-side fallbacks only.
var _hunger_decay_rate: float = 0.5
var _health_decay_when_starving: float = 1.0
var _cleanliness_decay_rate: float = 0.1
var _happiness_decay_rate: float = 0.2
var _tick_accumulator: float = 0.0

func _ready() -> void:
	_load_balance_data()

func _process(delta: float) -> void:
	_tick_accumulator += delta
	if _tick_accumulator >= 1.0:
		_tick_accumulator -= 1.0
		var snapshot: Array[RabbitData] = get_all_rabbits()
		for rabbit: RabbitData in snapshot:
			_tick_rabbit(rabbit, 1.0)


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


## Loads decay rates from balance.json "rabbit" section. Falls back to defaults on failure.
func _load_balance_data() -> void:
	var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
	if text.is_empty():
		push_error("RabbitSystem: balance.json not found — using defaults")
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("RabbitSystem: balance.json parse failed — using defaults")
		return
	var data: Dictionary = parsed as Dictionary
	var rabbit_section: Dictionary = data.get("rabbit", {}) as Dictionary
	_hunger_decay_rate = rabbit_section.get("hunger_decay_per_second", _hunger_decay_rate)
	_health_decay_when_starving = rabbit_section.get("health_decay_per_second_when_starving", _health_decay_when_starving)
	_cleanliness_decay_rate = rabbit_section.get("cleanliness_decay_per_second", _cleanliness_decay_rate)
	_happiness_decay_rate = rabbit_section.get("happiness_decay_per_second", _happiness_decay_rate)
	_baby_to_juvenile_threshold = rabbit_section.get("growth_baby_to_juvenile_seconds", _baby_to_juvenile_threshold)
	_juvenile_to_adult_threshold = rabbit_section.get("growth_juvenile_to_adult_seconds", _juvenile_to_adult_threshold)
	_adult_lifespan_seconds = int(rabbit_section.get("adult_lifespan_seconds", _adult_lifespan_seconds))
	_elder_duration_seconds = int(rabbit_section.get("elder_duration_seconds", _elder_duration_seconds))
	var food_section: Dictionary = data.get("food", {}) as Dictionary
	_grass_hunger_restore = food_section.get("grass_hunger_restore", _grass_hunger_restore)
	_carrot_hunger_restore = food_section.get("carrot_hunger_restore", _carrot_hunger_restore)
	_carrot_growth_bonus = food_section.get("carrot_growth_bonus", _carrot_growth_bonus)
	_star_carrot_growth_bonus = food_section.get("star_carrot_growth_bonus", _star_carrot_growth_bonus)
	_star_carrot_happiness_bonus = food_section.get("star_carrot_happiness_bonus", _star_carrot_happiness_bonus)

## Applies one tick of stat decay to a single rabbit. delta is seconds elapsed.
## Only RabbitSystem calls this — ADR-0005 immutability contract.
func _tick_rabbit(rabbit: RabbitData, delta: float) -> void:
	rabbit.hunger = maxf(0.0, rabbit.hunger - _hunger_decay_rate * delta)
	rabbit.cleanliness = maxf(0.0, rabbit.cleanliness - _cleanliness_decay_rate * delta)
	rabbit.happiness = maxf(0.0, rabbit.happiness - _happiness_decay_rate * delta)
	if rabbit.hunger <= 0.0:
		rabbit.health = maxf(0.0, rabbit.health - _health_decay_when_starving * delta)
	_check_stage_advance(rabbit)
	_check_death(rabbit)
	_gs().mark_dirty()

## Advances rabbit's stage when growth_progress or time thresholds are crossed.
## Emits EventBus.rabbit_matured on every advance. Stages never regress (ADR-0005).
func _check_stage_advance(rabbit: RabbitData) -> void:
	var advanced := false
	match rabbit.stage:
		RabbitData.RabbitStage.BABY:
			if rabbit.growth_progress >= _baby_to_juvenile_threshold:
				rabbit.stage = RabbitData.RabbitStage.JUVENILE
				rabbit.growth_progress = 0.0
				advanced = true
		RabbitData.RabbitStage.JUVENILE:
			if rabbit.growth_progress >= _juvenile_to_adult_threshold:
				rabbit.stage = RabbitData.RabbitStage.ADULT
				rabbit.growth_progress = 0.0
				advanced = true
		RabbitData.RabbitStage.ADULT:
			var now: int = int(Time.get_unix_time_from_system())
			if now >= rabbit.birth_timestamp + _adult_lifespan_seconds:
				rabbit.stage = RabbitData.RabbitStage.ELDER
				advanced = true
		RabbitData.RabbitStage.ELDER:
			var now: int = int(Time.get_unix_time_from_system())
			if now >= rabbit.birth_timestamp + _adult_lifespan_seconds + _elder_duration_seconds:
				rabbit.stage = RabbitData.RabbitStage.SANCTUARY
				advanced = true
		RabbitData.RabbitStage.SANCTUARY:
			pass
	if advanced:
		_event_bus().rabbit_matured.emit(rabbit.rabbit_id, rabbit.stage)

## Removes the rabbit and emits rabbit_died when health reaches 0.
## remove_rabbit runs before emit so listeners calling get_rabbit receive null (ADR-0005).
func _check_death(rabbit: RabbitData) -> void:
	if rabbit.health <= 0.0:
		var dead_id: String = rabbit.rabbit_id
		remove_rabbit(dead_id)
		_event_bus().rabbit_died.emit(dead_id)

## Assigns a unique rabbit_id if data.rabbit_id is empty, stores rabbit in the internal
## roster and in GameState.rabbits, marks state dirty, and returns the assigned id.
func add_rabbit(data: RabbitData) -> String:
	if data.rabbit_id.is_empty():
		data.rabbit_id = _generate_id()
	_rabbits[data.rabbit_id] = data
	var gs: Node = _gs()
	gs.rabbits.append(data)
	gs.mark_dirty()
	return data.rabbit_id

## Returns the RabbitData for the given id, or null if not found.
func get_rabbit(rabbit_id: String) -> RabbitData:
	return _rabbits.get(rabbit_id, null) as RabbitData

## Returns all rabbits currently in the roster.
func get_all_rabbits() -> Array[RabbitData]:
	var result: Array[RabbitData] = []
	result.assign(_rabbits.values())
	return result

## Sets the hutch_id field on a rabbit. Only HabitatSystem should call this (ADR-0010).
## No-op if rabbit_id is not found.
func set_hutch_id(rabbit_id: String, hutch_id: String) -> void:
	var rabbit: RabbitData = get_rabbit(rabbit_id)
	if rabbit == null:
		return
	rabbit.hutch_id = hutch_id
	_gs().mark_dirty()


## Returns only rabbits whose hutch_id matches the given id.
func get_rabbits_in_hutch(hutch_id: String) -> Array[RabbitData]:
	var result: Array[RabbitData] = []
	for rabbit: RabbitData in _rabbits.values():
		if rabbit.hutch_id == hutch_id:
			result.append(rabbit)
	return result

## Removes the rabbit from the roster and from GameState.rabbits.
## No-op if rabbit_id is not found.
func remove_rabbit(rabbit_id: String) -> void:
	if not _rabbits.has(rabbit_id):
		return
	var rabbit: RabbitData = _rabbits[rabbit_id]
	_rabbits.erase(rabbit_id)
	var gs: Node = _gs()
	gs.rabbits.erase(rabbit)
	gs.mark_dirty()

## Applies food stat effects to the rabbit identified by rabbit_id.
## food_type must match a key in balance.json food.items (e.g. "grass", "carrot").
## Returns false if rabbit_id is not found; true on success.
## All effect magnitudes come from balance.json "food" section (ADR-0004).
func feed_rabbit(rabbit_id: String, food_type: String) -> bool:
	var rabbit: RabbitData = get_rabbit(rabbit_id)
	if rabbit == null:
		return false
	match food_type:
		"grass":
			rabbit.hunger = minf(100.0, rabbit.hunger + _grass_hunger_restore)
		"carrot":
			rabbit.hunger = minf(100.0, rabbit.hunger + _carrot_hunger_restore)
			rabbit.growth_progress = minf(100.0, rabbit.growth_progress + _carrot_growth_bonus)
		"star_carrot":
			rabbit.growth_progress = minf(100.0, rabbit.growth_progress + _star_carrot_growth_bonus)
			rabbit.happiness = minf(100.0, rabbit.happiness + _star_carrot_happiness_bonus)
		_:
			push_warning("RabbitSystem: unknown food type '%s'" % food_type)
	_gs().mark_dirty()
	return true

func _generate_id() -> String:
	return "rabbit_%d_%d" % [int(Time.get_unix_time_from_system()), randi()]


## Marks the rabbit as on expedition by setting is_on_expedition = true.
## Called by ExpeditionSystem.start_expedition() after appending the slot (ADR-0011).
## No-op with push_warning if rabbit_id is unknown.
func send_on_expedition(rabbit_id: String, slot_id: String) -> void:
	var rabbit: RabbitData = get_rabbit(rabbit_id)
	if rabbit == null:
		push_warning("RabbitSystem.send_on_expedition: unknown rabbit '%s'" % rabbit_id)
		return
	rabbit.is_on_expedition = true
	_gs().mark_dirty()
	# slot_id is reserved for future UI display in story-002; parameter retained for API stability.


## Clears the is_on_expedition flag when a rabbit returns from an expedition (ADR-0011).
## Called by ExpeditionSystem.collect() after rewards are granted.
## No-op with push_warning if rabbit_id is unknown.
func return_from_expedition(rabbit_id: String) -> void:
	var rabbit: RabbitData = get_rabbit(rabbit_id)
	if rabbit == null:
		push_warning("RabbitSystem.return_from_expedition: unknown rabbit '%s'" % rabbit_id)
		return
	rabbit.is_on_expedition = false
	_gs().mark_dirty()


## Returns true if any rabbit in the roster has rarity LEGENDARY.
## TODO: implement when rarity system is complete.
func has_legendary_rabbit() -> bool:
	return false  # TODO: implement when rarity system is complete


## Returns the IDs of all rabbits in the roster that have rarity LEGENDARY.
## TODO: implement when rarity system is complete.
func get_legendary_rabbit_ids() -> Array[String]:
	return []  # TODO: implement when rarity system is complete
