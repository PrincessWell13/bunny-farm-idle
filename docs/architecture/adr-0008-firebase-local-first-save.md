# ADR-0008: Firebase as Async-Optional Backend — Local-First Save

## Status
Accepted

## Date
2026-05-16

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Platform |
| **Knowledge Risk** | MEDIUM — Firebase GDScript SDK options are post-cutoff; verify which addon approach is current |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | `FileAccess.store_string()` for save file (stable); `HTTPRequest` for Firebase REST API calls (stable). GDFirebase or Godot-Firebase addon compatibility with 4.6 must be verified before implementation. |
| **Verification Required** | (1) Confirm which Firebase GDScript addon is active for Godot 4.6 — GDFirebase (gdscript-firebase) or direct REST calls. (2) Confirm `user://savegame.json` is readable/writable in Android/iOS exports. (3) Confirm `HTTPRequest` async callbacks work in headless GdUnit4 test environment. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (SaveSystem is autoload #5; owns serialisation logic and Firebase sync queue; GameState is the data source), ADR-0002 (all serialised types are statically typed), ADR-0005 (RabbitData serialisation contract) |
| **Enables** | ADR-0011 (Guild boss raid — requires Firebase Realtime DB presence for async co-op scores) |
| **Blocks** | Any story implementing save/load, cloud sync, or cross-device progress until Accepted |
| **Ordering Note** | The FirebaseAdapter interface must be defined before Guild stories are written |

## Context

### Problem Statement
The game needs persistent save state that survives app kills (local) and device changes (cloud). The save must not block the app on launch — a slow or unavailable Firebase connection must never prevent the player from playing. Firebase is required for the Guild system (async multiplayer co-op) and cross-device progress, but the game must be fully playable with no internet connection.

### Constraints
- ADR-0001 fixed autoloads at 6 — no new autoload for Firebase. `FirebaseAdapter` is injected into SaveSystem, not an autoload.
- SaveSystem is autoload #5 — it loads before the first scene, so Firebase sync must be async (non-blocking)
- Local-first is a hard requirement: game must launch and play without network
- All save data is plain JSON (consistent with balance.json approach — human-readable, diff-friendly)
- Maximum 6 autoloads: Firebase API surface is isolated behind a `FirebaseAdapter` interface

### Requirements
- Must persist full `GameState` to `user://savegame.json` without network dependency
- Must sync `savegame.json` contents to Firebase Realtime DB when network is available
- Firebase sync must be non-blocking — any network delay or error must not pause the main thread
- Conflict resolution: when loading, local and cloud saves are compared by `last_save_timestamp`; the newer one wins
- Must support anonymous play (no account) with optional Google/Apple account linking
- Must isolate Firebase API behind an interface so SaveSystem unit tests run without Firebase

## Decision

**Local `user://savegame.json` is the authoritative save.** Firebase is a sync target, not the primary store. SaveSystem reads from and writes to the local file on every save operation. Firebase sync is a best-effort background operation performed after the local write completes.

### Save File Architecture

```
user://savegame.json        ← authoritative, always present after first save
Firebase Realtime DB        ← sync target; /users/{uid}/savegame (same JSON schema)
                               updated after every successful local save when online
```

### Save Format

`savegame.json` is the JSON serialisation of `GameState`. Schema:

```json
{
  "_version": 1,
  "_comment": "Bunny Farm Idle save file. Do not edit manually.",
  "last_save_timestamp": 1747439600,
  "prestige_count": 0,
  "rabbits": [ { ...RabbitData fields... } ],
  "hutches": [ { ...HutchData fields... } ],
  "collection_registry": { "white": true, "brown": false },
  "active_expeditions": [],
  "economy": {
    "carrot_coin": 1250,
    "star_dust": 3,
    "crystal_gem": 0,
    "gene_fragment": 12
  },
  "settings": {
    "font_scale": 1.0,
    "colorblind_mode": 0,
    "simplified_mode": false,
    "dark_mode": false
  }
}
```

Version field enables future migration: if `_version` < current schema version, `SaveSystem` runs a migration function before populating `GameState`.

### SaveSystem Responsibilities

```gdscript
# src/core/save_system.gd
class_name SaveSystem extends Node

const SAVE_PATH: String = "user://savegame.json"
const SAVE_INTERVAL_SECONDS: float = 30.0

var _firebase: FirebaseAdapter = null  # injected; null in unit tests

func _ready() -> void:
    _load_balance_data()
    load_game()
    _start_auto_save_timer()

func load_game() -> void:
    var local_data: Dictionary = _load_local()
    var cloud_data: Dictionary = {}
    if _firebase != null and _firebase.is_signed_in():
        cloud_data = await _firebase.fetch_save()  # async — may be empty if offline

    var save_data: Dictionary = _resolve_conflict(local_data, cloud_data)
    _populate_game_state(save_data)
    TimeManager.mark_session_start()
    IdleProductionSystem.calculate_offline_earnings.call_deferred(
        TimeManager.get_offline_delta(), TimeManager.was_backgrounded())

func save_game() -> void:
    var data: Dictionary = _serialise_game_state()
    data["last_save_timestamp"] = int(Time.get_unix_time_from_system())
    _write_local(data)
    GameState.is_dirty = false  # direct write permitted here — SaveSystem is the owner of save state
    if _firebase != null and _firebase.is_signed_in():
        _firebase.push_save_async(data)  # fire-and-forget; does not await

func _resolve_conflict(local: Dictionary, cloud: Dictionary) -> Dictionary:
    if local.is_empty():
        return cloud
    if cloud.is_empty():
        return local
    var local_ts: int = local.get("last_save_timestamp", 0)
    var cloud_ts: int = cloud.get("last_save_timestamp", 0)
    return cloud if cloud_ts > local_ts else local
```

### FirebaseAdapter Interface

`SaveSystem` depends on a `FirebaseAdapter` interface, not a concrete Firebase SDK class. This allows unit tests to inject a `MockFirebaseAdapter` that returns canned data.

```gdscript
# src/platform/firebase_adapter.gd
@abstract
class_name FirebaseAdapter extends RefCounted

@abstract func is_signed_in() -> bool: pass
@abstract func sign_in_anonymous() -> bool: pass
@abstract func fetch_save() -> Dictionary: pass  # async; returns {} on failure
@abstract func push_save_async(data: Dictionary) -> void: pass
@abstract func get_uid() -> String: pass
```

The concrete implementation (`GDFirebaseAdapter`) is in `src/platform/` and wraps the Firebase GDScript addon. It is instantiated and injected into SaveSystem from a bootstrap call in `SceneManager._ready()` (last autoload — all data already loaded).

### Authentication Flow

```
App launch (first time)
    ↓
SaveSystem.load_game() — loads local file if it exists
    ↓
SceneManager._ready() — injects GDFirebaseAdapter into SaveSystem
    ↓
GDFirebaseAdapter.sign_in_anonymous() — silent, no UI shown
    ↓
SaveSystem starts syncing to Firebase under anonymous UID
    ↓
Player opts in to Google/Apple account link (in Settings screen)
    ↓
Firebase anonymous account linked to Google/Apple UID
    ↓
All future saves use linked UID — cloud save preserved across device installs
```

Anonymous UID is stored locally so saves are attributed consistently even without linking.

### Error Handling

| Scenario | Behaviour |
|----------|-----------|
| Local file missing | `GameState` initialised to defaults; `EventBus.new_game_started` emitted |
| Local file corrupted | `push_error()`; fall through to defaults; `EventBus.new_game_started` emitted |
| Firebase offline at load | Cloud data = `{}`; local file wins; sync attempted on next save |
| Firebase push fails | Logged to `push_warning()`; retry queued for next auto-save interval |
| Cloud newer than local | Cloud wins; local file overwritten with cloud data |
| `_version` mismatch | Migration function runs before `_populate_game_state()` |

### Architecture Diagram

```
App launch
    │
    ▼
SaveSystem._ready()
    ├──► _load_local() → user://savegame.json
    ├──► _firebase.fetch_save() [async, non-blocking]
    ├──► _resolve_conflict() → best save data
    ├──► _populate_game_state() → GameState
    └──► TimeManager.mark_session_start() + offline catch-up

Every 30s / on background:
    │
    ▼
SaveSystem.save_game()
    ├──► _serialise_game_state()
    ├──► _write_local(data) [synchronous, <5ms for 50KB]
    └──► _firebase.push_save_async(data) [fire-and-forget]
```

## Alternatives Considered

### Alternative B: Firebase as primary store, local as cache only
- **Description**: GameState is loaded from Firebase on every launch; local file is only a fallback.
- **Pros**: Cross-device sync is always current; single source of truth.
- **Cons**: Network required at launch — any connection failure blocks the player from accessing their game. Mobile idle games frequently launch in areas with poor signal. This is an unacceptable dependency.
- **Rejection Reason**: "Local-first, cloud-optional" is Architecture Principle #1. Network must never be required to play.

### Alternative C: Godot's built-in `ConfigFile` / `ResourceSaver`
- **Description**: Use `ConfigFile` for settings and `ResourceSaver.save()` for game state.
- **Pros**: Native Godot API; no manual JSON serialisation.
- **Cons**: `ResourceSaver` produces `.tres` files — binary or verbose XML, not human-readable or diff-friendly. `ConfigFile` does not handle nested data well. Neither integrates naturally with Firebase JSON sync.
- **Rejection Reason**: JSON is the lingua franca for Firebase. Using JSON everywhere (balance.json, savegame.json, Firebase) minimises serialisation surface and keeps saves human-readable and debuggable.

### Alternative D: GDFirebase addon (full SDK)
- **Description**: Use the full GDFirebase GDScript addon (Auth, Realtime DB, Firestore, etc.).
- **Pros**: Full Firebase feature coverage from GDScript.
- **Cons**: Addon compatibility with Godot 4.6 must be verified. Adds an uncontrolled dependency — addon updates can break the project. Only Auth + Realtime DB are needed (not Firestore or other services).
- **Tradeoff vs direct REST**: Direct REST calls via `HTTPRequest` have zero addon dependency risk. The FirebaseAdapter abstraction makes swapping the implementation trivial. Chosen approach: FirebaseAdapter wraps whichever SDK or REST approach is verified for 4.6 at implementation time.
- **Rejection Reason for full-SDK commitment**: Defer SDK choice to implementation — the Architecture Decision is the local-first pattern and FirebaseAdapter interface, not which specific SDK version to use.

## Consequences

### Positive
- Game is fully playable offline — no network dependency for any core gameplay
- Firebase sync is transparent to the player — happens in the background
- FirebaseAdapter interface makes SaveSystem unit-testable without Firebase SDK
- Conflict resolution is simple and correct for solo-player save (latest timestamp wins)
- JSON save format matches Firebase's native format — no serialisation translation needed

### Negative
- Two save locations (local + cloud) can diverge — conflict resolution must handle edge cases (e.g., player plays on two devices simultaneously)
- Concurrent two-device play is not supported — last writer wins, so simultaneous play on two devices may lose one session's progress
- Firebase SDK addon compatibility with Godot 4.6 must be verified at implementation time (marked as VERIFICATION REQUIRED)
- Anonymous auth means no password recovery — if local file is lost and Firebase UID is not linked to a Google/Apple account, progress cannot be restored

### Risks
- **Risk**: Firebase addon incompatible with Godot 4.6 export on Android/iOS.
  - **Mitigation**: FirebaseAdapter abstraction allows swapping to direct REST API (`HTTPRequest`) at any time without changing SaveSystem. REST endpoint for Realtime DB is `https://[project].firebaseio.com/users/{uid}/savegame.json` — standard HTTP PUT/GET.
- **Risk**: Save file grows beyond 50KB as rabbit count and collection expand.
  - **Mitigation**: Audit save file size at Alpha with max populated state (24 rabbits, full collection). If >100KB, evaluate whether `active_expeditions` and `collection_registry` can be compressed or pruned.

## GDD Requirements Addressed

| GDD Req ID | GDD Section | Requirement | How This ADR Addresses It |
|------------|-------------|-------------|--------------------------|
| TR-save-001 | §5 (tech stack) | Full game state serialisation/deserialisation | SaveSystem serialises GameState to/from `user://savegame.json` on every save/load |
| TR-save-002 | §5 | Cloud backup / cross-device progress | Firebase Realtime DB sync after every local save; latest timestamp conflict resolution |
| TR-save-003 | §5 | Local save survives no-network launch | Local file is primary; Firebase is sync target; game launches from local file unconditionally |
| TR-guild-001 | §3.9 | Guild requires multiplayer backend | FirebaseAdapter provides the Auth + Realtime DB surface needed by GuildSystem (ADR-0011) |

## Performance Implications
- **CPU**: `JSON.stringify()` on a 50KB save dictionary ≈ 1–3ms. `FileAccess.store_string()` for 50KB ≈ 2–5ms. Total local save ≈ 5–8ms — acceptable for a 30-second interval trigger.
- **Memory**: One `Dictionary` copy of GameState in memory during serialisation — freed after write. ~2MB peak. Within mobile budget.
- **Load Time**: Local file read ≈ 1–3ms. Firebase async fetch does not block — runs in parallel. Net boot overhead: <5ms.
- **Network**: Firebase push is fire-and-forget via `HTTPRequest`. No main-thread blocking. Firebase fetch at load is awaited — but only after local file loads, so game state is populated regardless.

## Migration Plan
Greenfield — create `src/platform/firebase_adapter.gd` (abstract), `src/platform/gdfire_adapter.gd` (concrete — implementation deferred until Firebase SDK choice is verified for Godot 4.6), and `src/platform/mock_firebase_adapter.gd` (for unit tests). Update `SaveSystem._ready()` in `src/core/save_system.gd` to accept injected adapter.

## Validation Criteria
- [ ] GdUnit4 test: `SaveSystem` with `MockFirebaseAdapter` loads a known JSON fixture and populates GameState correctly
- [ ] GdUnit4 test: When local and cloud saves conflict, cloud timestamp > local timestamp → cloud wins
- [ ] GdUnit4 test: When local and cloud saves conflict, local timestamp > cloud timestamp → local wins
- [ ] GdUnit4 test: Corrupted local file → `push_error()` emitted; `GameState` initialised to defaults; no crash
- [ ] GdUnit4 test: `save_game()` produces JSON parseable by `JSON.parse_string()`
- [ ] Manual test: Delete `user://savegame.json`, launch game offline → new game starts, no crash
- [ ] Manual test: Save game → force-close app → relaunch → saved state restored from local file

## Related Decisions
- ADR-0001: SaveSystem is autoload #5; `mark_session_start()` called here; offline catch-up triggered here
- ADR-0002: All serialised data statically typed — no untyped Dictionary fields in `_populate_game_state()`
- ADR-0005: `_rabbit_to_dict()` / `_dict_to_rabbit()` serialisation contract defined in ADR-0005
- ADR-0011 (pending): Guild boss raid — FirebaseAdapter extended with guild-specific methods
- `docs/architecture/architecture.md` — Principle #1: "Local-first, cloud-optional"
