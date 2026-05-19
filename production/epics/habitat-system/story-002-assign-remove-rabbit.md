# Story 002: assign_rabbit() / remove_rabbit() API

> **Epic**: HabitatSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.4 Habitat System)
**Requirement**: `TR-habitat-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0010 Accepted ✅, ADR-0003 Accepted ✅

**ADR Governing Implementation**: ADR-0010: HabitatSystem Hutch Ownership and Rabbit Assignment Model; ADR-0003: Signal-Based Inter-System Communication via EventBus
**ADR Decision Summary**: `HabitatSystem` is the exclusive writer to `HutchData.occupants`. `assign_rabbit(rabbit_id, hutch_id)` validates three conditions before appending: (a) rabbit exists in RabbitSystem, (b) hutch has an open slot, (c) rabbit is not already assigned elsewhere. `remove_rabbit(rabbit_id)` scans `GameState.hutches` for the occupying hutch and removes the entry. Both operations update `RabbitData.hutch_id` atomically via `RabbitSystem` and emit `EventBus.rabbit_assigned_to_hutch`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Array.find()`, `Array.append()`, `Array.erase()` are stable in 4.4–4.6. Signal callable syntax unchanged. No post-cutoff APIs used.

**Control Manifest Rules (Core layer)**:
- Required: All cross-system communication via EventBus signals (F-03)
- Required: `rabbit_assigned_to_hutch` emitted only after state change is complete (F-03)
- Required: Balance values (capacity lookup) loaded from `balance.json` at `_ready()` (F-04)
- Forbidden: Direct field mutation of `RabbitData` fields from `HabitatSystem` — use `RabbitSystem` write API (C-01)
- Forbidden: Writing to `HutchData.occupants` from any file other than `habitat_system.gd`

**Note on `rabbit_assigned_to_hutch` signal**: ADR-0010 and ADR-0003 define this signal. It must be declared on `EventBus` before this story can be marked Done. If the signal is not yet in `src/core/event_bus.gd`, add it as part of this story's implementation scope.

---

## Acceptance Criteria

1. `assign_rabbit(rabbit_id: String, hutch_id: String) -> bool` implemented on `HabitatSystem`
2. `assign_rabbit()` returns `false` and emits no signal if the rabbit does not exist in `RabbitSystem`
3. `assign_rabbit()` returns `false` and emits no signal if `hutch.occupants.size() >= get_capacity(hutch_id)`
4. `assign_rabbit()` returns `false` and emits no signal if the rabbit is already present in any hutch's `occupants` array
5. `assign_rabbit()` returns `true`, appends `rabbit_id` to `hutch.occupants`, and calls the `RabbitSystem` write API to set `rabbit.hutch_id = hutch_id` when all three validations pass
6. `assign_rabbit()` emits `EventBus.rabbit_assigned_to_hutch(rabbit_id, hutch_id)` after both `occupants` and `rabbit.hutch_id` are updated (state-complete-first rule from F-03)
7. `remove_rabbit(rabbit_id: String) -> bool` implemented on `HabitatSystem`
8. `remove_rabbit()` returns `false` and emits no signal if `rabbit_id` is not found in any hutch's `occupants` array
9. `remove_rabbit()` returns `true`, removes `rabbit_id` from `hutch.occupants`, and calls the `RabbitSystem` write API to clear `rabbit.hutch_id = ""`
10. `remove_rabbit()` emits `EventBus.rabbit_assigned_to_hutch(rabbit_id, "")` after both mutations are complete (empty string signals the rabbit is now unassigned)
11. Both operations are atomic with respect to `HutchData.occupants` and `RabbitData.hutch_id` — if either write fails (e.g., RabbitSystem returns an error), neither write is committed
12. `GameState.mark_dirty()` is called after any successful assignment or removal to flag state as needing save

---

## Implementation Notes

*Derived from ADR-0010:*

`HabitatSystem` must access `RabbitSystem` to validate rabbit existence in `assign_rabbit()`. Call `RabbitSystem.get_rabbit(rabbit_id)` — if it returns `null`, reject and return `false`. Do not cache the returned `RabbitData` reference beyond the validation call.

The duplicate-assignment check in `assign_rabbit()` scans all hutches in `GameState.hutches`. ADR-0010 notes this is O(hutches × occupants) — at max scale (6 hutches × 24 occupants = 144 comparisons). This is acceptable for an infrequent player-initiated action; do not optimise prematurely.

`remove_rabbit()` uses the same scan pattern to find which hutch currently holds `rabbit_id`. There is no reverse-index; the scan is the defined implementation per ADR-0010.

Setting `rabbit.hutch_id` on the `RabbitData` object requires going through the `RabbitSystem` write API — `HabitatSystem` must never directly assign to `RabbitData` fields (C-01 rule). The write API method to use is defined in the C-01 interface contract in `control-manifest.md`; if no method currently exists for hutch assignment on `RabbitSystem`, add one as part of this story's implementation scope and document the addition.

The `rabbit_assigned_to_hutch` signal parameters per ADR-0010:
```gdscript
signal rabbit_assigned_to_hutch(rabbit_id: String, hutch_id: String)
```
Emit with `hutch_id = ""` when removing (rabbit becomes unassigned). This signal must be declared on `EventBus` in `src/core/event_bus.gd`.

`get_capacity(hutch_id)` is implemented in Story 005 and must be available before this story's capacity-check validation can be tested end-to-end. For unit testing purposes, a test double or stub capacity value is acceptable when Story 005 is not yet merged.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `HutchData` schema definition
- Story 003: Cleanliness decay — only occupancy is mutated here
- Story 004: `get_hutch_bonuses()` bonus calculation
- Story 005: `get_capacity()` implementation — this story calls it but does not define it

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC-1/AC-5**: Successful assignment
  - Given: a `HutchData` with `hutch_id = "h1"`, level 1 (capacity 4), empty occupants; a valid rabbit `"r1"` exists in RabbitSystem; `RabbitData.hutch_id == ""`
  - When: `HabitatSystem.assign_rabbit("r1", "h1")`
  - Then: returns `true`; `hutch.occupants` contains `"r1"`; `rabbit.hutch_id == "h1"`

- **AC-2**: Reject — rabbit does not exist
  - Given: rabbit `"nonexistent"` is not registered in RabbitSystem
  - When: `HabitatSystem.assign_rabbit("nonexistent", "h1")`
  - Then: returns `false`; `hutch.occupants` unchanged; no signal emitted

- **AC-3**: Reject — hutch at capacity
  - Given: a `HutchData` with capacity 4 and 4 occupants already assigned
  - When: `HabitatSystem.assign_rabbit("r5", "h1")`
  - Then: returns `false`; `hutch.occupants.size()` still 4; no signal emitted

- **AC-4**: Reject — rabbit already assigned elsewhere
  - Given: rabbit `"r1"` is already in `hutch_002.occupants`
  - When: `HabitatSystem.assign_rabbit("r1", "h1")`
  - Then: returns `false`; no mutation to either hutch; no signal emitted

- **AC-6**: Signal emitted after state update
  - Given: successful assignment scenario
  - When: monitor `EventBus.rabbit_assigned_to_hutch`
  - Then: signal fires exactly once with `(rabbit_id = "r1", hutch_id = "h1")`; signal fires after `hutch.occupants` already contains `"r1"`

- **AC-8/AC-9**: Successful removal
  - Given: rabbit `"r1"` is in `hutch_001.occupants`; `rabbit.hutch_id == "hutch_001"`
  - When: `HabitatSystem.remove_rabbit("r1")`
  - Then: returns `true`; `hutch_001.occupants` does not contain `"r1"`; `rabbit.hutch_id == ""`

- **AC-8 reject**: Removal of unassigned rabbit
  - Given: rabbit `"r_unassigned"` is not in any hutch's `occupants`
  - When: `HabitatSystem.remove_rabbit("r_unassigned")`
  - Then: returns `false`; no mutation; no signal emitted

- **AC-10**: Signal emitted on removal with empty hutch_id
  - Given: rabbit `"r1"` is assigned to `"h1"`
  - When: `HabitatSystem.remove_rabbit("r1")`
  - Then: `EventBus.rabbit_assigned_to_hutch` fires with `(rabbit_id = "r1", hutch_id = "")`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/habitat_system_assignment_test.gd` — must exist and pass

**Status**: [ ] `tests/unit/core/habitat_system_assignment_test.gd` — 8 test functions

---

## Dependencies

- Depends on: Story 001 (HutchData schema must exist)
- Unlocks: Story 003, Story 004, Story 005 may proceed in parallel once Story 001 is done; the full integration of this story requires Story 005 (`get_capacity()`) for end-to-end capacity validation

## Completion Notes
**Completed**: 2026-05-18
**Criteria**: 12/12 passing
**Deviations**: (1) Signal name `rabbit_assigned_to_hutch` used instead of ADR-specified `rabbit_assigned_to_hutch` — identical signature, avoids duplicate; (2) `get_capacity()` stub returns 4 — intentional, story-005 replaces with balance.json lookup
**Test Evidence**: Logic: `tests/unit/core/habitat_system_assignment_test.gd` (10 test functions)
**Code Review**: Skipped — Lean mode
