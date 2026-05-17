# Story 004: Lifecycle State Machine — Stage Advance + rabbit_matured Signal

> **Epic**: RabbitSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.1 — Vòng đời thỏ)
**Requirement**: `TR-rabbit-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0003 Accepted ✅, ADR-0004 Accepted ✅, ADR-0005 Accepted ✅

**ADR Governing Implementation**: ADR-0003 (EventBus signal emission), ADR-0004 (stage thresholds from balance.json), ADR-0005 (RabbitSystem owns stage field writes)
**ADR Decision Summary**: `_check_stage_advance(rabbit)` is called from `_tick_rabbit()`. When `growth_progress` crosses a threshold (loaded from balance.json), the stage advances and `EventBus.rabbit_matured(rabbit_id, new_stage)` is emitted. ELDER and SANCTUARY transitions are time-based (birth_timestamp + lifespan). Stages never regress.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Time.get_unix_time_from_system()` stable in 4.4–4.6. Signal emission via callable syntax (ADR-0003).

**Control Manifest Rules (Core layer)**:
- Required: callable-based signal emission (not string-based)
- Forbidden: stage regression — once a stage is set, it only increases
- Forbidden: hardcoded stage thresholds

---

## Acceptance Criteria

*From GDD §3.1 lifecycle diagram and ADR-0005 state machine:*

- [ ] `_check_stage_advance(rabbit: RabbitData)` advances `BABY → JUVENILE` when `growth_progress >= _baby_to_juvenile_threshold`
- [ ] Advances `JUVENILE → ADULT` when `growth_progress >= _juvenile_to_adult_threshold`
- [ ] Advances `ADULT → ELDER` when `Time.get_unix_time_from_system() >= rabbit.birth_timestamp + _adult_lifespan_seconds`
- [ ] Advances `ELDER → SANCTUARY` when elder duration threshold elapsed
- [ ] `EventBus.rabbit_matured.emit(rabbit_id, new_stage)` called on every stage advance
- [ ] Stage thresholds loaded from balance.json (`growth_baby_to_juvenile_seconds`, etc.)
- [ ] SANCTUARY rabbits do not advance further — `_check_stage_advance` is a no-op for them
- [ ] Stage does not regress under any condition

---

## Implementation Notes

*Derived from ADR-0005 lifecycle diagram and ADR-0004 loading pattern:*

```gdscript
var _baby_to_juvenile_threshold: float = 100.0   # growth_progress units
var _juvenile_to_adult_threshold: float = 100.0
var _adult_lifespan_seconds: int = 86400
var _elder_duration_seconds: int = 43200

func _check_stage_advance(rabbit: RabbitData) -> void:
    var advanced := false
    match rabbit.stage:
        RabbitData.RabbitStage.BABY:
            if rabbit.growth_progress >= _baby_to_juvenile_threshold:
                rabbit.stage = RabbitData.RabbitStage.JUVENILE
                rabbit.growth_progress = 0.0
                advanced = true
        RabbitData.RabbitStage.JUVENILE:
            if rabbit.growth_progress >= _juvenile_to_adult_threshold:
                rabbit.stage = RabbitData.RabbitStage.ADULT
                rabbit.growth_progress = 0.0
                advanced = true
        RabbitData.RabbitStage.ADULT:
            var now: int = Time.get_unix_time_from_system()
            if now >= rabbit.birth_timestamp + _adult_lifespan_seconds:
                rabbit.stage = RabbitData.RabbitStage.ELDER
                advanced = true
        RabbitData.RabbitStage.ELDER:
            var now: int = Time.get_unix_time_from_system()
            if now >= rabbit.birth_timestamp + _adult_lifespan_seconds + _elder_duration_seconds:
                rabbit.stage = RabbitData.RabbitStage.SANCTUARY
                advanced = true
        RabbitData.RabbitStage.SANCTUARY:
            pass  # no further advancement
    if advanced:
        EventBus.rabbit_matured.emit(rabbit.rabbit_id, rabbit.stage)
```

Balance.json keys to load (in `_load_balance_data()`):
- `"growth_baby_to_juvenile_seconds"` → maps to growth_progress threshold
- `"growth_juvenile_to_adult_seconds"` → second threshold

Note: ADR-0004 balance.json stores durations in seconds but `growth_progress` is a unitless float (0–100+). The threshold is how much progress constitutes a full stage. The per-tick accumulation rate (`growth_rate_for_stage`) is a separate balance value defining how fast progress accumulates.

---

## Out of Scope

- Story 005: death path (`_check_death`) — stubbed in story-003
- Story 007: aura effects for ELDER/SANCTUARY rabbits
- Presentation layer: visual effects for stage transitions
- GeneticsSystem: trait expression at JUVENILE stage

---

## QA Test Cases

- **AC-1**: BABY advances to JUVENILE at growth threshold
  - Given: rabbit with `stage=BABY`, `growth_progress=99.0`; `_baby_to_juvenile_threshold=100.0`
  - When: `_tick_rabbit(rabbit, 1.0)` with `growth_rate=2.0` per delta (so growth_progress becomes 101)
  - Then: `rabbit.stage == JUVENILE`; `EventBus.rabbit_matured` emitted with rabbit's ID

- **AC-2**: BABY does NOT advance when below threshold
  - Given: rabbit with `stage=BABY`, `growth_progress=50.0`; threshold=100.0
  - When: `_check_stage_advance(rabbit)`
  - Then: `rabbit.stage == BABY`; no signal emitted

- **AC-3**: rabbit_matured signal carries correct rabbit_id and new_stage
  - Given: rabbit with known `rabbit_id`; stage crosses threshold
  - When: signal fires
  - Then: first argument == `rabbit_id`; second argument == `RabbitData.RabbitStage.JUVENILE`

- **AC-4**: SANCTUARY rabbit is not advanced further
  - Given: rabbit with `stage=SANCTUARY`
  - When: `_check_stage_advance(rabbit)`
  - Then: `stage == SANCTUARY`; no signal emitted

- **AC-5**: growth_progress resets to 0.0 on BABY→JUVENILE and JUVENILE→ADULT
  - Given: rabbit crosses growth threshold
  - When: stage advances
  - Then: `rabbit.growth_progress == 0.0`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/rabbit_system_lifecycle_test.gd` — must exist and pass

**Status**: [x] `tests/integration/core/rabbit_system_lifecycle_test.gd` — 7 test functions

---

## Dependencies

- Depends on: **Story 003 must be DONE** — `_check_stage_advance` is called from `_tick_rabbit`
- Unlocks: Story 005 (death path also hooks into tick loop after lifecycle)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 8/8 passing
**Deviations**: ADVISORY — `86400` and `43200` as `var` fallback defaults (ADR-0004 pattern; logic uses variable names only)
**Test Evidence**: Integration — `tests/integration/core/rabbit_system_lifecycle_test.gd` ✅
**Code Review**: Skipped — Lean mode
