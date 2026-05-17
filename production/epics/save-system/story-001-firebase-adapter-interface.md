# Story 001: FirebaseAdapter Interface + MockFirebaseAdapter

> **Epic**: SaveSystem
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Blocked Reason

**BLOCKED: ADR-0008 is Proposed** — run `/architecture-decision retrofit docs/architecture/adr-0008-firebase-local-first-save.md` to promote it to Accepted.

ADR-0008 defines the `FirebaseAdapter` abstract interface contract and the `MockFirebaseAdapter` test double pattern. Until ADR-0008 is Accepted, the interface contract may still change.

---

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-save-001`, `TR-save-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: Firebase as Async-Optional Backend — Local-First Save
**ADR Decision Summary**: `FirebaseAdapter` is an abstract `RefCounted`-based interface isolating Firebase SDK calls from `SaveSystem`. `MockFirebaseAdapter` implements this interface for unit tests, returning canned data. `GDFirebaseAdapter` (concrete) is deferred until the Firebase SDK for Godot 4.6 is verified.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `@abstract` keyword is available in Godot 4.5+. `RefCounted` base class is stable. `GDFirebaseAdapter` implementation is deferred — Firebase SDK addon compatibility with Godot 4.6 must be verified at implementation time.

**Control Manifest Rules (Foundation layer)**:
- Forbidden: `calling_later_autoload_in_ready` — FirebaseAdapter is not an autoload; it is injected by SceneManager
- Firebase SDK must never be referenced in `save_system.gd` — only via `FirebaseAdapter` interface

---

## Acceptance Criteria

*From ADR-0008 FirebaseAdapter Interface section:*

- [ ] `class_name FirebaseAdapter extends RefCounted` exists at `src/platform/firebase_adapter.gd`
- [ ] `FirebaseAdapter` declares 5 abstract methods: `is_signed_in() -> bool`, `sign_in_anonymous() -> bool`, `fetch_save() -> Dictionary`, `push_save_async(data: Dictionary) -> void`, `get_uid() -> String`
- [ ] `class_name MockFirebaseAdapter extends FirebaseAdapter` exists at `src/platform/mock_firebase_adapter.gd`
- [ ] `MockFirebaseAdapter.fetch_save()` returns a configurable canned dictionary (settable by tests via `mock_save_data: Dictionary`)
- [ ] `MockFirebaseAdapter.is_signed_in()` returns a configurable bool (settable by tests via `mock_signed_in: bool`)
- [ ] `MockFirebaseAdapter.push_save_async()` records the last pushed data in `last_pushed: Dictionary`
- [ ] Both files instantiate in GdUnit4 tests without any scene or autoload dependencies
- [ ] GdUnit4: `MockFirebaseAdapter.fetch_save()` returns `mock_save_data` when set
- [ ] GdUnit4: `MockFirebaseAdapter.push_save_async()` stores data in `last_pushed`

---

## Implementation Notes

*Derived from ADR-0008 FirebaseAdapter Interface section:*

### Abstract interface

```gdscript
# src/platform/firebase_adapter.gd
class_name FirebaseAdapter extends RefCounted

func is_signed_in() -> bool:
    return false

func sign_in_anonymous() -> bool:
    return false

func fetch_save() -> Dictionary:
    return {}

func push_save_async(data: Dictionary) -> void:
    pass

func get_uid() -> String:
    return ""
```

Note: Godot 4.5+ supports `@abstract` keyword, but for testability, the base class provides safe no-op defaults. Subclasses override.

### MockFirebaseAdapter

```gdscript
# src/platform/mock_firebase_adapter.gd
class_name MockFirebaseAdapter extends FirebaseAdapter

var mock_signed_in: bool = true
var mock_save_data: Dictionary = {}
var last_pushed: Dictionary = {}

func is_signed_in() -> bool:
    return mock_signed_in

func fetch_save() -> Dictionary:
    return mock_save_data

func push_save_async(data: Dictionary) -> void:
    last_pushed = data

func get_uid() -> String:
    return "mock-uid-001"
```

### GDFirebaseAdapter (deferred)

`src/platform/gdfire_adapter.gd` is **not implemented in this story**. The concrete adapter wrapping the Firebase SDK is deferred until the SDK choice for Godot 4.6 is verified (REST vs addon). Create the file with a `TODO` stub only.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Local file read/write — SaveSystem I/O
- Story 003: GameState serialisation — `_populate_game_state()` / `_serialise_game_state()`
- Story 004: Conflict resolution — `_resolve_conflict()`
- Story 005: Boot sequence — `SaveSystem._ready()` wiring

---

## QA Test Cases

**AC-1 (fetch_save returns mock data)**:
- Given: `MockFirebaseAdapter` with `mock_save_data = {"last_save_timestamp": 12345}`
- When: `adapter.fetch_save()` called
- Then: returns `{"last_save_timestamp": 12345}`
- Edge cases: empty `mock_save_data` → returns `{}`

**AC-2 (push_save_async records data)**:
- Given: `MockFirebaseAdapter` with empty `last_pushed`
- When: `adapter.push_save_async({"prestige_count": 1})` called
- Then: `adapter.last_pushed == {"prestige_count": 1}`
- Edge cases: called twice → `last_pushed` holds the second call's data

**AC-3 (is_signed_in configurable)**:
- Given: `MockFirebaseAdapter` with `mock_signed_in = false`
- When: `adapter.is_signed_in()` called
- Then: returns `false`
- Edge cases: toggle `mock_signed_in = true` → subsequent call returns `true`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/save_system_adapter_test.gd` — must exist and pass

```
tests/unit/core/save_system_adapter_test.gd
  test_mock_adapter_fetch_returns_configured_data()
  test_mock_adapter_fetch_returns_empty_dict_by_default()
  test_mock_adapter_push_records_data_in_last_pushed()
  test_mock_adapter_push_overwrites_on_second_call()
  test_mock_adapter_is_signed_in_configurable()
  test_mock_adapter_get_uid_returns_mock_uid()
```

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **None** — FirebaseAdapter has no upstream story dependencies
- Unlocks: Story 002, Story 003, Story 004, Story 005 (all require MockFirebaseAdapter for tests)

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 9/9 passing
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/core/save_system_adapter_test.gd` (8 test functions)
**Code Review**: Skipped — Lean mode
