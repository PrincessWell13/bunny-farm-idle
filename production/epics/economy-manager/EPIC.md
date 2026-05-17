# Epic: EconomyManager

> **Layer**: Foundation
> **GDD**: design/gdd/bunny-farm-idle-master.md
> **Architecture Module**: `src/core/economy_manager.gd`
> **Status**: Ready
> **Control Manifest Version**: pending — run `/create-control-manifest` to assign
> **Stories**: 2 stories created

## Overview

EconomyManager owns the four currency ledgers: Carrot Coin (CC), Star Dust, Crystal Gem, and Gene Fragment. Every income and expenditure in the game passes through its `add()` and `spend()` methods. It is autoload #3 — initialised before GameState so that SaveSystem can populate balances during boot. It never stores any game logic — it is a transaction ledger with balance queries and emits `currency_changed` on every transaction.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | EconomyManager is autoload #3; owns currency ledgers; initialises to zero then populated by SaveSystem | LOW |
| ADR-0003: EventBus Signals | Emits `currency_changed(currency, new_balance, delta)` on every add/spend | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-economy-001 | 4-currency system accessible to all game systems | ADR-0001 ✅, ADR-0003 ✅ |

> Note: Individual currency use cases (sell price formula, expedition loot amounts) are covered by Feature layer ADRs (ADR-0009 pending). The EconomyManager epic only covers the ledger infrastructure.

## Key Interfaces

```gdscript
class_name EconomyManager extends Node

enum CurrencyType { CARROT_COIN, STAR_DUST, CRYSTAL_GEM, GENE_FRAGMENT }

func add(currency: CurrencyType, amount: int) -> void
func spend(currency: CurrencyType, amount: int) -> bool   # false if insufficient balance
func get_balance(currency: CurrencyType) -> int
func set_balance(currency: CurrencyType, amount: int) -> void  # SaveSystem only at boot
```

## Forbidden Patterns (from Architecture Registry)

- `calling_later_autoload_in_ready` — EconomyManager (autoload #3) may only call EventBus (autoload #1) and TimeManager (autoload #2) in `_ready()`
- `currency_ledgers` state is EconomyManager-only — no other system writes balances directly

## Definition of Done

This epic is complete when:
- [ ] All stories are implemented, reviewed, and closed via `/story-done`
- [ ] `EconomyManager` autoload registered as #3 in Godot Project Settings
- [ ] `spend()` returns `false` when balance is insufficient; never goes negative
- [ ] `currency_changed` signal fired on every `add()` and `spend()` (GdUnit4)
- [ ] GdUnit4: EconomyManager instantiates in isolation; `add()` + `get_balance()` round-trip
- [ ] After load: `get_balance(CARROT_COIN)` returns saved value (not zero)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Currency ledger — add/spend/get/set](story-001-currency-ledger.md) | Logic | Complete | ADR-0001 |
| 002 | [currency_changed signal integration](story-002-currency-changed-signal.md) | Integration | Complete | ADR-0001 + ADR-0003 |

## Next Step

EconomyManager epic COMPLETE — all 2 stories implemented and closed.
