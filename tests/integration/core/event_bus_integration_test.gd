## Integration tests for the EventBus connect/emit/disconnect cycle.
## Story: production/epics/event-bus/story-002-connect-emit-disconnect.md
## Does NOT test signal catalogue — see story-001-signal-catalogue.
extends GdUnitTestSuite

var _event_bus: Node

func before_test() -> void:
	_event_bus = preload("res://src/core/event_bus.gd").new()
	add_child(_event_bus)

func after_test() -> void:
	_event_bus.queue_free()
	_event_bus = null


## AC-1: connect callable, emit, assert value received.
func test_rabbit_born_connect_emit_receives_value() -> void:
	var received_id: String = ""
	_event_bus.rabbit_born.connect(func(id: String) -> void: received_id = id)
	_event_bus.rabbit_born.emit("bunny-42")
	assert_str(received_id).is_equal("bunny-42")


## AC-2: typed multi-parameter signal delivers all params correctly.
func test_currency_changed_typed_params_received() -> void:
	var received_currency: int = -1
	var received_balance: int = -1
	var received_delta: int = -1
	_event_bus.currency_changed.connect(
		func(c: int, b: int, d: int) -> void:
			received_currency = c
			received_balance = b
			received_delta = d
	)
	_event_bus.currency_changed.emit(0, 100, 50)
	assert_int(received_currency).is_equal(0)
	assert_int(received_balance).is_equal(100)
	assert_int(received_delta).is_equal(50)


## AC-3: multi-param production signal delivers correct values including zero-earnings case.
func test_production_ticked_params_received() -> void:
	var received_carrot: int = -1
	var received_dust: int = -1
	_event_bus.production_ticked.connect(
		func(carrot: int, dust: int) -> void:
			received_carrot = carrot
			received_dust = dust
	)
	_event_bus.production_ticked.emit(5, 2)
	assert_int(received_carrot).is_equal(5)
	assert_int(received_dust).is_equal(2)


## AC-3 edge: zero-earnings tick still fires.
func test_production_ticked_zero_earnings_still_fires() -> void:
	var fired: bool = false
	_event_bus.production_ticked.connect(func(_c: int, _d: int) -> void: fired = true)
	_event_bus.production_ticked.emit(0, 0)
	assert_bool(fired).is_true()


## AC-4: disconnect via stored Callable prevents callback after emit.
func test_disconnect_prevents_crash_on_emit() -> void:
	var called: bool = false
	var handler := func(_id: String) -> void: called = true
	_event_bus.rabbit_born.connect(handler)
	_event_bus.rabbit_born.disconnect(handler)
	_event_bus.rabbit_born.emit("post-disconnect")
	assert_bool(called).is_false()


## AC-5: multiple callables connected to the same signal all receive the emit.
func test_multiple_listeners_all_receive_emit() -> void:
	var count: int = 0
	_event_bus.save_requested.connect(func() -> void: count += 1)
	_event_bus.save_requested.connect(func() -> void: count += 1)
	_event_bus.save_requested.emit()
	assert_int(count).is_equal(2)


## AC-6: no string-based connect("signal_name",...) exists in src/core/event_bus.gd.
func test_no_string_based_connect_in_event_bus_src() -> void:
	var file := FileAccess.open("res://src/core/event_bus.gd", FileAccess.READ)
	assert_bool(file != null).is_true()
	var content: String = file.get_as_text()
	file.close()
	assert_bool(content.contains('connect("')).is_false()
