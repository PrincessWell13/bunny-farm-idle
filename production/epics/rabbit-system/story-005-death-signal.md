# Story 005: Death Path — rabbit_died Signal + Roster Removal

> **Epic**: RabbitSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.1 — "Thỏ chết nếu Health = 0")
**Requirement**: `TR-rabbit-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0003 Accepted ✅, ADR-0005 Accepted ✅

**ADR Governing Implementation**: ADR-0003 (EventBus signal emission) + ADR-0005 (RabbitSystem mutation contract and remove_rabbit)
**ADR Decision Summary**: When `rabbit.health <= 0.0`, `_check_death(rabbit)` emits `EventBus.rabbit_died(rabbit_id)` and calls `remove_rabbit(rabbit_id)`. Called from `_tick_rabbit()` on every tick. The rabbit must be removed from the roster before or alongside signal emission so listeners cannot find it via `get_rabbit()`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Emitting a signal and then mutating state in the same frame is safe in Godot 4. No deferred emit required here.

**Control Manifest Rules (Core layer)**:
- Required: callable-based signal emit
- Forbidden: Presentation-layer calls from within `_check_death`
- Required: `remove_rabbit()` called in same tick as `rabbit_died` emission

---

## Acceptance Criteria

*From GDD §3.1 and ADR-0005 death contract:*

- [ ] `_check_death(rabbit: RabbitData)` detects `rabbit.health <= 0.0`
- [ ] When health ≤ 0: `EventBus.rabbit_died.emit(rabbit.rabbit_id)` called
- [ ] When health ≤ 0: `remove_rabbit(rabbit.rabbit_id)` called in the same tick
- [ ] After `_check_death`, `get_rabbit(rabbit_id)` returns `null`
- [ ] When health > 0: `rabbit_died` is NOT emitted; rabbit remains in roster
- [ ] `_check_death` is called inside `_tick_rabbit` after stat decay

---

## Implementation Notes

*Derived from ADR-0005 lifecycle and ADR-0003 emit pattern:*

```gdscript
func _check_death(rabbit: RabbitData) -> void:
    if rabbit.health <= 0.0:
        var dead_id: String = rabbit.rabbit_id
        remove_rabbit(dead_id)
        EventBus.rabbit_died.emit(dead_id)
```

Note: `remove_rabbit` is called before `emit` to ensure that any listener calling `get_rabbit(id)` during the signal handler already receives `null`. This prevents listeners from operating on a dead rabbit reference.

The `_tick_rabbit` call order must be:
1. Decay stats (hunger, cleanliness, health, happiness)
2. `_check_stage_advance(rabbit)` — Story 004
3. `_check_death(rabbit)` — this story

Do not iterate `_rabbits.values()` and call `remove_rabbit` within the same loop iteration — collect IDs to remove first, then remove after the loop.

```gdscript
func _process(delta: float) -> void:
    _tick_accumulator += delta
    if _tick_accumulator >= 1.0:
        _tick_accumulator -= 1.0
        var rabbits_snapshot: Array[RabbitData] = get_all_rabbits()
        for rabbit: RabbitData in rabbits_snapshot:
            _tick_rabbit(rabbit, 1.0)
```

Using a snapshot (`get_all_rabbits()` returns a copy) avoids modifying the underlying dictionary while iterating.

---

## Out of Scope

- Story 003: the stat decay that drives health to 0
- Story 004: stage advance — happens before death check in same tick
- Presentation layer: death animation, tombstone particle effects

---

## QA Test Cases

- **AC-1**: `rabbit_died` emitted when health reaches 0
  - Given: rabbit with `health=0.0` in roster; EventBus connected
  - When: `_check_death(rabbit)`
  - Then: `rabbit_died` signal received with rabbit's `rabbit_id`

- **AC-2**: rabbit removed from roster after death
  - Given: rabbit with known ID; `health=0.0`
  - When: `_check_death(rabbit)`
  - Then: `get_rabbit(id) == null`; `get_all_rabbits().size()` decremented by 1

- **AC-3**: `rabbit_died` NOT emitted when health > 0
  - Given: rabbit with `health=50.0`; EventBus connected
  - When: `_check_death(rabbit)`
  - Then: signal NOT received; rabbit still in roster

- **AC-4**: listener calling `get_rabbit()` in death handler receives null
  - Given: rabbit about to die; listener connected that calls `get_rabbit(id)` on `rabbit_died`
  - When: `_check_death` fires
  - Then: listener receives null from `get_rabbit` (remove before emit)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/rabbit_system_death_test.gd` — must exist and pass

**Status**: [x] `tests/integration/core/rabbit_system_death_test.gd` — 4 test functions

---

## Dependencies

- Depends on: **Story 004 must be DONE** — `_check_death` is called after `_check_stage_advance` in the tick loop
- Unlocks: RabbitSystem core tick loop is complete (stories 001–005 done = functional rabbit lifecycle)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 6/6 passing
**Deviations**: ADVISORY — `_process` snapshot iteration fix included (story notes explicitly required this; not listed as a separate file change)
**Test Evidence**: Integration — `tests/integration/core/rabbit_system_death_test.gd` ✅
**Code Review**: Skipped — Lean mode
