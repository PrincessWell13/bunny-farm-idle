# Story 002: Production Formula — Tick Earnings

> **Epic**: IdleProductionSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.12 Idle & Offline)
**Requirement**: `TR-idle-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0007 Accepted ✅

**ADR Governing Implementation**: ADR-0007 (Idle Production Formula and Offline Catch-Up Calculation)
**ADR Decision Summary**: `IdleProductionSystem` is a stateless calculation node. `get_tick_earnings()` calls `_calculate(1.0, 1.0)`. `_calculate(delta_seconds, offline_multiplier)` computes `floor(productive_count × base_rate × hutch_bonus × season_mult × prestige_bonus × offline_multiplier × delta_seconds)`. Only ADULT and ELDER rabbits are counted as productive. All rates from `balance.json`. The system never calls `EconomyManager.add()`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript arithmetic. `floor()` called once at end. `FileAccess.get_file_as_string()` + `JSON.parse_string()` for balance loading — both stable in 4.4–4.6.

**Control Manifest Rules (Core layer)**:
- Required: all production rates loaded from `balance.json idle_production` section
- Forbidden: `hardcoded_balance_values` — no float literals representing game balance in `src/`
- Forbidden: `IdleProductionSystem` must never call `EconomyManager.add()` directly

---

## Acceptance Criteria

*From GDD §3.12 and ADR-0007 Production Formula section:*

- [ ] `get_tick_earnings()` returns an `EarningsReport` with `delta_seconds == 1.0` and `applied_multiplier == 1.0`
- [ ] With 0 productive rabbits: `EarningsReport.carrot_coin == 0`
- [ ] With 24 ADULT rabbits and `base_rate = 0.05`: `carrot_coin == floor(24 × 0.05 × 1.0) = 1`
- [ ] BABY and JUVENILE rabbits are not counted in `productive_count`
- [ ] `_calculate()` never calls `EconomyManager.add()` — pure function, no side effects
- [ ] `_base_rate` loaded from `balance.json idle_production.base_cc_per_rabbit_per_second`; fallback default 0.05 used if absent
- [ ] `source_breakdown` in the report contains rabbit count and base_rate

---

## Implementation Notes

*Derived from ADR-0007 Implementation section:*

Create `src/core/idle_production_system.gd`:

```gdscript
class_name IdleProductionSystem extends Node

var _base_rate: float = 0.05  # fallback — loaded from balance.json

func _ready() -> void:
    _load_balance_data()

func get_tick_earnings() -> EarningsReport:
    return _calculate(1.0, 1.0)  # 1 second, full online rate

func _calculate(delta_seconds: float, offline_multiplier: float) -> EarningsReport:
    var productive_count: int = _count_productive_rabbits()
    var hutch_bonus: float = _get_hutch_bonus()        # stub: 1.0 (Story 004 wires real value)
    var season_mult: float = _get_season_multiplier()  # stub: 1.0 (Story 004 wires real value)
    var prestige_bonus: float = _get_prestige_bonus()  # stub: 1.0 (Story 004 wires real value)
    var raw: float = (productive_count * _base_rate * hutch_bonus
                      * season_mult * prestige_bonus * offline_multiplier * delta_seconds)
    var report := EarningsReport.new()
    report.carrot_coin = int(floor(raw))
    report.applied_multiplier = offline_multiplier
    report.delta_seconds = delta_seconds
    report.source_breakdown = [{"rabbits": productive_count, "base_rate": _base_rate,
                                 "hutch_bonus": hutch_bonus, "season_mult": season_mult,
                                 "prestige_bonus": prestige_bonus}]
    return report
```

`_count_productive_rabbits()` reads from `RabbitSystem` (autoload) — counts rabbits with stage `ADULT` or `ELDER`. Use `RabbitSystem.get_all_rabbits()` (implemented in rabbit-system epic) and filter by `rabbit.stage`.

Stub helpers for this story (return 1.0 — replaced by Story 004):
```gdscript
func _get_hutch_bonus() -> float:     return 1.0
func _get_season_multiplier() -> float: return 1.0
func _get_prestige_bonus() -> float:   return 1.0
```

`_load_balance_data()`: load `idle_production` section from `balance.json`. Extract `base_cc_per_rabbit_per_second` → `_base_rate`. Additional multiplier keys loaded in Story 003.

For unit testing without autoloads: expose `func set_rabbit_source(source: Array[RabbitData])` or use a `var _rabbit_override: Array[RabbitData]` that `_count_productive_rabbits()` checks first. This keeps the test independent of the live RabbitSystem.

---

## Out of Scope

- Story 001: EarningsReport class definition — must be DONE before this story
- Story 003: `calculate_offline_earnings()` and multiplier tiers — do not implement here
- Story 004: wiring real hutch/season/prestige values — stubs are intentional here

---

## QA Test Cases

- **AC-1**: `get_tick_earnings()` returns EarningsReport with correct meta fields
  - Given: system with 0 rabbits
  - When: `var r := system.get_tick_earnings()`
  - Then: `r is EarningsReport`, `r.delta_seconds == 1.0`, `r.applied_multiplier == 1.0`

- **AC-2**: 0 productive rabbits → carrot_coin == 0
  - Given: system with no rabbits injected
  - When: `system.get_tick_earnings()`
  - Then: `r.carrot_coin == 0`

- **AC-3**: 24 adult rabbits × base_rate 0.05 → carrot_coin == 1
  - Given: 24 ADULT rabbits; `_base_rate = 0.05`; hutch/season/prestige all 1.0
  - When: `system.get_tick_earnings()`
  - Then: `r.carrot_coin == 1` (floor(24 × 0.05 × 1.0) = floor(1.2) = 1)

- **AC-4**: BABY and JUVENILE rabbits not counted
  - Given: 5 BABY + 5 JUVENILE rabbits; 0 ADULT/ELDER
  - When: `system.get_tick_earnings()`
  - Then: `r.carrot_coin == 0`

- **AC-5**: source_breakdown contains rabbit count
  - Given: 10 ADULT rabbits
  - When: `system.get_tick_earnings()`
  - Then: `r.source_breakdown[0]["rabbits"] == 10`

- **AC-6**: balance.json base_rate applied
  - Given: set `system._base_rate = 0.10`; 10 ADULT rabbits
  - When: `system.get_tick_earnings()`
  - Then: `r.carrot_coin == 1` (floor(10 × 0.10) = 1)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/idle_production_formula_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/idle_production_formula_test.gd` — 8 test functions

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 7/7 passing
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/core/idle_production_formula_test.gd` ✅ (8 test functions)
**Code Review**: Skipped — Lean mode

---

## Dependencies

- Depends on: **Story 001 must be DONE** — `EarningsReport` class must exist
- Unlocks: Story 003 (offline tiers add to this file), Story 004 (wires real multipliers)
