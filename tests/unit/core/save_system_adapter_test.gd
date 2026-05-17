## Unit tests for FirebaseAdapter interface and MockFirebaseAdapter — Story 001.
## Verifies MockFirebaseAdapter is a complete, configurable test double.
extends GdUnitTestSuite

var _adapter: MockFirebaseAdapter


func before_test() -> void:
	_adapter = MockFirebaseAdapter.new()


func after_test() -> void:
	_adapter = null


## AC-1: fetch_save() returns the configured mock_save_data.
func test_mock_adapter_fetch_returns_configured_data() -> void:
	_adapter.mock_save_data = {"last_save_timestamp": 12345, "prestige_count": 2}
	var result: Dictionary = _adapter.fetch_save()
	assert_int(result["last_save_timestamp"]).is_equal(12345)
	assert_int(result["prestige_count"]).is_equal(2)


## AC-1 edge: fetch_save() returns {} when mock_save_data not set.
func test_mock_adapter_fetch_returns_empty_dict_by_default() -> void:
	var result: Dictionary = _adapter.fetch_save()
	assert_bool(result.is_empty()).is_true()


## AC-2: push_save_async() records the pushed data in last_pushed.
func test_mock_adapter_push_records_data_in_last_pushed() -> void:
	_adapter.push_save_async({"prestige_count": 1, "carrot_coin": 500})
	assert_int(_adapter.last_pushed["prestige_count"]).is_equal(1)
	assert_int(_adapter.last_pushed["carrot_coin"]).is_equal(500)


## AC-2 edge: second push overwrites last_pushed with new data.
func test_mock_adapter_push_overwrites_on_second_call() -> void:
	_adapter.push_save_async({"prestige_count": 1})
	_adapter.push_save_async({"prestige_count": 3})
	assert_int(_adapter.last_pushed["prestige_count"]).is_equal(3)
	assert_bool(_adapter.last_pushed.has("carrot_coin")).is_false()


## AC-3: is_signed_in() returns the configured mock_signed_in value.
func test_mock_adapter_is_signed_in_configurable() -> void:
	_adapter.mock_signed_in = false
	assert_bool(_adapter.is_signed_in()).is_false()
	_adapter.mock_signed_in = true
	assert_bool(_adapter.is_signed_in()).is_true()


## get_uid() returns the fixed mock UID string.
func test_mock_adapter_get_uid_returns_mock_uid() -> void:
	assert_str(_adapter.get_uid()).is_equal("mock-uid-001")


## MockFirebaseAdapter is a FirebaseAdapter (interface contract satisfied).
func test_mock_adapter_is_firebase_adapter() -> void:
	assert_bool(_adapter is FirebaseAdapter).is_true()


## FirebaseAdapter base class safe defaults: is_signed_in false, fetch_save empty.
func test_base_adapter_safe_defaults() -> void:
	var base := FirebaseAdapter.new()
	assert_bool(base.is_signed_in()).is_false()
	assert_bool(base.fetch_save().is_empty()).is_true()
	assert_str(base.get_uid()).is_equal("")
