# Story 001: EarningsReport Schema

> **Epic**: IdleProductionSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.12 Idle & Offline)
**Requirement**: `TR-idle-001` (structural prerequisite — EarningsReport is the return type for all production methods)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0007 Proposed ❌
**BLOCKED**: ADR-0007 is Proposed — run `/architecture-decision retrofit docs/architecture/adr-0007-idle-production-offline.md` to advance it.

**ADR Governing Implementation**: ADR-0007 (Idle Production Formula and Offline Catch-Up Calculation)
**ADR Decision Summary**: `EarningsReport` is a `RefCounted` value object returned by both `get_tick_earnings()` and `calculate_offline_earnings()`. It carries: `carrot_coin: int`, `star_dust: int`, `applied_multiplier: float`, `delta_seconds: float`, `source_breakdown: Array`. The caller uses it to call `EconomyManager.add()` and to populate the offline reward UI.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript class definition. No engine API surface.

**Control Manifest Rules (Core layer)**:
- Required: all gameplay values must be data-driven (external config)
- Forbidden: `direct_rabbitdata_mutation` — do not modify any rabbit
- Forbidden: `upward_direct_method_calls` — Core may not call Feature or Presentation methods

---

## Acceptance Criteria

*From ADR-0007 EarningsReport Value Object section:*

- [ ] `EarningsReport` class defined at `src/core/earnings_report.gd` with `class_name EarningsReport extends RefCounted`
- [ ] Field `carrot_coin: int = 0` — default 0
- [ ] Field `star_dust: int = 0` — default 0 (Star Dust not from idle; from expeditions only)
- [ ] Field `applied_multiplier: float = 1.0` — default 1.0 (online rate)
- [ ] Field `delta_seconds: float = 0.0` — default 0.0
- [ ] Field `source_breakdown: Array = []` — default empty array
- [ ] A freshly instantiated `EarningsReport.new()` has all defaults without modification

---

## Implementation Notes

*Derived from ADR-0007 EarningsReport section:*

Create `src/core/earnings_report.gd`:

```gdscript
class_name EarningsReport extends RefCounted

var carrot_coin: int = 0
var star_dust: int = 0
var applied_multiplier: float = 1.0
var delta_seconds: float = 0.0
var source_breakdown: Array = []
```

`star_dust` is reserved for future expedition rewards — idle production never sets it to a non-zero value.
`source_breakdown` is populated by `_calculate()` in Story 002 for the offline reward UI breakdown display.

---

## Out of Scope

- Story 002: `IdleProductionSystem` that creates and populates `EarningsReport` instances
- Offline reward UI that reads `source_breakdown`

---

## QA Test Cases

- **AC-1**: EarningsReport instantiates with correct defaults
  - Given: `var r := EarningsReport.new()`
  - When: read all fields
  - Then: `r.carrot_coin == 0`, `r.star_dust == 0`, `r.applied_multiplier == 1.0`, `r.delta_seconds == 0.0`, `r.source_breakdown == []`

- **AC-2**: Fields are writable
  - Given: `var r := EarningsReport.new()`
  - When: `r.carrot_coin = 42; r.applied_multiplier = 0.60`
  - Then: `r.carrot_coin == 42`, `r.applied_multiplier == 0.60`

- **AC-3**: EarningsReport is a RefCounted (no Node, no scene tree required)
  - Given: `var r := EarningsReport.new()`
  - When: `r is RefCounted`
  - Then: `true`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/idle_earnings_report_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/idle_earnings_report_test.gd` — 3 test functions

---

## Dependencies

- Depends on: None
- Unlocks: Story 002 (IdleProductionSystem needs EarningsReport as return type)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/core/idle_earnings_report_test.gd` ✅ (3 test functions)
**Code Review**: Skipped — Lean mode
