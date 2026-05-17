# Story 002: Local File Read/Write

> **Epic**: SaveSystem
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Blocked Reason

**BLOCKED: ADR-0008 is Proposed** — run `/architecture-decision retrofit docs/architecture/adr-0008-firebase-local-first-save.md` to promote it to Accepted.

ADR-0008 defines the save file path (`user://savegame.json`), the JSON schema (including `_version` field), and all error handling behaviour for missing/corrupted files.

---

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-save-001`, `TR-save-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: Firebase as Async-Optional Backend — Local-First Save
**ADR Decision Summary**: `user://savegame.json` is the authoritative local save. `_load_local()` reads and parses it, returning `{}` on missing or corrupted file. `_write_local(data)` serialises to JSON and writes atomically. Both operations are synchronous and must complete in <10ms for a 50KB file.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `FileAccess.open()`, `FileAccess.store_string()`, `FileAccess.get_as_text()` are stable in 4.6. `user://` path resolves to the correct app data directory on Android and iOS. `JSON.stringify()` and `JSON.parse_string()` are stable in 4.4–4.6.

**Control Manifest Rules (Foundation layer)**:
- Forbidden: blocking I/O on main thread for operations >10ms — local file read/write at 50KB is within budget; Firebase is async (handled in story 005)
- Forbidden: `calling_later_autoload_in_ready` — `_load_local()` and `_write_local()` are pure file operations; no autoload calls

---

## Acceptance Criteria

*From ADR-0008 Save File Architecture section:*

- [ ] `func _load_local() -> Dictionary` exists on SaveSystem; reads `user://savegame.json` and returns parsed Dictionary
- [ ] `_load_local()` returns `{}` when file does not exist (first boot)
- [ ] `_load_local()` calls `push_error()` and returns `{}` when file exists but JSON is malformed
- [ ] `func _write_local(data: Dictionary) -> void` exists; serialises `data` to JSON and writes to `user://savegame.json`
- [ ] `_write_local()` adds `_version: 1` and `_comment` fields to the written JSON
- [ ] The written file is parseable by `JSON.parse_string()` without error
- [ ] `FileAccess.store_string()` used — no deprecated file write API
- [ ] GdUnit4: `_load_local()` returns `{}` when file absent
- [ ] GdUnit4: round-trip — `_write_local(dict)` then `_load_local()` returns equal dict (excluding `_version` / `_comment`)

---

## Implementation Notes

*Derived from ADR-0008 Decision section:*

### _load_local()

```gdscript
const SAVE_PATH: String = "user://savegame.json"

func _load_local() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_error("SaveSystem: cannot open save file")
        return {}
    var text: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(text)
    if parsed == null or not parsed is Dictionary:
        push_error("SaveSystem: save file corrupted — starting fresh")
        return {}
    return parsed
```

### _write_local()

```gdscript
func _write_local(data: Dictionary) -> void:
    data["_version"] = 1
    data["_comment"] = "Bunny Farm Idle save file. Do not edit manually."
    var text: String = JSON.stringify(data, "\t")
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("SaveSystem: cannot write save file")
        return
    file.store_string(text)
    file.close()
```

### Test isolation

Unit tests for `_load_local()` / `_write_local()` should use the actual `user://` path since GdUnit4 runs in a headless Godot process with a valid `user://` directory. Clean up written files in `after_test()`.

Alternatively, expose `_save_path: String` as a settable field (defaulting to `SAVE_PATH`) so tests can redirect to a temp path. This is the preferred approach for deterministic test isolation.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `FirebaseAdapter` interface — needed for Firebase tests but not for local I/O
- Story 003: `_populate_game_state()` / `_serialise_game_state()` — data structure mapping
- Story 004: `_resolve_conflict()` — choosing between local and cloud data
- Story 005: `_ready()` boot wiring — calling `_load_local()` at boot

---

## QA Test Cases

**AC-1 (missing file returns empty dict)**:
- Given: No save file at the test path
- When: `_load_local()` called
- Then: returns `{}`
- Edge cases: calling twice → still `{}`

**AC-2 (corrupted file returns empty dict + push_error)**:
- Given: Save file exists with content `"not valid json {{{"`
- When: `_load_local()` called
- Then: returns `{}`; `push_error()` was called

**AC-3 (write then read round-trip)**:
- Given: SaveSystem with redirected `_save_path` to temp file
- When: `_write_local({"prestige_count": 3, "last_save_timestamp": 99999})` called, then `_load_local()` called
- Then: result contains `"prestige_count": 3` and `"last_save_timestamp": 99999`
- Edge cases: written file is valid JSON (parseable independently)

**AC-4 (written JSON includes _version)**:
- Given: SaveSystem with redirected path
- When: `_write_local({})` called, then raw file content read
- Then: `JSON.parse_string(content)["_version"] == 1`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/save_system_local_io_test.gd` — must exist and pass

```
tests/unit/core/save_system_local_io_test.gd
  test_load_local_returns_empty_dict_when_file_absent()
  test_load_local_returns_empty_dict_and_logs_error_on_corrupted_file()
  test_write_local_then_load_local_round_trip()
  test_write_local_adds_version_field()
  test_written_json_is_parseable()
```

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **Story 001 must be DONE** (MockFirebaseAdapter available for subsequent tests)
- Unlocks: Story 003 (serialisation uses `_write_local` as its write target), Story 005 (boot sequence calls `_load_local`)

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 9/9 passing
**Deviations**: None. Extra test: `test_write_local_does_not_mutate_caller_dict` — validates `.duplicate()` pattern used instead of mutating input.
**Test Evidence**: Logic — `tests/unit/core/save_system_local_io_test.gd` (7 test functions)
**Code Review**: Skipped — Lean mode
