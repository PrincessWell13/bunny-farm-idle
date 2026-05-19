# Story 001: Season Clock — Day Counter, Season Advancement, and season_changed Signal

> **Epic**: SeasonSystem
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.5 — Hệ thống Thời tiết & Mùa vụ)
**Requirement**: `TR-season-001`, `TR-season-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0001 Accepted ✅, ADR-0003 Accepted ✅, ADR-0004 Accepted ✅

**ADR Governing Implementation**: ADR-0001 (Autoload Boot Sequence), ADR-0003 (EventBus Signal Architecture), ADR-0004 (Balance JSON)
**ADR Decision Summary**: SeasonSystem connects to `TimeManager.tick` in `_ready()`. It accumulates elapsed seconds; when accumulated time ≥ `balance.json season.seconds_per_day`, it increments `day_within_season`. When `day_within_season` ≥ `balance.json season.days_per_season` (default 7), the season advances and `EventBus.season_changed(new_season)` is emitted. All timing parameters are loaded from `balance.json`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `TimeManager.tick` signal connection stable. Integer modulo arithmetic for season wrap is stable. No post-cutoff APIs required.

**Control Manifest Rules (Feature layer — uses Foundation rules)**:
- Required: All variable declarations and function signatures must be statically typed (F-02)
- Required: `seconds_per_day` and `days_per_season` loaded from `balance.json` at `_ready()` — never hardcoded (F-04)
- Required: `season_changed` emitted on `EventBus` only — no direct UI calls (F-03)
- Required: Disconnect `TimeManager.tick` in `_exit_tree()` (F-03)
- Forbidden: Hardcoded timing constants in `season_system.gd`

---

## Acceptance Criteria

1. `SeasonSystem.get_current_season() -> int` is implemented and returns the current season as an integer constant: `SPRING = 0`, `SUMMER = 1`, `AUTUMN = 2`, `WINTER = 3`
2. SeasonSystem accumulates elapsed seconds from `TimeManager.tick(delta)`. When accumulated seconds ≥ `_seconds_per_day`, `day_within_season` increments by 1 and the accumulator resets (subtract `_seconds_per_day`, do not zero-reset — preserves sub-day precision)
3. When `day_within_season` reaches `_days_per_season`, the season advances by 1 and `day_within_season` resets to 0
4. Season wraps: after `WINTER` (3) the next season is `SPRING` (0) — use modulo 4
5. On every season boundary, `EventBus.season_changed(new_season: int)` is emitted with the new season value
6. `_seconds_per_day` and `_days_per_season` are loaded from `balance.json` keys `season.seconds_per_day` and `season.days_per_season` respectively; if either key is absent, `push_error()` is called and fallback defaults are used (`seconds_per_day = 3600`, `days_per_season = 7`)
7. `get_current_season()` is a pure read — it does not advance the clock or mutate any state

---

## Implementation Notes

*Derived from ADR-0001, ADR-0003, ADR-0004:*

```gdscript
## SeasonSystem — tracks in-game season and day counter.
## Connects to TimeManager.tick. Emits EventBus.season_changed on season boundary.
## All timing from balance.json. No state persisted to GameState yet (SaveSystem epic).
extends Node

const SPRING: int = 0
const SUMMER: int = 1
const AUTUMN: int = 2
const WINTER: int = 3
const SEASON_COUNT: int = 4

var _seconds_per_day: float = 3600.0   # fallback: 1 real hour = 1 in-game day
var _days_per_season: int = 7          # fallback: 7 days per season

var _current_season: int = SPRING
var _day_within_season: int = 0
var _elapsed_seconds: float = 0.0


func _ready() -> void:
    _load_balance_data()
    TimeManager.tick.connect(_on_tick)


func _exit_tree() -> void:
    if TimeManager.tick.is_connected(_on_tick):
        TimeManager.tick.disconnect(_on_tick)


func _load_balance_data() -> void:
    var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
    if text.is_empty():
        push_error("SeasonSystem: balance.json not found — using defaults")
        return
    var parsed: Variant = JSON.parse_string(text)
    if not parsed is Dictionary:
        push_error("SeasonSystem: balance.json parse failed — using defaults")
        return
    var data: Dictionary = parsed as Dictionary
    var season: Dictionary = data.get("season", {}) as Dictionary
    if season.has("seconds_per_day"):
        _seconds_per_day = float(season["seconds_per_day"])
    else:
        push_error("SeasonSystem: balance.json missing season.seconds_per_day — using 3600")
    if season.has("days_per_season"):
        _days_per_season = int(season["days_per_season"])
    else:
        push_error("SeasonSystem: balance.json missing season.days_per_season — using 7")


func get_current_season() -> int:
    return _current_season


func _on_tick(delta: float) -> void:
    _elapsed_seconds += delta
    while _elapsed_seconds >= _seconds_per_day:
        _elapsed_seconds -= _seconds_per_day
        _advance_day()


func _advance_day() -> void:
    _day_within_season += 1
    if _day_within_season >= _days_per_season:
        _day_within_season = 0
        _current_season = (_current_season + 1) % SEASON_COUNT
        EventBus.season_changed.emit(_current_season)
```

**balance.json additions required** (under `"season"` key):
```json
"season": {
    "seconds_per_day": 3600,
    "days_per_season": 7,
    "multipliers": {
        "spring": { "production_mult": 1.0, "fertility_mult": 1.3, "growth_mult": 1.0, "offline_mult": 1.0 },
        "summer": { "production_mult": 1.0, "fertility_mult": 1.0, "growth_mult": 1.2, "offline_mult": 1.0 },
        "autumn": { "production_mult": 1.5, "fertility_mult": 1.0, "growth_mult": 1.0, "offline_mult": 1.0 },
        "winter": { "production_mult": 1.0, "fertility_mult": 1.0, "growth_mult": 1.0, "offline_mult": 1.3 }
    }
}
```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `get_active_multipliers()` — reads `_current_season` but defined in story-002
- SaveSystem epic: persisting `_current_season` and `_day_within_season` to `GameState`
- RabbitSystem: special seasonal rabbit spawning (separate epic)
- Special seasonal rabbit spawning — future story, triggered by `season_changed` signal

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC-1**: `get_current_season()` returns SPRING (0) at initialisation
  - Given: fresh `SeasonSystem` with `_current_season = SPRING`
  - When: `get_current_season()` called
  - Then: returns `0`

- **AC-2**: Day advances when accumulated seconds ≥ seconds_per_day
  - Given: `_seconds_per_day = 10.0`; `_elapsed_seconds = 0.0`; `_day_within_season = 0`
  - When: `_on_tick(10.0)` called (delta = 10 seconds)
  - Then: `_day_within_season == 1`; `_elapsed_seconds == 0.0`

- **AC-2b**: Sub-day precision preserved (accumulator subtracts, not zeros)
  - Given: `_seconds_per_day = 10.0`; `_elapsed_seconds = 0.0`
  - When: `_on_tick(11.5)` called
  - Then: `_day_within_season == 1`; `_elapsed_seconds == 1.5` (not 0.0)

- **AC-3**: Season advances when day_within_season reaches days_per_season
  - Given: `_days_per_season = 3`; `_day_within_season = 2`; `_current_season = SPRING`; `_seconds_per_day = 1.0`
  - When: `_on_tick(1.0)` called
  - Then: `_current_season == SUMMER (1)`; `_day_within_season == 0`

- **AC-4**: Season wraps from WINTER back to SPRING
  - Given: `_days_per_season = 1`; `_current_season = WINTER (3)`; `_day_within_season = 0`; `_seconds_per_day = 1.0`
  - When: `_on_tick(1.0)` called
  - Then: `_current_season == SPRING (0)`

- **AC-5**: season_changed signal emitted with correct new season int
  - Given: `_days_per_season = 1`; `_current_season = SPRING`; season_changed connected to recorder
  - When: season boundary crossed via tick
  - Then: recorded signal value == `SUMMER (1)`

- **AC-6**: Missing balance.json key falls back to defaults; no crash
  - Given: `_system._seconds_per_day` and `_system._days_per_season` set directly (bypass _load_balance_data)
  - When: ticks applied
  - Then: system advances correctly using injected values

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/season_system_clock_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/season_system_clock_test.gd` — exists (9 test functions)

---

## Dependencies

- Depends on: None — first SeasonSystem story
- Unlocks: Story 002 (`get_active_multipliers()`) reads `_current_season` and can be tested end-to-end once this story is done

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 7/7 passing (AC-6 covered by test injection pattern — balance.json I/O bypassed in tests via direct field assignment)
**Deviations**: ADVISORY — `var _seconds_per_day: float = 3600.0` in class body is a GDScript-side fallback default (overwritten by `_load_balance_data()` at runtime). Consistent with established pattern across project systems.
**Test Evidence**: Logic — `tests/unit/core/season_system_clock_test.gd` (9 functions, covers all 7 ACs including story-002 multiplier ACs)
**Code Review**: Skipped (lean mode)
