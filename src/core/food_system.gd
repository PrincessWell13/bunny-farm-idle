## FoodSystem — owns all mutations to food_inventory and farm_plots (ADR-0009).
## Sole mutator of GameState.food_inventory and GameState.farm_plots.
## Loaded from balance.json at _ready(). Plot ticking via TimeManager.tick.
## Offline catch-up via _resolve_offline_plots() deferred from _ready() (story-004).
##
## Public API:
##   get_inventory() -> Dictionary              — snapshot copy of food_inventory
##   get_farm_plot_state() -> Array             — snapshot copy of farm_plots
##   feed_rabbit(rabbit_id, food_id) -> bool    — deduct food, apply stat effect
##   seed_plot(food_id) -> bool                 — spend coins, start plot growth
##   harvest_plot(plot_index) -> bool           — collect a completed plot (story-005)
extends Node

const KEY_FOOD_ID    := &"food_id"
const KEY_STARTED_AT := &"started_at"
const KEY_DURATION   := &"duration"
const KEY_MAX_STACK  := &"max_stack"

## Default max stack used when a food item's balance.json entry lacks max_stack.
var _default_max_stack: int = 99

## Food definition cache: food_id (String) → definition Dict from balance.json.
var _food_defs: Dictionary = {}


func _ready() -> void:
	_load_balance_data()
	TimeManager.tick.connect(_on_tick)
	call_deferred(&"_resolve_offline_plots")


func _exit_tree() -> void:
	if TimeManager.tick.is_connected(_on_tick):
		TimeManager.tick.disconnect(_on_tick)


## Reads the food section of balance.json and populates _food_defs and _default_max_stack.
## Emits push_error on missing or malformed data; falls back to empty defs and default 99.
func _load_balance_data() -> void:
	var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
	if text.is_empty():
		push_error("FoodSystem: balance.json not found — using defaults")
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("FoodSystem: balance.json parse failed — using defaults")
		return
	var data: Dictionary = parsed as Dictionary
	var food: Dictionary = data.get("food", {}) as Dictionary
	if food.has("items"):
		_food_defs = food["items"] as Dictionary
	else:
		push_error("FoodSystem: balance.json missing food.items — _food_defs empty")
	if food.has("max_stack"):
		_default_max_stack = int(food["max_stack"])


## Returns a snapshot copy of the current food inventory.
## Callers must not mutate the returned Dictionary — it is a duplicate, not a reference.
func get_inventory() -> Dictionary:
	return GameState.food_inventory.duplicate()


## Returns a snapshot copy of the current farm plot array (read-only).
func get_farm_plot_state() -> Array:
	return GameState.farm_plots.duplicate()


## Deducts one unit of food_id from inventory and delegates stat effects to RabbitSystem.
## Guard order: rabbit existence checked before any inventory touch.
## Rolls back the deduction if RabbitSystem rejects the feed.
## FoodSystem emits no signal on this path — RabbitSystem owns rabbit_fed.
## Returns true on success, false if rabbit unknown, food absent/zero, or RabbitSystem rejects.
func feed_rabbit(rabbit_id: String, food_id: String) -> bool:
	if RabbitSystem.get_rabbit(rabbit_id) == null:
		return false
	var stock: int = GameState.food_inventory.get(food_id, 0)
	if stock <= 0:
		return false
	GameState.food_inventory[food_id] = stock - 1
	GameState.mark_dirty()
	var accepted: bool = RabbitSystem.feed_rabbit(rabbit_id, food_id)
	if not accepted:
		GameState.food_inventory[food_id] = stock
		GameState.mark_dirty()
		push_warning("FoodSystem: RabbitSystem rejected feed for rabbit '%s' — rolled back" % rabbit_id)
		return false
	EventBus.food_used.emit(food_id)
	return true


## Harvests the farm plot at plot_index if it has finished growing.
## Returns false if plot_index is out of bounds or the plot is not yet complete.
## On success: removes the plot, grants harvest_quantity food,
## emits food_harvested(food_id, quantity) and farm_plots_updated().
func harvest_plot(plot_index: int) -> bool:
	if plot_index < 0 or plot_index >= GameState.farm_plots.size():
		return false
	var plot: Dictionary = GameState.farm_plots[plot_index]
	var now: float = Time.get_unix_time_from_system()
	if now - float(plot[KEY_STARTED_AT]) < float(plot[KEY_DURATION]):
		return false
	var food_id: String = str(plot[KEY_FOOD_ID])
	var harvest_qty: int = int(_food_defs.get(food_id, {}).get(&"harvest_quantity", 1))
	GameState.farm_plots.remove_at(plot_index)
	_add_to_inventory(food_id, harvest_qty)
	GameState.mark_dirty()
	EventBus.food_harvested.emit(food_id, harvest_qty)
	EventBus.farm_plots_updated.emit()
	return true


## Spends Coins via EconomyManager and starts a new farm plot for food_id.
## Returns false if food_id unknown or coin cost cannot be paid; true on success.
func seed_plot(food_id: String) -> bool:
	if not _food_defs.has(food_id):
		push_warning("FoodSystem: seed_plot called with unknown food_id '%s'" % food_id)
		return false
	var cost: int = int(_food_defs[food_id].get(&"seed_cost", 0))
	if not EconomyManager.spend(EconomyManager.CurrencyType.CARROT_COIN, cost):
		return false
	var plot: Dictionary = {
		KEY_FOOD_ID:    food_id,
		KEY_STARTED_AT: Time.get_unix_time_from_system(),
		KEY_DURATION:   float(_food_defs[food_id].get(&"grow_time_seconds", 60.0)),
	}
	GameState.farm_plots.append(plot)
	GameState.mark_dirty()
	return true


## Adds quantity of food_id to inventory, clamped to max_stack.
## Rejects unknown food_id with a push_warning and makes no mutation.
func _add_to_inventory(food_id: String, quantity: int) -> void:
	if not _food_defs.has(food_id):
		push_warning("FoodSystem: unknown food_id '%s' — skipping inventory add" % food_id)
		return
	var current: int = GameState.food_inventory.get(food_id, 0)
	var item_def: Dictionary = _food_defs[food_id] as Dictionary
	var max_stack: int = int(item_def.get(KEY_MAX_STACK, _default_max_stack))
	GameState.food_inventory[food_id] = mini(current + quantity, max_stack)
	GameState.mark_dirty()


## Deducts quantity of food_id from inventory.
## Returns false (and makes no change) if current quantity < quantity.
## Returns true and decrements on success.
func _deduct_from_inventory(food_id: String, quantity: int) -> bool:
	var current: int = GameState.food_inventory.get(food_id, 0)
	if current < quantity:
		return false
	GameState.food_inventory[food_id] = current - quantity
	GameState.mark_dirty()
	return true


## Resolves any farm plots that completed while the app was offline (story-004, ADR-0009).
## Called once via call_deferred from _ready(), after SaveSystem.load_game() has populated
## GameState.farm_plots. Each completed plot yields exactly one harvest regardless of how
## long it was overdue — no multi-tick overflow (ADR-0009: "no partial credit").
func _resolve_offline_plots() -> void:
	var now: float = Time.get_unix_time_from_system()
	var completed: Array[int] = []
	for i: int in range(GameState.farm_plots.size()):
		var plot: Dictionary = GameState.farm_plots[i]
		if now - float(plot[KEY_STARTED_AT]) >= float(plot[KEY_DURATION]):
			completed.append(i)
	completed.reverse()
	for idx: int in completed:
		var plot: Dictionary = GameState.farm_plots[idx]
		var food_id: String = str(plot[KEY_FOOD_ID])
		var harvest_qty: int = int(_food_defs.get(food_id, {}).get(&"harvest_quantity", 1))
		GameState.farm_plots.remove_at(idx)
		_add_to_inventory(food_id, harvest_qty)
		EventBus.food_harvested.emit(food_id, harvest_qty)
	if not completed.is_empty():
		GameState.mark_dirty()


## Checks all farm plots for completion on each TimeManager tick.
## Completed plots are removed, their harvest added to inventory, and food_harvested emitted.
## Removal uses reverse-index order to avoid index-shifting on multiple simultaneous completions (ADR-0009).
func _on_tick(_delta: float) -> void:
	var now: float = Time.get_unix_time_from_system()
	var completed: Array[int] = []
	for i: int in range(GameState.farm_plots.size()):
		var plot: Dictionary = GameState.farm_plots[i]
		var elapsed: float = now - float(plot[KEY_STARTED_AT])
		if elapsed >= float(plot[KEY_DURATION]):
			completed.append(i)
	completed.reverse()
	for idx: int in completed:
		var plot: Dictionary = GameState.farm_plots[idx]
		var food_id: String = str(plot[KEY_FOOD_ID])
		var harvest_qty: int = int(_food_defs.get(food_id, {}).get(&"harvest_quantity", 1))
		GameState.farm_plots.remove_at(idx)
		_add_to_inventory(food_id, harvest_qty)
		EventBus.food_harvested.emit(food_id, harvest_qty)
	if not completed.is_empty():
		GameState.mark_dirty()
	if not GameState.farm_plots.is_empty():
		EventBus.farm_plots_updated.emit()
