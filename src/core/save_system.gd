## SaveSystem — autoload #5. Owns local file I/O and Firebase sync for all game state.
## Depends on FirebaseAdapter (injected by SceneManager post-boot — never call SceneManager in _ready()).
## ADR-0008: user://savegame.json is authoritative; Firebase is async sync target.
class_name SaveSystem extends Node

const SAVE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1
const SAVE_INTERVAL_SECONDS: float = 30.0

## Injected post-boot by SceneManager. Null in unit tests — all Firebase paths guard on this.
var _firebase: FirebaseAdapter = null

## Overridable for test isolation — tests set this to a temp path before calling _load_local/_write_local.
var _save_path: String = SAVE_PATH

## Injectable for test isolation; production fallback uses Engine.get_singleton("GameState").
var _game_state: GameState = null

## Injectable for test isolation; production fallback uses Engine.get_singleton("TimeManager").
var _time_manager: TimeManager = null


## Called at boot (autoload #5). Loads game state then arms the auto-save timer.
## load_game() is started as a non-blocking coroutine — _ready() returns immediately.
func _ready() -> void:
	load_game()
	_start_auto_save_timer()


## Saves on mobile backgrounding and on desktop window focus loss.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		save_game()


## Reads local save, optionally fetches cloud save, resolves conflict, populates GameState.
## Uses await for the Firebase fetch path; callers that need the result must await this function.
func load_game() -> void:
	var local_data: Dictionary = _load_local()
	var cloud_data: Dictionary = {}
	if _firebase != null and _firebase.is_signed_in():
		cloud_data = await _firebase.fetch_save()
	var save_data: Dictionary = _resolve_conflict(local_data, cloud_data)
	_populate_game_state(save_data)


## Serialises GameState, stamps the current timestamp, writes locally, and pushes to Firebase.
## GameState.is_dirty = false is the ONE permitted direct assignment (ADR-0008).
func save_game() -> void:
	var data: Dictionary = _serialise_game_state()
	data["last_save_timestamp"] = int(Time.get_unix_time_from_system())
	_write_local(data)
	_gs().is_dirty = false
	if _firebase != null and _firebase.is_signed_in():
		_firebase.push_save_async(data)


## Inject the Firebase adapter. Called by SceneManager after boot sequence completes.
func inject_firebase(adapter: FirebaseAdapter) -> void:
	_firebase = adapter


func _start_auto_save_timer() -> void:
	var timer := Timer.new()
	timer.wait_time = SAVE_INTERVAL_SECONDS
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)


## Reads user://savegame.json and returns the parsed Dictionary.
## Returns {} on first boot (file absent) or on corrupted file (also calls push_error).
func _load_local() -> Dictionary:
	if not FileAccess.file_exists(_save_path):
		return {}
	var file := FileAccess.open(_save_path, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: cannot open save file at %s" % _save_path)
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_error("SaveSystem: save file corrupted — starting fresh")
		return {}
	return parsed as Dictionary


## Serialises data to JSON and writes to the save path.
## Adds _version and _comment fields to the written JSON without mutating the caller's dict.
func _write_local(data: Dictionary) -> void:
	var to_write: Dictionary = data.duplicate()
	to_write["_version"] = SAVE_VERSION
	to_write["_comment"] = "Bunny Farm Idle save file. Do not edit manually."
	var text: String = JSON.stringify(to_write, "\t")
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: cannot write save file at %s" % _save_path)
		return
	file.store_string(text)
	file.close()


## Returns the injected GameState or falls back to the autoload singleton.
func _gs() -> GameState:
	return _game_state if _game_state != null else (Engine.get_singleton("GameState") as GameState)


## Returns the injected TimeManager or falls back to the autoload singleton.
func _tm() -> TimeManager:
	return _time_manager if _time_manager != null else (Engine.get_singleton("TimeManager") as TimeManager)


## Serialises full GameState to the save schema defined in ADR-0008.
func _serialise_game_state() -> Dictionary:
	var gs := _gs()
	var rabbits_array: Array = []
	for r: RabbitData in gs.rabbits:
		rabbits_array.append(_rabbit_to_dict(r))
	return {
		"last_save_timestamp": gs.last_save_timestamp,
		"prestige_count": gs.prestige_count,
		"rabbits": rabbits_array,
		"hutches": [],
		"collection_registry": gs.collection_registry.duplicate(),
		"active_expeditions": gs.active_expeditions.duplicate(),
		"economy": _serialise_economy(),
		"settings": gs.settings.duplicate(),
	}


## Writes all schema fields from save data to GameState using safe .get() defaults.
## Calls GameState.mark_dirty() after population so SaveSystem queues a write next interval.
## Calls TimeManager.mark_session_start() and set_game_epoch() for session timing.
func _populate_game_state(data: Dictionary) -> void:
	var gs := _gs()
	gs.prestige_count = data.get("prestige_count", 0)
	gs.collection_registry = data.get("collection_registry", {})
	gs.active_expeditions = data.get("active_expeditions", [])
	gs.settings = data.get("settings", gs.settings)
	gs.last_save_timestamp = data.get("last_save_timestamp", 0)
	var raw_rabbits: Array = data.get("rabbits", [])
	var typed_rabbits: Array[RabbitData] = []
	for d: Variant in raw_rabbits:
		typed_rabbits.append(_dict_to_rabbit(d as Dictionary))
	gs.rabbits = typed_rabbits
	_populate_economy(data.get("economy", {}))
	gs.mark_dirty()
	var tm := _tm()
	tm.mark_session_start(gs.last_save_timestamp)
	tm.set_game_epoch(data.get("game_epoch", int(Time.get_unix_time_from_system())))


## Serialises a RabbitData to a Dictionary using the 16-field schema from ADR-0005.
func _rabbit_to_dict(rabbit: RabbitData) -> Dictionary:
	return {
		"rabbit_id": rabbit.rabbit_id,
		"display_name": rabbit.display_name,
		"stage": rabbit.stage,
		"genome": _genome_to_dict(rabbit.genome),
		"hunger": rabbit.hunger,
		"happiness": rabbit.happiness,
		"health": rabbit.health,
		"cleanliness": rabbit.cleanliness,
		"growth_progress": rabbit.growth_progress,
		"fertility": rabbit.fertility,
		"mutation_chance": rabbit.mutation_chance,
		"aura_type": rabbit.aura_type,
		"birth_timestamp": rabbit.birth_timestamp,
		"parent_a_id": rabbit.parent_a_id,
		"parent_b_id": rabbit.parent_b_id,
		"hutch_id": rabbit.hutch_id,
	}


## Reconstructs a RabbitData from a save dictionary.
## Genome reconstruction is deferred until ADR-0006 (Genetics) is implemented.
func _dict_to_rabbit(d: Dictionary) -> RabbitData:
	var r := RabbitData.new()
	r.rabbit_id = d.get("rabbit_id", "")
	r.display_name = d.get("display_name", "")
	r.stage = (d.get("stage", RabbitData.RabbitStage.BABY)) as RabbitData.RabbitStage
	r.hunger = d.get("hunger", 100.0)
	r.happiness = d.get("happiness", 100.0)
	r.health = d.get("health", 100.0)
	r.cleanliness = d.get("cleanliness", 100.0)
	r.growth_progress = d.get("growth_progress", 0.0)
	r.fertility = d.get("fertility", 1.0)
	r.mutation_chance = d.get("mutation_chance", 0.05)
	r.aura_type = d.get("aura_type", "")
	r.birth_timestamp = d.get("birth_timestamp", 0)
	r.parent_a_id = d.get("parent_a_id", "")
	r.parent_b_id = d.get("parent_b_id", "")
	r.hutch_id = d.get("hutch_id", "")
	return r


## Serialises a Genome resource to a Dictionary (ADR-0006 6-slot schema).
func _genome_to_dict(genome: Genome) -> Dictionary:
	if genome == null:
		return {}
	return {
		"color": _gene_slot_to_dict(genome.color),
		"size": _gene_slot_to_dict(genome.size),
		"ears": _gene_slot_to_dict(genome.ears),
		"trait_a": _gene_slot_to_dict(genome.trait_a),
		"trait_b": _gene_slot_to_dict(genome.trait_b),
		"special": _gene_slot_to_dict(genome.special),
	}


func _gene_slot_to_dict(slot: GeneSlot) -> Dictionary:
	if slot == null:
		return {"allele_a": "none", "allele_b": "none"}
	return {"allele_a": slot.allele_a, "allele_b": slot.allele_b}


## Economy serialisation stub — deferred until EconomyManager epic is implemented.
func _serialise_economy() -> Dictionary:
	return {}


## Economy population stub — deferred until EconomyManager epic is implemented.
func _populate_economy(_data: Dictionary) -> void:
	pass


## HutchData serialisation stub — deferred until HabitatSystem epic defines HutchData.
func _hutch_to_dict(_hutch: Variant) -> Dictionary:
	return {}


## HutchData reconstruction stub — deferred until HabitatSystem epic defines HutchData.
func _dict_to_hutch(_d: Dictionary) -> Variant:
	return null


## Chooses between local and cloud save data based on last_save_timestamp (ADR-0008).
## Pure function — no side effects, no I/O, no autoload calls.
## Empty local → cloud wins. Empty cloud → local wins. Both empty → {}. Tie → local wins.
func _resolve_conflict(local: Dictionary, cloud: Dictionary) -> Dictionary:
	if local.is_empty():
		return cloud
	if cloud.is_empty():
		return local
	var local_ts: int = local.get("last_save_timestamp", 0)
	var cloud_ts: int = cloud.get("last_save_timestamp", 0)
	return cloud if cloud_ts > local_ts else local
