## Integration tests for HUD story-001 — currency header display.
## Story: production/epics/hud/story-001-currency-header.md
## Verifies AC-1 through AC-5 using mock autoloads via Engine.register_singleton.
extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# Mock classes
# ---------------------------------------------------------------------------

class MockEconomyManager extends Node:
	var _balances: Dictionary = {
		0: 0,  # CARROT_COIN
		1: 0,  # STAR_DUST
		2: 0,  # CRYSTAL_GEM
		3: 0,  # GENE_FRAGMENT
	}

	func get_balance(currency: int) -> int:
		return _balances.get(currency, 0)

	func set_mock_balance(currency: int, amount: int) -> void:
		_balances[currency] = amount


class MockEventBus extends Node:
	signal currency_changed(currency: int, new_balance: int, delta: int)


# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------

var _mock_economy: MockEconomyManager
var _mock_event_bus: MockEventBus

func before_test() -> void:
	_mock_economy = MockEconomyManager.new()
	_mock_event_bus = MockEventBus.new()
	add_child(_mock_economy)
	add_child(_mock_event_bus)
	Engine.register_singleton("EconomyManager", _mock_economy)
	Engine.register_singleton("EventBus", _mock_event_bus)

func after_test() -> void:
	Engine.unregister_singleton("EconomyManager")
	Engine.unregister_singleton("EventBus")
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
	add_child(hud)
	hud.add_child(cc_lbl)
	hud.add_child(gem_lbl)
	return hud


# ---------------------------------------------------------------------------
# AC-1: EventBus.currency_changed subscription
# ---------------------------------------------------------------------------

## AC-1: currency_changed is connected after _ready().
func test_hud_subscribes_to_currency_changed_on_ready() -> void:
	var hud: HUD = _build_hud()
	assert_bool(_mock_event_bus.currency_changed.is_connected(hud._on_currency_changed)).is_true()

## AC-1: currency_changed is disconnected after _exit_tree().
func test_hud_disconnects_currency_changed_on_exit_tree() -> void:
	var hud: HUD = _build_hud()
	hud._exit_tree()
	assert_bool(_mock_event_bus.currency_changed.is_connected(hud._on_currency_changed)).is_false()


# ---------------------------------------------------------------------------
# AC-2: Initial balances loaded from EconomyManager
# ---------------------------------------------------------------------------

## AC-2: cc_label shows CARROT_COIN balance on ready.
func test_hud_shows_initial_carrot_coin_balance() -> void:
	_mock_economy.set_mock_balance(0, 42)  # CARROT_COIN = 0
	var hud: HUD = _build_hud()
	assert_str(hud.cc_label.text).is_equal("42")

## AC-2: gem_label shows CRYSTAL_GEM balance on ready.
func test_hud_shows_initial_crystal_gem_balance() -> void:
	_mock_economy.set_mock_balance(2, 7)  # CRYSTAL_GEM = 2
	var hud: HUD = _build_hud()
	assert_str(hud.gem_label.text).is_equal("7")


# ---------------------------------------------------------------------------
# AC-3 + AC-4: Labels update on currency_changed signal
# ---------------------------------------------------------------------------

## AC-3: cc_label updates when CARROT_COIN currency_changed fires.
func test_hud_cc_label_updates_on_carrot_coin_signal() -> void:
	var hud: HUD = _build_hud()
	_mock_event_bus.currency_changed.emit(0, 100, 100)  # CARROT_COIN = 0
	assert_str(hud.cc_label.text).is_equal("100")

## AC-4: gem_label updates when CRYSTAL_GEM currency_changed fires.
func test_hud_gem_label_updates_on_crystal_gem_signal() -> void:
	var hud: HUD = _build_hud()
	_mock_event_bus.currency_changed.emit(2, 15, 5)  # CRYSTAL_GEM = 2
	assert_str(hud.gem_label.text).is_equal("15")

## AC-3 isolation: CC signal does not change gem_label.
func test_hud_cc_signal_does_not_change_gem_label() -> void:
	_mock_economy.set_mock_balance(2, 3)
	var hud: HUD = _build_hud()
	_mock_event_bus.currency_changed.emit(0, 99, 99)
	assert_str(hud.gem_label.text).is_equal("3")


# ---------------------------------------------------------------------------
# AC-5: Unknown currency silently ignored
# ---------------------------------------------------------------------------

## AC-5: STAR_DUST signal does not crash and does not change cc or gem labels.
func test_hud_ignores_star_dust_currency_signal() -> void:
	_mock_economy.set_mock_balance(0, 10)
	_mock_economy.set_mock_balance(2, 5)
	var hud: HUD = _build_hud()
	_mock_event_bus.currency_changed.emit(1, 50, 50)  # STAR_DUST = 1
	assert_str(hud.cc_label.text).is_equal("10")
	assert_str(hud.gem_label.text).is_equal("5")
