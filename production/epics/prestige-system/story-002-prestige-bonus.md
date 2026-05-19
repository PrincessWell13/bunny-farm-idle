# Story 002: Prestige Bonus — Stacking Production Multiplier in IdleProductionSystem

> **Epic**: PrestigeSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§5 — PRESTIGE SYSTEM)
**Requirement**: `TR-prestige-001`, `TR-prestige-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0004 Accepted ✅, ADR-0007 Accepted ✅

**ADR Governing Implementation**: ADR-0004 (Balance JSON — all bonus values in `balance.json prestige.bonuses_per_level`), ADR-0007 (Idle Production Formula — `prestige_bonus` from `GameState.prestige_count` is factored into `calculate_earnings()`)
**ADR Decision Summary**: `IdleProductionSystem` reads `GameState.prestige_count` and maps it to a `growth_rate_bonus` from `balance.json prestige.bonuses_per_level`. The bonus is additive: `prestige_multiplier = 1.0 + bonus_for_current_level`. The highest level entry with `level <= prestige_count` is used (e.g., prestige_count = 3 uses level "3" entry; prestige_count = 7 uses level "5" since that is the highest defined). This story modifies `src/core/idle_production_system.gd` only — it does NOT touch `prestige_system.gd`.

**balance.json discrepancy note**: `balance.json` currently defines only 5 prestige levels (`"1"` through `"5"`). The GDD specifies a 20-level bonus table with entries at levels 1, 2, 3, 4, 5, 10, and 20. This story implements against what is in `balance.json` (levels 1–5 defined). The missing levels 6–20 are out of scope — a future story or balance pass will add them. The lookup logic uses the highest defined level ≤ `prestige_count` so it is forward-compatible when new levels are added.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Reads `GameState.prestige_count` from autoload (stable). Dictionary iteration and key comparison are stable GDScript 4 patterns. No post-cutoff APIs required.

**Control Manifest Rules (Core layer)**:
- Required: All variable declarations and function signatures must be statically typed
- Required: Prestige bonus values loaded from `balance.json prestige.bonuses_per_level` — never hardcoded in `idle_production_system.gd`
- Required: `growth_rate_bonus` key used for production multiplier (not `offline_production_bonus` — that key is for offline catch-up already wired in story-004)
- Forbidden: `upward_direct_method_calls` — Core may not call Presentation methods

---

## Acceptance Criteria

1. `IdleProductionSystem` exposes a private method `_get_prestige_growth_bonus() -> float` that returns `1.0` when `GameState.prestige_count == 0`.
2. When `prestige_count == 1` and `balance.json` has level `"1"` with `growth_rate_bonus: 0.05`, `_get_prestige_growth_bonus()` returns `1.05`.
3. When `prestige_count == 5` and level `"5"` has `growth_rate_bonus: 0.25`, `_get_prestige_growth_bonus()` returns `1.25`.
4. When `prestige_count == 7` (no level `"7"` defined in balance.json — only up to `"5"`), `_get_prestige_growth_bonus()` returns the bonus for the highest defined level ≤ 7, which is level `"5"` → `1.25`. The lookup does NOT return `1.0` for undefined intermediate levels.
5. `_get_prestige_growth_bonus()` is factored into `calculate_earnings()` / `get_tick_earnings()` as a multiplier applied to the base production rate (alongside the existing season and offline multipliers from story-004).
6. `_prestige_growth_bonuses` dictionary is loaded from `balance.json prestige.bonuses_per_level` in `_load_balance_data()` — extracting only `growth_rate_bonus` values into an `int → float` lookup (or `String → float` matching the JSON key pattern).
7. If `balance.json prestige.bonuses_per_level` is absent or empty, `_get_prestige_growth_bonus()` returns `1.0` without error.

---

## Implementation Notes

*Derived from ADR-0007 and ADR-0004:*

Add to `src/core/idle_production_system.gd`:

```gdscript
## Maps prestige level (int) → growth_rate_bonus (float).
## Loaded from balance.json prestige.bonuses_per_level.
## Only levels with a growth_rate_bonus key are stored.
var _prestige_growth_bonuses: Dictionary = {}  # int → float
```

Extend `_load_balance_data()` to load growth bonuses:
```gdscript
var prestige_section: Dictionary = data.get("prestige", {}) as Dictionary
var bonuses_per_level: Dictionary = prestige_section.get("bonuses_per_level", {}) as Dictionary
for level_str: String in bonuses_per_level:
    var level_bonuses: Dictionary = bonuses_per_level[level_str] as Dictionary
    var growth_bonus: float = level_bonuses.get("growth_rate_bonus", 0.0) as float
    if growth_bonus > 0.0:
        _prestige_growth_bonuses[int(level_str)] = growth_bonus
```

Add `_get_prestige_growth_bonus()`:
```gdscript
func _get_prestige_growth_bonus() -> float:
    var prestige_count: int = GameState.prestige_count
    if prestige_count <= 0 or _prestige_growth_bonuses.is_empty():
        return 1.0
    # Find the highest defined level that is <= prestige_count
    var best_level: int = 0
    for level: int in _prestige_growth_bonuses:
        if level <= prestige_count and level > best_level:
            best_level = level
    if best_level == 0:
        return 1.0
    return 1.0 + (_prestige_growth_bonuses[best_level] as float)
```

Wire into production formula (modify `_calculate()` or `get_tick_earnings()`):
```gdscript
# Existing call sites already have: season_mult * prestige_offline_bonus
# Add prestige_growth_bonus alongside the existing multipliers:
var prestige_growth: float = _get_prestige_growth_bonus()
# ... apply to base_rate or total earnings as an additive multiplier
```

**balance.json prestige.bonuses_per_level** (current state for reference):
```json
"prestige": {
    "max_level": 20,
    "bonuses_per_level": {
        "1": { "growth_rate_bonus": 0.05, "offline_production_bonus": 0.05 },
        "2": { "growth_rate_bonus": 0.10, "offline_production_bonus": 0.10 },
        "3": { "growth_rate_bonus": 0.15, "offline_production_bonus": 0.15 },
        "4": { "growth_rate_bonus": 0.20, "offline_production_bonus": 0.20 },
        "5": { "growth_rate_bonus": 0.25, "offline_production_bonus": 0.25 }
    }
}
```

**GDD vs balance.json gap**: GDD specifies bonus entries at levels 1, 2, 3, 4, 5, 10, and 20. balance.json currently has only levels 1–5. The highest-defined-level lookup logic in `_get_prestige_growth_bonus()` ensures that when levels 6–20 are added to balance.json later, the behaviour automatically becomes correct without code changes.

---

## Out of Scope

- `_get_prestige_offline_bonus()` — already implemented in story-004 (uses `offline_production_bonus` key). This story adds the separate `growth_rate_bonus` path.
- Non-production bonuses from the GDD bonus table (Mutation Chance +8%, expedition slot, Cosmic Hutch unlock, Legendary chance +0.5%, Cosmic Rabbit unlock) — those affect other systems and are out of scope for this story.
- CollectionSystem prerequisite check — that belongs to story-001 (`can_prestige()`).
- Adding levels 6–20 to balance.json — out of scope; a future balance pass story.
- PrestigeSystem (`prestige_system.gd`) — this story modifies `idle_production_system.gd` only.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC-1**: prestige_count = 0 → growth bonus = 1.0
  - Given: `GameState.prestige_count = 0`; `_prestige_growth_bonuses` loaded with levels 1–5
  - When: `system._get_prestige_growth_bonus()`
  - Then: returns `1.0`

- **AC-2**: prestige_count = 1 → growth bonus = 1.05
  - Given: `GameState.prestige_count = 1`; `_prestige_growth_bonuses = {1: 0.05, 2: 0.10, ...}`
  - When: `system._get_prestige_growth_bonus()`
  - Then: returns `1.05`

- **AC-3**: prestige_count = 5 → growth bonus = 1.25
  - Given: `GameState.prestige_count = 5`; `_prestige_growth_bonuses = {1: 0.05, 2: 0.10, 3: 0.15, 4: 0.20, 5: 0.25}`
  - When: `system._get_prestige_growth_bonus()`
  - Then: returns `1.25`

- **AC-4**: prestige_count = 7 (no level 7 defined) → falls back to highest defined level ≤ 7 = level 5 → 1.25
  - Given: `GameState.prestige_count = 7`; `_prestige_growth_bonuses` has keys 1–5 only
  - When: `system._get_prestige_growth_bonus()`
  - Then: returns `1.25` (not `1.0`)

- **AC-5**: empty bonus table → growth bonus = 1.0 (no crash)
  - Given: `_prestige_growth_bonuses = {}`
  - When: `system._get_prestige_growth_bonus()`
  - Then: returns `1.0` without error

- **AC-6**: growth bonus factored into tick earnings
  - Given: 20 ADULT rabbits; `_base_rate = 0.05`; `prestige_count = 5` (growth_bonus = 1.25); season_mult = 1.0; offline_bonus = 1.0
  - When: `system.get_tick_earnings()` for 1 second
  - Then: `carrot_coin == int(floor(20 * 0.05 * 1.25)) == int(floor(1.25)) == 1`

- **AC-7**: growth bonus is distinct from offline bonus (both active simultaneously)
  - Given: `prestige_count = 3`; growth_rate_bonus = 0.15 → growth_mult = 1.15; offline_production_bonus = 0.15 → offline_mult = 1.15; 20 ADULT rabbits; offline duration = 60 seconds
  - When: `system.calculate_offline_earnings(60)` (offline path)
  - Then: both multipliers apply — offline earnings reflect both the growth and offline bonuses

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/prestige_bonus_test.gd` — must exist and pass

**Status**: [ ] not yet written

---

## Dependencies

- Depends on: `prestige-system/story-001-can-prestige-execute.md` — PrestigeSystem must exist and `GameState.prestige_count` must be incrementable via `execute_prestige()`. story-001 must be DONE before this story is dev-started.
- Depends on: `idle-production-system/story-004-season-prestige-integration.md` — `_get_prestige_bonus()` (offline path) already implemented; this story adds the separate `growth_rate_bonus` path alongside it. story-004 must be DONE ✅ (it is).
- Unlocks: PrestigeSystem epic complete (both stories done = prestige gate + bonus both functional)

---

## Completion Notes

**Completed**: —
**Criteria**: —
**Deviations**: —
**Test Evidence**: Logic — `tests/unit/core/prestige_bonus_test.gd`
**Code Review**: —
