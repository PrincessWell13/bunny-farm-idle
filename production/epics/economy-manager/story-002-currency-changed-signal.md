# Story 002: currency_changed Signal Integration

> **Epic**: EconomyManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirement**: `TR-economy-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (EconomyManager owns ledger; emit on every transaction), ADR-0003 (all cross-system events via EventBus typed signals)
**ADR Decision Summary**: Every successful `add()` and `spend()` call must emit `EventBus.currency_changed(currency, new_balance, delta)`. `delta` is positive for add, negative for spend. Signal is NOT emitted when `spend()` returns `false` (no balance change occurred). The HUD subscribes to `currency_changed` to update the currency display without polling.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `EventBus.currency_changed.emit(currency, new_balance, delta)` — typed signal with `EconomyManager.CurrencyType`, `int`, `int` parameters. Callable-based connect/disconnect is required (no string-based connect). Stable in 4.4–4.6.

**Control Manifest Rules (Foundation layer)**:
- Required: emit `EventBus.currency_changed` on every successful balance change — never skip
- Forbidden: `calling_later_autoload_in_ready` — EventBus is autoload #1, safe to call from EconomyManager (#3)
- Forbidden: string-based `connect("currency_changed", ...)` — use callable syntax only

---

## Acceptance Criteria

*From ADR-0003 Signal Catalogue and ADR-0001 EconomyManager rules:*

- [ ] `add(currency, amount)` emits `EventBus.currency_changed(currency, new_balance, delta)` with positive `delta == amount`
- [ ] Successful `spend(currency, amount)` emits `EventBus.currency_changed(currency, new_balance, delta)` with negative `delta == -amount`
- [ ] Failed `spend()` (insufficient balance) does NOT emit `currency_changed`
- [ ] `set_balance()` does NOT emit `currency_changed` (boot-time population must not spam the signal)
- [ ] Signal parameters are correctly typed: `currency: EconomyManager.CurrencyType`, `new_balance: int`, `delta: int`
- [ ] GdUnit4 integration: connect a handler to `EventBus.currency_changed`; call `add()`; verify handler received correct `(currency, new_balance, delta)`
- [ ] GdUnit4 integration: call `spend()` with sufficient balance; verify handler received `delta < 0`
- [ ] GdUnit4 integration: call `spend()` with insufficient balance; verify handler was NOT called
- [ ] GdUnit4 integration: call `set_balance()`; verify handler was NOT called

---

## Implementation Notes

*Derived from ADR-0003 Emit Pattern and ADR-0001 EconomyManager ownership:*

### Modified add()

```gdscript
func add(currency: CurrencyType, amount: int) -> void:
    if amount <= 0:
        return
    _balances[currency] += amount
    EventBus.currency_changed.emit(currency, _balances[currency], amount)
```

### Modified spend()

```gdscript
func spend(currency: CurrencyType, amount: int) -> bool:
    if amount <= 0:
        return false
    if _balances[currency] < amount:
        return false
    _balances[currency] -= amount
    EventBus.currency_changed.emit(currency, _balances[currency], -amount)
    return true
```

### set_balance() unchanged

`set_balance()` does NOT emit. It is a boot-time restore operation — emitting would fire a spurious signal before any UI is ready to receive it. The HUD initialises its display from `get_balance()` in its own `_ready()`, not from the signal.

### Integration test pattern

The integration test must instantiate both `EconomyManager` and `EventBus` as sibling nodes under the test scene root. Connect a handler via the callable pattern before calling `add()`/`spend()`.

```gdscript
var _event_bus: Node
var _economy: Node
var _received_signals: Array = []

func before_test() -> void:
    _event_bus = preload("res://src/core/event_bus.gd").new()
    add_child(_event_bus)
    _economy = preload("res://src/core/economy_manager.gd").new()
    add_child(_economy)
    # Inject EventBus reference if EconomyManager uses a typed reference,
    # or rely on autoload substitution in GdUnit4 headless environment.
```

Note: GdUnit4 in headless mode may not have autoloads. If `EventBus` is accessed via its autoload name, the test must either register it as a fake autoload or inject a reference. Preferred: EconomyManager reads EventBus via its autoload name (standard for Foundation layer); the GdUnit4 test registers a mock EventBus node under the `EventBus` autoload name before each test. Document the approach when implementing.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: ledger core operations (`add`, `spend`, `get_balance`, `set_balance`) — must be DONE first
- HUD epic (Presentation): connecting to `currency_changed` and updating the display
- SaveSystem epic: `set_balance()` calls during boot — no signal, intentional

---

## QA Test Cases

**AC-1 (add emits currency_changed with correct params)**:
- Given: handler connected to `EventBus.currency_changed`; CARROT_COIN balance = 0
- When: `economy.add(CARROT_COIN, 150)` called
- Then: handler received `(CARROT_COIN, 150, 150)` — currency, new_balance, positive delta

**AC-2 (spend emits with negative delta)**:
- Given: CARROT_COIN balance = 200; handler connected
- When: `economy.spend(CARROT_COIN, 80)` called
- Then: returns `true`; handler received `(CARROT_COIN, 120, -80)`

**AC-3 (failed spend does not emit)**:
- Given: CARROT_COIN balance = 50; handler connected; `_received_signals = []`
- When: `economy.spend(CARROT_COIN, 100)` called
- Then: returns `false`; `_received_signals` remains empty

**AC-4 (set_balance does not emit)**:
- Given: handler connected; `_received_signals = []`
- When: `economy.set_balance(STAR_DUST, 500)` called
- Then: `_received_signals` remains empty

**AC-5 (multiple adds emit multiple signals)**:
- Given: handler connected; count of received signals starts at 0
- When: `add(CARROT_COIN, 10)` called 3 times
- Then: handler called 3 times; final `new_balance == 30`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/economy_manager_signal_test.gd` — must exist and pass

```
tests/integration/core/economy_manager_signal_test.gd
  test_add_emits_currency_changed_with_correct_params()
  test_spend_success_emits_with_negative_delta()
  test_spend_failure_does_not_emit()
  test_set_balance_does_not_emit()
  test_multiple_adds_emit_multiple_signals()
```

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **Story 001 must be DONE** — `add()`, `spend()`, and `set_balance()` must exist before they can be wired with signal emission
- Unlocks: EconomyManager epic COMPLETE — HUD epic (Presentation) can connect to `currency_changed` for live balance display

## Completion Notes
**Completed**: 2026-05-17
**Criteria**: 9/9 passing
**Deviations**: `src/core/event_bus.gd` touched (signal type updated from `int` placeholder to `EconomyManager.CurrencyType` — required by AC-5, deferred from story-001 by design); TR-economy-001 not in tr-registry.yaml (empty registry); control manifest missing — all known infrastructure gaps
**Test Evidence**: Integration: `tests/integration/core/economy_manager_signal_test.gd` — 5 test functions
**Code Review**: Skipped — Lean mode
