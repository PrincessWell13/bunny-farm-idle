# Story 003: Stat Decay Tick — hunger / cleanliness / health / happiness

> **Epic**: RabbitSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.1 — visible stat table)
**Requirement**: `TR-rabbit-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0004 Accepted ✅, ADR-0005 Accepted ✅

**ADR Governing Implementation**: ADR-0004 (balance.json loading pattern) + ADR-0005 (RabbitSystem is sole mutator of RabbitData fields)
**ADR Decision Summary**: All decay rates loaded from `balance.json "rabbit"` section in `_ready()`. `_tick_rabbit(rabbit, delta)` applies hunger decay, cleanliness decay, and conditional health decay (only when starving). Stats clamp at 0.0 minimum.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `FileAccess.get_file_as_string()` and `JSON.parse_string()` stable in 4.4–4.6. `_process(delta)` or a Timer with 1-second intervals both work. Use `_process` for smoother offline catch-up (pass larger deltas); use Timer for exact per-second ticks.

**Control Manifest Rules (Core layer)**:
- Forbidden: No hardcoded numeric decay values — all from balance.json
- Required: Fallback defaults documented if balance.json is absent or key missing

---

## Acceptance Criteria

*From GDD §3.1 stat table and ADR-0004 loading pattern:*

- [ ] `_load_balance_data()` reads `"rabbit"` section from `balance.json`; stores as typed instance variables
- [ ] `_tick_rabbit(rabbit: RabbitData, delta: float)` decreases `rabbit.hunger` by `_hunger_decay_rate * delta`
- [ ] `_tick_rabbit` decreases `rabbit.cleanliness` by `_cleanliness_decay_rate * delta`
- [ ] When `rabbit.hunger <= 0.0`: `rabbit.health` decreases by `_health_decay_when_starving * delta`
- [ ] When `rabbit.hunger > 0.0`: `rabbit.health` does NOT decrease from starvation
- [ ] `rabbit.hunger` clamps to `0.0` minimum (no negative values)
- [ ] `rabbit.health` clamps to `0.0` minimum
- [ ] All decay rates sourced from balance.json keys: `hunger_decay_per_second`, `health_decay_per_second_when_starving`, `cleanliness_decay_per_second`
- [ ] If balance.json is absent: `push_error(...)` logged; fallback defaults used (no crash)
- [ ] Grep: no multi-digit numeric decay literals in `rabbit_system.gd`

---

## Implementation Notes

*Derived from ADR-0004 loading pattern and ADR-0005 mutation contract:*

### Balance data loading

```gdscript
var _hunger_decay_rate: float = 0.5
var _health_decay_when_starving: float = 1.0
var _cleanliness_decay_rate: float = 0.1
var _happiness_decay_rate: float = 0.2

func _load_balance_data() -> void:
    var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
    if text.is_empty():
        push_error("RabbitSystem: balance.json not found — using defaults")
        return
    var parsed: Variant = JSON.parse_string(text)
    if not parsed is Dictionary:
        push_error("RabbitSystem: balance.json parse failed — using defaults")
        return
    var section: Dictionary = (parsed as Dictionary).get("rabbit", {}) as Dictionary
    _hunger_decay_rate = section.get("hunger_decay_per_second", _hunger_decay_rate)
    _health_decay_when_starving = section.get("health_decay_per_second_when_starving", _health_decay_when_starving)
    _cleanliness_decay_rate = section.get("cleanliness_decay_per_second", _cleanliness_decay_rate)
    _happiness_decay_rate = section.get("happiness_decay_per_second", _happiness_decay_rate)
```

### Tick function

```gdscript
func _tick_rabbit(rabbit: RabbitData, delta: float) -> void:
    rabbit.hunger = maxf(0.0, rabbit.hunger - _hunger_decay_rate * delta)
    rabbit.cleanliness = maxf(0.0, rabbit.cleanliness - _cleanliness_decay_rate * delta)
    if rabbit.hunger <= 0.0:
        rabbit.health = maxf(0.0, rabbit.health - _health_decay_when_starving * delta)
    rabbit.happiness = maxf(0.0, rabbit.happiness - _happiness_decay_rate * delta)
    _check_stage_advance(rabbit)   # Story 004 — stub until that story is done
    _check_death(rabbit)           # Story 005 — stub until that story is done
    GameState.mark_dirty()
```

### Ticking all rabbits

Call `_tick_rabbit` for every rabbit once per second. Use a Timer or accumulate delta:

```gdscript
var _tick_accumulator: float = 0.0

func _process(delta: float) -> void:
    _tick_accumulator += delta
    if _tick_accumulator >= 1.0:
        _tick_accumulator -= 1.0
        for rabbit: RabbitData in _rabbits.values():
            _tick_rabbit(rabbit, 1.0)
```

### Unit test pattern

Tests inject mock balance values directly (no file I/O):

```gdscript
func before_test() -> void:
    _system = RabbitSystemScript.new()
    _system._hunger_decay_rate = 0.5  # inject test values directly
    _system._health_decay_when_starving = 1.0
    _system._cleanliness_decay_rate = 0.1
```

---

## Out of Scope

- Story 004: `_check_stage_advance()` — stub as empty function here
- Story 005: `_check_death()` — stub as empty function here
- Story 006: `feed_rabbit()` — stat increases from feeding
- balance.json file creation — that is a Config/Data story in the balance epic

---

## QA Test Cases

- **AC-1**: hunger decreases by decay_rate × delta each tick
  - Given: rabbit with `hunger=100.0`; system with `_hunger_decay_rate=0.5`
  - When: `_tick_rabbit(rabbit, 1.0)`
  - Then: `rabbit.hunger == 99.5`
  - Edge cases: `delta=0.0` → hunger unchanged

- **AC-2**: health decreases when starving (hunger ≤ 0)
  - Given: rabbit with `hunger=0.0`, `health=80.0`; `_health_decay_when_starving=1.0`
  - When: `_tick_rabbit(rabbit, 1.0)`
  - Then: `rabbit.health == 79.0`

- **AC-3**: health NOT decreased when hunger > 0
  - Given: rabbit with `hunger=50.0`, `health=80.0`
  - When: `_tick_rabbit(rabbit, 1.0)`
  - Then: `rabbit.health == 80.0` (unchanged)

- **AC-4**: hunger clamps at 0.0 — no negative values
  - Given: rabbit with `hunger=0.3`; `_hunger_decay_rate=0.5`; `delta=1.0`
  - When: `_tick_rabbit(rabbit, 1.0)`
  - Then: `rabbit.hunger == 0.0` (not -0.2)

- **AC-5**: cleanliness decreases each tick
  - Given: rabbit with `cleanliness=100.0`; `_cleanliness_decay_rate=0.1`
  - When: `_tick_rabbit(rabbit, 1.0)`
  - Then: `rabbit.cleanliness == 99.9`

- **AC-6**: missing balance.json → uses defaults, no crash
  - Given: system where `_load_balance_data()` receives empty string
  - When: `_load_balance_data()`
  - Then: `push_error` logged; `_hunger_decay_rate` retains default value; system operational

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/rabbit_system_decay_test.gd` — must exist and pass

**Status**: [x] `tests/unit/core/rabbit_system_decay_test.gd` — 7 test functions

---

## Dependencies

- Depends on: **Story 002 must be DONE** — `_tick_rabbit` operates on rabbits in the roster
- Unlocks: Story 004 (lifecycle — stage advance hooks into tick loop)

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 10/10 passing
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/core/rabbit_system_decay_test.gd` ✅
**Code Review**: Skipped — Lean mode
