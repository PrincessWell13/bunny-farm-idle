## SeasonSystem — tracks in-game season and day counter.
## Connects to TimeManager.tick. Emits EventBus.season_changed on season boundary.
## All timing from balance.json. Season state is in-memory only (SaveSystem epic adds persistence).
extends Node

const SPRING: int = 0
const SUMMER: int = 1
const AUTUMN: int = 2
const WINTER: int = 3
const SEASON_COUNT: int = 4

## Ordered season names for balance.json lookup — index matches season int constant.
const SEASON_NAMES: Array = ["spring", "summer", "autumn", "winter"]

## Neutral fallback multipliers returned when balance data is missing.
const NEUTRAL_MULTIPLIERS: Dictionary = {
	"production_mult": 1.0,
	"fertility_mult":  1.0,
	"growth_mult":     1.0,
	"offline_mult":    1.0
}

## Real seconds per in-game day. Loaded from balance.json. Fallback: 3600 (1 hour).
var _seconds_per_day: float = 3600.0

## In-game days before season advances. Loaded from balance.json. Fallback: 7.
var _days_per_season: int = 7

## Multiplier dicts per season, indexed by season int (SPRING=0..WINTER=3).
## Populated from balance.json season.multipliers at _ready().
var _multiplier_table: Array = []

var _current_season: int = SPRING
var _day_within_season: int = 0
var _elapsed_seconds: float = 0.0


func _ready() -> void:
	_load_balance_data()
	TimeManager.tick.connect(_on_tick)


func _exit_tree() -> void:
	if TimeManager.tick.is_connected(_on_tick):
		TimeManager.tick.disconnect(_on_tick)


## Loads season timing and multipliers from balance.json.
## Both keys loaded independently — missing one does not block the other.
func _load_balance_data() -> void:
	var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
	if text.is_empty():
		push_error("SeasonSystem: balance.json not found — using defaults")
		_build_neutral_table()
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("SeasonSystem: balance.json parse failed — using defaults")
		_build_neutral_table()
		return
	var data: Dictionary = parsed as Dictionary
	var season: Dictionary = data.get("season", {}) as Dictionary
	if season.has("seconds_per_day"):
		_seconds_per_day = float(season["seconds_per_day"])
	else:
		push_error("SeasonSystem: balance.json missing season.seconds_per_day — using 3600")
	if season.has("days_per_season"):
		_days_per_season = int(season["days_per_season"])
	else:
		push_error("SeasonSystem: balance.json missing season.days_per_season — using 7")
	if season.has("multipliers"):
		var mults: Dictionary = season["multipliers"] as Dictionary
		_multiplier_table.clear()
		for season_name: String in SEASON_NAMES:
			if mults.has(season_name):
				_multiplier_table.append(mults[season_name] as Dictionary)
			else:
				push_error("SeasonSystem: balance.json missing season.multipliers.%s — using neutral" % season_name)
				_multiplier_table.append(NEUTRAL_MULTIPLIERS.duplicate())
	else:
		push_error("SeasonSystem: balance.json missing season.multipliers — all seasons neutral")
		_build_neutral_table()


func _build_neutral_table() -> void:
	_multiplier_table.clear()
	for _i: int in range(SEASON_COUNT):
		_multiplier_table.append(NEUTRAL_MULTIPLIERS.duplicate())


## Returns the current season as an int constant (SPRING=0, SUMMER=1, AUTUMN=2, WINTER=3).
## Pure read — no state mutation.
func get_current_season() -> int:
	return _current_season


## Returns the production, fertility, growth, and offline multipliers for the active season.
## Pure read — no state mutation.
func get_active_multipliers() -> Dictionary:
	if _multiplier_table.is_empty() or _current_season >= _multiplier_table.size():
		return NEUTRAL_MULTIPLIERS.duplicate()
	return _multiplier_table[_current_season]


func _on_tick(delta: float) -> void:
	_elapsed_seconds += delta
	while _elapsed_seconds >= _seconds_per_day:
		_elapsed_seconds -= _seconds_per_day
		_advance_day()


func _advance_day() -> void:
	_day_within_season += 1
	if _day_within_season >= _days_per_season:
		_day_within_season = 0
		_current_season = (_current_season + 1) % SEASON_COUNT
		EventBus.season_changed.emit(_current_season)
