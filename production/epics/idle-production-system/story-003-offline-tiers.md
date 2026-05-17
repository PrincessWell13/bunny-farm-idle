# Story 003: Offline Catch-Up + Multiplier Tiers

> **Epic**: IdleProductionSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.12 Idle & Offline)
**Requirement**: `TR-idle-002`, `TR-idle-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0007 Accepted ✅

**ADR Governing Implementation**: ADR-0007 (Idle Production Formula and Offline Catch-Up Calculation)
**ADR Decision Summary**: `calculate_offline_earnings(offline_seconds, was_backgrounded)` clamps delta to `max_offline_hours × 3600`, selects the correct multiplier tier via `_get_offline_multiplier()`, then calls `_calculate(capped_delta, multiplier)`. Background (0.75) is a separate path from the 3-tier offline table. All threshold values and multipliers loaded from `balance.json`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript arithmetic. No engine API calls.

**Control Manifest Rules (Core layer)**:
- Required: multiplier values loaded from `balance.json idle_production` section
- Forbidden: `hardcoded_balance_values` — no float literals for multipliers in `src/`
- Forbidden: `IdleProductionSystem` must never call `EconomyManager.add()` directly

---

## Acceptance Criteria

*From GDD §3.12 and ADR-0007 Offline Multiplier Tier Selection section:*

- [ ] `calculate_offline_earnings(0.0, false)` → `carrot_coin == 0`
- [ ] `was_backgrounded = true` → `applied_multiplier == 0.75` regardless of duration
- [ ] `offline_seconds = 3 × 3600` (3 hours) → `applied_multiplier == 0.60` (< 4h tier)
- [ ] `offline_seconds = 8 × 3600` (8 hours) → `applied_multiplier == 0.50` (4–12h tier)
- [ ] `offline_seconds = 20 × 3600` (20 hours) → `applied_multiplier == 0.40` (> 12h tier)
- [ ] `offline_seconds = 100 × 3600` (100 hours, beyond 72h cap) → `delta_seconds` in report capped at `72 × 3600`
- [ ] All multiplier values loaded from `balance.json idle_production`; fallback defaults used if absent
- [ ] `calculate_offline_earnings()` does not call `EconomyManager.add()`

---

## Implementation Notes

*Derived from ADR-0007 Offline Multiplier Tier and Offline Cap sections:*

Add to `src/core/idle_production_system.gd`:

```gdscript
var _multiplier_background: float = 0.75   # fallback
var _multiplier_under_4h: float    = 0.60   # fallback
var _multiplier_4_to_12h: float    = 0.50   # fallback
var _multiplier_over_12h: float    = 0.40   # fallback
var _max_offline_hours: float      = 72.0   # fallback

func calculate_offline_earnings(offline_seconds: float, was_backgrounded: bool) -> EarningsReport:
    var capped: float = min(offline_seconds, _max_offline_hours * 3600.0)
    var multiplier: float = (
        _multiplier_background if was_backgrounded
        else _get_offline_multiplier(capped)
    )
    return _calculate(capped, multiplier)

func _get_offline_multiplier(offline_seconds: float) -> float:
    var hours: float = offline_seconds / 3600.0
    if offline_seconds <= 0.0:
        return 1.0  # online
    elif hours < 4.0:
        return _multiplier_under_4h
    elif hours < 12.0:
        return _multiplier_4_to_12h
    else:
        return _multiplier_over_12h
```

Also extend `_load_balance_data()` to load the multiplier keys and `max_offline_hours` from the `idle_production` section of `balance.json`.

**Cap implementation**: the `capped` value is what gets passed to `_calculate()` as `delta_seconds`. The report's `delta_seconds` field reflects the capped value, not the raw offline duration — this is what the UI uses to display "you were away for X hours (capped at 72h)".

---

## Out of Scope

- Story 002: `get_tick_earnings()` and `_calculate()` core formula — must be DONE
- Story 004: season and prestige multipliers factored into `_calculate()`
- Item-based offline modifiers (Alarm Bunny +70%) — covered by ADR-0010 (not yet written)

---

## QA Test Cases

- **AC-1**: zero offline → zero earnings
  - Given: system with 10 ADULT rabbits; `offline_seconds = 0.0`
  - When: `system.calculate_offline_earnings(0.0, false)`
  - Then: `r.carrot_coin == 0`

- **AC-2**: backgrounded → 0.75 multiplier
  - Given: `was_backgrounded = true`; any positive `offline_seconds`
  - When: `system.calculate_offline_earnings(3600.0, true)`
  - Then: `r.applied_multiplier == 0.75`

- **AC-3**: 3-hour offline → 0.60 multiplier
  - Given: `offline_seconds = 3 * 3600`
  - When: `system.calculate_offline_earnings(3 * 3600.0, false)`
  - Then: `r.applied_multiplier == 0.60`

- **AC-4**: 8-hour offline → 0.50 multiplier
  - Given: `offline_seconds = 8 * 3600`
  - When: `system.calculate_offline_earnings(8 * 3600.0, false)`
  - Then: `r.applied_multiplier == 0.50`

- **AC-5**: 20-hour offline → 0.40 multiplier
  - Given: `offline_seconds = 20 * 3600`
  - When: `system.calculate_offline_earnings(20 * 3600.0, false)`
  - Then: `r.applied_multiplier == 0.40`

- **AC-6**: 100-hour offline → capped at 72h
  - Given: `offline_seconds = 100 * 3600`; `_max_offline_hours = 72.0`
  - When: `var r := system.calculate_offline_earnings(100 * 3600.0, false)`
  - Then: `r.delta_seconds == 72.0 * 3600.0`
  - Edge case: verify coins earned match 72h worth, not 100h worth

- **AC-7**: boundary — exactly 4h → 0.50 tier (not 0.60)
  - Given: `offline_seconds = 4 * 3600`
  - When: `system.calculate_offline_earnings(4 * 3600.0, false)`
  - Then: `r.applied_multiplier == 0.50`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/idle_offline_tiers_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/idle_offline_tiers_test.gd` — 10 test functions

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 8/8 passing
**Deviations**: Implementation included in Story 002 file (all offline methods already present in `idle_production_system.gd`)
**Test Evidence**: Logic — `tests/unit/core/idle_offline_tiers_test.gd` ✅ (10 test functions)
**Code Review**: Skipped — Lean mode

---

## Dependencies

- Depends on: **Story 002 must be DONE** — `_calculate()` must exist in `idle_production_system.gd`
- Unlocks: Story 004 (can proceed in parallel once story 002 is done)
