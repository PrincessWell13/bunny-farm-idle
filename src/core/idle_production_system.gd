## IdleProductionSystem — pure calculation node for idle Carrot Coin production (ADR-0007).
## Returns EarningsReport — caller passes result to EconomyManager.add(). Never mutates state.
## All rates loaded from balance.json idle_production section (ADR-0004).
class_name IdleProductionSystem extends Node

## Loaded from balance.json; fallback defaults used when file is absent or key missing.
var _base_rate: float = 0.05
var _multiplier_background: float = 0.75
var _multiplier_under_4h: float = 0.60
var _multiplier_4_to_12h: float = 0.50
var _multiplier_over_12h: float = 0.40
var _max_offline_hours: float = 72.0

## prestige_level (string key) → offline_production_bonus (float). Loaded from balance.json.
var _prestige_offline_bonuses: Dictionary = {}

## Injected rabbit list for unit testing — when non-empty, bypasses RabbitSystem autoload.
var _rabbit_override: Array[RabbitData] = []


func _ready() -> void:
	_load_balance_data()


## Returns earnings for one real-time tick (1 second, full online rate).
func get_tick_earnings() -> EarningsReport:
	return _calculate(1.0, 1.0)


## Returns catch-up earnings after offline absence. Caller passes offline_seconds from
## TimeManager.get_offline_delta(); was_backgrounded from TimeManager.was_backgrounded().
func calculate_offline_earnings(offline_seconds: float, was_backgrounded: bool) -> EarningsReport:
	var capped: float = min(offline_seconds, _max_offline_hours * 3600.0)
	var multiplier: float = _multiplier_background if was_backgrounded else _get_offline_multiplier(capped)
	return _calculate(capped, multiplier)


## Pure function — no side effects, no EconomyManager calls.
func _calculate(delta_seconds: float, offline_multiplier: float) -> EarningsReport:
	var productive_count: int = _count_productive_rabbits()
	var hutch_bonus: float = _get_hutch_bonus()
	var season_mult: float = _get_season_multiplier()
	var prestige_bonus: float = _get_prestige_bonus()

	var raw: float = (productive_count
			* _base_rate
			* hutch_bonus
			* season_mult
			* prestige_bonus
			* offline_multiplier
			* delta_seconds)

	var report := EarningsReport.new()
	report.carrot_coin = int(floor(raw))
	report.star_dust = 0
	report.applied_multiplier = offline_multiplier
	report.delta_seconds = delta_seconds
	report.source_breakdown = [
		{
			"rabbits": productive_count,
			"base_rate": _base_rate,
			"hutch_bonus": hutch_bonus,
			"season_mult": season_mult,
			"prestige_bonus": prestige_bonus,
		}
	]
	return report


## Counts ADULT + ELDER rabbits. Uses _rabbit_override when injected (for unit tests).
func _count_productive_rabbits() -> int:
	var source: Array[RabbitData]
	if _rabbit_override.size() > 0:
		source = _rabbit_override
	elif Engine.has_singleton("RabbitSystem"):
		source = (Engine.get_singleton("RabbitSystem") as Node).get_all_rabbits()
	else:
		return 0

	var count: int = 0
	for rabbit: RabbitData in source:
		if rabbit.stage == RabbitData.RabbitStage.ADULT or rabbit.stage == RabbitData.RabbitStage.ELDER:
			count += 1
	return count


## Stub — returns 1.0 until HabitatSystem epic wires real hutch bonuses.
func _get_hutch_bonus() -> float:
	return 1.0


## Returns 1.0 + harvest_bonus from SeasonSystem autoload when present; 1.0 when absent.
func _get_season_multiplier() -> float:
	if not Engine.has_singleton("SeasonSystem"):
		return 1.0
	var harvest_bonus: float = (Engine.get_singleton("SeasonSystem") as Node).get_harvest_bonus()
	return 1.0 + harvest_bonus


## Returns 1.0 + offline_production_bonus for the player's prestige level (from GameState).
## Level 0 or no bonus entry → returns 1.0.
func _get_prestige_bonus() -> float:
	if not Engine.has_singleton("GameState"):
		return 1.0
	var prestige_count: int = (Engine.get_singleton("GameState") as Node).prestige_count
	if prestige_count <= 0:
		return 1.0
	var bonus: float = _prestige_offline_bonuses.get(str(prestige_count), 0.0) as float
	return 1.0 + bonus


## Returns the offline multiplier tier for the given elapsed seconds.
## Background multiplier (0.75) handled at call site via was_backgrounded flag.
func _get_offline_multiplier(offline_seconds: float) -> float:
	if offline_seconds <= 0.0:
		return 1.0
	var hours: float = offline_seconds / 3600.0
	if hours < 4.0:
		return _multiplier_under_4h
	elif hours < 12.0:
		return _multiplier_4_to_12h
	else:
		return _multiplier_over_12h


func _load_balance_data() -> void:
	const PATH: String = "res://assets/data/balance.json"
	if not FileAccess.file_exists(PATH):
		return
	var text: String = FileAccess.get_file_as_string(PATH)
	var data = JSON.parse_string(text)
	if not data is Dictionary:
		return
	var section: Dictionary = data.get("idle_production", {}) as Dictionary
	if section.has("base_cc_per_rabbit_per_second"):
		_base_rate = section["base_cc_per_rabbit_per_second"] as float
	if section.has("offline_multiplier_background"):
		_multiplier_background = section["offline_multiplier_background"] as float
	if section.has("offline_multiplier_under_4h"):
		_multiplier_under_4h = section["offline_multiplier_under_4h"] as float
	if section.has("offline_multiplier_4_to_12h"):
		_multiplier_4_to_12h = section["offline_multiplier_4_to_12h"] as float
	if section.has("offline_multiplier_over_12h"):
		_multiplier_over_12h = section["offline_multiplier_over_12h"] as float
	if section.has("max_offline_hours"):
		_max_offline_hours = section["max_offline_hours"] as float

	var prestige_section: Dictionary = data.get("prestige", {}) as Dictionary
	var bonuses_per_level: Dictionary = prestige_section.get("bonuses_per_level", {}) as Dictionary
	for level_str: String in bonuses_per_level:
		var level_bonuses: Dictionary = bonuses_per_level[level_str] as Dictionary
		var prod_bonus: float = level_bonuses.get("offline_production_bonus", 0.0) as float
		if prod_bonus > 0.0:
			_prestige_offline_bonuses[level_str] = prod_bonus
