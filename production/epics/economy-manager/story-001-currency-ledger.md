# Story 001: Currency Ledger — add/spend/get/set

> **Epic**: EconomyManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-economy-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Autoload Boot Sequence and GameState Ownership
**ADR Decision Summary**: EconomyManager is autoload #3. It owns the 4 currency ledgers and initialises them to zero in `_ready()`. SaveSystem populates balances via `set_balance()` after loading the save. All systems read balances via `get_balance()` and write via `add()` or `spend()` — never by direct field access.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Dictionary` keyed by enum int is the simplest ledger. `enum CurrencyType` in a named class is stable in 4.4–4.6. No post-cutoff APIs required.

**Control Manifest Rules (Foundation layer)**:
- Forbidden: `calling_later_autoload_in_ready` — EconomyManager (autoload #3) may only reference EventBus (#1) and TimeManager (#2) — but this story requires NO EventBus calls (signal emission is story 002)
- Forbidden: `currency_ledgers` state accessed by other systems directly — only EconomyManager methods may read or write `_balances`

---

## Acceptance Criteria

*From ADR-0001 Ownership Rules and EconomyManager epic key interfaces:*

- [ ] `class_name EconomyManager extends Node` exists at `src/core/economy_manager.gd`
- [ ] `enum CurrencyType { CARROT_COIN, STAR_DUST, CRYSTAL_GEM, GENE_FRAGMENT }` declared on EconomyManager
- [ ] All 4 currency balances initialise to `0` in `_ready()`
- [ ] `func add(currency: CurrencyType, amount: int) -> void` exists; increases the balance by `amount`
- [ ] `add()` with `amount <= 0` is a no-op (guard against invalid inputs)
- [ ] `func spend(currency: CurrencyType, amount: int) -> bool` exists; returns `true` and deducts `amount` when balance is sufficient; returns `false` and changes nothing when insufficient
- [ ] Balance never goes below `0` (spend on insufficient funds returns `false`, no deduction)
- [ ] `func get_balance(currency: CurrencyType) -> int` exists; returns current balance
- [ ] `func set_balance(currency: CurrencyType, amount: int) -> void` exists; sets balance to `amount` directly (SaveSystem boot use only)
- [ ] EconomyManager instantiates in GdUnit4 without any autoload or scene dependency
- [ ] GdUnit4: `add(CARROT_COIN, 100)` → `get_balance(CARROT_COIN) == 100`
- [ ] GdUnit4: `spend(CARROT_COIN, 50)` when balance is 100 → returns `true`, balance is 50
- [ ] GdUnit4: `spend(CARROT_COIN, 200)` when balance is 100 → returns `false`, balance unchanged at 100
- [ ] GdUnit4: `set_balance(STAR_DUST, 999)` → `get_balance(STAR_DUST) == 999`
- [ ] GdUnit4: all 4 currencies operate independently (CARROT_COIN add does not affect STAR_DUST)

---

## Implementation Notes

*Derived from ADR-0001 Ownership Rules:*

### Ledger structure

```gdscript
class_name EconomyManager extends Node

enum CurrencyType { CARROT_COIN, STAR_DUST, CRYSTAL_GEM, GENE_FRAGMENT }

var _balances: Dictionary = {}

func _ready() -> void:
    _balances = {
        CurrencyType.CARROT_COIN:   0,
        CurrencyType.STAR_DUST:     0,
        CurrencyType.CRYSTAL_GEM:   0,
        CurrencyType.GENE_FRAGMENT: 0,
    }
```

### add()

```gdscript
func add(currency: CurrencyType, amount: int) -> void:
    if amount <= 0:
        return
    _balances[currency] += amount
```

### spend()

```gdscript
func spend(currency: CurrencyType, amount: int) -> bool:
    if amount <= 0:
        return false
    if _balances[currency] < amount:
        return false
    _balances[currency] -= amount
    return true
```

### get_balance() / set_balance()

```gdscript
func get_balance(currency: CurrencyType) -> int:
    return _balances[currency]

## Called by SaveSystem only — sets balance to saved value at boot.
func set_balance(currency: CurrencyType, amount: int) -> void:
    _balances[currency] = max(0, amount)
```

### No EventBus in this story

`add()` and `spend()` do not yet emit `EventBus.currency_changed`. Signal wiring is story 002. This keeps the ledger unit-testable in complete isolation — no autoload dependency.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `EventBus.currency_changed` signal emission in `add()` and `spend()`
- SaveSystem epic: the actual `set_balance()` calls during `_populate_game_state()`
- Feature layer: sell price formulas, loot tables, expedition rewards — those systems call `add()` and `spend()`

---

## QA Test Cases

**AC-1 (add increases balance)**:
- Given: EconomyManager fresh; CARROT_COIN balance = 0
- When: `add(CARROT_COIN, 100)` called
- Then: `get_balance(CARROT_COIN) == 100`
- Edge cases: `add(CARROT_COIN, 0)` → balance unchanged; `add(CARROT_COIN, -5)` → balance unchanged

**AC-2 (spend succeeds when sufficient)**:
- Given: balance = 100 after `add(CARROT_COIN, 100)`
- When: `spend(CARROT_COIN, 50)` called
- Then: returns `true`; `get_balance(CARROT_COIN) == 50`
- Edge cases: spend exactly the full balance → returns `true`; balance = 0

**AC-3 (spend fails when insufficient)**:
- Given: balance = 100
- When: `spend(CARROT_COIN, 200)` called
- Then: returns `false`; `get_balance(CARROT_COIN) == 100` (unchanged)
- Edge cases: balance = 0, spend 1 → returns `false`

**AC-4 (set_balance sets directly)**:
- Given: EconomyManager fresh
- When: `set_balance(STAR_DUST, 999)` called
- Then: `get_balance(STAR_DUST) == 999`
- Edge cases: `set_balance(STAR_DUST, -5)` → clamped to 0

**AC-5 (currencies are independent)**:
- Given: fresh EconomyManager
- When: `add(CARROT_COIN, 500)`; `add(STAR_DUST, 10)`
- Then: `get_balance(CARROT_COIN) == 500`; `get_balance(STAR_DUST) == 10`; `get_balance(CRYSTAL_GEM) == 0`

**AC-6 (all currencies initialise to zero)**:
- Given: EconomyManager freshly instantiated
- When: `get_balance()` called for all 4 currencies
- Then: all return `0`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/economy_manager_ledger_test.gd` — must exist and pass

```
tests/unit/core/economy_manager_ledger_test.gd
  test_all_balances_initialise_to_zero()
  test_add_increases_balance()
  test_add_zero_is_no_op()
  test_add_negative_is_no_op()
  test_spend_succeeds_when_sufficient()
  test_spend_exact_balance_succeeds()
  test_spend_fails_when_insufficient()
  test_spend_does_not_go_negative()
  test_set_balance_sets_directly()
  test_set_balance_negative_clamped_to_zero()
  test_currencies_are_independent()
```

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **None** — EconomyManager ledger has no upstream story dependencies
- Unlocks: Story 002 (signal integration requires this story's `add()` and `spend()` to exist)

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 15/15 passing
**Deviations**: TR-economy-001 not in tr-registry.yaml (empty registry); control manifest not yet created — both infrastructure gaps, not code issues
**Test Evidence**: Logic: `tests/unit/core/economy_manager_ledger_test.gd` — 11 test functions
**Code Review**: Skipped — Lean mode
