# Story 003: Cleanliness Decay via TimeManager Tick

> **Epic**: HabitatSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.4 Habitat System)
**Requirements**: `TR-habitat-001`, `TR-habitat-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0010 Accepted ✅, ADR-0004 Accepted ✅

**ADR Governing Implementation**: ADR-0010: HabitatSystem Hutch Ownership and Rabbit Assignment Model; ADR-0004: JSON Balance Data — No Hardcoded Values
**ADR Decision Summary**: Cleanliness decays per `TimeManager.tick` signal. Decay rate is loaded from `balance.json` key `habitat.cleanliness_decay_per_second` in `_ready()`. Empty hutches (zero occupants) do not decay. `cleanliness` is clamped to `0.0`–`1.0` after each tick. `hutch_cleanliness_changed` signal emitted on EventBus after every update.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Signal.connect()` callable syntax, `clampf()`, and `TimeManager.tick` pattern are stable. `clampf()` available since Godot 4.0. No post-cutoff APIs used.

**Control Manifest Rules (Core layer)**:
- Required: Decay rate loaded from `balance.json` at `_ready()` — never hardcoded (F-04)
- Required: `hutch_cleanliness_changed` emitted after state is updated (F-03)
- Required: `TimeManager.tick` connection established in `_ready()` (F-01 boot order)
- Forbidden: Hardcoded decay rate literals anywhere in `src/` (F-04)
- Forbidden: Decay running on hutches with zero occupants

**Note on `hutch_cleanliness_changed` signal**: ADR-0010 defines this signal. It must be declared on `EventBus` (`src/core/event_bus.gd`) before this story can be marked Done. If not yet present, add it as part of this story's implementation scope.

---

## Acceptance Criteria

1. `HabitatSystem._ready()` connects to `TimeManager.tick` using callable syntax: `TimeManager.tick.connect(_on_tick)`
2. `HabitatSystem._load_balance_data()` loads `habitat.cleanliness_decay_per_second` from `balance.json` into a typed private variable `_decay_rate: float`
3. If `balance.json` is missing the `habitat.cleanliness_decay_per_second` key at boot, `push_error()` is called and a safe fallback default is used — the system does not crash
4. `_on_tick(delta: float)` iterates all hutches in `GameState.hutches`
5. For each hutch with `occupants.is_empty() == true`, no decay is applied — `cleanliness` is unchanged
6. For each hutch with at least one occupant, `cleanliness` decreases by `_decay_rate * delta`
7. `cleanliness` is clamped to `0.0` after decay — it never goes negative
8. `cleanliness` is never modified above `1.0` by the decay function (clamp upper bound enforced)
9. `EventBus.hutch_cleanliness_changed(hutch_id: String, cleanliness: float)` is emitted for each hutch that was updated (occupied hutches only)
10. `GameState.mark_dirty()` is called once per tick after all hutch updates complete (not once per hutch)
11. No decay rate literal appears in `habitat_system.gd` — the value is always read from `_decay_rate`

---

## Implementation Notes

*Derived from ADR-0010:*

The canonical `_on_tick` implementation per ADR-0010:
```gdscript
func _on_tick(delta: float) -> void:
    for hutch: HutchData in GameState.hutches:
        if hutch.occupants.is_empty():
            continue
        hutch.cleanliness -= _decay_rate * delta
        hutch.cleanliness = clampf(hutch.cleanliness, 0.0, 1.0)
        EventBus.hutch_cleanliness_changed.emit(hutch.hutch_id, hutch.cleanliness)
    GameState.mark_dirty()
```

`_decay_rate` is loaded in `_load_balance_data()` from the `habitat` namespace in `balance.json`. The `balance.json` key is `habitat.cleanliness_decay_per_second`. Follow the standard loading pattern from ADR-0004 / F-04.

The `hutch_cleanliness_changed` signal parameters:
```gdscript
signal hutch_cleanliness_changed(hutch_id: String, cleanliness: float)
```
This must be declared on `EventBus` in `src/core/event_bus.gd`.

ADR-0010 notes: "Cleanliness decay fires on every `TimeManager.tick` for all occupied hutches. At max scale this is 6 hutch updates per second — negligible CPU cost." Do not add delta-accumulation logic or lazy evaluation; tick-driven decay is the committed design.

For unit testing, `GameState.hutches` must be injectable or resettable. The test file should set up a controlled array of `HutchData` instances directly rather than relying on GameState autoload state. Consider accepting `hutches` as a parameter in a testable inner function, or use GdUnit4's autoload mock capabilities.

`balance.json` must have `assets/data/balance.json → habitat → cleanliness_decay_per_second` populated with a value (e.g., `0.001` for a slow decay suited to gameplay) before any playtest build. If this key is absent at the time this story is merged, add a skeleton entry to `balance.json` as part of the implementation.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `HutchData` schema definition
- Story 002: Rabbit assignment that determines whether a hutch has occupants
- Story 004: `get_hutch_bonuses()` which consumes the `cleanliness` value produced here
- SaveSystem epic: offline catch-up for cleanliness decay (offline accumulation handled separately)

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC-5**: Empty hutch does not decay
  - Given: a `HutchData` with `occupants.is_empty() == true` and `cleanliness = 0.9`
  - When: `HabitatSystem._on_tick(1.0)` is called
  - Then: `hutch.cleanliness` is still `0.9`; no `hutch_cleanliness_changed` signal emitted for this hutch

- **AC-6**: Occupied hutch decays at correct rate
  - Given: a `HutchData` with one occupant and `cleanliness = 0.5`; `_decay_rate = 0.1`
  - When: `HabitatSystem._on_tick(1.0)`
  - Then: `hutch.cleanliness == 0.4` (within float tolerance)

- **AC-7**: Cleanliness clamps at 0.0
  - Given: a `HutchData` with one occupant and `cleanliness = 0.05`; `_decay_rate = 0.1`
  - When: `HabitatSystem._on_tick(1.0)`
  - Then: `hutch.cleanliness == 0.0` — does not go negative

- **AC-8**: Decay does not increase cleanliness
  - Given: a `HutchData` with `cleanliness = 1.0` and one occupant
  - When: `HabitatSystem._on_tick(1.0)`
  - Then: `hutch.cleanliness <= 1.0`

- **AC-9**: Signal fired for occupied hutch only
  - Given: two hutches — one empty (`cleanliness = 0.8`), one occupied (`cleanliness = 0.6`)
  - When: `HabitatSystem._on_tick(1.0)`
  - Then: `hutch_cleanliness_changed` fires exactly once (for the occupied hutch only); empty hutch emits no signal

- **AC-10**: `GameState.mark_dirty()` called once per tick
  - Given: two occupied hutches
  - When: `HabitatSystem._on_tick(1.0)`
  - Then: `GameState.mark_dirty()` called exactly once (not twice)

- **AC-3**: Missing balance.json key falls back safely
  - Given: `balance.json` has no `habitat.cleanliness_decay_per_second` key
  - When: `HabitatSystem._ready()` calls `_load_balance_data()`
  - Then: `push_error()` logged; `_decay_rate` is set to a non-zero safe default; no crash

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/habitat_system_cleanliness_test.gd` — must exist and pass

**Status**: [ ] `tests/unit/core/habitat_system_cleanliness_test.gd` — 7 test functions

---

## Dependencies

- Depends on: Story 001 (HutchData schema must exist)
- Unlocks: Story 004 (`get_hutch_bonuses()` consumes the cleanliness value this story produces)

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 11/11 passing
**Deviations**: `_decay_rate: float = 0.001` GDScript-side fallback default — balance.json value overwrites at runtime; matches rabbit_system.gd pattern
**Test Evidence**: Logic: `tests/unit/core/habitat_system_cleanliness_test.gd` (7 test functions)
**Code Review**: Skipped — Lean mode
