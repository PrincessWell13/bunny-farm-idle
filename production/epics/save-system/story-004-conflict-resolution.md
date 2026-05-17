# Story 004: Conflict Resolution — Local vs Cloud Timestamp

> **Epic**: SaveSystem
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Blocked Reason

**BLOCKED: ADR-0008 is Proposed** — run `/architecture-decision retrofit docs/architecture/adr-0008-firebase-local-first-save.md` to promote it to Accepted.

ADR-0008 defines the conflict resolution algorithm: compare `last_save_timestamp` between local and cloud saves; the higher timestamp wins. The exact fallback behaviour (empty dict, null, offline) is specified in the ADR.

---

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-save-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: Firebase as Async-Optional Backend — Local-First Save
**ADR Decision Summary**: `_resolve_conflict(local, cloud)` compares `last_save_timestamp` values. Empty local → cloud wins. Empty cloud → local wins. Both present → higher timestamp wins.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `Dictionary.is_empty()` is stable. `Dictionary.get(key, default)` is stable. No engine-specific APIs needed for the conflict logic itself.

**Control Manifest Rules (Foundation layer)**:
- `_resolve_conflict()` is a pure function — no GameState writes, no autoload calls, no I/O
- Forbidden: `calling_later_autoload_in_ready` — this method is called from `load_game()`, not from `_ready()`

---

## Acceptance Criteria

*From ADR-0008 Decision section `_resolve_conflict()`:*

- [ ] `func _resolve_conflict(local: Dictionary, cloud: Dictionary) -> Dictionary` exists on SaveSystem
- [ ] Empty local + non-empty cloud → returns cloud
- [ ] Non-empty local + empty cloud → returns local
- [ ] Both empty → returns `{}` (first boot)
- [ ] Local `last_save_timestamp` > cloud `last_save_timestamp` → returns local
- [ ] Cloud `last_save_timestamp` > local `last_save_timestamp` → returns cloud
- [ ] Equal timestamps → returns local (tie-break: local wins)
- [ ] GdUnit4: all 6 cases above tested

---

## Implementation Notes

*Derived from ADR-0008 `_resolve_conflict()` code in Decision section:*

```gdscript
func _resolve_conflict(local: Dictionary, cloud: Dictionary) -> Dictionary:
    if local.is_empty():
        return cloud
    if cloud.is_empty():
        return local
    var local_ts: int = local.get("last_save_timestamp", 0)
    var cloud_ts: int = cloud.get("last_save_timestamp", 0)
    return cloud if cloud_ts > local_ts else local
```

This function is **pure** — no side effects, no I/O, no autoload calls. It can be unit tested directly on an isolated `SaveSystem` instance.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `MockFirebaseAdapter` — provides the canned cloud data for tests
- Story 002: `_load_local()` — provides the local dict fed into `_resolve_conflict()`
- Story 005: `load_game()` — wires `_resolve_conflict()` into the boot sequence

---

## QA Test Cases

**AC-1 (empty local → cloud wins)**:
- Given: `local = {}`, `cloud = {"last_save_timestamp": 100}`
- When: `_resolve_conflict(local, cloud)`
- Then: returns `cloud`

**AC-2 (empty cloud → local wins)**:
- Given: `local = {"last_save_timestamp": 200}`, `cloud = {}`
- When: `_resolve_conflict(local, cloud)`
- Then: returns `local`

**AC-3 (both empty → empty)**:
- Given: `local = {}`, `cloud = {}`
- When: `_resolve_conflict(local, cloud)`
- Then: returns `{}`

**AC-4 (local newer → local wins)**:
- Given: `local = {"last_save_timestamp": 500}`, `cloud = {"last_save_timestamp": 300}`
- When: `_resolve_conflict(local, cloud)`
- Then: returns `local`

**AC-5 (cloud newer → cloud wins)**:
- Given: `local = {"last_save_timestamp": 300}`, `cloud = {"last_save_timestamp": 500}`
- When: `_resolve_conflict(local, cloud)`
- Then: returns `cloud`

**AC-6 (equal timestamps → local wins)**:
- Given: `local = {"last_save_timestamp": 400, "prestige_count": 2}`, `cloud = {"last_save_timestamp": 400, "prestige_count": 1}`
- When: `_resolve_conflict(local, cloud)`
- Then: returns `local` (prestige_count == 2)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/save_system_conflict_test.gd` — must exist and pass

```
tests/unit/core/save_system_conflict_test.gd
  test_empty_local_returns_cloud()
  test_empty_cloud_returns_local()
  test_both_empty_returns_empty()
  test_local_newer_returns_local()
  test_cloud_newer_returns_cloud()
  test_equal_timestamps_returns_local()
```

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **Story 001 DONE** (MockFirebaseAdapter for test setup)
- Unlocks: Story 005 (boot sequence uses `_resolve_conflict()` in `load_game()`)

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 7/7 passing
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/core/save_system_conflict_test.gd` (6 test functions)
**Code Review**: Skipped — Lean mode
