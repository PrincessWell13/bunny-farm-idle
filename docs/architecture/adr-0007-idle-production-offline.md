# ADR-0007: Idle Production Formula and Offline Catch-Up Calculation

## Status
Accepted

## Date
2026-05-16

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — pure GDScript arithmetic; no engine API surface beyond `Time.get_unix_time_from_system()` |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None — `Time.get_unix_time_from_system()` stable since Godot 4.0 |
| **Verification Required** | Confirm `Time.get_unix_time_from_system()` returns correct Unix seconds in Android/iOS exported builds — previously `OS.get_unix_time()` (deprecated in 4.0, removed by 4.4) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (TimeManager owns offline_delta and the 1-second tick; SaveSystem calls IdleProductionSystem on boot), ADR-0004 (all production rates and multipliers from balance.json), ADR-0005 (RabbitSystem.get_all_rabbits() as input to production calc) |
| **Enables** | Any story implementing idle income, offline reward popup, or prestige offline bonus |
| **Blocks** | All idle production and offline catch-up stories until Accepted |
| **Ordering Note** | No dependency on ADR-0006 (Genetics) — production is based on rabbit count and stage, not genome |

## Context

### Problem Statement
The game's core idle loop produces Carrot Coins over time at a rate determined by rabbit count, hutch bonuses, season multipliers, and the player's online/offline state. When the player returns after being offline, the game must calculate and award the earnings they accumulated. This calculation must be: (a) deterministic given the same inputs, (b) separated from side effects (no currency mutation inside the formula), (c) bounded by a hard cap so whales cannot AFK for months, and (d) tunable from `balance.json`.

### Constraints
- `calculate_offline_earnings()` must be a pure function with no side effects — caller passes result to `EconomyManager.add()` (ADR-0003 data-down rule)
- All production rates, multipliers, and caps loaded from `balance.json` (ADR-0004)
- Max offline credit: 72 hours (from `balance.json idle_production.max_offline_hours`)
- Tiered multipliers: background 75%, offline <4h 60%, offline 4–12h 50%, offline >12h 40%
- Idle tick runs once per second (TimeManager 1-second timer from ADR-0001)

### Requirements
- Must produce Carrot Coins per second based on rabbit count and modifiers
- Must apply the correct offline multiplier tier based on absence duration
- Must not credit more than `max_offline_hours` of production regardless of actual absence
- Must produce an `EarningsReport` consumable by EconomyManager and the offline reward UI
- Must be unit-testable with injected inputs (no calls to autoloads inside the formula function)

## Decision

**`IdleProductionSystem` is a stateless calculation node.** It exposes two public methods: `get_tick_earnings()` for the real-time 1-second tick, and `calculate_offline_earnings(delta_seconds)` for catch-up on resume. Both return an `EarningsReport`. Neither method mutates any state — the caller is responsible for passing the result to `EconomyManager`.

### Production Formula

```
base_rate = balance.json idle_production.base_cc_per_rabbit_per_second
           = 0.05 CC/rabbit/second

tick_earnings = floor(
    rabbit_count_productive
    × base_rate
    × hutch_bonus_multiplier
    × season_multiplier
    × prestige_bonus
    × delta_seconds
)
```

Where:
- `rabbit_count_productive` = count of ADULT + ELDER rabbits (BABY and JUVENILE do not produce)
- `hutch_bonus_multiplier` = product of all active hutch production bonuses (from HabitatSystem)
- `season_multiplier` = 1.0 + current season harvest_bonus (from SeasonSystem; autumn = 1.5)
- `prestige_bonus` = 1.0 + `offline_production_bonus` from prestige level (from GameState)
- `delta_seconds` = elapsed seconds (1.0 for real-time tick; large value for offline catch-up)

`floor()` is applied once at the end — not per multiplicand — to avoid precision drift accumulation.

### Offline Multiplier Tier Selection

```gdscript
func _get_offline_multiplier(offline_seconds: float) -> float:
    # Thresholds from balance.json
    var hours: float = offline_seconds / 3600.0
    if offline_seconds <= 0.0:
        return 1.0  # online / foreground
    elif hours < 4.0:
        return _multiplier_under_4h      # 0.60
    elif hours < 12.0:
        return _multiplier_4_to_12h     # 0.50
    else:
        return _multiplier_over_12h     # 0.40
    # Note: background (0.75) is handled separately — TimeManager tracks
    # whether the app was backgrounded vs fully closed
```

Background multiplier (0.75) applies when `TimeManager.was_backgrounded()` returns true — the app was minimised but not killed. `TimeManager` records this distinction via `NotificationWM_GO_BACK_REQUEST` / `NotificationApplication_Paused` on mobile.

### Offline Cap

```gdscript
var capped_seconds: float = min(offline_seconds, _max_offline_hours * 3600.0)
```

Applied before the formula. No earnings are credited beyond the cap regardless of actual absence time.

### Implementation

```gdscript
# src/core/idle_production_system.gd
class_name IdleProductionSystem extends Node

# Loaded from balance.json in _ready()
var _base_rate: float = 0.05
var _multiplier_background: float = 0.75
var _multiplier_under_4h: float = 0.60
var _multiplier_4_to_12h: float = 0.50
var _multiplier_over_12h: float = 0.40
var _max_offline_hours: float = 72.0

func get_tick_earnings() -> EarningsReport:
    return _calculate(1.0, 1.0)  # 1 second, full online rate

func calculate_offline_earnings(offline_seconds: float, was_backgrounded: bool) -> EarningsReport:
    var capped: float = min(offline_seconds, _max_offline_hours * 3600.0)
    var multiplier: float = _multiplier_background if was_backgrounded else _get_offline_multiplier(capped)
    return _calculate(capped, multiplier)

# Pure function — no side effects, no autoload calls
func _calculate(delta_seconds: float, offline_multiplier: float) -> EarningsReport:
    var productive_count: int = _count_productive_rabbits()
    var hutch_bonus: float = _get_hutch_bonus()
    var season_mult: float = _get_season_multiplier()
    var prestige_bonus: float = _get_prestige_bonus()

    var raw: float = (productive_count
                      * _base_rate
                      * hutch_bonus
                      * season_mult
                      * prestige_bonus
                      * offline_multiplier
                      * delta_seconds)
    var cc_earned: int = int(floor(raw))

    var report: EarningsReport = EarningsReport.new()
    report.carrot_coin = cc_earned
    report.star_dust = 0  # Star Dust not from idle production (from expeditions only)
    report.applied_multiplier = offline_multiplier
    report.delta_seconds = delta_seconds
    report.source_breakdown = [
        {"rabbits": productive_count, "base_rate": _base_rate,
         "hutch_bonus": hutch_bonus, "season_mult": season_mult,
         "prestige_bonus": prestige_bonus}
    ]
    return report
```

### EarningsReport Value Object

```gdscript
# src/core/earnings_report.gd
class_name EarningsReport extends RefCounted

var carrot_coin: int = 0
var star_dust: int = 0
var applied_multiplier: float = 1.0
var delta_seconds: float = 0.0
var source_breakdown: Array = []
```

### Integration with Caller

`IdleProductionSystem` never calls `EconomyManager.add()` itself. The caller pattern:

```gdscript
# In the TimeManager 1-second tick handler (connected via EventBus):
func _on_tick() -> void:
    var report: EarningsReport = IdleProductionSystem.get_tick_earnings()
    if report.carrot_coin > 0:
        EconomyManager.add(EconomyManager.CurrencyType.CARROT_COIN, report.carrot_coin)
    EventBus.production_ticked.emit(report.carrot_coin, report.star_dust)

# In SaveSystem.load_game() boot sequence:
func _apply_offline_catch_up() -> void:
    var delta: float = TimeManager.get_offline_delta()
    var was_bg: bool = TimeManager.was_backgrounded()
    var report: EarningsReport = IdleProductionSystem.calculate_offline_earnings(delta, was_bg)
    if report.carrot_coin > 0:
        EconomyManager.add(EconomyManager.CurrencyType.CARROT_COIN, report.carrot_coin)
    # UI layer reads EarningsReport from a GameState field to show the reward popup
    GameState.pending_offline_report = report
    GameState.mark_dirty()
```

### Architecture Diagram

```
TimeManager (1-sec tick)
    │
    ▼
IdleProductionSystem.get_tick_earnings()
    │   (pure — reads RabbitSystem, HabitatSystem, SeasonSystem, GameState)
    ▼
EarningsReport
    │
    ├──► EconomyManager.add(CARROT_COIN, amount)
    └──► EventBus.production_ticked.emit(cc, sd)   ──► HUD (update label)

SaveSystem.load_game()
    │
    ├──► TimeManager.get_offline_delta()
    ├──► IdleProductionSystem.calculate_offline_earnings(delta, was_bg)
    └──► EconomyManager.add(CARROT_COIN, amount)
         GameState.pending_offline_report = report  ──► OfflineRewardUI
```

## Alternatives Considered

### Alternative B: Accumulate fractional CC and flush on whole-number crossings
- **Description**: Track `_fractional_cc: float` between ticks; only call `EconomyManager.add()` when it exceeds 1.0.
- **Pros**: More granular CC accumulation; smoother at very low rates.
- **Cons**: Fractional state must be serialised to `GameState` and saved — adds state that can get out of sync. With 24 adult rabbits × 0.05 CC/sec = 1.2 CC/sec, the tick already produces whole CCs on every tick.
- **Rejection Reason**: At the target rabbit count the tick always produces ≥1 CC/second. Fractional accumulation adds save state complexity for no observable player benefit.

### Alternative C: Server-side offline calculation (Firebase Cloud Function)
- **Description**: Firebase Cloud Function calculates offline earnings on the server at session start.
- **Pros**: Cheat-resistant — client cannot manipulate offline duration.
- **Cons**: Requires network on app launch before the player can see their rewards. Adds latency and failure states. The game is explicitly local-first (ADR-0008). Idle math is not a significant cheat vector for this game type.
- **Rejection Reason**: Contradicts local-first save architecture (ADR-0008). Network dependency at boot is unacceptable. Offline math is deterministic — player can verify locally.

## Consequences

### Positive
- `calculate_offline_earnings()` is a pure function — fully unit-testable with injected rabbit counts and delta values
- EarningsReport carries enough data for the offline reward popup (breakdown by source) without a second calculation
- Formula is entirely defined by balance.json values — rebalancing requires no code change
- `floor()` applied once at the end prevents floating-point drift in long offline sessions

### Negative
- `IdleProductionSystem._calculate()` reads from `RabbitSystem`, `HabitatSystem`, `SeasonSystem`, and `GameState` — these must all be initialised before `calculate_offline_earnings()` is called at boot. The `call_deferred` in the boot sequence (ADR-0001) ensures this.
- Binary offline multiplier tiers (not continuous) create a visible reward cliff at the 4-hour and 12-hour boundaries. Acceptable per GDD design intent.
- Item-based offline modifiers (Alarm Bunny +70%) are not included in this ADR — covered separately in ADR-0010 (item system).

### Risks
- **Risk**: `Time.get_unix_time_from_system()` returns wrong value in exported Android build if device clock changes between sessions.
  - **Mitigation**: Cap offline delta at `max_offline_hours * 3600` regardless of calculated delta. Any anomalously large delta (> 30 days) is treated as corrupted and reset to `max_offline_hours`.
- **Risk**: Player exploits clock manipulation (set device clock forward) to gain extra offline earnings.
  - **Mitigation**: Cap enforced client-side. Future ADR-0008 Firebase backend can validate timestamps server-side if this becomes a problem.

## GDD Requirements Addressed

| GDD Req ID | GDD Section | Requirement | How This ADR Addresses It |
|------------|-------------|-------------|--------------------------|
| TR-idle-001 | §3.12 | Real-time idle production (online = 100%) | `get_tick_earnings()` called on every 1-second TimeManager tick |
| TR-idle-002 | §3.12 | Offline catch-up applied on app resume | `calculate_offline_earnings(delta, was_bg)` called by SaveSystem.load_game() |
| TR-idle-003 | §3.12 | 4 tiered offline multipliers (background 75%, <4h 60%, 4–12h 50%, >12h 40%) | `_get_offline_multiplier()` tier selection + `was_backgrounded` flag |
| TR-season-001 | §3.5 | Season multipliers affect production | `season_mult` from SeasonSystem factored into formula |
| TR-prestige-001 | §4 | Prestige bonuses persist and affect production | `prestige_bonus` from GameState.prestige_count factored into formula |

## Performance Implications
- **CPU**: Formula is 6 multiplications + 1 floor() = sub-microsecond. Runs once per second. Completely negligible.
- **CPU** (offline catch-up): Single call at boot with a large delta_seconds. Same formula, no loop. <0.01ms.
- **Memory**: `EarningsReport` is a `RefCounted` — GC'd immediately after being processed. No ongoing allocation.
- **Load Time**: Offline calculation adds <0.1ms to boot. No impact.
- **Network**: No impact — calculation is entirely local.

## Migration Plan
Greenfield — create `src/core/idle_production_system.gd` and `src/core/earnings_report.gd` before any story implementing the idle tick or offline reward popup.

## Validation Criteria
- [ ] GdUnit4 test: `calculate_offline_earnings(0, false)` returns `EarningsReport.carrot_coin == 0`
- [ ] GdUnit4 test: 24 adult rabbits × 1 second online → `carrot_coin == floor(24 × 0.05 × 1.0)` = 1
- [ ] GdUnit4 test: offline_seconds = 3 × 3600 (3 hours) → `applied_multiplier == 0.60`
- [ ] GdUnit4 test: offline_seconds = 8 × 3600 (8 hours) → `applied_multiplier == 0.50`
- [ ] GdUnit4 test: offline_seconds = 20 × 3600 (20 hours) → `applied_multiplier == 0.40`
- [ ] GdUnit4 test: offline_seconds = 100 × 3600 (100 hours > cap) → delta capped at 72 × 3600
- [ ] GdUnit4 test: BABY rabbits not counted in productive_count
- [ ] `calculate_offline_earnings()` does not call `EconomyManager.add()` directly (static analysis / grep)

## Related Decisions
- ADR-0001: TimeManager drives the 1-second tick; SaveSystem calls offline catch-up during boot sequence
- ADR-0004: All production rates and multiplier values in `balance.json idle_production` section
- ADR-0005: `RabbitSystem.get_all_rabbits()` provides rabbit count input to formula
- ADR-0010 (pending): Item-based offline modifiers (Alarm Bunny +70%) extend `_calculate()` with item_boost parameter
