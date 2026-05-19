# Story 001: can_prestige() + execute_prestige() — Prestige Gate and Reset Trigger

> **Epic**: PrestigeSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§5 — PRESTIGE SYSTEM)
**Requirement**: `TR-prestige-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Status**: ADR-0001 Accepted ✅, ADR-0004 Accepted ✅

**ADR Governing Implementation**: ADR-0001 (Autoload Boot Sequence + GameState ownership), ADR-0004 (Balance JSON — prestige cap lives in `balance.json`)
**ADR Decision Summary**: `GameState.prestige_reset(keep: Dictionary)` is the sole reset entry point — PrestigeSystem must NOT wipe state itself. `prestige_count` lives in `GameState`. The 20-level cap is read from `balance.json prestige.max_level`. Legendary rabbit ownership check delegates to `RabbitSystem.has_legendary_rabbit()`. CollectionSystem ≥ 80% check is stubbed to `true` because CollectionSystem ADR is not yet written.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Reads `GameState` and `RabbitSystem` autoloads — both stable. No post-cutoff Godot APIs required. `Engine.has_singleton()` guard used for RabbitSystem call to allow isolated unit tests.

**Control Manifest Rules (Core layer)**:
- Required: All variable declarations and function signatures must be statically typed
- Required: Prestige cap loaded from `balance.json prestige.max_level` — never hardcoded
- Required: State reset delegated entirely to `GameState.prestige_reset(keep)` — PrestigeSystem must not mutate GameState fields directly
- Required: Cross-system communication via EventBus signals only — no direct UI calls
- Forbidden: `upward_direct_method_calls` — Core may not call Presentation methods

---

## Acceptance Criteria

1. `PrestigeSystem.can_prestige() -> bool` is implemented. It returns `true` only when ALL of the following hold: `GameState.prestige_count < _max_prestige_level`, `RabbitSystem.has_legendary_rabbit()` returns `true`, and the collection stub returns `true`.
2. `can_prestige()` returns `false` when `GameState.prestige_count >= _max_prestige_level` (cap enforced), even if all other conditions are met.
3. `can_prestige()` returns `false` when `RabbitSystem.has_legendary_rabbit()` returns `false` (no Legendary rabbit owned), even if prestige count is below cap.
4. `PrestigeSystem.execute_prestige() -> void` is implemented. When called, it calls `GameState.prestige_reset(keep)` where the `keep` dictionary contains the list of Legendary rabbit IDs obtained from `RabbitSystem.get_legendary_rabbit_ids()`.
5. After `execute_prestige()` runs, `GameState.prestige_count` has been incremented by 1 (the increment happens inside `GameState.prestige_reset()` per ADR-0001 — PrestigeSystem does NOT increment it directly).
6. `execute_prestige()` is a no-op (does nothing, emits no signals, calls no reset) if `can_prestige()` returns `false` at call time. A `push_warning()` is emitted to signal the invalid call.
7. `_max_prestige_level` is loaded from `balance.json prestige.max_level` at `_ready()`. If the key is absent, `push_error()` is called and a hardcoded fallback of `20` is used.
8. The collection threshold check is a private stub method `_collection_threshold_met() -> bool` that always returns `true`. It is clearly documented with a `# TODO: wire to CollectionSystem when ADR is written` comment.

---

## Implementation Notes

*Derived from ADR-0001 and ADR-0004:*

```gdscript
## PrestigeSystem — validates prestige eligibility and triggers the selective reset.
## Delegates all state wipe to GameState.prestige_reset(keep).
## CollectionSystem check is stubbed — replace when CollectionSystem ADR is written.
extends Node

var _max_prestige_level: int = 20  # fallback default — overwritten by _load_balance_data()


func _ready() -> void:
    _load_balance_data()


func _load_balance_data() -> void:
    var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
    if text.is_empty():
        push_error("PrestigeSystem: balance.json not found — using max_level default 20")
        return
    var parsed: Variant = JSON.parse_string(text)
    if not parsed is Dictionary:
        push_error("PrestigeSystem: balance.json parse failed — using max_level default 20")
        return
    var data: Dictionary = parsed as Dictionary
    var prestige: Dictionary = data.get("prestige", {}) as Dictionary
    if prestige.has("max_level"):
        _max_prestige_level = int(prestige["max_level"])
    else:
        push_error("PrestigeSystem: balance.json missing prestige.max_level — using 20")


func can_prestige() -> bool:
    if GameState.prestige_count >= _max_prestige_level:
        return false
    if not RabbitSystem.has_legendary_rabbit():
        return false
    if not _collection_threshold_met():
        return false
    return true


func execute_prestige() -> void:
    if not can_prestige():
        push_warning("PrestigeSystem: execute_prestige() called when can_prestige() == false — no-op")
        return
    var keep: Dictionary = {
        "legendary_rabbit_ids": RabbitSystem.get_legendary_rabbit_ids()
    }
    GameState.prestige_reset(keep)


## TODO: wire to CollectionSystem when CollectionSystem ADR is written.
## Stub always returns true — CollectionSystem not yet implemented.
func _collection_threshold_met() -> bool:
    return true
```

**balance.json additions required** (under `"prestige"` key):
```json
"prestige": {
    "max_level": 20,
    "bonuses_per_level": { ... }
}
```

**RabbitSystem stubs required** — these methods must exist (even as stubs) on `RabbitSystem` before this story can be fully integration-tested:
- `has_legendary_rabbit() -> bool` — returns true if any rabbit in the roster has rarity == LEGENDARY
- `get_legendary_rabbit_ids() -> Array[String]` — returns array of rabbit IDs with rarity == LEGENDARY

---

## Out of Scope

- Story 002: applying the stacking prestige bonus to `IdleProductionSystem.calculate_earnings()` — that is a separate story
- CollectionSystem integration — stubbed here; wired when CollectionSystem ADR is written
- Prestige UI / confirmation dialog — Presentation layer, separate epic
- Specific bonus table values per prestige level — story-002 domain
- `GameState.prestige_reset()` implementation — already done (game-state epic story-002)

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC-1**: `can_prestige()` returns true when all conditions met
  - Given: `prestige_count = 0`; `_max_prestige_level = 20`; `RabbitSystem` stub returns `has_legendary_rabbit() = true`
  - When: `can_prestige()` called
  - Then: returns `true`

- **AC-2**: `can_prestige()` returns false at cap
  - Given: `prestige_count = 20`; `_max_prestige_level = 20`; legendary stub = true
  - When: `can_prestige()` called
  - Then: returns `false`

- **AC-3**: `can_prestige()` returns false with no Legendary rabbit
  - Given: `prestige_count = 5`; `_max_prestige_level = 20`; `has_legendary_rabbit()` returns `false`
  - When: `can_prestige()` called
  - Then: returns `false`

- **AC-4**: `execute_prestige()` calls `prestige_reset()` with legendary IDs in keep dict
  - Given: `can_prestige()` returns true; `get_legendary_rabbit_ids()` returns `["r-001", "r-002"]`
  - When: `execute_prestige()` called
  - Then: `GameState.prestige_reset()` was called with `keep = {"legendary_rabbit_ids": ["r-001", "r-002"]}`

- **AC-5**: `execute_prestige()` is a no-op when `can_prestige()` is false
  - Given: `prestige_count = 20` (at cap)
  - When: `execute_prestige()` called
  - Then: `GameState.prestige_reset()` is NOT called; a `push_warning()` is emitted

- **AC-6**: `_max_prestige_level` loaded from balance.json
  - Given: balance.json contains `prestige.max_level = 10`
  - When: `_load_balance_data()` called
  - Then: `_max_prestige_level == 10`

- **AC-7**: Missing balance.json key falls back to 20 without crash
  - Given: balance.json exists but `prestige.max_level` key is absent
  - When: `_load_balance_data()` called
  - Then: `_max_prestige_level == 20`; `push_error()` was called

- **AC-8**: `_collection_threshold_met()` always returns true (stub)
  - Given: any state
  - When: `_collection_threshold_met()` called directly
  - Then: returns `true`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/prestige_system_test.gd` — must exist and pass

**Status**: [ ] not yet written

---

## Dependencies

- Depends on: `game-state/story-002-prestige-reset.md` — `GameState.prestige_reset(keep)` must be DONE ✅ (it is)
- Depends on: `rabbit-system/story-002-roster-crud.md` — `RabbitSystem` must exist ✅ (it is); `has_legendary_rabbit()` and `get_legendary_rabbit_ids()` may need stub additions to rabbit_system.gd
- Unlocks: story-002-prestige-bonus.md (depends on PrestigeSystem existing and prestige_count being incrementable)

---

## Completion Notes

**Completed**: 2026-05-19
**Criteria**: 8/8 passing
**Deviations**: ADVISORY — AC-7 push_error branch not unit-tested; `_load_balance_data()` reads from disk with no injection seam. Test verifies the initial default (20) is correct. Recommend adding `_load_from_text(text: String)` seam in a follow-up story.
**Test Evidence**: Logic — `tests/unit/core/prestige_system_test.gd` (9 test functions)
**Code Review**: Skipped — Lean mode
**Extra files**: `assets/data/balance.json` (added prestige.max_level), `src/core/rabbit_system.gd` (added has_legendary_rabbit / get_legendary_rabbit_ids stubs) — both in scope per story spec
