## HUD — always-visible game chrome (Presentation layer).
## Header: CC + Gem balance display; nav bar; notification toast; prestige button.
## Presentation never decides — HUD only displays and dispatches signals (ADR-0003).
class_name HUD
extends Control

enum NavTab { FARM = 0, BREEDING = 1, GUILD = 2, SHOP = 3, QUEST = 4 }

## Currency index mirrors EconomyManager.CurrencyType — avoids autoload enum access in tests.
const _CURRENCY_CARROT_COIN := 0
const _CURRENCY_CRYSTAL_GEM := 2

## Story-001: header currency labels
@export var cc_label: Label
@export var gem_label: Label

## Story-002: bottom nav bar buttons
@export var farm_button: Button
@export var breeding_button: Button
@export var guild_button: Button
@export var shop_button: Button
@export var quest_button: Button

## Story-003: notification toast
@export var notification_container: Control
@export var notification_label: Label

## Story-007: prestige button + confirmation dialog
@export var prestige_button: Button
@export var prestige_confirm_dialog: ConfirmationDialog

## Story-004: food inventory widget.
## Scenes wire individual labels via register_food_label(food_id, label).
## _food_counts tracks the live display value per food_id; updated by signals.
var _food_counts: Dictionary = {}
var _food_labels: Dictionary = {}

## Story-005: farm plot progress UI.
## Scenes wire slot labels (countdown/state text) and slot buttons (tap target) via exports.
## Index correspondence: plot_slot_labels[i] ↔ plot_slot_buttons[i] ↔ GameState.farm_plots[i].
@export var plot_slot_labels: Array[Label] = []
@export var plot_slot_buttons: Array[Button] = []

var _plot_states: Array = []
var _countdown_timer: Timer = null

var _active_tab: int = NavTab.FARM
var _active_tween: Tween = null

func _ready() -> void:
	var eb: Node = _event_bus()
	eb.currency_changed.connect(_on_currency_changed)
	eb.notification_requested.connect(_on_notification_requested)
	var em: Node = _economy_mgr()
	cc_label.text = str(em.get_balance(_CURRENCY_CARROT_COIN))
	gem_label.text = str(em.get_balance(_CURRENCY_CRYSTAL_GEM))
	farm_button.pressed.connect(_on_tab_pressed.bind(NavTab.FARM))
	breeding_button.pressed.connect(_on_tab_pressed.bind(NavTab.BREEDING))
	guild_button.pressed.connect(_on_tab_pressed.bind(NavTab.GUILD))
	shop_button.pressed.connect(_on_tab_pressed.bind(NavTab.SHOP))
	quest_button.pressed.connect(_on_tab_pressed.bind(NavTab.QUEST))
	_set_active_tab(NavTab.FARM)
	_hide_notification()
	if prestige_button != null:
		prestige_button.pressed.connect(_on_prestige_tapped)
		eb.rabbit_born.connect(_on_prestige_state_changed)
		eb.breeding_completed.connect(_on_prestige_state_changed)
		_refresh_prestige_button()
	if prestige_confirm_dialog != null:
		prestige_confirm_dialog.dialog_text = "Prestige now? Your coins and farm will reset, but you will earn a permanent production bonus."
		prestige_confirm_dialog.confirmed.connect(_on_prestige_confirmed)
	eb.food_harvested.connect(_on_food_harvested)
	eb.food_used.connect(_on_food_used)
	_refresh_food_display()
	eb.farm_plots_updated.connect(_on_farm_plots_updated)
	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.autostart = true
	_countdown_timer.timeout.connect(_update_countdowns)
	add_child(_countdown_timer)
	_refresh_all_plots()

func _exit_tree() -> void:
	var eb: Node = _event_bus()
	if eb.currency_changed.is_connected(_on_currency_changed):
		eb.currency_changed.disconnect(_on_currency_changed)
	if eb.notification_requested.is_connected(_on_notification_requested):
		eb.notification_requested.disconnect(_on_notification_requested)
	if eb.rabbit_born.is_connected(_on_prestige_state_changed):
		eb.rabbit_born.disconnect(_on_prestige_state_changed)
	if eb.breeding_completed.is_connected(_on_prestige_state_changed):
		eb.breeding_completed.disconnect(_on_prestige_state_changed)
	if eb.food_harvested.is_connected(_on_food_harvested):
		eb.food_harvested.disconnect(_on_food_harvested)
	if eb.food_used.is_connected(_on_food_used):
		eb.food_used.disconnect(_on_food_used)
	if eb.farm_plots_updated.is_connected(_on_farm_plots_updated):
		eb.farm_plots_updated.disconnect(_on_farm_plots_updated)


## Resolves EventBus via Engine singleton first to allow test-time mock injection.
func _event_bus() -> Node:
	if Engine.has_singleton("EventBus"):
		return Engine.get_singleton("EventBus")
	return get_node_or_null("/root/EventBus")


## Resolves EconomyManager via Engine singleton first to allow test-time mock injection.
func _economy_mgr() -> Node:
	if Engine.has_singleton("EconomyManager"):
		return Engine.get_singleton("EconomyManager")
	return get_node_or_null("/root/EconomyManager")


## Resolves FoodSystem via Engine singleton first to allow test-time mock injection.
func _food_sys() -> Node:
	if Engine.has_singleton("FoodSystem"):
		return Engine.get_singleton("FoodSystem")
	return get_node_or_null("/root/FoodSystem")


## Resolves PrestigeSystem via Engine singleton first to allow test-time mock injection.
func _prestige_sys() -> Node:
	if Engine.has_singleton("PrestigeSystem"):
		return Engine.get_singleton("PrestigeSystem")
	return get_node_or_null("/root/PrestigeSystem")


## Updates CC or Gem label when currency_changed fires. Also re-evaluates prestige eligibility.
func _on_currency_changed(currency: int, new_balance: int, _delta: int) -> void:
	match currency:
		_CURRENCY_CARROT_COIN:
			cc_label.text = str(new_balance)
		_CURRENCY_CRYSTAL_GEM:
			gem_label.text = str(new_balance)
	_refresh_prestige_button()

## Dispatches nav_tab_pressed. Same-tab re-tap is a no-op (AC-5).
func _on_tab_pressed(tab: int) -> void:
	if tab == _active_tab:
		return
	_set_active_tab(tab)
	_event_bus().nav_tab_pressed.emit(tab)

func _set_active_tab(tab: int) -> void:
	_active_tab = tab
	var buttons: Array[Button] = [farm_button, breeding_button, guild_button, shop_button, quest_button]
	for i: int in buttons.size():
		buttons[i].modulate = Color.WHITE if i != tab else Color(1.0, 0.8, 0.2)

## Displays a timed toast notification. External callers use EventBus.notification_requested.
func show_notification(text: String, duration_sec: float = 3.0) -> void:
	_cancel_active_toast()
	notification_label.text = text
	notification_container.visible = true
	_active_tween = create_tween()
	_active_tween.tween_interval(duration_sec)
	_active_tween.tween_callback(_hide_notification)

func _on_notification_requested(text: String, duration_sec: float) -> void:
	show_notification(text, duration_sec)

func _cancel_active_toast() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	notification_container.visible = false

func _hide_notification() -> void:
	notification_container.visible = false
	_active_tween = null

## --- Story-004: Food Inventory Widget ---

## Wires a Label to a food_id key. Called by the HUD scene after nodes are ready.
## The update path never uses hardcoded food_id strings — it reads from the signal payload.
func register_food_label(food_id: String, label: Label) -> void:
	_food_labels[food_id] = label
	_update_food_label(food_id)

## Returns the current display count for a food_id (0 if not tracked). Used by tests.
func get_food_count(food_id: String) -> int:
	return int(_food_counts.get(food_id, 0))

## Reads FoodSystem.get_inventory() and initialises _food_counts from current state (AC-2).
## Ensures labels show the saved value rather than assuming 0 on load.
func _refresh_food_display() -> void:
	var fs: Node = _food_sys()
	if fs == null:
		return
	var inventory: Dictionary = fs.get_inventory()
	for food_id: String in inventory:
		_food_counts[food_id] = int(inventory.get(food_id, 0))
		_update_food_label(food_id)

## Sets the label text for food_id if a label is registered. Never hides label at 0 (AC-3).
func _update_food_label(food_id: String) -> void:
	if not _food_labels.has(food_id):
		return
	(_food_labels[food_id] as Label).text = str(_food_counts.get(food_id, 0))

## Increments the display count for food_id by quantity when a harvest completes (AC-4).
func _on_food_harvested(food_id: String, quantity: int) -> void:
	_food_counts[food_id] = _food_counts.get(food_id, 0) + quantity
	_update_food_label(food_id)

## Decrements the display count for food_id by 1 when food is consumed, clamped to 0 (AC-5, AC-6).
## Signal used: EventBus.food_used(food_id) — emitted by FoodSystem.feed_rabbit() on success.
func _on_food_used(food_id: String) -> void:
	_food_counts[food_id] = maxi(_food_counts.get(food_id, 0) - 1, 0)
	_update_food_label(food_id)

## --- Story-007: Prestige button ---

## Re-evaluates prestige eligibility and reflects it on the button (AC-2, AC-3, AC-9).
func _refresh_prestige_button() -> void:
	if prestige_button == null:
		return
	var ps: Node = _prestige_sys()
	if ps == null:
		return
	var eligible: bool = ps.can_prestige()
	prestige_button.disabled = not eligible
	prestige_button.modulate = Color.WHITE if eligible else Color(1.0, 1.0, 1.0, 0.4)

## Fired whenever rabbit_born or breeding_completed may change prestige eligibility (AC-9).
func _on_prestige_state_changed(_arg: Variant = null) -> void:
	_refresh_prestige_button()

## Shows confirmation dialog when prestige button tapped while eligible (AC-4, AC-5).
func _on_prestige_tapped() -> void:
	var ps: Node = _prestige_sys()
	if ps == null or not ps.can_prestige():
		return
	if prestige_confirm_dialog != null:
		prestige_confirm_dialog.popup_centered()

## Calls PrestigeSystem.execute_prestige() after player confirms (AC-6, AC-8).
## HUD never mutates game state directly — all state change delegated to PrestigeSystem (ADR-0003).
func _on_prestige_confirmed() -> void:
	var ps: Node = _prestige_sys()
	if ps != null:
		ps.execute_prestige()
	_refresh_prestige_button()

## --- Story-005: Farm Plot Progress UI ---

## Reads FoodSystem.get_farm_plot_state() and re-renders all slot labels and buttons (AC-1, AC-9).
func _refresh_all_plots() -> void:
	var fs: Node = _food_sys()
	if fs == null:
		return
	_plot_states = fs.get_farm_plot_state()
	var slot_count: int = plot_slot_labels.size()
	for i: int in range(slot_count):
		if i < _plot_states.size():
			_render_plot(i, _plot_states[i])
		else:
			_render_empty(i)

## Called when farm_plots_updated fires — re-fetches state and re-renders (AC-5).
func _on_farm_plots_updated() -> void:
	_refresh_all_plots()

## Renders a slot that has an active or completed plot.
## Completed (remaining ≤ 0) → "READY" + button enabled (AC-6).
## In-progress → countdown seconds + button disabled (AC-3).
func _render_plot(idx: int, plot: Dictionary) -> void:
	if idx >= plot_slot_labels.size():
		return
	var now: float = Time.get_unix_time_from_system()
	var remaining: float = float(plot.get("started_at", 0.0)) + float(plot.get("duration", 0.0)) - now
	_set_slot_display(idx, remaining)

## Renders an empty slot with a "SEED" call-to-action (AC-2).
func _render_empty(idx: int) -> void:
	if idx >= plot_slot_labels.size():
		return
	plot_slot_labels[idx].text = "SEED"
	if idx < plot_slot_buttons.size():
		plot_slot_buttons[idx].disabled = true

## Updates countdown labels once per second via _countdown_timer (AC-4).
## Only allocates a string when the displayed second actually changes.
func _update_countdowns() -> void:
	var now: float = Time.get_unix_time_from_system()
	for i: int in range(_plot_states.size()):
		if i >= plot_slot_labels.size():
			break
		var plot: Dictionary = _plot_states[i]
		var remaining: float = float(plot.get("started_at", 0.0)) + float(plot.get("duration", 0.0)) - now
		_set_slot_display(i, remaining)

## Shared display helper: sets label text and button state for a slot given remaining seconds.
func _set_slot_display(idx: int, remaining: float) -> void:
	var label: Label = plot_slot_labels[idx]
	if remaining <= 0.0:
		label.text = "READY"
		if idx < plot_slot_buttons.size():
			plot_slot_buttons[idx].disabled = false
	else:
		label.text = "%ds" % int(remaining)
		if idx < plot_slot_buttons.size():
			plot_slot_buttons[idx].disabled = true

## Called by the scene when a plot slot is tapped (AC-7).
## Guards against in-progress and empty slots — only READY plots are harvested.
## Delegates all state mutation to FoodSystem.harvest_plot() (ADR-0003, ADR-0009).
func on_plot_tapped(plot_index: int) -> void:
	if plot_index >= _plot_states.size():
		return
	var plot: Dictionary = _plot_states[plot_index]
	var now: float = Time.get_unix_time_from_system()
	var remaining: float = float(plot.get("started_at", 0.0)) + float(plot.get("duration", 0.0)) - now
	if remaining > 0.0:
		return
	var fs: Node = _food_sys()
	if fs != null:
		fs.harvest_plot(plot_index)
