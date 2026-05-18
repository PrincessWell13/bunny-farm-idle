## GameState — authoritative owner of all persistent player data.
## Autoload #4. Data tree is allocated empty here; SaveSystem.load_game() populates it.
## Every mutation must call mark_dirty() when done.
## See ADR-0001 for ownership rules and boot sequence.
extends Node

var rabbits: Array[RabbitData] = []
## forward-ref: update to Array[HutchData] when habitat-system epic is created
var hutches: Array = []
var prestige_count: int = 0
## species_id (String) → discovered (bool)
var collection_registry: Dictionary = {}
var active_expeditions: Array = []
var settings: Dictionary = {}
var last_save_timestamp: int = 0
var is_dirty: bool = false
## forward-ref: update to EarningsReport when idle-production-system story-001 is done (ADR-0007)
var pending_offline_report: Variant = null

func _ready() -> void:
	settings = {
		"font_scale": 1.0,
		"colorblind_mode": 0,
		"simplified_mode": false,
		"dark_mode": false,
	}

## Sets the dirty flag. SaveSystem polls this every 30 s and on background/quit.
## This is the ONLY valid way to mark state as needing a save — never assign is_dirty directly.
func mark_dirty() -> void:
	is_dirty = true

## Selective prestige wipe. Caller (PrestigeSystem) filters data and passes what to preserve.
## keep keys: "rabbits" (Array), "hutches" (Array), "collection_registry" (Dictionary)
## Fields absent from keep are wiped. prestige_count always increments.
## settings and last_save_timestamp are never reset by prestige.
func prestige_reset(keep: Dictionary) -> void:
	rabbits = keep.get("rabbits", [])
	hutches = keep.get("hutches", [])
	active_expeditions = []
	collection_registry = keep.get("collection_registry", {})
	prestige_count += 1
	mark_dirty()
