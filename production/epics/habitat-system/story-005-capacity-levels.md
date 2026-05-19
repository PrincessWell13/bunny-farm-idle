# Story 005: get_capacity() — Level-Based Hutch Slot Count

> **Epic**: HabitatSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.4 Habitat System)
**Requirement**: `TR-habitat-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0010 Accepted ✅, ADR-0004 Accepted ✅

**ADR Governing Implementation**: ADR-0010: HabitatSystem Hutch Ownership and Rabbit Assignment Model; ADR-0004: JSON Balance Data — No Hardcoded Values
**ADR Decision Summary**: `get_capacity(hutch_id)` returns the maximum rabbit slot count for a hutch by looking up `hutch.level` in the `balance.json` array `habitat.capacity_by_level`. Level 1 yields 4 slots; the maximum level yields 24 slots. Upgrading a hutch level (incrementing `hutch.level`) increases capacity without evicting current occupants.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Array` index access by integer key is stable. No post-cutoff APIs used.

**Control Manifest Rules (Core layer)**:
- Required: Capacity values loaded from `balance.json` at `_ready()` — never hardcoded (F-04)
- Required: Return type explicitly declared as `int` (F-02)
- Required: Safe fallback if `hutch_id` not found — return `0` with a `push_warning()`
- Forbidden: Hardcoded slot count literals (`4`, `24`, etc.) in `src/` (F-04)
- Forbidden: Evicting occupants when a hutch is upgraded — existing occupants are preserved

---

## Acceptance Criteria

1. `get_capacity(hutch_id: String) -> int` implemented on `HabitatSystem`
2. `_capacity_table: Array` is loaded from `balance.json` key `habitat.capacity_by_level` in `_load_balance_data()` — it is an Array where index `0` corresponds to level 1, index `1` to level 2, etc.
3. `get_capacity()` returns `_capacity_table[hutch.level - 1]` for the matching hutch
4. A level-1 hutch returns `4` (value from `balance.json` index 0)
5. A max-level hutch returns `24` (value from `balance.json` final index)
6. If `hutch_id` is not found in `GameState.hutches`, return `0` and call `push_warning()`
7. If `hutch.level` would produce an out-of-bounds index into `_capacity_table`, return the last valid value (the max capacity) and call `push_warning()` — do not crash
8. If `balance.json` is missing `habitat.capacity_by_level` at boot, `push_error()` is called and `_capacity_table` falls back to a single-entry array `[4]` (minimum viable capacity)
9. Upgrading a hutch's level (setting `hutch.level += 1`) does not evict any current occupants — `occupants` array is untouched by the capacity change
10. `get_capacity()` does not modify any state — it is a pure read
11. No capacity literal appears in `habitat_system.gd` — all values are read from `_capacity_table`

---

## Implementation Notes

*Derived from ADR-0010:*

The capacity lookup per ADR-0010:
```gdscript
func get_capacity(hutch_id: String) -> int:
    var hutch: HutchData = _find_hutch(hutch_id)
    if hutch == null:
        push_warning("HabitatSystem.get_capacity: hutch_id '%s' not found" % hutch_id)
        return 0
    var index: int = hutch.level - 1
    if index < 0 or index >= _capacity_table.size():
        push_warning("HabitatSystem.get_capacity: level %d out of range for hutch '%s'" % [hutch.level, hutch_id])
        return _capacity_table[_capacity_table.size() - 1] as int
    return _capacity_table[index] as int
```

The `balance.json` schema for capacity (ADR-0010 reference — level count and exact values are tunable):
```json
"habitat": {
    "capacity_by_level": [4, 6, 8, 12, 16, 24]
}
```

Index mapping: `capacity_by_level[0]` = level 1 capacity, `capacity_by_level[1]` = level 2 capacity, etc. The number of entries in the array implicitly defines the maximum hutch level. This is intentional — no separate `max_level` constant is needed.

`get_capacity()` is consumed by `assign_rabbit()` (Story 002) to enforce the slot cap. If Story 002 is implemented before this story, it should use a stub or inline fallback capacity; once this story merges, the stub is replaced with the real call.

The `_find_hutch(hutch_id: String) -> HutchData` helper introduced in Story 004 is reused here. If Story 004 is not yet merged, declare this helper in this story and Story 004 will use it too. Avoid duplicating the implementation — coordinate with whoever implements Story 004 first.

Hutch level upgrades are a future feature (a separate story in a later sprint — `hutch_upgraded` EventBus signal already exists in the signal registry). This story only needs to guarantee that `get_capacity()` reads the correct tier for any level value, and that setting `hutch.level` to a higher integer has no destructive side effect on `occupants`. No "upgrade" method is implemented here.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `HutchData` schema (`level: int` field is defined there)
- Story 002: `assign_rabbit()` calls `get_capacity()` but does not define it
- Story 003: Cleanliness decay — unrelated to capacity
- Story 004: `get_hutch_bonuses()` — unrelated to capacity
- Future sprint: hutch upgrade flow (spending coins to increment `hutch.level`)

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC-4**: Level-1 hutch returns 4
  - Given: a `HutchData` with `level = 1`; `balance.json` `capacity_by_level[0] = 4`
  - When: `HabitatSystem.get_capacity("h1")`
  - Then: returns `4`

- **AC-5**: Max-level hutch returns 24
  - Given: a `HutchData` with `level` equal to the last index in `capacity_by_level`; that entry = `24`
  - When: `HabitatSystem.get_capacity("h1")`
  - Then: returns `24`

- **AC-6**: Unknown hutch_id returns 0
  - Given: `GameState.hutches` has no hutch with `hutch_id = "unknown"`
  - When: `HabitatSystem.get_capacity("unknown")`
  - Then: returns `0`; `push_warning()` called

- **AC-7**: Out-of-bounds level returns max capacity
  - Given: a `HutchData` with `level = 999` (far beyond table length)
  - When: `HabitatSystem.get_capacity("h1")`
  - Then: returns the last value in `_capacity_table`; `push_warning()` called; no crash

- **AC-8**: Missing balance.json key falls back to [4]
  - Given: `balance.json` has no `habitat.capacity_by_level` key
  - When: `HabitatSystem._ready()` calls `_load_balance_data()`
  - Then: `push_error()` logged; `get_capacity()` returns `4` for any level-1 hutch

- **AC-9**: Increasing hutch level preserves occupants
  - Given: a `HutchData` with `level = 1`, `occupants = ["r1", "r2"]`
  - When: `hutch.level = 2` (simulating an upgrade)
  - Then: `hutch.occupants` still contains `["r1", "r2"]`; `get_capacity("h1")` now returns `capacity_by_level[1]`

- **AC-10**: No state mutation
  - Given: a `HutchData` with `level = 2`
  - When: `HabitatSystem.get_capacity("h1")` called 3 times
  - Then: `hutch.level` is still `2` after all three calls

- **AC-11**: No literals in implementation
  - Given: parse `src/core/habitat_system.gd`
  - When: inspect `get_capacity()` function body
  - Then: no numeric literals for slot counts appear — only `_capacity_table` index references

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/habitat_system_capacity_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/habitat_system_capacity_test.gd` — 8 test functions

---

## Dependencies

- Depends on: Story 001 (HutchData schema — `level: int` field must exist)
- Unlocks: Story 002 end-to-end capacity enforcement (assign_rabbit capacity check becomes fully functional)

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 11/11 passing
**Deviations**:
- ADVISORY: `capacity_by_level` in balance.json was seeded as a Dict `{"1":4,...}` by story-003; corrected to Array `[4, 8, 12, 16, 20, 24]` to match Array-index lookup required by ADR-0010.
- ADVISORY: `_capacity_table: Array = [4]` GDScript-side fallback default at declaration — consistent with fallback pattern used in stories 003 and 004.
**Test Evidence**: Logic — `tests/unit/core/habitat_system_capacity_test.gd` (8 functions) ✅
**Code Review**: Skipped — Lean mode
