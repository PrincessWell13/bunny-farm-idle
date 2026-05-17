# Epic: RabbitSystem

> **Layer**: Core
> **GDD**: design/gdd/bunny-farm-idle-master.md (§3.1 Rabbit System)
> **Architecture Module**: `src/core/rabbit_system.gd` + `src/core/rabbit_data.gd`
> **Status**: Ready
> **Control Manifest Version**: pending — run `/create-control-manifest` to assign
> **Stories**: 7 stories — 6 Ready, 1 Blocked (story-007 needs aura formula spec)

## Overview

RabbitSystem owns every living rabbit. It holds the lifecycle state machine for each rabbit (Baby → Juvenile → Adult → Elder → Sanctuary), ticks all stat decay (hunger, happiness, health, cleanliness) once per second, checks stage-advance thresholds, and handles death. `RabbitData` is a typed `Resource` — other systems read its fields freely but may only write them through RabbitSystem methods. The `rabbit_stat_changed`, `rabbit_matured`, and `rabbit_died` signals fire here and are consumed by the Presentation layer.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | `GameState.rabbits: Array[RabbitData]` is the backing store; RabbitSystem reads and mutates it | LOW |
| ADR-0004: JSON Balance Data | Hunger decay, health decay, cleanliness decay, growth thresholds — all from `balance.json` | LOW |
| ADR-0005: RabbitData as Resource | Full `RabbitData` schema; `RabbitStage` enum; immutability contract (only RabbitSystem writes fields) | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-rabbit-001 | 4 visible stats (Hunger, Happiness, Health, Cleanliness) with real-time decay | ADR-0005 ✅ |
| TR-rabbit-002 | 5 hidden stats (Growth Rate, Fertility, Mutation Chance, Lifespan, Aura) | ADR-0005 ✅ |
| TR-rabbit-003 | 5-stage lifecycle: Baby → Juvenile → Adult → Elder → Sanctuary | ADR-0005 ✅ |
| TR-rabbit-004 | Aura buff system — Elder rabbits buff nearby hutches | ADR-0005 ✅ (data level; aura_type key) |
| TR-rabbit-005 | Parentage tracking (parent_a_id, parent_b_id) for genealogy | ADR-0005 ✅ |

> ⚠️ Partially untraced: Aura effect stacking math (how aura_type key maps to numeric bonuses) has no dedicated ADR — covered at data level by ADR-0005 but the formula is not yet specified. Stories for aura bonus application will be Blocked until a Quick Spec or ADR covers the formula.

## Key Interfaces

```gdscript
# src/core/rabbit_system.gd
func get_rabbit(rabbit_id: String) -> RabbitData        # null if not found
func get_all_rabbits() -> Array[RabbitData]
func get_rabbits_in_hutch(hutch_id: String) -> Array[RabbitData]
func add_rabbit(data: RabbitData) -> String              # returns rabbit_id
func remove_rabbit(rabbit_id: String) -> void
func feed_rabbit(rabbit_id: String, food: FoodItem) -> bool
func get_aura_bonus(hutch_id: String) -> AuraBonus
```

```gdscript
# src/core/rabbit_data.gd
class_name RabbitData extends Resource
enum RabbitStage { BABY, JUVENILE, ADULT, ELDER, SANCTUARY }
# Full field list — see ADR-0005
```

## Forbidden Patterns (from Architecture Registry)

- `direct_rabbitdata_mutation` — no file outside `rabbit_system.gd` may assign to RabbitData fields
- `upward_direct_method_calls` — RabbitSystem may not call Feature or Presentation methods

## Definition of Done

This epic is complete when:
- [ ] All stories are implemented, reviewed, and closed via `/story-done`
- [ ] GdUnit4: `RabbitData` instantiates with no scene or autoload dependencies
- [ ] GdUnit4: round-trip `_rabbit_to_dict()` → `_dict_to_rabbit()` preserves all fields
- [ ] GdUnit4: stage advance `BABY → JUVENILE` when `growth_progress` crosses threshold
- [ ] GdUnit4: `rabbit_died` emitted and rabbit removed when `health` reaches 0
- [ ] Grep: no `.hunger =`, `.health =`, `.happiness =` assignments outside `rabbit_system.gd`
- [ ] All decay rates loaded from `balance.json` (grep: no multi-digit numeric literals in `rabbit_system.gd`)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [RabbitData Schema + Instantiation](story-001-rabbit-data-schema.md) | Logic | Complete | ADR-0005 ✅ |
| 002 | [Roster CRUD — add/get/remove](story-002-roster-crud.md) | Logic | Complete | ADR-0001 ✅ + ADR-0005 ✅ |
| 003 | [Stat Decay Tick](story-003-stat-decay.md) | Logic | Complete | ADR-0004 ✅ + ADR-0005 ✅ |
| 004 | [Lifecycle State Machine — stage advance](story-004-lifecycle.md) | Integration | Complete | ADR-0003 ✅ + ADR-0004 ✅ + ADR-0005 ✅ |
| 005 | [Death Path — rabbit_died signal](story-005-death-signal.md) | Integration | Complete | ADR-0003 ✅ + ADR-0005 ✅ |
| 006 | [feed_rabbit — immediate stat restoration](story-006-feed-rabbit.md) | Logic | Complete | ADR-0004 ✅ + ADR-0005 ✅ |
| 007 | [Aura Bonus — get_aura_bonus()](story-007-aura-bonus.md) | Logic | Blocked | formula spec missing |

## Unblock Path

1. `/architecture-decision retrofit docs/architecture/adr-0005-rabbitdata-resource.md` → promotes ADR-0005 → unblocks stories 001, 002, 005
2. `/architecture-decision retrofit docs/architecture/adr-0004-balance-json.md` → promotes ADR-0004 → unblocks stories 003, 004, 006
3. `/quick-design aura-bonus-formula` → defines aura stacking formula → unblocks story 007

## Next Step

Promote ADR-0005 and ADR-0004 to Accepted, then run `/dev-story production/epics/rabbit-system/story-001-rabbit-data-schema.md`.
