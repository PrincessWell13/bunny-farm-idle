# Story 001: Currency Header Display

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§7 UI/UX)
**Requirement**: `TR-hud-001`, `TR-ui-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

> ⚠️ TR-hud-001 is not yet in `tr-registry.yaml`. Add it when running `/architecture-review rtm`.
> Stable ID reserved: `TR-hud-001` — "Header bar: coin + gem balance display with real-time update via currency_changed signal"

**ADR Governing Implementation**: ADR-0003 (EventBus Signal Architecture), ADR-0001 (Autoload Boot Sequence)
**ADR Decision Summary**: HUD subscribes to `EventBus.currency_changed` — never reads `EconomyManager._balances` directly. On `_ready()`, reads current balance via `EconomyManager.get_balance(CurrencyType)` for initial display. Disconnect in `_exit_tree()` (ADR-0003 Disconnect Pattern). HUD initialises at boot step 12 (after all autoloads) — safe to call `EconomyManager.get_balance()` in `_ready()` (ADR-0001).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Signal system unchanged in 4.4–4.6. No post-cutoff APIs used.

**Control Manifest Rules (Presentation layer)**:
- Required: Subscribe to `EventBus.currency_changed` in `_ready()`; disconnect in `_exit_tree()` (F-03)
- Required: All variables and return types statically typed (F-02)
- Forbidden: Direct read of `EconomyManager._balances` — use `get_balance()` getter only
- Forbidden: Calling methods that mutate any Core state from HUD
- Guardrail: All interactive elements ≥ 44×44 px

---

## Acceptance Criteria

*From GDD §7 and architecture.md HUD module spec:*

- [x] AC-1: HUD subscribes to `EventBus.currency_changed` in `_ready()` and disconnects in `_exit_tree()`
- [x] AC-2: On `_ready()`, HUD calls `EconomyManager.get_balance(CARROT_COIN)` and `EconomyManager.get_balance(CRYSTAL_GEM)` to display initial balances in header labels
- [x] AC-3: When `currency_changed(currency, new_balance, delta)` fires with `currency == CARROT_COIN`, the CC label updates to `new_balance`
- [x] AC-4: When `currency_changed` fires with `currency == CRYSTAL_GEM`, the Gem label updates to `new_balance`
- [x] AC-5: Labels for other currency types (STAR_DUST, GENE_FRAGMENT) that fire `currency_changed` do not crash HUD — they are silently ignored

---

## Implementation Notes

*Derived from ADR-0003 EventBus Signal Architecture:*

### Signal subscription (Disconnect Pattern)
```gdscript
func _ready() -> void:
    EventBus.currency_changed.connect(_on_currency_changed)
    cc_label.text = str(EconomyManager.get_balance(EconomyManager.CurrencyType.CARROT_COIN))
    gem_label.text = str(EconomyManager.get_balance(EconomyManager.CurrencyType.CRYSTAL_GEM))

func _exit_tree() -> void:
    if EventBus.currency_changed.is_connected(_on_currency_changed):
        EventBus.currency_changed.disconnect(_on_currency_changed)

func _on_currency_changed(currency: int, new_balance: int, _delta: int) -> void:
    match currency:
        EconomyManager.CurrencyType.CARROT_COIN:
            cc_label.text = str(new_balance)
        EconomyManager.CurrencyType.CRYSTAL_GEM:
            gem_label.text = str(new_balance)
```

> **Note**: `EventBus.currency_changed` in the actual implementation uses `int` for currency type (not `EconomyManager.CurrencyType` enum) — check `src/core/event_bus.gd` signal definition before implementing.

### Node refs (@export)
```gdscript
@export var cc_label: Label
@export var gem_label: Label
```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Bottom nav bar buttons and `nav_tab_pressed` dispatch
- Story 003: Notification toast (`show_notification()` method)
- Offline earnings popup — requires IdleProductionSystem integration story (separate epic)

---

## QA Test Cases

*Integration story — automated test specs.*

- **AC-1**: EventBus.currency_changed subscription
  - Given: HUD node added to scene tree, MockEventBus registered as singleton
  - When: `_ready()` completes
  - Then: `EventBus.currency_changed.is_connected(_on_currency_changed)` == true
  - Edge cases: After `_exit_tree()`, signal is disconnected

- **AC-2**: Initial balance display from EconomyManager
  - Given: MockEconomyManager registered; `get_balance(CARROT_COIN)` returns 42; `get_balance(CRYSTAL_GEM)` returns 7
  - When: HUD `_ready()` runs
  - Then: `cc_label.text == "42"` and `gem_label.text == "7"`

- **AC-3 + AC-4**: Currency labels update on signal
  - Given: HUD ready with cc_label and gem_label at "0"
  - When: `EventBus.currency_changed.emit(CARROT_COIN, 100, 100)` fires
  - Then: `cc_label.text == "100"`, `gem_label.text` unchanged
  - When: `EventBus.currency_changed.emit(CRYSTAL_GEM, 15, 5)` fires
  - Then: `gem_label.text == "15"`, `cc_label.text` unchanged

- **AC-5**: Unknown currency silently ignored
  - Given: HUD ready
  - When: `EventBus.currency_changed.emit(STAR_DUST, 50, 50)` fires
  - Then: No crash; cc_label and gem_label unchanged

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ui/hud_currency_display_test.gd` — must exist and pass

**Status**: [x] `tests/integration/ui/hud_currency_display_test.gd` — 8 test functions, all ACs covered

---

## Dependencies

- Depends on: EventBus story-001 DONE — `currency_changed` signal must be defined ✅
- Depends on: EconomyManager (core autoload) — `get_balance()` must exist ✅
- Unlocks: Story 002 (nav bar — shares the same `hud.gd` / `HUD.tscn` file)

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 5/5 passing
**Deviations**: None
**Test Evidence**: `tests/integration/ui/hud_currency_display_test.gd` — 8 test functions (GdUnit4)
**Code Review**: Skipped — Lean mode
