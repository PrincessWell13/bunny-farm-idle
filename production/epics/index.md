# Epics Index

**Last Updated**: 2026-05-19 (BreedingUI + HUD epics created)
**Engine**: Godot 4.6 / GDScript
**Layers created**: Foundation, Core, Feature

---

## Foundation Layer

| Epic | Module | Stories | Status |
|------|--------|---------|--------|
| [EventBus](event-bus/EPIC.md) | `src/core/event_bus.gd` | 2 stories | ✅ Complete |
| [GameState](game-state/EPIC.md) | `src/core/game_state.gd` | 2 stories | ✅ Complete |
| [TimeManager](time-manager/EPIC.md) | `src/core/time_manager.gd` | 2 stories | ✅ Complete |
| [EconomyManager](economy-manager/EPIC.md) | `src/core/economy_manager.gd` | 2 stories | ✅ Complete |
| [SceneManager](scene-manager/EPIC.md) | `src/core/scene_manager.gd` | 3 stories | ✅ Complete |
| [SaveSystem](save-system/EPIC.md) | `src/core/save_system.gd` + platform adapters | 5 stories | ✅ Complete |

## Core Layer

| Epic | Module | Stories | Status |
|------|--------|---------|--------|
| [RabbitSystem](rabbit-system/EPIC.md) | `src/core/rabbit_system.gd` + `rabbit_data.gd` | 7 stories (6 Complete, 1 Blocked) | ⚠️ Blocked (story-007 aura formula) |
| [GeneticsSystem](genetics-system/EPIC.md) | `src/core/genetics_system.gd` + `genetics/` | 5 stories | ✅ Complete |
| [IdleProductionSystem](idle-production-system/EPIC.md) | `src/core/idle_production_system.gd` | 4 stories | ✅ Complete |

## Feature Layer

| Epic | Module | Stories | Status | ADR Gate |
|------|--------|---------|--------|----------|
| [HabitatSystem](habitat-system/EPIC.md) | `src/core/habitat_system.gd` | 5 stories (all Complete) | ✅ Complete | ADR-0010 ✅ |
| [FoodSystem](food-system/EPIC.md) | `src/core/food_system.gd` | 4 stories (1 Complete, 3 Ready) | 🔄 In Progress | ADR-0009 ✅ |
| [SeasonSystem](season-system/EPIC.md) | `src/core/season_system.gd` | 2 stories (all Ready) | 🟡 Stories created | All ADRs present |
| [PrestigeSystem](prestige-system/EPIC.md) | `src/core/prestige_system.gd` | Not yet created | **Ready** | All ADRs present |
| [ExpeditionSystem](expedition-system/EPIC.md) | `src/core/expedition_system.gd` | Not yet created | Blocked | ADR-0011 needed |
| [GuildSystem](guild-system/EPIC.md) | `src/core/guild_system.gd` | Not yet created | Blocked | ADR-0014 needed |
| [EventSystem](event-system/EPIC.md) | `src/core/event_system.gd` | Not yet created | Blocked | ADR-0013 needed |
| [MerchantSystem](merchant-system/EPIC.md) | `src/core/merchant_system.gd` | Not yet created | Blocked | ADR-0015 needed |
| [GenePuzzleSystem](gene-puzzle-system/EPIC.md) | `src/core/gene_puzzle_system.gd` | Not yet created | Blocked | ADR-0016 needed |
| [CollectionSystem](collection-system/EPIC.md) | `src/core/collection_system.gd` | Not yet created | Blocked | ADR-0017 needed |

## Presentation Layer

| Epic | Module | Stories | Status |
|------|--------|---------|--------|
| FarmMapUI | `src/ui/farm_map_ui.gd` | Not yet created | Not yet created |
| [BreedingUI](breeding-ui/EPIC.md) | `src/ui/breeding_ui.gd` | Not yet created | 🟡 Epic created |
| [HUD](hud/EPIC.md) | `src/ui/hud.gd` | Not yet created | 🟡 Epic created |
| ShopUI / QuestUI / GuildUI | `src/ui/` | Not yet created | Not yet created |
| MiniGameSystem | `src/ui/mini_games/` | Not yet created | Not yet created |
| AccessibilitySystem | `src/ui/accessibility/` | Not yet created | Not yet created |

## Platform Layer

| Epic | Module | Stories | Status |
|------|--------|---------|--------|
| FirebaseAdapter | `src/platform/firebase_adapter.gd` | Partial (story in SaveSystem) | Stub only |
| IAPAdapter | `src/platform/iap_adapter.gd` | Not yet created | Not yet created |
| AdAdapter | `src/platform/ad_adapter.gd` | Not yet created | Not yet created |
| NotificationAdapter | `src/platform/notification_adapter.gd` | Not yet created | Not yet created |

---

## ADR Gaps Blocking Feature Epics (priority order)

| ADR | Blocks | Priority |
|-----|--------|----------|
| ADR-0009 FoodSystem inventory | FoodSystem | **HIGH — Sprint 03** |
| ADR-0010 HabitatSystem hutch ownership | HabitatSystem | **HIGH — Sprint 03** |
| ADR-0011 ExpeditionSystem async timer | ExpeditionSystem | Medium |
| ADR-0013 EventSystem scheduler | EventSystem | Medium |
| ADR-0014 GuildSystem async raid | GuildSystem | Medium |
| ADR-0015 MerchantSystem rotation | MerchantSystem | Low |
| ADR-0016 GenePuzzle sharing | GenePuzzleSystem | Medium |
| ADR-0017 CollectionSystem persistence | CollectionSystem | Low |
