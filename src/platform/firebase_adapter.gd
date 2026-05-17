## FirebaseAdapter — abstract interface isolating Firebase SDK calls from SaveSystem (ADR-0008).
## SaveSystem depends on this interface, never on a concrete Firebase SDK class.
## Inject MockFirebaseAdapter in unit tests; GDFirebaseAdapter in production.
class_name FirebaseAdapter extends RefCounted

## Returns true if the current session has an authenticated Firebase user.
func is_signed_in() -> bool:
	return false


## Signs in anonymously. Returns true on success.
## Non-blocking in the concrete implementation — fire-and-forget at first boot.
func sign_in_anonymous() -> bool:
	return false


## Fetches the cloud save for the current user. Returns {} on failure or when offline.
## Async in the concrete implementation — SaveSystem awaits this at load time.
func fetch_save() -> Dictionary:
	return {}


## Pushes save data to Firebase Realtime DB. Fire-and-forget — SaveSystem does not await.
func push_save_async(data: Dictionary) -> void:
	pass


## Returns the current Firebase anonymous or linked UID. Empty string if not signed in.
func get_uid() -> String:
	return ""
