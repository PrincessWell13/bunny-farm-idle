# Story 004: Season + Prestige Integration

> **Epic**: IdleProductionSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.12 Idle & Offline, §3.5 Seasons, §4 Prestige)
**Requirement**: `TR-season-001`, `TR-prestige-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0007 Accepted ✅

**ADR Governing Implementation**: ADR-0007 (Idle Production Formula and Offline Catch-Up Calculation)
**ADR Decision Summary**: `_get_season_multiplier()` reads from SeasonSystem (when available) — returns `1.0 + season_harvest_bonus`; autumn = 1.5. `_get_prestige_bonus()` reads `GameState.prestige_count` and maps it to `1.0 + offline_production_bonus` from `balance.json prestige.bonuses_per_level`. Both are factored into `_calculate()`. The stubs from Story 002 are replaced here.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Reads from `GameState` autoload (stable) and `SeasonSystem` (not yet implemented — stub to 1.0 if absent). No engine API surface.

**Control Manifest Rules (Core layer)**:
- Required: prestige bonus values read from `balance.json prestige.bonuses_per_level`
- Forbidden: `upward_direct_method_calls` — Core may not call Presentation methods
- Note: SeasonSystem is a Core system; reading it from IdleProductionSystem is valid (same layer)

---

## Acceptance Criteria

*From GDD §3.5 Seasons and §4 Prestige and ADR-0007:*

- [ ] When `GameState.prestige_count == 0`: `_get_prestige_bonus()` returns `1.0`
- [ ] When `GameState.prestige_count == 3` (prestige level 3 has `offline_production_bonus: 0.15`): `_get_prestige_bonus()` returns `1.15`
- [ ] Prestige bonus applied to production: 10 ADULT rabbits × prestige_bonus 1.15 × 1 second → `carrot_coin == floor(10 × 0.05 × 1.15) = floor(0.575) = 0`; with 24 rabbits → `floor(24 × 0.05 × 1.15) = floor(1.38) = 1`
- [ ] `_get_season_multiplier()` returns `1.0` gracefully when SeasonSystem is not present
- [ ] When season is autumn (`harvest_bonus = 0.50`): `_get_season_multiplier()` returns `1.5`
- [ ] Season multiplier changes production proportionally: same rabbit count × different season_mult → carrot_coin scales accordingly

---

## Implementation Notes

*Derived from ADR-0007 Implementation section:*

Replace the 1.0 stubs from Story 002 in `src/core/idle_production_system.gd`:

```gdscript
func _get_prestige_bonus() -> float:
    var prestige_count: int = GameState.prestige_count
    if prestige_count <= 0:
        return 1.0
    # Read prestige bonus table from balance.json
    var bonus: float = _prestige_offline_bonuses.get(str(prestige_count), 0.0) as float
    return 1.0 + bonus

func _get_season_multiplier() -> float:
    # SeasonSystem may not exist yet — check for autoload gracefully
    if not Engine.has_singleton("SeasonSystem"):
        return 1.0
    var harvest_bonus: float = SeasonSystem.get_harvest_bonus()
    return 1.0 + harvest_bonus
```

Add instance variable for prestige bonus table loaded from balance.json:
```gdscript
var _prestige_offline_bonuses: Dictionary = {}  # prestige_level (str) → offline_production_bonus
```

Extend `_load_balance_data()` to load prestige offline bonuses:
```gdscript
var prestige_section: Dictionary = data.get("prestige", {}) as Dictionary
var bonuses_per_level: Dictionary = prestige_section.get("bonuses_per_level", {}) as Dictionary
for level_str: String in bonuses_per_level:
    var level_bonuses: Dictionary = bonuses_per_level[level_str] as Dictionary
    var prod_bonus: float = level_bonuses.get("offline_production_bonus", 0.0) as float
    if prod_bonus > 0.0:
        _prestige_offline_bonuses[level_str] = prod_bonus
```

**Note on SeasonSystem dependency**: SeasonSystem is a future Core epic. The `Engine.has_singleton()` check ensures graceful degradation — production works correctly without it, returning 1.0 (no season modifier). When SeasonSystem is implemented, it will register itself as a singleton, and `_get_season_multiplier()` will automatically pick it up.

**Note on prestige levels**: `balance.json prestige.bonuses_per_level` has level "3" with `offline_production_bonus: 0.15`. Only levels with an `offline_production_bonus` key affect idle production — others (growth_rate_bonus, mutation_chance_bonus etc.) are ignored here.

---

## Out of Scope

- Story 002: core `_calculate()` formula — must be DONE
- HabitatSystem hutch bonus wiring — `_get_hutch_bonus()` stub remains 1.0 (wired in HabitatSystem epic)
- SeasonSystem implementation — that is a separate epic; this story only wires the call site
- Item-based multipliers (Alarm Bunny) — ADR-0010, future story

---

## QA Test Cases

- **AC-1**: prestige_count = 0 → prestige_bonus = 1.0
  - Given: `GameState.prestige_count = 0`
  - When: `system._get_prestige_bonus()`
  - Then: result == 1.0

- **AC-2**: prestige_count = 3 → prestige_bonus = 1.15
  - Given: `GameState.prestige_count = 3`; balance data includes level "3" with `offline_production_bonus: 0.15`
  - When: `system._get_prestige_bonus()`
  - Then: result == 1.15

- **AC-3**: prestige bonus scales production
  - Given: 20 ADULT rabbits; `_base_rate = 0.05`; prestige_count = 3 (bonus = 1.15); no season
  - When: `system.get_tick_earnings()`
  - Then: `r.carrot_coin == int(floor(20 * 0.05 * 1.15)) == 1`

- **AC-4**: no SeasonSystem → season_multiplier = 1.0 (no crash)
  - Given: SeasonSystem not registered
  - When: `system._get_season_multiplier()`
  - Then: returns `1.0` without error

- **AC-5**: injected season harvest_bonus = 0.5 → season_multiplier = 1.5
  - Given: mock or direct call with harvest_bonus = 0.5
  - When: production calc with season_mult = 1.5; 10 ADULT rabbits
  - Then: production is 1.5× what it would be at season_mult = 1.0
  - Edge case: verify autumn multiplier uses `harvest_bonus` key, not other season bonus keys

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/idle_production_integration_test.gd` — must exist and pass

**Status**: [x] `tests/integration/core/idle_production_integration_test.gd` — 6 test functions

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 6/6 passing
**Deviations**: `_get_prestige_bonus()` reads GameState autoload at runtime; integration tests verify table loading and formula correctness via direct `_prestige_offline_bonuses` injection (GameState absent in test env). SeasonSystem graceful degradation tested via absence check.
**Test Evidence**: Integration — `tests/integration/core/idle_production_integration_test.gd` ✅ (6 test functions)
**Code Review**: Skipped — Lean mode

---

## Dependencies

- Depends on: **Story 002 must be DONE** — `_calculate()` must exist with stub multipliers
- Unlocks: IdleProductionSystem epic complete (all 4 stories done = full production pipeline)
