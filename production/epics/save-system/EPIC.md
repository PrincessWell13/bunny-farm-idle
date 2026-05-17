# Epic: SaveSystem

> **Layer**: Foundation
> **GDD**: design/gdd/bunny-farm-idle-master.md
> **Architecture Module**: `src/core/save_system.gd` + `src/platform/firebase_adapter.gd` + `src/platform/mock_firebase_adapter.gd`
> **Status**: Ready
> **Control Manifest Version**: pending — run `/create-control-manifest` to assign
> **Stories**: 5 stories — all Ready (ADR-0008 Accepted 2026-05-17)

## Overview

SaveSystem owns serialisation, the local save file, and the Firebase sync queue. It is autoload #5 — after GameState is allocated. At boot, it reads `user://savegame.json`, optionally fetches a cloud save from Firebase, resolves any conflict by timestamp, then populates GameState and triggers offline catch-up. Every 30 seconds and on app background, it re-serialises GameState to disk and fires off a non-blocking Firebase push. SaveSystem depends on `FirebaseAdapter` — an abstract interface injected by SceneManager after boot, ensuring SaveSystem is unit-testable without any SDK.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | SaveSystem is autoload #5; calls `load_game()` in `_ready()`; triggers offline catch-up via `call_deferred` | LOW |
| ADR-0005: RabbitData Resource | `_rabbit_to_dict()` / `_dict_to_rabbit()` serialisation contract | LOW |
| ADR-0008: Firebase Local-First Save | `user://savegame.json` is authoritative; Firebase is async sync target; latest-timestamp conflict resolution; FirebaseAdapter interface | MEDIUM (Firebase SDK addon for 4.6 must be verified) |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-save-001 | Full game state serialisation/deserialisation | ADR-0001 ✅, ADR-0008 ✅ |
| TR-save-002 | Cloud backup / cross-device progress | ADR-0008 ✅ |
| TR-save-003 | Local save survives no-network launch | ADR-0008 ✅ |
| TR-guild-001 | Guild requires multiplayer backend | ADR-0008 ✅ (FirebaseAdapter surface) |

## Key Interfaces

```gdscript
class_name SaveSystem extends Node

const SAVE_PATH: String = "user://savegame.json"
const SAVE_INTERVAL_SECONDS: float = 30.0

var _firebase: FirebaseAdapter = null  # injected post-boot; null in tests

func load_game() -> void          # reads local + cloud; populates GameState
func save_game() -> void          # writes local; async push to Firebase
func inject_firebase(adapter: FirebaseAdapter) -> void  # called by SceneManager
```

```gdscript
@abstract
class_name FirebaseAdapter extends RefCounted

@abstract func is_signed_in() -> bool: pass
@abstract func sign_in_anonymous() -> bool: pass
@abstract func fetch_save() -> Dictionary: pass
@abstract func push_save_async(data: Dictionary) -> void: pass
@abstract func get_uid() -> String: pass
```

## Forbidden Patterns (from Architecture Registry)

- `calling_later_autoload_in_ready` — SaveSystem (autoload #5) must not call SceneManager (autoload #6) in `_ready()`
- Firebase SDK must never be referenced directly in `save_system.gd` — only via `FirebaseAdapter` interface

## Engine Verification Required

- `user://savegame.json` readable/writable in Android/iOS exports
- `FileAccess.store_string()` — stable in 4.6
- Firebase GDScript addon compatibility with Godot 4.6 — must be confirmed before implementing `GDFirebaseAdapter`

## Definition of Done

This epic is complete when:
- [ ] All stories are implemented, reviewed, and closed via `/story-done`
- [ ] `SaveSystem` autoload registered as #5 in Godot Project Settings
- [ ] Round-trip test: serialise full GameState → write to file → read back → all fields match
- [ ] Conflict resolution test: cloud timestamp > local → cloud wins (GdUnit4 with MockFirebaseAdapter)
- [ ] Corrupted local file test: `push_error()` emitted; game starts with defaults; no crash
- [ ] Manual test: Delete save file, launch offline → new game starts
- [ ] `MockFirebaseAdapter` used in all GdUnit4 tests — no real Firebase calls in CI

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [FirebaseAdapter interface + MockFirebaseAdapter](story-001-firebase-adapter-interface.md) | Logic | Blocked | ADR-0008 |
| 002 | [Local file read/write](story-002-local-file-io.md) | Logic | Blocked | ADR-0001 + ADR-0008 |
| 003 | [GameState serialise/deserialise round-trip](story-003-gamestate-serialisation.md) | Integration | Blocked | ADR-0001 + ADR-0005 + ADR-0008 |
| 004 | [Conflict resolution — local vs cloud timestamp](story-004-conflict-resolution.md) | Logic | Blocked | ADR-0008 |
| 005 | [Boot integration + auto-save timer](story-005-boot-integration-autosave.md) | Integration | Blocked | ADR-0001 + ADR-0008 |

## Next Step

Promote ADR-0008 to Accepted: run `/architecture-decision retrofit docs/architecture/adr-0008-firebase-local-first-save.md`
Then promote ADR-0005 (needed for story 003): run `/architecture-decision retrofit docs/architecture/adr-0005-rabbitdata-resource.md`
Then run `/dev-story production/epics/save-system/story-001-firebase-adapter-interface.md`.
