# Epics Index

Last Updated: 2026-05-16
Engine: Godot 4.6 / GDScript
Scope created: Foundation + Core layers

| Epic | Layer | Module | Stories | Status |
|------|-------|--------|---------|--------|
| [GameState](game-state/EPIC.md) | Foundation | `src/core/game_state.gd` | 2 stories | Ready |
| [TimeManager](time-manager/EPIC.md) | Foundation | `src/core/time_manager.gd` | 2 stories (1 Ready, 1 Blocked) | Ready |
| [EventBus](event-bus/EPIC.md) | Foundation | `src/core/event_bus.gd` | 2 stories | Ready |
| [SaveSystem](save-system/EPIC.md) | Foundation | `src/core/save_system.gd` + platform adapters | 5 stories (all Blocked — ADR-0008) | Ready |
| [EconomyManager](economy-manager/EPIC.md) | Foundation | `src/core/economy_manager.gd` | 2 stories | Ready |
| [SceneManager](scene-manager/EPIC.md) | Foundation | `src/core/scene_manager.gd` | 3 stories | Ready |
| [RabbitSystem](rabbit-system/EPIC.md) | Core | `src/core/rabbit_system.gd` + `rabbit_data.gd` | Not yet created | Ready |
| [GeneticsSystem](genetics-system/EPIC.md) | Core | `src/core/genetics_system.gd` + `genetics/` | Not yet created | Ready |
| [IdleProductionSystem](idle-production-system/EPIC.md) | Core | `src/core/idle_production_system.gd` | Not yet created | Ready |

## Layers Not Yet Created

| Layer | Epics Remaining | When to Create |
|-------|----------------|----------------|
| Feature | 10 epics (HabitatSystem, FoodSystem, ExpeditionSystem, SeasonSystem, PrestigeSystem, GuildSystem, EventSystem, MerchantSystem, GenePuzzleSystem, CollectionSystem) | After Core layer is ≥70% complete |
| Presentation | 6 epics (FarmMapUI, BreedingUI, HUD, ShopUI/QuestUI/GuildUI, MiniGameSystem, AccessibilitySystem) | After Feature layer is ≥70% complete |
| Platform | 4 epics (FirebaseAdapter, IAPAdapter, AdAdapter, NotificationAdapter) | Before first release build |

## Prerequisite Notes

- `docs/architecture/control-manifest.md` not yet created — run `/create-control-manifest` before stories are created
- `docs/architecture/tr-registry.yaml` empty — run `/architecture-review` to populate TR IDs
- All ADRs are currently `Proposed`; promote to `Accepted` after implementation validates each one

## Next Steps

1. Run `/create-stories [epic-slug]` for each epic in order (start with `event-bus` — no dependencies)
2. Run `/create-control-manifest` to generate the programmer rules sheet
3. Run `/gate-check production` when Foundation + Core stories are complete
