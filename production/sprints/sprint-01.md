# Sprint 01 — Foundation + Core Systems

**Sprint**: 01
**Dates**: 2026-05-16 — 2026-05-18
**Stage**: Pre-Production
**Goal**: Implement all Foundation and Core layer systems. All logic is verifiable by automated tests. No UI, no rendering — data and computation only.

---

## Sprint Scope

### Must Have (all 28 stories)

**Foundation Layer**

| Story | Path | Status | Type |
|-------|------|--------|------|
| EventBus Signal Catalogue | `production/epics/event-bus/story-001-signal-catalogue.md` | Complete | Logic |
| EventBus Connect-Emit-Disconnect | `production/epics/event-bus/story-002-connect-emit-disconnect.md` | Complete | Integration |
| GameState Data Structure | `production/epics/game-state/story-001-data-structure.md` | Complete | Logic |
| GameState Prestige Reset | `production/epics/game-state/story-002-prestige-reset.md` | Complete | Logic |
| TimeManager Core Tracking | `production/epics/time-manager/story-001-core-time-tracking.md` | Ready | Logic |
| TimeManager Background Detection | `production/epics/time-manager/story-002-background-detection.md` | Complete | Logic |
| SaveSystem Firebase Adapter Interface | `production/epics/save-system/story-001-firebase-adapter-interface.md` | Ready | Logic |
| SaveSystem Local File I/O | `production/epics/save-system/story-002-local-file-io.md` | Ready | Logic |
| SaveSystem GameState Serialisation | `production/epics/save-system/story-003-gamestate-serialisation.md` | Ready | Integration |
| SaveSystem Conflict Resolution | `production/epics/save-system/story-004-conflict-resolution.md` | Ready | Logic |
| SaveSystem Boot Integration + Autosave | `production/epics/save-system/story-005-boot-integration-autosave.md` | Ready | Integration |
| SceneManager goto_scene | `production/epics/scene-manager/story-001-goto-scene.md` | Ready | Logic |
| SceneManager Overlay Stack | `production/epics/scene-manager/story-002-overlay-stack.md` | Ready | Logic |
| SceneManager Boot + Nav Routing | `production/epics/scene-manager/story-003-boot-nav-routing.md` | Ready | Integration |

**Core Layer**

| Story | Path | Status | Type |
|-------|------|--------|------|
| RabbitData Schema | `production/epics/rabbit-system/story-001-rabbit-data-schema.md` | Complete | Logic |
| RabbitSystem Roster CRUD | `production/epics/rabbit-system/story-002-roster-crud.md` | Complete | Logic |
| RabbitSystem Stat Decay | `production/epics/rabbit-system/story-003-stat-decay.md` | Complete | Logic |
| RabbitSystem Lifecycle | `production/epics/rabbit-system/story-004-lifecycle.md` | Complete | Integration |
| RabbitSystem Death Signal | `production/epics/rabbit-system/story-005-death-signal.md` | Complete | Integration |
| RabbitSystem Feed Rabbit | `production/epics/rabbit-system/story-006-feed-rabbit.md` | Complete | Logic |
| GeneticsSystem Genome Schema | `production/epics/genetics-system/story-001-genome-schema.md` | Complete | Logic |
| GeneticsSystem Inheritance + Mutation | `production/epics/genetics-system/story-002-inheritance-mutation.md` | Complete | Logic |
| GeneticsSystem Breed Preview | `production/epics/genetics-system/story-003-breed-preview.md` | Complete | Logic |
| GeneticsSystem Rarity Tier | `production/epics/genetics-system/story-004-rarity-tier.md` | Complete | Logic |
| GeneticsSystem Trait Stacking | `production/epics/genetics-system/story-005-trait-stacking.md` | Complete | Logic |
| EconomyManager Currency Ledger | `production/epics/economy-manager/story-001-currency-ledger.md` | Ready | Logic |
| EconomyManager Currency Changed Signal | `production/epics/economy-manager/story-002-currency-changed-signal.md` | Ready | Logic |
| IdleProductionSystem Earnings Report Schema | `production/epics/idle-production-system/story-001-earnings-report-schema.md` | Complete | Logic |
| IdleProductionSystem Production Formula | `production/epics/idle-production-system/story-002-production-formula.md` | Complete | Logic |
| IdleProductionSystem Offline Tiers | `production/epics/idle-production-system/story-003-offline-tiers.md` | Complete | Logic |
| IdleProductionSystem Season + Prestige Integration | `production/epics/idle-production-system/story-004-season-prestige-integration.md` | Complete | Integration |

### Should Have (deferred to Sprint 02)

| Story | Path | Reason |
|-------|------|--------|
| RabbitSystem Aura Bonus | `production/epics/rabbit-system/story-007-aura-bonus.md` | BLK-001: Aura Bonus GDD spec not yet written; deferred to Sprint 02 |

---

## Sprint 01 Completion Summary

**Status**: Partially Complete — 21 of 30 Must Have stories done; 9 Ready (SaveSystem, SceneManager, EconomyManager, TimeManager story-001).

**Completed stories**: 21
**Remaining stories in sprint**: 9 (economy-manager: 2, save-system: 5, scene-manager: 3, time-manager: 1)

**Test coverage**: 107 test functions across 21 test files

### Test Files Written This Sprint

```
tests/unit/core/event_bus_catalogue_test.gd          (3 functions)
tests/integration/core/event_bus_integration_test.gd (7 functions)
tests/unit/core/game_state_init_test.gd              (6 functions)
tests/unit/core/game_state_prestige_test.gd          (8 functions)
tests/unit/core/genetics_schema_test.gd              (8 functions)
tests/unit/core/genetics_inheritance_test.gd         (8 functions)
tests/unit/core/genetics_breed_preview_test.gd       (8 functions)
tests/unit/core/genetics_rarity_test.gd              (8 functions)
tests/unit/core/genetics_trait_stacking_test.gd      (8 functions)
tests/unit/core/idle_earnings_report_test.gd         (3 functions)
tests/unit/core/idle_production_formula_test.gd      (8 functions)
tests/unit/core/idle_offline_tiers_test.gd           (10 functions)
tests/integration/core/idle_production_integration_test.gd (6 functions)
tests/unit/core/rabbit_data_schema_test.gd           (7 functions)
tests/unit/core/rabbit_system_roster_test.gd         (7 functions)
tests/unit/core/rabbit_system_decay_test.gd          (7 functions)
tests/integration/core/rabbit_system_lifecycle_test.gd (7 functions)
tests/integration/core/rabbit_system_death_test.gd   (4 functions)
tests/unit/core/rabbit_system_feeding_test.gd        (5 functions)
tests/unit/core/time_manager_background_test.gd      (6 functions)
```

---

## Next Sprint

**Sprint 02** covers:
- Remaining Sprint 01 stories (economy-manager, save-system, scene-manager, time-manager story-001)
- RabbitSystem Aura Bonus (pending BLK-001 GDD spec)
- Core Loop Prototype (vertical slice validation)
- Presentation layer stubs (UI scenes, HUD)

---

*Sprint 01 — Bunny Farm Idle — 2026-05-16 to 2026-05-18*
