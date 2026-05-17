# Session State — Bunny Farm Idle

**Ngày bắt đầu**: 2026-05-16
**Giai đoạn hiện tại**: Pre-production — Architecture complete, ADRs next

## Tiến độ hiện tại

- [x] Project khởi tạo từ CCGS template
- [x] Engine cấu hình: Godot 4.6 / GDScript
- [x] GDD lưu tại: `design/gdd/bunny-farm-idle-master.md`
- [x] Technical preferences cấu hình
- [x] Architecture document: `docs/architecture/architecture.md` — DONE (v1.0, TD APPROVED WITH CONDITIONS)
- [x] ADRs — 8/8 Foundation ADRs written (0001–0008) — all Foundation ADRs COMPLETE
- [x] Epics tạo từ GDD — 9 epics (Foundation + Core) tại production/epics/
- [x] Stories tạo từ Epics — event-bus: 2 stories; remaining 8 epics have no stories yet
- [x] Implementation bắt đầu — event-bus story-001 COMPLETE (signal count corrected: 22→23)

## Quyết định đã đưa ra

1. **Engine**: Godot 4.6 (GDScript)
2. **Scope**: Full game
3. **Workflow**: CCGS framework
4. **Platform**: Android/iOS primary, PC sau
5. **Backend**: Firebase (Auth + Realtime DB + Cloud Functions) — confirmed
6. **Multiplayer**: Async only (Guild Boss Raid = 7-day contribution window, no real-time)
7. **Architecture**: 5-layer (Foundation → Core → Feature → Presentation → Platform)
8. **Communication pattern**: EventBus signals for all cross-layer communication

## Files đang làm việc

- `docs/architecture/architecture.md` — DONE (v1.0)
- `docs/architecture/tr-registry.yaml` — cần populate với 60 TR IDs
- `src/core/event_bus.gd` — DONE (story-001, 22 signals)
- `tests/unit/core/event_bus_catalogue_test.gd` — DONE (story-001, 3 test functions)

## Session Extract — /dev-story 2026-05-16
- Story: production/epics/event-bus/story-001-signal-catalogue.md — EventBus Signal Catalogue
- Files changed: src/core/event_bus.gd, tests/unit/core/event_bus_catalogue_test.gd
- Test written: tests/unit/core/event_bus_catalogue_test.gd (3 test functions)
- Blockers: None
- Next: /story-done production/epics/event-bus/story-001-signal-catalogue.md

## Session Extract — /story-done 2026-05-16
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/event-bus/story-001-signal-catalogue.md — EventBus Signal Catalogue
- Tech debt logged: None
- Deviation fixed: Signal count "22" corrected to "23" in test file and story AC text (per ADR-0003)
- Next recommended: story-002-connect-emit-disconnect.md (Integration, depends on story-001 DONE ✅)

## Session Extract — /dev-story 2026-05-16
- Story: production/epics/event-bus/story-002-connect-emit-disconnect.md — EventBus Connect-Emit-Disconnect Integration
- Files changed: tests/integration/core/event_bus_integration_test.gd (created, 7 test functions)
- Test written: tests/integration/core/event_bus_integration_test.gd
- Blockers: ADR-0003 still Proposed — recommend promoting to Accepted after this story validates the pattern
- Next: /story-done production/epics/event-bus/story-002-connect-emit-disconnect.md

## Session Extract — /story-done 2026-05-16
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/event-bus/story-002-connect-emit-disconnect.md — EventBus Connect-Emit-Disconnect Integration
- Tech debt logged: None
- Next recommended: EventBus epic COMPLETE — run /create-stories game-state (next Foundation epic)

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/game-state/story-001-data-structure.md — GameState Data Structure + Initialization
- Files changed: src/core/game_state.gd, tests/unit/core/game_state_init_test.gd
- Test written: tests/unit/core/game_state_init_test.gd (6 test functions)
- Blockers: None
- Next: /story-done production/epics/game-state/story-001-data-structure.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/game-state/story-001-data-structure.md — GameState Data Structure + Initialization
- Tech debt logged: None
- Next recommended: story-002-prestige-reset.md (depends on story-001 DONE ✅)

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/game-state/story-002-prestige-reset.md — prestige_reset() Selective Wipe
- Files changed: src/core/game_state.gd (modified), tests/unit/core/game_state_prestige_test.gd (created)
- Test written: tests/unit/core/game_state_prestige_test.gd (8 test functions)
- Blockers: None
- Next: /story-done production/epics/game-state/story-002-prestige-reset.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/game-state/story-002-prestige-reset.md — prestige_reset() Selective Wipe
- Tech debt logged: None
- Next recommended: GameState epic COMPLETE — run /create-stories time-manager (next Foundation epic)

## Session Extract — /create-stories 2026-05-17
- Epic: production/epics/time-manager/
- Stories created: story-001-core-time-tracking.md (Ready), story-002-background-detection.md (Blocked — ADR-0007 Proposed)
- Files updated: EPIC.md stories table, production/epics/index.md
- Next: /dev-story production/epics/time-manager/story-001-core-time-tracking.md

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/time-manager/story-001-core-time-tracking.md — Core Time Tracking
- Files changed: src/core/time_manager.gd (created), tests/unit/core/time_manager_core_test.gd (created)
- Test written: tests/unit/core/time_manager_core_test.gd (8 test functions)
- Blockers: None
- Next: /story-done production/epics/time-manager/story-001-core-time-tracking.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/time-manager/story-001-core-time-tracking.md — Core Time Tracking
- Tech debt logged: None
- Next recommended: TimeManager story-001 COMPLETE — promote ADR-0007 to unblock story-002, or run /create-stories save-system

## Session Extract — /create-stories 2026-05-17
- Epic: production/epics/save-system/
- Stories created: 5 stories — all Blocked (ADR-0008 Proposed; story-003 also Blocked on ADR-0005)
- Files updated: EPIC.md stories table, production/epics/index.md
- Blocker: ADR-0008 must be promoted before any save-system story can be implemented
- Next: /architecture-decision retrofit docs/architecture/adr-0008-firebase-local-first-save.md OR /create-stories economy-manager

## Session Extract — /create-stories 2026-05-17
- Epic: production/epics/economy-manager/
- Stories created: story-001-currency-ledger.md (Ready), story-002-currency-changed-signal.md (Ready)
- Files updated: EPIC.md stories table, production/epics/index.md
- Next: /dev-story production/epics/economy-manager/story-001-currency-ledger.md

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/economy-manager/story-001-currency-ledger.md — Currency Ledger
- Files changed: src/core/economy_manager.gd (created), tests/unit/core/economy_manager_ledger_test.gd (created)
- Test written: tests/unit/core/economy_manager_ledger_test.gd (11 test functions)
- Blockers: None
- Next: /story-done production/epics/economy-manager/story-001-currency-ledger.md

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/economy-manager/story-002-currency-changed-signal.md — currency_changed Signal Integration
- Files changed: src/core/event_bus.gd (modified — currency_changed signal typed from int to EconomyManager.CurrencyType), src/core/economy_manager.gd (modified — emit calls in add() and spend()), tests/integration/core/economy_manager_signal_test.gd (created)
- Test written: tests/integration/core/economy_manager_signal_test.gd (5 test functions)
- Blockers: None
- Next: /story-done production/epics/economy-manager/story-002-currency-changed-signal.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/economy-manager/story-002-currency-changed-signal.md — currency_changed Signal Integration
- Tech debt logged: None
- Next recommended: EconomyManager epic COMPLETE — run /create-stories scene-manager (last Foundation epic without stories)

## Session Extract — /create-stories 2026-05-17
- Epic: production/epics/scene-manager/
- Stories created: story-001-goto-scene.md (Ready), story-002-overlay-stack.md (Ready), story-003-boot-nav-routing.md (Ready)
- Files updated: EPIC.md stories table, production/epics/index.md
- Note: All Foundation epics now have stories. Core epics (rabbit-system, genetics-system, idle-production-system) have no stories yet.
- Next: /dev-story production/epics/scene-manager/story-001-goto-scene.md

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/scene-manager/story-001-goto-scene.md — goto_scene + get_current_scene
- Files changed: src/core/scene_manager.gd (created), tests/helpers/minimal_scene.tscn (created), tests/integration/core/scene_manager_transitions_test.gd (created)
- Test written: tests/integration/core/scene_manager_transitions_test.gd (3 test functions)
- Blockers: None
- Next: /story-done production/epics/scene-manager/story-001-goto-scene.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/scene-manager/story-001-goto-scene.md — goto_scene + get_current_scene
- Tech debt logged: None
- Next recommended: story-002-overlay-stack.md (depends on story-001 DONE ✅)

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/scene-manager/story-002-overlay-stack.md — Overlay Stack
- Files changed: src/core/scene_manager.gd (modified — added push_overlay, pop_overlay, _clear_overlays, _overlay_stack; goto_scene now calls _clear_overlays), tests/unit/core/scene_manager_overlay_test.gd (created)
- Test written: tests/unit/core/scene_manager_overlay_test.gd (5 test functions)
- Blockers: None
- Next: /story-done production/epics/scene-manager/story-002-overlay-stack.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/scene-manager/story-002-overlay-stack.md — Overlay Stack
- Tech debt logged: None
- Next recommended: story-003-boot-nav-routing.md (depends on story-001 ✅ + story-002 ✅)

## Session Extract — ADR promotion 2026-05-17
- ADR-0005 (RabbitData Resource): Proposed → Accepted — unblocked stories 001, 002, 005
- ADR-0004 (Balance JSON): Proposed → Accepted — unblocked stories 003, 004, 006
- rabbit-system: 6/7 stories now Ready; story-007 still blocked (aura formula spec missing)
- Next: /dev-story production/epics/rabbit-system/story-001-rabbit-data-schema.md

## Session Extract — /create-stories 2026-05-17
- Epic: production/epics/rabbit-system/
- Stories created: 7 stories — all Blocked (ADR-0004 + ADR-0005 Proposed; story-007 also missing aura formula spec)
- Files updated: EPIC.md stories table, production/epics/index.md (pending)
- Unblock path: retrofit ADR-0005 → stories 001/002/005; retrofit ADR-0004 → stories 003/004/006; quick-design aura formula → story 007
- Next: /architecture-decision retrofit docs/architecture/adr-0005-rabbitdata-resource.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/scene-manager/story-003-boot-nav-routing.md — Boot Launch + nav_tab_pressed Routing
- Tech debt logged: None
- Next recommended: SceneManager epic COMPLETE — run /create-stories rabbit-system (next Core epic)

## Bước tiếp theo: 8 Foundation ADRs (theo thứ tự ưu tiên)

Chạy `/architecture-decision` 8 lần:

1. "Autoload boot sequence and GameState ownership"
2. "GDScript over C# for Godot 4.6"
3. "Signal-based inter-system communication via EventBus"
4. "JSON balance data — no hardcoded values"
5. "RabbitData as Resource type — immutable from outside RabbitSystem"
6. "Genetics allele model and mutation algorithm"
7. "Idle production and offline catch-up calculation"
8. "Firebase as async-optional backend — local-first save"

Sau khi có 8 ADRs này → chạy `/create-epics`

## Technical Requirements

- 60 TRs tổng cộng — 57 covered, 3 gaps (có ADR riêng)
- Gap 1: TR-puzzle-003 (Gene Journal sharing) — ADR 12
- Gap 2: TR-economy-002 (Rabbit sale value formula) — ADR 9
- Gap 3: TR-idle-004 (Item-based offline modifiers) — ADR 10

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/rabbit-system/story-001-rabbit-data-schema.md — RabbitData Schema + Instantiation
- Files changed: src/core/rabbit_data.gd (created), tests/unit/core/rabbit_data_schema_test.gd (created)
- Test written: tests/unit/core/rabbit_data_schema_test.gd (7 test functions)
- Blockers: None
- Next: /story-done production/epics/rabbit-system/story-001-rabbit-data-schema.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/rabbit-system/story-001-rabbit-data-schema.md — RabbitData Schema + Instantiation
- Tech debt logged: None
- Next recommended: story-002-roster-crud.md (depends on story-001 DONE ✅)

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/rabbit-system/story-002-roster-crud.md — Roster CRUD add/get/remove
- Files changed: src/core/rabbit_system.gd (created), src/core/game_state.gd (rabbits typed to Array[RabbitData]), tests/unit/core/rabbit_system_roster_test.gd (created)
- Test written: tests/unit/core/rabbit_system_roster_test.gd (7 test functions)
- Blockers: None
- Next: /story-done production/epics/rabbit-system/story-002-roster-crud.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/rabbit-system/story-002-roster-crud.md — Roster CRUD add/get/remove
- Tech debt logged: None
- Next recommended: story-003-stat-decay.md AND story-006-feed-rabbit.md (both depend on story-002 DONE ✅)

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/rabbit-system/story-003-stat-decay.md — Stat Decay Tick
- Files changed: src/core/rabbit_system.gd (modified — added decay vars, _ready, _process, _load_balance_data, _tick_rabbit, stubs), tests/unit/core/rabbit_system_decay_test.gd (created)
- Test written: tests/unit/core/rabbit_system_decay_test.gd (7 test functions)
- Blockers: None
- Next: /story-done production/epics/rabbit-system/story-003-stat-decay.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE
- Story: production/epics/rabbit-system/story-003-stat-decay.md — Stat Decay Tick
- Tech debt logged: None
- Next recommended: story-006-feed-rabbit.md (depends on story-002 ✅) OR story-004-lifecycle.md (depends on story-003 ✅)

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/rabbit-system/story-006-feed-rabbit.md — feed_rabbit Immediate Stat Restoration
- Files changed: src/core/rabbit_system.gd (modified — FoodItem inner class, food balance vars, feed_rabbit, _load_balance_data food section), tests/unit/core/rabbit_system_feeding_test.gd (created)
- Test written: tests/unit/core/rabbit_system_feeding_test.gd (5 test functions)
- Blockers: None
- Next: /story-done production/epics/rabbit-system/story-006-feed-rabbit.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE
- Story: production/epics/rabbit-system/story-006-feed-rabbit.md — feed_rabbit Immediate Stat Restoration
- Tech debt logged: None
- Next recommended: story-004-lifecycle.md (depends on story-003 ✅)

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/rabbit-system/story-004-lifecycle.md — Lifecycle State Machine Stage Advance
- Files changed: src/core/rabbit_system.gd (modified — stage threshold vars, balance loading, _check_stage_advance implementation), tests/integration/core/rabbit_system_lifecycle_test.gd (created)
- Test written: tests/integration/core/rabbit_system_lifecycle_test.gd (7 test functions)
- Blockers: None
- Next: /story-done production/epics/rabbit-system/story-004-lifecycle.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/rabbit-system/story-004-lifecycle.md — Lifecycle State Machine Stage Advance
- Tech debt logged: None
- Next recommended: story-005-death-signal.md (depends on story-004 ✅)

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/rabbit-system/story-005-death-signal.md — Death Path rabbit_died Signal
- Files changed: src/core/rabbit_system.gd (modified — _check_death implementation, _process snapshot fix), tests/integration/core/rabbit_system_death_test.gd (created)
- Test written: tests/integration/core/rabbit_system_death_test.gd (4 test functions)
- Blockers: None
- Next: /story-done production/epics/rabbit-system/story-005-death-signal.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/rabbit-system/story-005-death-signal.md — Death Path rabbit_died Signal
- Tech debt logged: None
- Next recommended: RabbitSystem epic 6/6 ready stories COMPLETE — story-007 blocked (aura formula) — run /create-stories genetics-system or /create-stories idle-production-system

## Session Extract — /story-done genetics story-003 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/genetics-system/story-003-breed-preview.md — Gene Preview: Probability Tables
- Tech debt logged: None
- Next recommended: Story 004 — Rarity Tier (production/epics/genetics-system/story-004-rarity-tier.md)

## Session Extract — /dev-story genetics story-003 2026-05-17
- Story: production/epics/genetics-system/story-003-breed-preview.md — Gene Preview: Probability Tables
- Files changed: src/core/genetics_system.gd (get_breed_preview, _slot_probabilities, _get_catalogue, _estimate_rarity added)
- Test written: tests/unit/core/genetics_breed_preview_test.gd (8 test functions)
- Blockers: None
- Next: /story-done production/epics/genetics-system/story-003-breed-preview.md

## Session Extract — /story-done genetics story-002 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/genetics-system/story-002-inheritance-mutation.md — Breed: Inheritance + Mutation
- Tech debt logged: None
- Next recommended: Story 003 — Gene Preview (production/epics/genetics-system/story-003-breed-preview.md)

## Session Extract — /dev-story genetics story-002 2026-05-17
- Story: production/epics/genetics-system/story-002-inheritance-mutation.md — Breed: Inheritance + Mutation
- Files changed: src/core/genetics_system.gd (created), src/core/rabbit_data.gd (genome field retyped to Genome)
- Test written: tests/unit/core/genetics_inheritance_test.gd (9 test functions)
- Blockers: None
- Next: /story-done production/epics/genetics-system/story-002-inheritance-mutation.md

## Session Extract — /story-done genetics story-001 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/genetics-system/story-001-genome-schema.md — Genome Schema + AlleleCatalogue
- Tech debt logged: None
- Next recommended: Story 002 — Breed Inheritance + Mutation (production/epics/genetics-system/story-002-inheritance-mutation.md)

## Session Extract — /dev-story genetics story-001 2026-05-17
- Story: production/epics/genetics-system/story-001-genome-schema.md — Genome Schema + AlleleCatalogue
- Files changed: src/core/genetics/gene_slot.gd, src/core/genetics/genome.gd, src/core/genetics/allele_catalogue.gd, src/core/genetics/breed_preview.gd, src/core/genetics/trait_effects.gd
- Test written: tests/unit/core/genetics_schema_test.gd (8 test functions)
- Blockers: None
- Next: /story-done production/epics/genetics-system/story-001-genome-schema.md

## Session Extract — /create-stories genetics-system 2026-05-17
- Verdict: COMPLETE — 5 stories written to `production/epics/genetics-system/`
- All stories: Status Blocked (ADR-0006 is Proposed)
- Stories: 001 Genome Schema, 002 Inheritance+Mutation, 003 Breed Preview, 004 Rarity Tier, 005 Trait Stacking
- To unblock: `/architecture-decision retrofit docs/architecture/adr-0006-genetics-allele-model.md`
- Next recommended: retrofit ADR-0006 → flip stories to Ready → `/dev-story story-001-genome-schema.md`

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/genetics-system/story-005-trait-stacking.md — Trait Stacking: Synergy, Cancellation, Ultra Trait
- Files changed: assets/data/balance.json (created), src/core/genetics_system.gd (modified — get_trait_effects, _collect_active_traits, _apply_bonus_dict, _trait_synergies/_cancellations/_ultra_combos vars, _load_balance_data extended), tests/unit/core/genetics_trait_stacking_test.gd (created)
- Test written: tests/unit/core/genetics_trait_stacking_test.gd (8 test functions)
- Blockers: None
- Next: /story-done production/epics/genetics-system/story-005-trait-stacking.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/genetics-system/story-005-trait-stacking.md — Trait Stacking: Synergy, Cancellation, Ultra Trait
- Tech debt logged: None
- Next recommended: GeneticsSystem epic COMPLETE (5/5 stories) — run /create-stories idle-production-system (last Core epic without stories)

## Câu hỏi đã giải quyết

- Backend: Firebase ✅
- Multiplayer: Async ✅


## Session Extract — /dev-story idle-production-system stories 002+003+004 2026-05-17
- Story 002: production/epics/idle-production-system/story-002-production-formula.md — Production Formula
  - Files changed: src/core/idle_production_system.gd (created), assets/data/balance.json (idle_production + prestige sections added), tests/unit/core/idle_production_formula_test.gd (created)
  - Test written: tests/unit/core/idle_production_formula_test.gd (8 test functions)
  - Blockers: None
- Story 003: production/epics/idle-production-system/story-003-offline-tiers.md — Offline Catch-Up + Multiplier Tiers
  - Files changed: No new files — calculate_offline_earnings() and _get_offline_multiplier() implemented in Story 002's idle_production_system.gd
  - Test written: tests/unit/core/idle_offline_tiers_test.gd (10 test functions)
  - Blockers: None
- Story 004: production/epics/idle-production-system/story-004-season-prestige-integration.md — Season + Prestige Integration
  - Files changed: src/core/idle_production_system.gd (modified — _get_season_multiplier, _get_prestige_bonus wired; _prestige_offline_bonuses loaded)
  - Test written: tests/integration/core/idle_production_integration_test.gd (6 test functions)
  - Blockers: None
- Next: IdleProductionSystem epic COMPLETE (4/4 stories) — all Foundation+Core epics now have stories and most are implemented

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/idle-production-system/story-004-season-prestige-integration.md — Season + Prestige Integration
- Tech debt logged: None
- Advisory: AC-5 (autumn multiplier) untested pending SeasonSystem epic; prestige_count runtime path untestable without GameState autoload
- Next recommended: IdleProductionSystem epic COMPLETE (4/4) — consider /story-done on stories 002 and 003 to formally close them, or advance to remaining epics

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE
- Story: production/epics/idle-production-system/story-002-production-formula.md — Production Formula — Tick Earnings
- Tech debt logged: None
- Next recommended: /story-done production/epics/idle-production-system/story-003-offline-tiers.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE
- Story: production/epics/idle-production-system/story-003-offline-tiers.md — Offline Catch-Up + Multiplier Tiers
- Tech debt logged: None
- Next recommended: IdleProductionSystem epic fully closed (4/4 COMPLETE) — unblock time-manager story-002 or retrofit ADR-0008

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/time-manager/story-002-background-detection.md — Background Detection — was_backgrounded() Flag
- Files changed: src/core/time_manager.gd (modified — _backgrounded var, _notification, was_backgrounded, reset_backgrounded), tests/unit/core/time_manager_background_test.gd (created)
- Test written: tests/unit/core/time_manager_background_test.gd (6 test functions)
- Blockers: None
- Next: /story-done production/epics/time-manager/story-002-background-detection.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/time-manager/story-002-background-detection.md — Background Detection
- Tech debt logged: None
- Advisory: reset_backgrounded() added beyond AC scope — specified in Implementation Notes, valid addition
- Next recommended: TimeManager epic COMPLETE (2/2) — retrofit ADR-0008 to unblock save-system stories

## Session Extract — /architecture-decision retrofit ADR-0008 2026-05-17
- ADR-0008 (Firebase Local-First Save): Proposed → Accepted
- Unblocked: save-system stories 001–005 (all now Ready)
- Next recommended: /dev-story production/epics/save-system/story-001-firebase-adapter-interface.md

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/save-system/story-001-firebase-adapter-interface.md — FirebaseAdapter Interface + MockFirebaseAdapter
- Files changed: src/platform/firebase_adapter.gd (created), src/platform/mock_firebase_adapter.gd (created), src/platform/gdfire_adapter.gd (created — TODO stub), tests/unit/core/save_system_adapter_test.gd (created)
- Test written: tests/unit/core/save_system_adapter_test.gd (8 test functions)
- Blockers: None
- Next: /story-done then /dev-story production/epics/save-system/story-002-local-file-io.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE
- Story: production/epics/save-system/story-001-firebase-adapter-interface.md — FirebaseAdapter Interface + MockFirebaseAdapter
- Tech debt logged: None
- Next recommended: /dev-story production/epics/save-system/story-002-local-file-io.md

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/save-system/story-002-local-file-io.md — Local File Read/Write
- Files changed: src/core/save_system.gd (created — _load_local, _write_local, _save_path override), tests/unit/core/save_system_local_io_test.gd (created)
- Test written: tests/unit/core/save_system_local_io_test.gd (7 test functions)
- Blockers: None — control-manifest.md absent (warned, continued)
- Next: /story-done then /dev-story production/epics/save-system/story-003-gamestate-serialisation.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE
- Story: production/epics/save-system/story-002-local-file-io.md — Local File Read/Write
- Tech debt logged: None
- Next recommended: /dev-story production/epics/save-system/story-003-gamestate-serialisation.md

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/save-system/story-003-gamestate-serialisation.md — GameState Serialise/Deserialise Round-Trip
- Files changed: src/core/save_system.gd (modified — added _serialise_game_state, _populate_game_state, _rabbit_to_dict, _dict_to_rabbit, _genome_to_dict, _gene_slot_to_dict, economy/hutch stubs, _gs/_tm helpers), tests/integration/core/save_system_round_trip_test.gd (created)
- Test written: tests/integration/core/save_system_round_trip_test.gd (6 test functions)
- Blockers: None — control-manifest.md absent (warned, continued)
- Next: /story-done then /dev-story production/epics/save-system/story-004-conflict-resolution.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE
- Story: production/epics/save-system/story-003-gamestate-serialisation.md — GameState Serialise/Deserialise Round-Trip
- Tech debt logged: None
- Next recommended: /dev-story production/epics/save-system/story-004-conflict-resolution.md

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/save-system/story-004-conflict-resolution.md — Conflict Resolution — Local vs Cloud Timestamp
- Files changed: src/core/save_system.gd (modified — added _resolve_conflict), tests/unit/core/save_system_conflict_test.gd (created)
- Test written: tests/unit/core/save_system_conflict_test.gd (6 test functions)
- Blockers: None
- Next: /story-done then /dev-story production/epics/save-system/story-005-boot-integration-autosave.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE
- Story: production/epics/save-system/story-004-conflict-resolution.md — Conflict Resolution
- Tech debt logged: None
- Next recommended: /dev-story production/epics/save-system/story-005-boot-integration-autosave.md

## Session Extract — /dev-story 2026-05-17
- Story: production/epics/save-system/story-005-boot-integration-autosave.md — Boot Integration + Auto-Save Timer
- Files changed: src/core/save_system.gd (modified — added _ready, _notification, load_game, save_game, _start_auto_save_timer), tests/integration/core/save_system_boot_test.gd (created)
- Test written: tests/integration/core/save_system_boot_test.gd (6 test functions)
- Blockers: None
- Next: /story-done production/epics/save-system/story-005-boot-integration-autosave.md

## Session Extract — /story-done 2026-05-17
- Verdict: COMPLETE
- Story: production/epics/save-system/story-005-boot-integration-autosave.md — Boot Integration + Auto-Save Timer
- Tech debt logged: None
- Next recommended: SPRINT CLOSE-OUT — all Must Have stories complete (31 Complete, 1 Blocked: rabbit-system/story-007-aura-bonus)

## Session Extract — /smoke-check sprint 2026-05-17
- Verdict: PASS WITH WARNINGS
- Report: production/qa/smoke-2026-05-17.md
- Warnings: automated tests NOT RUN (no godot binary / no project.godot); CI not configured
- Coverage: 31/31 Complete stories COVERED, 0 MISSING

## Session Extract — /team-qa sprint 2026-05-17
- Verdict: APPROVED WITH CONDITIONS
- QA Plan: production/qa/qa-plan-foundation-core-2026-05-17.md
- Sign-off: production/qa/qa-signoff-foundation-core-2026-05-17.md
- Bugs filed: 0
- Conditions: BLK-002 (create project.godot), BLK-003 (configure CI), then run test suite green
- Next: Resolve BLK-002 + BLK-003, then /gate-check

## Session Extract — BLK-002 + BLK-003 resolved 2026-05-17
- project.godot created with 6 autoloads (EventBus #1 → SceneManager #6, per ADR-0001)
- .github/workflows/ci.yml created — MikeSchulze/gdUnit4-action@v1, Godot 4.6.0, tests/unit + tests/integration
- .gitignore updated: reports/, addons/gdunit4/.gdunit_temp/
- icon.svg placeholder created
- QA sign-off updated: BLK-002 + BLK-003 marked RESOLVED
- Remaining: BLK-001 (aura formula spec — game-designer task); run test suite to confirm green
- Next: /gate-check (conditions 1-3 met structurally; test execution pending CI first push)
