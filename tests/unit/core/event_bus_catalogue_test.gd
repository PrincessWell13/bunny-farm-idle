## Tests that EventBus declares all 32 required signals with typed parameters.
## Story: production/epics/event-bus/story-001-signal-catalogue.md
## Does NOT test emit/connect behaviour — see story-002-connect-emit-disconnect.
extends GdUnitTestSuite

const EventBusScript := preload("res://src/core/event_bus.gd")

var _event_bus: Node

func before_test() -> void:
	_event_bus = EventBusScript.new()
	add_child(_event_bus)

func after_test() -> void:
	_event_bus.queue_free()
	_event_bus = null


func test_all_required_signals_present() -> void:
	var expected: Array[String] = [
		"rabbit_born", "rabbit_matured", "rabbit_stat_changed", "rabbit_died",
		"currency_changed",
		"production_ticked",
		"breed_requested", "breeding_completed",
		"hutch_dirtied", "hutch_upgraded", "rabbit_assigned_to_hutch", "hutch_cleanliness_changed",
		"expedition_started", "expedition_completed", "expedition_collected",
		"rabbit_sent_on_expedition", "rabbit_returned_from_expedition", "expedition_ready_to_collect",
		"save_requested", "save_synced", "new_game_started",
		"nav_tab_pressed", "notification_requested",
		"season_changed", "event_activated", "merchant_appeared",
		"prestige_executed",
		"guild_contribution_submitted", "guild_boss_attacked",
		"food_harvested", "food_used", "farm_plots_updated",
	]
	for signal_name: String in expected:
		assert_bool(_event_bus.has_signal(signal_name)).is_true()


func test_signal_count_is_32() -> void:
	# Collect built-in Node signal names once to filter them out.
	var builtin_node: Node = Node.new()
	var builtin_names: Array[String] = []
	for s: Dictionary in builtin_node.get_signal_list():
		builtin_names.append(s["name"])
	builtin_node.free()

	var custom_signals: Array[Dictionary] = _event_bus.get_signal_list().filter(
		func(s: Dictionary) -> bool:
			return not (s["name"] in builtin_names)
	)
	assert_int(custom_signals.size()).is_equal(32)


func test_no_variant_parameters() -> void:
	# type 0 == TYPE_NIL / Variant (untyped). All game logic signal params must be typed.
	var builtin_node: Node = Node.new()
	var builtin_names: Array[String] = []
	for s: Dictionary in builtin_node.get_signal_list():
		builtin_names.append(s["name"])
	builtin_node.free()

	for signal_info: Dictionary in _event_bus.get_signal_list():
		if signal_info["name"] in builtin_names:
			continue
		var args: Array = signal_info.get("args", [])
		for arg: Dictionary in args:
			var type_hint: int = arg.get("type", 0)
			assert_int(type_hint).is_not_equal(0)
