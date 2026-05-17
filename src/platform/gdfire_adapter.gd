## GDFirebaseAdapter — concrete FirebaseAdapter wrapping the Firebase GDScript SDK (ADR-0008).
## TODO: Implement after Firebase SDK compatibility with Godot 4.6 is verified.
## Options: GDFirebase addon (gdscript-firebase) or direct HTTPRequest REST calls.
## REST endpoint: https://[project].firebaseio.com/users/{uid}/savegame.json
class_name GDFirebaseAdapter extends FirebaseAdapter

## TODO: Implement all 5 abstract methods once SDK choice is confirmed.
## See ADR-0008 Alternative D for the REST vs addon tradeoff analysis.
