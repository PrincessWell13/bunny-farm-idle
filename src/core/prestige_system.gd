## PrestigeSystem — validates prestige eligibility and triggers the selective reset.
## Delegates all state wipe to GameState.prestige_reset(keep).
## CollectionSystem check is stubbed — replace when CollectionSystem ADR is written.
##
## Public API:
##   can_prestige() -> bool          — true only when all eligibility conditions are met
##   execute_prestige() -> void      — triggers the reset if can_prestige() returns true
extends Node


## Fallback default — overwritten by _load_balance_data() reading balance.json prestige.max_level.
var _max_prestige_level: int = 20


func _ready() -> void:
	_load_balance_data()


## Reads balance.json and sets _max_prestige_level from prestige.max_level.
## Calls push_error() on missing key or parse failure; falls back to 20.
func _load_balance_data() -> void:
	var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
	if text.is_empty():
		push_error("PrestigeSystem: balance.json not found — using max_level default 20")
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("PrestigeSystem: balance.json parse failed — using max_level default 20")
		return
	var data: Dictionary = parsed as Dictionary
	var prestige: Dictionary = data.get("prestige", {}) as Dictionary
	if prestige.has("max_level"):
		_max_prestige_level = int(prestige["max_level"])
	else:
		push_error("PrestigeSystem: balance.json missing prestige.max_level — using 20")


## Returns true only when ALL of the following hold:
##   - GameState.prestige_count < _max_prestige_level (cap not reached)
##   - RabbitSystem.has_legendary_rabbit() returns true
##   - _collection_threshold_met() returns true (stubbed)
func can_prestige() -> bool:
	if GameState.prestige_count >= _max_prestige_level:
		return false
	if not RabbitSystem.has_legendary_rabbit():
		return false
	if not _collection_threshold_met():
		return false
	return true


## Triggers the selective prestige reset if can_prestige() is true.
## Passes a keep dict containing legendary rabbit IDs to GameState.prestige_reset().
## Emits push_warning() and returns without action if can_prestige() is false.
func execute_prestige() -> void:
	if not can_prestige():
		push_warning("PrestigeSystem: execute_prestige() called when can_prestige() == false — no-op")
		return
	var keep: Dictionary = {
		"legendary_rabbit_ids": RabbitSystem.get_legendary_rabbit_ids()
	}
	GameState.prestige_reset(keep)


## Stub always returns true — CollectionSystem not yet implemented.
## TODO: wire to CollectionSystem when CollectionSystem ADR is written.
func _collection_threshold_met() -> bool:
	return true
