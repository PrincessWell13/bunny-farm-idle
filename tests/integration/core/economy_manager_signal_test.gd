## Integration tests for EconomyManager currency_changed signal emission.
## Story: production/epics/economy-manager/story-002-currency-changed-signal.md
## Pattern: Engine.register_singleton("EventBus", ...) makes EventBus accessible
## to EconomyManager.add() / spend() in the headless GdUnit4 environment.
## If the project autoloads are already loaded, we use the existing singleton.
extends GdUnitTestSuite

const EventBusScript := preload("res://src/core/event_bus.gd")
const EconomyManagerScript := preload("res://src/core/economy_manager.gd")

var _event_bus: Node
var _economy: Node
var _received: Array = []
var _owned_event_bus: bool = false


func before_test() -> void:
	_received = []
	_owned_event_bus = false
	if Engine.has_singleton("EventBus"):
		_event_bus = Engine.get_singleton("EventBus")
	else:
		_event_bus = EventBusScript.new()
		Engine.register_singleton("EventBus", _event_bus)
		add_child(_event_bus)
		_owned_event_bus = true
	_economy = EconomyManagerScript.new()
	add_child(_economy)
	_event_bus.currency_changed.connect(_on_currency_changed)


func after_test() -> void:
	if is_instance_valid(_event_bus) and _event_bus.currency_changed.is_connected(_on_currency_changed):
		_event_bus.currency_changed.disconnect(_on_currency_changed)
	if is_instance_valid(_economy):
		_economy.queue_free()
	if _owned_event_bus and is_instance_valid(_event_bus):
		Engine.unregister_singleton("EventBus")
		_event_bus.queue_free()
	_economy = null
	_event_bus = null
	_owned_event_bus = false


func _on_currency_changed(currency: int, new_balance: int, delta: int) -> void:
	_received.append({"currency": currency, "new_balance": new_balance, "delta": delta})


## AC-1: add() emits currency_changed with currency, correct new_balance, and positive delta.
func test_add_emits_currency_changed_with_correct_params() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 150)
	assert_int(_received.size()).is_equal(1)
	var sig: Dictionary = _received[0]
	assert_int(sig["currency"]).is_equal(EconomyManagerScript.CurrencyType.CARROT_COIN)
	assert_int(sig["new_balance"]).is_equal(150)
	assert_int(sig["delta"]).is_equal(150)


## AC-2: spend() success emits currency_changed with negative delta equal to -amount.
func test_spend_success_emits_with_negative_delta() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 200)
	_received.clear()
	var result: bool = _economy.spend(EconomyManagerScript.CurrencyType.CARROT_COIN, 80)
	assert_bool(result).is_true()
	assert_int(_received.size()).is_equal(1)
	var sig: Dictionary = _received[0]
	assert_int(sig["currency"]).is_equal(EconomyManagerScript.CurrencyType.CARROT_COIN)
	assert_int(sig["new_balance"]).is_equal(120)
	assert_int(sig["delta"]).is_equal(-80)


## AC-3: spend() with insufficient balance returns false and does not emit.
func test_spend_failure_does_not_emit() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 50)
	_received.clear()
	var result: bool = _economy.spend(EconomyManagerScript.CurrencyType.CARROT_COIN, 100)
	assert_bool(result).is_false()
	assert_int(_received.size()).is_equal(0)


## AC-4: set_balance() does not emit currency_changed (boot-time population must not spam signals).
func test_set_balance_does_not_emit() -> void:
	_economy.set_balance(EconomyManagerScript.CurrencyType.STAR_DUST, 500)
	assert_int(_received.size()).is_equal(0)


## AC-5: each add() call emits one signal; cumulative new_balance reflects all additions.
func test_multiple_adds_emit_multiple_signals() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 10)
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 10)
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 10)
	assert_int(_received.size()).is_equal(3)
	assert_int(_received[2]["new_balance"]).is_equal(30)
