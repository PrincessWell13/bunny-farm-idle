## RabbitSystem — owns the rabbit population and enforces the immutability contract.
## Only methods in this file may write to RabbitData fields (ADR-0005).
## Backing store is GameState.rabbits (ADR-0001); internal dict provides O(1) lookup.
extends Node

## Lightweight food descriptor. Construct with FoodItem.new("grass") etc.
class FoodItem:
	var food_type: String = ""
	func _init(type: String) -> void:
		food_type = type

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
	GameState.mark_dirty()

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
		EventBus.rabbit_matured.emit(rabbit.rabbit_id, rabbit.stage)

## Removes the rabbit and emits rabbit_died when health reaches 0.
## remove_rabbit runs before emit so listeners calling get_rabbit receive null (ADR-0005).
func _check_death(rabbit: RabbitData) -> void:
	if rabbit.health <= 0.0:
		var dead_id: String = rabbit.rabbit_id
		remove_rabbit(dead_id)
		EventBus.rabbit_died.emit(dead_id)

## Assigns a unique rabbit_id if data.rabbit_id is empty, stores rabbit in the internal
## roster and in GameState.rabbits, marks state dirty, and returns the assigned id.
func add_rabbit(data: RabbitData) -> String:
	if data.rabbit_id.is_empty():
		data.rabbit_id = _generate_id()
	_rabbits[data.rabbit_id] = data
	GameState.rabbits.append(data)
	GameState.mark_dirty()
	return data.rabbit_id

## Returns the RabbitData for the given id, or null if not found.
func get_rabbit(rabbit_id: String) -> RabbitData:
	return _rabbits.get(rabbit_id, null) as RabbitData

## Returns all rabbits currently in the roster.
func get_all_rabbits() -> Array[RabbitData]:
	var result: Array[RabbitData] = []
	result.assign(_rabbits.values())
	return result

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
	GameState.rabbits.erase(rabbit)
	GameState.mark_dirty()

## Applies the food item's stat effects to the rabbit. Returns false if rabbit not found.
## All effect magnitudes come from balance.json "food" section (ADR-0004).
func feed_rabbit(rabbit_id: String, food: FoodItem) -> bool:
	var rabbit: RabbitData = get_rabbit(rabbit_id)
	if rabbit == null:
		return false
	match food.food_type:
		"grass":
			rabbit.hunger = minf(100.0, rabbit.hunger + _grass_hunger_restore)
		"carrot":
			rabbit.hunger = minf(100.0, rabbit.hunger + _carrot_hunger_restore)
			rabbit.growth_progress = minf(100.0, rabbit.growth_progress + _carrot_growth_bonus)
		"star_carrot":
			rabbit.growth_progress = minf(100.0, rabbit.growth_progress + _star_carrot_growth_bonus)
			rabbit.happiness = minf(100.0, rabbit.happiness + _star_carrot_happiness_bonus)
		_:
			push_warning("RabbitSystem: unknown food type '%s'" % food.food_type)
	GameState.mark_dirty()
	return true

func _generate_id() -> String:
	return "rabbit_%d_%d" % [int(Time.get_unix_time_from_system()), randi()]
