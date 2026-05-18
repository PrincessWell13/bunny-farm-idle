## Unit tests for RabbitSystem roster CRUD: add/get/get_all/get_in_hutch/remove.
## Story: production/epics/rabbit-system/story-002-roster-crud.md
## GameState is mocked via Engine.register_singleton — no autoload required.
extends GdUnitTestSuite


class MockGameState:
	var rabbits: Array[RabbitData] = []
	var dirty: bool = false
	func mark_dirty() -> void:
		dirty = true


var _system: RabbitSystem
var _mock_gs: MockGameState
var _owned_gs: bool = false


func before_test() -> void:
	_mock_gs = MockGameState.new()
	_owned_gs = false
	if not Engine.has_singleton("GameState"):
		Engine.register_singleton("GameState", _mock_gs)
		_owned_gs = true
	_system = RabbitSystem.new()


func after_test() -> void:
	_system.free()
	_system = null
	if _owned_gs:
		Engine.unregister_singleton("GameState")
	elif Engine.has_singleton("GameState"):
		Engine.get_singleton("GameState").rabbits.clear()


## AC-1: add_rabbit returns a non-empty string id.
func test_add_rabbit_returns_non_empty_id() -> void:
	var data := RabbitData.new()
	var id := _system.add_rabbit(data)
	assert_str(id).is_not_empty()


## AC-1: two consecutive add_rabbit calls return distinct ids.
func test_add_rabbit_assigns_unique_ids() -> void:
	var a := RabbitData.new()
	var b := RabbitData.new()
	var id_a := _system.add_rabbit(a)
	var id_b := _system.add_rabbit(b)
	assert_str(id_a).is_not_equal(id_b)


## AC-2: get_rabbit returns the same instance that was added.
func test_get_rabbit_returns_correct_instance() -> void:
	var data := RabbitData.new()
	var id := _system.add_rabbit(data)
	var found := _system.get_rabbit(id)
	assert_bool(found == data).is_true()


## AC-3: get_rabbit returns null for an unknown id.
func test_get_rabbit_returns_null_for_unknown_id() -> void:
	var result := _system.get_rabbit("does-not-exist")
	assert_bool(result == null).is_true()


## AC-4: remove_rabbit makes the rabbit unfindable and causes no crash.
func test_remove_rabbit_makes_rabbit_unfindable() -> void:
	var data := RabbitData.new()
	var id := _system.add_rabbit(data)
	_system.remove_rabbit(id)
	assert_bool(_system.get_rabbit(id) == null).is_true()


## AC-5: get_rabbits_in_hutch filters by hutch_id correctly.
func test_get_rabbits_in_hutch_filters_correctly() -> void:
	var a := RabbitData.new()
	a.hutch_id = "hutch-1"
	var b := RabbitData.new()
	b.hutch_id = "hutch-2"
	_system.add_rabbit(a)
	_system.add_rabbit(b)
	var result := _system.get_rabbits_in_hutch("hutch-1")
	assert_int(result.size()).is_equal(1)
	assert_bool(result[0] == a).is_true()


## AC-6: remove_rabbit with unknown id is a no-op — no error, roster stays empty.
func test_remove_rabbit_unknown_id_is_no_op() -> void:
	_system.remove_rabbit("phantom-id")
	assert_int(_system.get_all_rabbits().size()).is_equal(0)
