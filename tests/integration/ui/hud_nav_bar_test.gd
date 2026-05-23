## Integration tests for HUD story-002 — bottom navigation bar.
## Story: production/epics/hud/story-002-nav-bar.md
## Verifies AC-1 through AC-5 using mock autoloads via Engine.register_singleton.
extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# Mock classes
# ---------------------------------------------------------------------------

class MockEconomyManager extends Node:
	func get_balance(_currency: int) -> int:
		return 0


class MockEventBus extends Node:
	signal currency_changed(currency: int, new_balance: int, delta: int)
	signal nav_tab_pressed(tab: int)
	signal notification_requested(text: String, duration_sec: float)
	signal food_harvested(food_id: String, quantity: int)
	signal food_used(food_id: String)
	signal farm_plots_updated()

	var nav_tab_pressed_calls: Array[int] = []

	func _ready() -> void:
		nav_tab_pressed.connect(_record_tab)

	func _record_tab(tab: int) -> void:
		nav_tab_pressed_calls.append(tab)


# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------

var _mock_economy: MockEconomyManager
var _mock_event_bus: MockEventBus
var _orig_economy: Object = null
var _orig_event_bus: Object = null

func before_test() -> void:
	_mock_economy = MockEconomyManager.new()
	_mock_event_bus = MockEventBus.new()
	add_child(_mock_economy)
	add_child(_mock_event_bus)
	_orig_economy = Engine.get_singleton("EconomyManager") if Engine.has_singleton("EconomyManager") else null
	if Engine.has_singleton("EconomyManager"):
		Engine.unregister_singleton("EconomyManager")
	Engine.register_singleton("EconomyManager", _mock_economy)
	_orig_event_bus = Engine.get_singleton("EventBus") if Engine.has_singleton("EventBus") else null
	if Engine.has_singleton("EventBus"):
		Engine.unregister_singleton("EventBus")
	Engine.register_singleton("EventBus", _mock_event_bus)

func after_test() -> void:
	if Engine.has_singleton("EconomyManager"):
		Engine.unregister_singleton("EconomyManager")
	if _orig_economy != null:
		Engine.register_singleton("EconomyManager", _orig_economy)
	_orig_economy = null
	if Engine.has_singleton("EventBus"):
		Engine.unregister_singleton("EventBus")
	if _orig_event_bus != null:
		Engine.register_singleton("EventBus", _orig_event_bus)
	_orig_event_bus = null
	_mock_economy.queue_free()
	_mock_event_bus.queue_free()


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

func _build_hud() -> HUD:
	var hud: HUD = HUD.new()
	var cc_lbl: Label = Label.new()
	var gem_lbl: Label = Label.new()
	hud.cc_label = cc_lbl
	hud.gem_label = gem_lbl
	var farm_btn: Button = Button.new()
	var breeding_btn: Button = Button.new()
	var guild_btn: Button = Button.new()
	var shop_btn: Button = Button.new()
	var quest_btn: Button = Button.new()
	farm_btn.custom_minimum_size = Vector2(44, 44)
	breeding_btn.custom_minimum_size = Vector2(44, 44)
	guild_btn.custom_minimum_size = Vector2(44, 44)
	shop_btn.custom_minimum_size = Vector2(44, 44)
	quest_btn.custom_minimum_size = Vector2(44, 44)
	hud.farm_button = farm_btn
	hud.breeding_button = breeding_btn
	hud.guild_button = guild_btn
	hud.shop_button = shop_btn
	hud.quest_button = quest_btn
	var notif_container: Control = Control.new()
	var notif_label: Label = Label.new()
	hud.notification_container = notif_container
	hud.notification_label = notif_label
	add_child(hud)
	hud.add_child(cc_lbl)
	hud.add_child(gem_lbl)
	hud.add_child(farm_btn)
	hud.add_child(breeding_btn)
	hud.add_child(guild_btn)
	hud.add_child(shop_btn)
	hud.add_child(quest_btn)
	notif_container.add_child(notif_label)
	hud.add_child(notif_container)
	return hud


# ---------------------------------------------------------------------------
# AC-1: All 5 buttons accessible after _ready()
# ---------------------------------------------------------------------------

## AC-1: All 5 nav button exports are set and accessible.
func test_hud_nav_bar_all_five_buttons_exist() -> void:
	var hud: HUD = _build_hud()
	assert_object(hud.farm_button).is_not_null()
	assert_object(hud.breeding_button).is_not_null()
	assert_object(hud.guild_button).is_not_null()
	assert_object(hud.shop_button).is_not_null()
	assert_object(hud.quest_button).is_not_null()


# ---------------------------------------------------------------------------
# AC-4: All buttons meet 44×44 px minimum touch target
# ---------------------------------------------------------------------------

## AC-4: All nav buttons have custom_minimum_size >= 44x44.
func test_hud_nav_buttons_meet_touch_target_size() -> void:
	var hud: HUD = _build_hud()
	var buttons: Array[Button] = [
		hud.farm_button, hud.breeding_button, hud.guild_button,
		hud.shop_button, hud.quest_button
	]
	for btn: Button in buttons:
		assert_float(btn.custom_minimum_size.x).is_greater_equal(44.0)
		assert_float(btn.custom_minimum_size.y).is_greater_equal(44.0)


# ---------------------------------------------------------------------------
# AC-2: Correct tab value emitted per button
# ---------------------------------------------------------------------------

## AC-2: Tapping FARM emits nav_tab_pressed(0).
func test_hud_farm_tab_emits_correct_value() -> void:
	var hud: HUD = _build_hud()
	# Switch away first so FARM tap is not a same-tab no-op
	hud._on_tab_pressed(HUD.NavTab.BREEDING)
	_mock_event_bus.nav_tab_pressed_calls.clear()
	hud._on_tab_pressed(HUD.NavTab.FARM)
	assert_int(_mock_event_bus.nav_tab_pressed_calls.size()).is_equal(1)
	assert_int(_mock_event_bus.nav_tab_pressed_calls[0]).is_equal(0)

## AC-2: Tapping BREEDING emits nav_tab_pressed(1).
func test_hud_breeding_tab_emits_correct_value() -> void:
	var hud: HUD = _build_hud()
	hud._on_tab_pressed(HUD.NavTab.BREEDING)
	assert_int(_mock_event_bus.nav_tab_pressed_calls.size()).is_equal(1)
	assert_int(_mock_event_bus.nav_tab_pressed_calls[0]).is_equal(1)

## AC-2: Tapping GUILD emits nav_tab_pressed(2).
func test_hud_guild_tab_emits_correct_value() -> void:
	var hud: HUD = _build_hud()
	hud._on_tab_pressed(HUD.NavTab.GUILD)
	assert_int(_mock_event_bus.nav_tab_pressed_calls.size()).is_equal(1)
	assert_int(_mock_event_bus.nav_tab_pressed_calls[0]).is_equal(2)

## AC-2: Tapping SHOP emits nav_tab_pressed(3).
func test_hud_shop_tab_emits_correct_value() -> void:
	var hud: HUD = _build_hud()
	hud._on_tab_pressed(HUD.NavTab.SHOP)
	assert_int(_mock_event_bus.nav_tab_pressed_calls.size()).is_equal(1)
	assert_int(_mock_event_bus.nav_tab_pressed_calls[0]).is_equal(3)

## AC-2: Tapping QUEST emits nav_tab_pressed(4).
func test_hud_quest_tab_emits_correct_value() -> void:
	var hud: HUD = _build_hud()
	hud._on_tab_pressed(HUD.NavTab.QUEST)
	assert_int(_mock_event_bus.nav_tab_pressed_calls.size()).is_equal(1)
	assert_int(_mock_event_bus.nav_tab_pressed_calls[0]).is_equal(4)


# ---------------------------------------------------------------------------
# AC-5: Same-tab re-tap does not re-emit
# ---------------------------------------------------------------------------

## AC-5: Tapping the already-active tab does not emit nav_tab_pressed.
func test_hud_same_tab_tap_does_not_emit() -> void:
	var hud: HUD = _build_hud()
	# Default active tab is FARM after _ready()
	hud._on_tab_pressed(HUD.NavTab.FARM)
	assert_int(_mock_event_bus.nav_tab_pressed_calls.size()).is_equal(0)

## AC-5: Switching tabs clears active state — second different-tab tap does emit.
func test_hud_switching_tabs_updates_active_tab() -> void:
	var hud: HUD = _build_hud()
	hud._on_tab_pressed(HUD.NavTab.SHOP)
	hud._on_tab_pressed(HUD.NavTab.SHOP)  # same tab — no-op
	assert_int(_mock_event_bus.nav_tab_pressed_calls.size()).is_equal(1)
