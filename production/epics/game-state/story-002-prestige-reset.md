# Story 002: prestige_reset() Selective Wipe

> **Epic**: GameState
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-prestige-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Autoload Boot Sequence and GameState Ownership
**ADR Decision Summary**: `GameState.prestige_reset(keep: Dictionary)` is the sole entry point for resetting state on prestige. The caller (PrestigeSystem) determines what to preserve and passes it as the keep dict. GameState applies the reset atomically and calls `mark_dirty()`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: No post-cutoff engine concerns. Dictionary and Array operations are stable across 4.4–4.6.

**Control Manifest Rules (Foundation layer)**:
- Required: `mark_dirty()` must be called at the end of any mutation method
- Forbidden: `bypassing_mark_dirty`
- Forbidden: `direct_cross_system_state_write`

---

## Acceptance Criteria

*From ADR-0001 and GDD Prestige System:*

- [ ] `func prestige_reset(keep: Dictionary) -> void` exists on GameState
- [ ] Calling with an empty keep dict clears: `rabbits → []`, `hutches → []`, `active_expeditions → []`, `collection_registry → {}`
- [ ] `prestige_count` is incremented by 1 on every `prestige_reset` call regardless of keep contents
- [ ] Fields present in keep dict are restored: `keep.get("rabbits", [])` → `rabbits`; `keep.get("hutches", [])` → `hutches`; `keep.get("collection_registry", {})` → `collection_registry`
- [ ] `settings` and `last_save_timestamp` are never touched by `prestige_reset` (they survive prestige)
- [ ] `mark_dirty()` is called at the end of `prestige_reset()`
- [ ] GdUnit4: empty keep → all resetable fields cleared, `prestige_count` incremented
- [ ] GdUnit4: keep with data → specified data preserved in corresponding fields
- [ ] GdUnit4: `is_dirty == true` after prestige_reset completes

---

## Implementation Notes

*Derived from ADR-0001 Decision and GDD Prestige System rules:*

### GDD prestige rules (source of truth for what to reset vs. keep)

From GDD Section 5 — Prestige System:
- **Reset**: Carrot Coin balance, common rabbits, basic hutches
- **Keep**: Legendary rabbits, Guild rank, Blueprints, special items

GameState itself does not decide what is legendary — that is PrestigeSystem's job. PrestigeSystem filters the data and passes what to preserve via the keep dict. GameState applies it without questioning the contents.

### Implementation

```gdscript
## Selective prestige wipe. Caller provides filtered data to preserve.
## keep keys: "rabbits" (Array), "hutches" (Array), "collection_registry" (Dictionary)
## Fields not in keep are wiped to empty. prestige_count always increments.
## settings and last_save_timestamp are never reset.
func prestige_reset(keep: Dictionary) -> void:
    rabbits = keep.get("rabbits", [])
    hutches = keep.get("hutches", [])
    active_expeditions = []
    collection_registry = keep.get("collection_registry", {})
    prestige_count += 1
    mark_dirty()
```

### Fields that are NEVER reset by prestige

- `settings` — user preferences survive prestige
- `last_save_timestamp` — overwritten by SaveSystem on next save, not reset by prestige
- `is_dirty` — managed only by `mark_dirty()` and SaveSystem
- `pending_offline_report` — owned by SaveSystem during boot, not a prestige concern

### Caller responsibility (PrestigeSystem — Feature layer, not implemented yet)

```gdscript
# Example of what PrestigeSystem will do (NOT implemented in this story):
var keep := {
    "rabbits": GameState.rabbits.filter(func(r) -> bool: return r.is_legendary),
    "hutches": [],  # all hutches reset
    "collection_registry": GameState.collection_registry,  # collection survives
}
GameState.prestige_reset(keep)
EventBus.prestige_executed.emit(GameState.prestige_count)
```

---

## Out of Scope

*Handled by other epics:*
- PrestigeSystem (Feature layer) — deciding what is "legendary" and building the keep dict
- EconomyManager — wiping currency balances on prestige (handled in EconomyManager epic)
- Emitting `prestige_executed` signal — PrestigeSystem's responsibility after calling prestige_reset

---

## QA Test Cases

*Story Type: Logic — automated test specs*

**AC-1 + AC-2**: Empty keep dict clears all resetable fields
- Given: GameState with non-empty `rabbits`, `hutches`, `active_expeditions`, `collection_registry`
- When: `game_state.prestige_reset({})`
- Then: `rabbits == []`, `hutches == []`, `active_expeditions == []`, `collection_registry == {}`
- Edge cases: Already-empty arrays stay empty (idempotent)

**AC-3**: prestige_count increments
- Given: GameState with `prestige_count == 0`
- When: `game_state.prestige_reset({})`
- Then: `prestige_count == 1`
- Edge cases: Multiple resets accumulate: call twice → `prestige_count == 2`

**AC-4**: keep dict preserves specified data
- Given: GameState; a test rabbit dict `{"id": "legendary-1"}` in keep
- When: `game_state.prestige_reset({"rabbits": [{"id": "legendary-1"}]})`
- Then: `rabbits.size() == 1`, `rabbits[0]["id"] == "legendary-1"`
- Edge cases: Keep dict with unrecognised key → silently ignored, no crash

**AC-5**: settings and last_save_timestamp survive prestige
- Given: GameState with `settings["font_scale"] == 2.0`, `last_save_timestamp == 12345`
- When: `game_state.prestige_reset({})`
- Then: `settings["font_scale"] == 2.0`, `last_save_timestamp == 12345` (unchanged)

**AC-6 + AC-9**: mark_dirty called → is_dirty true after reset
- Given: GameState fresh (is_dirty == false)
- When: `game_state.prestige_reset({})`
- Then: `is_dirty == true`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/game_state_prestige_test.gd` — must exist and pass

```
tests/unit/core/game_state_prestige_test.gd
  test_empty_keep_clears_all_resetable_fields()
  test_prestige_count_increments_on_reset()
  test_keep_dict_preserves_specified_rabbits()
  test_settings_survive_prestige_reset()
  test_last_save_timestamp_survives_prestige_reset()
  test_is_dirty_true_after_prestige_reset()
  test_multiple_resets_accumulate_prestige_count()
```

**Status**: [x] Created — `tests/unit/core/game_state_prestige_test.gd`

---

## Dependencies

- Depends on: **Story 001 must be DONE** — prestige_reset modifies the fields defined in story-001
- Unlocks: PrestigeSystem epic (Feature layer) — needs this method to exist before prestige flow can be implemented

---

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 6/6 passing
**Deviations**: TR-prestige-002 not in tr-registry.yaml (empty registry); control manifest missing
**Test Evidence**: Logic: `tests/unit/core/game_state_prestige_test.gd` — 8 test functions
**Code Review**: Skipped — Lean mode
