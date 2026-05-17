## MockFirebaseAdapter — test double for FirebaseAdapter (ADR-0008).
## Configure before use: set mock_save_data, mock_signed_in, then read last_pushed after calls.
## Instantiates without any scene tree or autoload dependencies.
class_name MockFirebaseAdapter extends FirebaseAdapter

## Set this before calling fetch_save() to control what the mock returns.
var mock_save_data: Dictionary = {}
## Set this to control what is_signed_in() returns.
var mock_signed_in: bool = true
## Holds the last data passed to push_save_async() — inspect in tests.
var last_pushed: Dictionary = {}


func is_signed_in() -> bool:
	return mock_signed_in


func sign_in_anonymous() -> bool:
	return true


func fetch_save() -> Dictionary:
	return mock_save_data


func push_save_async(data: Dictionary) -> void:
	last_pushed = data


func get_uid() -> String:
	return "mock-uid-001"
