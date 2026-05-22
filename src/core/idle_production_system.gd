## IdleProductionSystem — pure calculation node for idle Carrot Coin production (ADR-0007).
## Returns EarningsReport — caller passes result to EconomyManager.add(). Never mutates state.
## All rates loaded from balance.json idle_production section (ADR-0004).
extends Node

## Loaded from balance.json; fallback defaults used when file is absent or key missing.
var _base_rate: float = 0.05
var _multiplier_background: float = 0.75
var _multiplier_under_4h: float = 0.60
var _multiplier_4_to_12h: float = 0.50
var _multiplier_over_12h: float = 0.40
var _max_offline_hours: float = 72.0

## prestige_level (string key) → offline_production_bonus (float). Loaded from balance.json.
var _prestige_offline_bonuses: Dictionary = {}

## Maps prestige level (int key) → growth_rate_bonus (float). Loaded from balance.json
## prestige.bonuses_per_level. Only levels with a growth_rate_bonus key are stored.
var _prestige_growth_bonuses: Dictionary = {}  # int → float

## Injected rabbit list for unit testing — when non-empty, bypasses RabbitSystem autoload.
var _rabbit_override: Array[RabbitData] = []


func _ready() -> void:
	_load_balance_data()


## Returns earnings for one real-time tick (1 second, full online rate).
func get_tick_earnings() -> EarningsReport:
	return _calculate(1.0, 1.0)


## Returns catch-up earnings after offline absence. Caller passes offline_seconds from
## TimeManager.get_offline_delta(); was_backgrounded from TimeManager.was_backgrounded().
## Uses offline_mult from SeasonSystem (e.g. Winter +1.3×) rather than production_mult.
func calculate_offline_earnings(offline_seconds: float, was_backgrounded: bool) -> EarningsReport:
	var capped: float = min(offline_seconds, _max_offline_hours * 3600.0)
	var multiplier: float = _multiplier_background if was_backgrounded else _get_offline_multiplier(capped)
	return _calculate(capped, multiplier, true)


## Pure function — no side effects, no EconomyManager calls.
## use_offline_season: when true, reads offline_mult from SeasonSystem (for offline catch-up);
## when false, reads production_mult (for online tick earnings).
func _calculate(delta_seconds: float, offline_multiplier: float, use_offline_season: bool = false) -> EarningsReport:
	var productive_count: int = _count_productive_rabbits()
	var hutch_bonus: float = _get_hutch_bonus()
	var season_mult: float = _get_offline_season_multiplier() if use_offline_season else _get_season_multiplier()
	var prestige_bonus: float = _get_prestige_bonus()
	var prestige_growth: float = _get_prestige_growth_bonus()

	var raw: float = (productive_count
			* _base_rate
			* hutch_bonus
			* season_mult
			* prestige_bonus
			* prestige_growth
			* offline_multiplier
			* delta_seconds)

	var report := EarningsReport.new()
	report.carrot_coin = int(floor(raw))
	report.carrot_coin_raw = raw
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
			"prestige_growth": prestige_growth,
		}
	]
	return report


## Counts ADULT + ELDER rabbits. Uses _rabbit_override when injected (for unit tests).
func _count_productive_rabbits() -> int:
	var source: Array[RabbitData]
	if _rabbit_override.size() > 0:
		source = _rabbit_override
	else:
		var rs: Node = Engine.get_singleton("RabbitSystem") if Engine.has_singleton("RabbitSystem") \
				else get_node_or_null("/root/RabbitSystem")
		if rs == null:
			return 0
		source = rs.get_all_rabbits()

	var count: int = 0
	for rabbit: RabbitData in source:
		if rabbit.stage == RabbitData.RabbitStage.ADULT or rabbit.stage == RabbitData.RabbitStage.ELDER:
			count += 1
	return count


## Stub — returns 1.0 until HabitatSystem epic wires real hutch bonuses.
func _get_hutch_bonus() -> float:
	return 1.0


## Returns the online production_mult from SeasonSystem (e.g. 1.5 in Autumn, 1.0 otherwise).
## Reads season.multipliers.[season].production_mult via SeasonSystem.get_active_multipliers().
func _get_season_multiplier() -> float:
	var ss: Node = Engine.get_singleton("SeasonSystem") if Engine.has_singleton("SeasonSystem") \
			else get_node_or_null("/root/SeasonSystem")
	if ss == null:
		return 1.0
	var mults: Dictionary = ss.get_active_multipliers() as Dictionary
	return mults.get("production_mult", 1.0) as float


## Returns the offline_mult from SeasonSystem (e.g. 1.3 in Winter, 1.0 otherwise).
## Reads season.multipliers.[season].offline_mult via SeasonSystem.get_active_multipliers().
## Called only from _calculate() when use_offline_season = true (offline catch-up path).
func _get_offline_season_multiplier() -> float:
	var ss: Node = Engine.get_singleton("SeasonSystem") if Engine.has_singleton("SeasonSystem") \
			else get_node_or_null("/root/SeasonSystem")
	if ss == null:
		return 1.0
	var mults: Dictionary = ss.get_active_multipliers() as Dictionary
	return mults.get("offline_mult", 1.0) as float


## Returns 1.0 + offline_production_bonus for the player's prestige level (from GameState).
## Level 0 or no bonus entry → returns 1.0.
func _get_prestige_bonus() -> float:
	var gs: Node = Engine.get_singleton("GameState") if Engine.has_singleton("GameState") \
			else get_node_or_null("/root/GameState")
	if gs == null:
		return 1.0
	var prestige_count: int = gs.prestige_count
	if prestige_count <= 0:
		return 1.0
	var bonus: float = _prestige_offline_bonuses.get(str(prestige_count), 0.0) as float
	return 1.0 + bonus


## Returns 1.0 + growth_rate_bonus for the player's prestige level (from GameState).
## Uses the highest defined level <= prestige_count from balance.json prestige.bonuses_per_level.
## Level 0, empty bonus table, or no matching level → returns 1.0.
##
## Example:
##   prestige_count = 3, bonuses {1: 0.05, 2: 0.10, 3: 0.15} → returns 1.15
##   prestige_count = 7, bonuses {1..5 defined} → returns 1.25 (highest ≤ 7 is level 5)
func _get_prestige_growth_bonus() -> float:
	var gs: Node = Engine.get_singleton("GameState") if Engine.has_singleton("GameState") \
			else get_node_or_null("/root/GameState")
	var prestige_count: int = 0
	if gs != null:
		prestige_count = gs.prestige_count
	if prestige_count <= 0 or _prestige_growth_bonuses.is_empty():
		return 1.0
	var best_level: int = 0
	for level: int in _prestige_growth_bonuses:
		if level <= prestige_count and level > best_level:
			best_level = level
	if best_level == 0:
		return 1.0
	return 1.0 + (_prestige_growth_bonuses[best_level] as float)


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
		var growth_bonus: float = level_bonuses.get("growth_rate_bonus", 0.0) as float
		if growth_bonus > 0.0:
			_prestige_growth_bonuses[int(level_str)] = growth_bonus
