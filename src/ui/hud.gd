## HUD — always-visible game chrome (Presentation layer).
## Header: CC + Gem balance display; nav bar; notification toast.
## Presentation never decides — HUD only displays and dispatches signals (ADR-0003).
class_name HUD
extends Control

enum NavTab { FARM = 0, BREEDING = 1, GUILD = 2, SHOP = 3, QUEST = 4 }

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

var _active_tab: int = NavTab.FARM
var _active_tween: Tween = null

func _ready() -> void:
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.notification_requested.connect(_on_notification_requested)
	cc_label.text = str(EconomyManager.get_balance(EconomyManager.CurrencyType.CARROT_COIN))
	gem_label.text = str(EconomyManager.get_balance(EconomyManager.CurrencyType.CRYSTAL_GEM))
	farm_button.pressed.connect(_on_tab_pressed.bind(NavTab.FARM))
	breeding_button.pressed.connect(_on_tab_pressed.bind(NavTab.BREEDING))
	guild_button.pressed.connect(_on_tab_pressed.bind(NavTab.GUILD))
	shop_button.pressed.connect(_on_tab_pressed.bind(NavTab.SHOP))
	quest_button.pressed.connect(_on_tab_pressed.bind(NavTab.QUEST))
	_set_active_tab(NavTab.FARM)
	_hide_notification()

func _exit_tree() -> void:
	if EventBus.currency_changed.is_connected(_on_currency_changed):
		EventBus.currency_changed.disconnect(_on_currency_changed)
	if EventBus.notification_requested.is_connected(_on_notification_requested):
		EventBus.notification_requested.disconnect(_on_notification_requested)

## Updates CC or Gem label when currency_changed fires. Other currencies silently ignored (AC-5).
func _on_currency_changed(currency: int, new_balance: int, _delta: int) -> void:
	match currency:
		EconomyManager.CurrencyType.CARROT_COIN:
			cc_label.text = str(new_balance)
		EconomyManager.CurrencyType.CRYSTAL_GEM:
			gem_label.text = str(new_balance)

## Dispatches nav_tab_pressed. Same-tab re-tap is a no-op (AC-5).
func _on_tab_pressed(tab: int) -> void:
	if tab == _active_tab:
		return
	_set_active_tab(tab)
	EventBus.nav_tab_pressed.emit(tab)

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
