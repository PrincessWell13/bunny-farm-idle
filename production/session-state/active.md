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

## Session Extract — /story-done 2026-05-20
- Verdict: COMPLETE (×3) + COMPLETE WITH NOTES (×1)
- Stories closed: expedition-system/story-001, story-002, story-003; prestige-system/story-002
- Tech debt logged: None (advisory deviation noted in expedition story-001 completion notes)
- Next recommended: S05-02 (balance.json food keys) or S05-04 (confirm CI badge)

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

## Session Extract — Gate blocker resolution 2026-05-18

### Pre-Production → Production gate blockers resolved this session:
- design/art/art-bible.md — CREATED (9 sections, pixel 16-bit style, warm pastel palette)
- design/accessibility-requirements.md — CREATED (Standard tier committed)
- design/ux/interaction-patterns.md — CREATED (12 patterns: IP-01 through IP-12)
- docs/architecture/control-manifest.md — CREATED (derived from ADR-0001 through ADR-0008)
- design/ux/main-menu.md — CREATED (main menu UX spec)
- design/ux/hud.md — CREATED (HUD spec: header strip + currency counters + notification bell)
- design/ux/pause-menu.md — CREATED (settings panel as tall bottom sheet)
- production/sprints/sprint-01.md — CREATED (Foundation + Core sprint plan, 21 Complete + 9 Ready)
- prototypes/core-loop-prototype/README.md — CREATED (scope, success criteria, playtest protocol)
- design/characters/character-visual-profiles.md — CREATED (player avatar + 7 rabbit archetypes)

### Remaining gate blockers (require actual gameplay + human playtesting):
- Vertical Slice build — requires Sprint 02 prototype implementation (Godot scenes)
- 3 playtest sessions — requires Vertical Slice first
- production/playtests/ — empty, needs playtest reports after sessions

### Next recommended:
1. Implement core-loop-prototype scenes in Godot (Sprint 02)
2. Conduct 3 playtest sessions, write reports to production/playtests/
3. Run /gate-check pre-production to verify all blockers resolved

## Session Extract — /story-done 2026-05-18
- Verdict: COMPLETE
- Story: production/epics/habitat-system/story-001-hutch-data-schema.md — HutchData Schema + Instantiation
- Tech debt logged: None
- Next recommended: story-002-assign-remove-rabbit.md (depends on story-001 ✅)

## Session Extract — /dev-story 2026-05-18
- Story: production/epics/habitat-system/story-001-hutch-data-schema.md — HutchData Schema + Instantiation
- Files changed: src/core/hutch_data.gd (created), tests/unit/core/hutch_data_schema_test.gd (created)
- Test written: tests/unit/core/hutch_data_schema_test.gd (8 test functions, AC-1 through AC-8)
- Blockers: None
- Next: /story-done production/epics/habitat-system/story-001-hutch-data-schema.md

## Session Extract — /create-stories habitat-system + food-system 2026-05-18
- HabitatSystem: 5 stories created (story-001 through story-005), all Ready
  - story-001: HutchData Schema (Logic)
  - story-002: assign_rabbit / remove_rabbit (Logic)
  - story-003: Cleanliness Decay (Logic)
  - story-004: get_hutch_bonuses (Logic)
  - story-005: get_capacity Level-Based (Logic)
  - Flag: rabbit_hutch_changed + hutch_cleanliness_changed signals must be added to event_bus.gd
  - Flag: balance.json needs habitat namespace keys
- FoodSystem: 4 stories created (story-001 through story-004), all Ready
  - story-001: Inventory Schema (Logic)
  - story-002: feed_rabbit delegation + rollback (Integration)
  - story-003: Farm Plot Timers (Logic)
  - story-004: Offline Plot Resolution (Integration)
  - Flag: food_harvested + farm_plots_updated signals must be added to event_bus.gd
- S03-03 + S03-05 CLOSED
- S03-04 + S03-06 next: /dev-story

## Session Extract — ADR-0009 + ADR-0010 written 2026-05-18
- ADR-0009: FoodSystem Inventory Model — Accepted (docs/architecture/adr-0009-food-system-inventory.md)
- ADR-0010: HabitatSystem Hutch Ownership — Accepted (docs/architecture/adr-0010-habitat-system-hutch-ownership.md)
- Notable: ADR-0010 flags dual-source truth risk (RabbitData.hutch_id + HutchData.occupants must stay in sync atomically)
- HabitatSystem epic: Blocked → Ready; FoodSystem epic: Blocked → Ready
- TR-food-001 and TR-habitat-002 now active in tr-registry.yaml
- Next: /create-stories habitat-system and /create-stories food-system (S03-03 + S03-05)

## Session Extract — /create-epics layer:feature 2026-05-18
- 10 Feature epics created in production/epics/
- Ready: SeasonSystem, PrestigeSystem (ADRs fully covered)
- Blocked: HabitatSystem (ADR-0010), FoodSystem (ADR-0009), ExpeditionSystem (ADR-0011), GuildSystem (ADR-0014), EventSystem (ADR-0013), MerchantSystem (ADR-0015), GenePuzzleSystem (ADR-0016), CollectionSystem (ADR-0017)
- S03-02 CLOSED
- Next: write ADR-0009 + ADR-0010 to unblock HabitatSystem and FoodSystem stories (S03-03 + S03-05)

## Session Extract — /architecture-review 2026-05-18
- Verdict: CONCERNS (Foundation+Core PASS-grade; 14 Feature-layer ADR gaps expected)
- Requirements: 40 total — 25 covered (full chain), 1 partial (aura), 14 gaps (Feature)
- New TR-IDs registered: 26 active in tr-registry.yaml
- GDD revision flags: None
- Top ADR gaps: ADR-0009 FoodSystem, ADR-0010 HabitatSystem, ADR-0014 GuildSystem
- Files: docs/architecture/architecture-review-2026-05-18.md, architecture-traceability.md, tr-registry.yaml (v2)
- S03-01 CLOSED — gate concern resolved

## Session Extract — Sprint 03 planned 2026-05-18
- Sprint 03 written: production/sprints/sprint-03.md
- sprint-status.yaml written: production/sprint-status.yaml
- Gate check: CONCERNS (not FAIL) — accepted, proceeding to Production
- Open concerns: traceability matrix missing (S03-01), tests never CI-run (S03-14)
- Sprint 03 critical path: architecture-review → create-epics feature → habitat/food/breeding-ui stories → dev-story

## Session Extract — Core Loop Prototype implemented 2026-05-18
- Prototype: prototypes/core-loop-prototype/
- Files created: main.tscn, core_loop_prototype.gd (688 lines)
- Files modified: project.godot (3 new autoloads + main scene), src/core/scene_manager.gd (null guard)
- Prototype status: Implemented — ready for playtesting
- Project autoloads now: EventBus → TimeManager → EconomyManager → GameState → RabbitSystem → GeneticsSystem → IdleProductionSystem → SaveSystem → SceneManager
- To run: Open in Godot 4.6, press F5
- Next: Conduct 3 playtest sessions, write reports to production/playtests/
- After playtests: run /gate-check pre-production to advance to Production stage

## Session Extract — /story-done 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/habitat-system/story-002-assign-remove-rabbit.md — assign_rabbit() / remove_rabbit() API
- Files: src/core/habitat_system.gd (created), src/core/rabbit_system.gd (added set_hutch_id), tests/unit/core/habitat_system_assignment_test.gd (10 tests)
- Tech debt logged: None
- Next recommended: production/epics/habitat-system/story-003-cleanliness-decay.md

## Session Extract — /dev-story 2026-05-19
- Story: production/epics/habitat-system/story-003-cleanliness-decay.md — Cleanliness Decay via TimeManager Tick
- Files changed: src/core/habitat_system.gd (added _ready/_exit_tree/_load_balance_data/_on_tick), src/core/event_bus.gd (added hutch_cleanliness_changed signal), assets/data/balance.json (added habitat namespace)
- Test written: tests/unit/core/habitat_system_cleanliness_test.gd (7 test functions)
- Blockers: None
- Next: /story-done production/epics/habitat-system/story-003-cleanliness-decay.md

## Session Extract — /story-done 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/habitat-system/story-003-cleanliness-decay.md — Cleanliness Decay via TimeManager Tick
- Tech debt logged: None
- Next recommended: production/epics/habitat-system/story-004-hutch-bonuses.md

## Session Extract — /dev-story 2026-05-19
- Story: production/epics/habitat-system/story-004-hutch-bonuses.md — get_hutch_bonuses()
- Files changed: src/core/habitat_system.gd (added _cleanliness_thresholds var + get_hutch_bonuses + updated _load_balance_data)
- Test written: tests/unit/core/habitat_system_bonuses_test.gd (8 test functions)
- Blockers: None
- Next: /story-done production/epics/habitat-system/story-004-hutch-bonuses.md

## Session Extract — /story-done 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/habitat-system/story-004-hutch-bonuses.md — get_hutch_bonuses()
- Tech debt logged: None
- Next recommended: production/epics/habitat-system/story-005-capacity-levels.md

## Session Extract — /dev-story 2026-05-19
- Story: production/epics/habitat-system/story-005-capacity-levels.md — get_capacity()
- Files changed: src/core/habitat_system.gd (added _capacity_table + get_capacity() replacing stub), assets/data/balance.json (fixed capacity_by_level from dict to array)
- Test written: tests/unit/core/habitat_system_capacity_test.gd (8 test functions)
- Blockers: None
- Next: /story-done production/epics/habitat-system/story-005-capacity-levels.md

## Session Extract — /story-done 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/habitat-system/story-005-capacity-levels.md — get_capacity() level-based slot count
- Tech debt logged: None
- Next recommended: production/epics/food-system/story-001-inventory-schema.md

## Session Extract — /dev-story 2026-05-19
- Story: production/epics/food-system/story-001-inventory-schema.md — FoodSystem inventory schema
- Files changed: src/core/game_state.gd (added food_inventory field + _reset_state()), src/core/event_bus.gd (added 3 food signals), src/core/food_system.gd (created — get_inventory, _add_to_inventory, _deduct_from_inventory + stubs), assets/data/balance.json (added food section)
- Test written: tests/unit/core/food_system_inventory_test.gd (7 test functions)
- Blockers: None
- Next: /story-done production/epics/food-system/story-001-inventory-schema.md

## Session Extract — /story-done 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/food-system/story-001-inventory-schema.md — FoodSystem inventory schema
- Tech debt logged: None
- Next recommended: production/epics/food-system/story-002-feed-rabbit.md (if it exists) or next FoodSystem story

## Session Extract — /create-epics layer:feature 2026-05-19
- Verdict: COMPLETE — 10 Feature layer epics already existed from prior session
- Epics ready (ADRs present): HabitatSystem, FoodSystem, SeasonSystem, PrestigeSystem
- Epics blocked (ADRs needed): ExpeditionSystem (ADR-0011), GuildSystem (ADR-0014), EventSystem (ADR-0013), MerchantSystem (ADR-0015), GenePuzzleSystem (ADR-0016), CollectionSystem (ADR-0017)
- S03-02 marked done in sprint-status.yaml; epics index updated
- Next: /create-stories season-system or /create-stories prestige-system (both Ready)

## Session Extract — /create-stories season-system 2026-05-19
- Verdict: COMPLETE — 2 stories written
- Story 001: season-clock.md — season clock, day advancement, season_changed signal
- Story 002: active-multipliers.md — get_active_multipliers() for all 4 seasons
- balance.json additions required: season.seconds_per_day, season.days_per_season, season.multipliers
- S03-11 marked done; SeasonSystem epic updated
- Next: /dev-story production/epics/season-system/story-001-season-clock.md

## Session Extract — /dev-story 2026-05-19
- Story: production/epics/season-system/story-001-season-clock.md — Season Clock
- Files changed: src/core/season_system.gd (created — full SeasonSystem with clock + multipliers), assets/data/balance.json (added season section)
- Test written: tests/unit/core/season_system_clock_test.gd (9 test functions covering story-001 + story-002 ACs)
- Blockers: None
- Next: /story-done production/epics/season-system/story-001-season-clock.md

## Session Extract — /story-done 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/season-system/story-001-season-clock.md — Season Clock
- Tech debt logged: None
- Advisory: GDScript-side fallback defaults (_seconds_per_day = 3600.0, _days_per_season = 7) are class-body typed vars overwritten at runtime by _load_balance_data() — consistent project pattern, not hardcoding
- S03-12 marked done in sprint-status.yaml
- Next recommended: /story-done production/epics/season-system/story-002-active-multipliers.md (implementation already complete in season_system.gd)

## Session Extract — /story-done story-002-active-multipliers 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/season-system/story-002-active-multipliers.md — Active Multipliers
- Tech debt logged: None (advisory — follow-up tests for Summer/Winter/pure-read multiplier ACs)
- Next recommended: SeasonSystem epic COMPLETE (2/2 stories done). Must-have stories S03-07/S03-08 (BreedingUI) need /create-stories breeding-ui next.

## Session Extract — /create-epics + /create-stories breeding-ui 2026-05-19
- BreedingUI EPIC created: production/epics/breeding-ui/EPIC.md (ADR-0003 + ADR-0006)
- HUD EPIC created: production/epics/hud/EPIC.md (ADR-0001 + ADR-0003)
- 2 BreedingUI stories created:
  - story-001-parent-selector-breed-trigger.md (Integration, ready for dev)
  - story-002-result-reveal-panel.md (Visual/Feel, depends on story-001)
- S03-07 done, S03-08 ready-for-dev, S03-09 done
- Next: /dev-story production/epics/breeding-ui/story-001-parent-selector-breed-trigger.md

## Session Extract — /story-done breeding-ui-story-001 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/breeding-ui/story-001-parent-selector-breed-trigger.md — Parent Selector + Breed Trigger
- Files: src/ui/breeding_ui.gd (new), tests/integration/ui/breeding_ui_breed_trigger_test.gd (new, 11 tests)
- Tech debt logged: None (advisory — parent_a_id public for test access; 44px hardcoded as UI constant)
- Next recommended: /dev-story production/epics/breeding-ui/story-002-result-reveal-panel.md (Visual/Feel, depends on story-001 DONE)

## Session Extract — /dev-story breeding-ui-story-002 2026-05-19
- Story: production/epics/breeding-ui/story-002-result-reveal-panel.md — Result Reveal Panel
- Files changed: src/ui/breeding_ui.gd (extended with reveal panel), assets/data/balance.json (added ui.breed_reveal_duration: 1.5)
- Test written: None — Visual/Feel story; evidence doc created at production/qa/evidence/breeding-ui-reveal-evidence.md
- Blockers: None
- Next: /story-done production/epics/breeding-ui/story-002-result-reveal-panel.md

## Session Extract — /story-done breeding-ui-story-002 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/breeding-ui/story-002-result-reveal-panel.md — Result Reveal Panel
- Tech debt logged: None (advisory — Tween vs AnimationPlayer; AC-4/AC-5 deferred to playtest)
- Next recommended: BreedingUI epic COMPLETE (2/2 stories done). Should-have: HUD story-001 coin display (need /create-stories hud first). All Must Have stories done — sprint close-out available.

## Session Extract — /dev-story hud-story-001 2026-05-19
- Story: production/epics/hud/story-001-currency-header.md — Currency Header Display
- Files changed: src/ui/hud.gd (new), tests/integration/ui/hud_currency_display_test.gd (new, 8 tests)
- Test written: tests/integration/ui/hud_currency_display_test.gd
- Blockers: None
- Next: /story-done production/epics/hud/story-001-currency-header.md

## Session Extract — /story-done hud-story-001 2026-05-19
- Verdict: COMPLETE
- Story: production/epics/hud/story-001-currency-header.md — Currency Header Display
- Tech debt logged: None
- Next recommended: /dev-story production/epics/hud/story-002-nav-bar.md (Integration, depends on story-001 DONE)

## Session Extract — /dev-story hud-story-002 2026-05-19
- Story: production/epics/hud/story-002-nav-bar.md — Bottom Navigation Bar
- Files changed: src/ui/hud.gd (extended with nav bar), tests/integration/ui/hud_nav_bar_test.gd (new, 10 tests)
- Test written: tests/integration/ui/hud_nav_bar_test.gd
- Blockers: None
- Next: /story-done production/epics/hud/story-002-nav-bar.md

## Session Extract — /story-done hud-story-002 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/hud/story-002-nav-bar.md — Bottom Navigation Bar
- Tech debt logged: None (advisory — placeholder active tab colour)
- Next recommended: /dev-story production/epics/hud/story-003-notification-toast.md (UI, depends on story-002 DONE)

## Session Extract — /dev-story + /story-done hud-story-003 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/hud/story-003-notification-toast.md — Notification Toast
- Files changed: src/ui/hud.gd (extended with show_notification + notification signal), production/qa/evidence/hud-notification-evidence.md (new)
- Test written: None — UI story; evidence doc awaiting in-game sign-off
- HUD EPIC COMPLETE: all 3 stories done
- Next: Sprint close-out available — /smoke-check sprint → /team-qa sprint → /gate-check

## Session Extract — /smoke-check + /team-qa 2026-05-19
- Smoke check: PASS WITH WARNINGS → PASS (season-system/002 blocker resolved mid-cycle)
- QA verdict: APPROVED WITH CONDITIONS
- Condition: CONDITION-01 — habitat-system/002 signal rename (`rabbit_hutch_changed` vs `rabbit_assigned_to_hutch`) needs consistency check before gate
- Bugs filed: 0
- Files: production/qa/smoke-2026-05-19.md, production/qa/qa-plan-sprint-03-2026-05-19.md, production/qa/qa-signoff-sprint-03-2026-05-19.md
- Next: Resolve CONDITION-01 (signal rename check), then /gate-check

## Session Extract — CONDITION-01 resolved 2026-05-19
- Audit: codebase-wide grep for `rabbit_hutch_changed` — zero hits in src/ or tests/
- Finding: signal was always named `rabbit_assigned_to_hutch` throughout implementation
  - event_bus.gd line 28: `signal rabbit_assigned_to_hutch(rabbit_id: String, hutch_id: String)` — canonical declaration
  - habitat_system.gd line 89: assign path emits `EventBus.rabbit_assigned_to_hutch`
  - habitat_system.gd line 100: remove path emits `EventBus.rabbit_assigned_to_hutch`
- CONDITION-01 was a QA documentation error — no code change required
- Files updated: production/qa/qa-signoff-sprint-03-2026-05-19.md (CONDITION-01 → RESOLVED, verdict → APPROVED), production/qa/smoke-2026-05-19.md (PASS WITH WARNINGS → PASS, table updated)
- QA verdict is now: APPROVED — all conditions resolved
- Next: /gate-check pre-production → Production stage gate

## Session Extract — /dev-story 2026-05-19
- Story: production/epics/food-system/story-002-feed-rabbit.md — feed_rabbit() delegation + rollback
- Files changed: src/core/rabbit_system.gd (FoodItem inner class removed; feed_rabbit signature changed to food_type: String), src/core/food_system.gd (feed_rabbit stub replaced with full ADR-0009 implementation)
- Test written: tests/integration/core/food_system_feed_test.gd (7 test functions)
- Deviations: RabbitSystem.feed_rabbit signature changed from FoodItem→String (inner class inaccessible via autoload reference in GDScript 4)
- Next: /story-done production/epics/food-system/story-002-feed-rabbit.md

## Session Extract — /story-done 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/food-system/story-003-farm-plot-timers.md — Farm Plot Timers
- Tech debt logged: None (3 advisories documented in story Completion Notes)
- Next recommended: S04-03 — FoodSystem story-004 offline plot resolution (now unblocked)

## Session Extract — /dev-story 2026-05-19
- Story: production/epics/food-system/story-004-offline-plot-resolution.md — Offline Plot Resolution
- Files changed: src/core/food_system.gd (added _resolve_offline_plots(), call_deferred in _ready), assets/data/balance.json (food items: added seed_cost/grow_time_seconds/harvest_quantity)
- Test written: tests/integration/core/food_system_offline_test.gd (7 test functions)
- Blockers: None
- Next: /story-done production/epics/food-system/story-004-offline-plot-resolution.md

## Session Extract — /story-done 2026-05-19
- Verdict: COMPLETE
- Story: production/epics/food-system/story-004-offline-plot-resolution.md — Offline Plot Resolution
- Tech debt logged: None
- Next recommended: S04-04 — Write ADR-0011 (ExpeditionSystem), S04-07 — /create-stories prestige-system, S04-09 — difficulty-curve.md (all unblocked, can run in parallel)

## Session Extract — difficulty-curve.md written 2026-05-19
- File: design/difficulty-curve.md — CREATED (v1.0, all 8 GDD sections present)
- Covers: 5 time brackets (first hour → first prestige), 5 fun cliff moments, difficulty scaling rules, idle production formula with worked examples, prestige gate timeline, pity system spec, 8 functional + 5 experiential acceptance criteria
- Flags raised: gestation timer, hutch costs, and pity thresholds are design-doc-only — need balance.json entries before Sprint 04 breeding/expedition epics
- Next: /design-review design/difficulty-curve.md to validate before Production→Polish gate

## Session Extract — /create-stories prestige-system 2026-05-19
- Epic: production/epics/prestige-system/
- Stories created: story-001-can-prestige-execute.md (Ready, Logic), story-002-prestige-bonus.md (Ready, Logic)
- Story 001: can_prestige() + execute_prestige() — gate check (Legendary rabbit + cap), selective reset via GameState.prestige_reset(keep); CollectionSystem check stubbed to true
- Story 002: _get_prestige_growth_bonus() in IdleProductionSystem — reads balance.json prestige.bonuses_per_level growth_rate_bonus; highest-defined-level-≤-prestige_count lookup; distinct from offline_production_bonus path already in story-004
- Notable: balance.json only defines 5 prestige levels vs GDD's 20 — documented in story-002, lookup logic is forward-compatible
- Files updated: EPIC.md stories table, session state
- RabbitSystem stubs needed: has_legendary_rabbit() + get_legendary_rabbit_ids() must exist before story-001 integration test
- Next: /dev-story production/epics/prestige-system/story-001-can-prestige-execute.md

## Session Extract — /story-done 2026-05-19
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/prestige-system/story-001-can-prestige-execute.md — PrestigeSystem story-001 can_prestige() + execute_prestige()
- Tech debt logged: None
- Next recommended: S04-12 PrestigeSystem story-002 prestige bonus (production/epics/prestige-system/story-002-prestige-bonus.md)

## Session Extract — /dev-story 2026-05-20
- Story: production/epics/hud/story-006-expedition-slot-panel.md — Expedition Slot Panel (S05-09)
- Files changed: src/ui/expedition_slot_ui.gd (created), src/ui/expedition_panel.gd (created)
- Test written: None — UI story; manual evidence required at production/qa/evidence/s05-09-expedition-panel-evidence.md
- Blockers: None
- Next: /story-done production/epics/hud/story-006-expedition-slot-panel.md

## Session Extract — /story-done 2026-05-20
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/hud/story-006-expedition-slot-panel.md — Expedition Slot Panel
- Tech debt logged: None
- Next recommended: S05-10 — Prestige Button (production/epics/hud/story-007-prestige-button.md)

## Session Extract — /dev-story + /story-done S05-10 2026-05-22
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/hud/story-007-prestige-button.md — Prestige Button
- S05-02 also closed: balance.json food keys (seed_cost/grow_time_seconds/harvest_quantity) confirmed already present from food-system story-004
- Files changed: src/ui/hud.gd (extended with prestige_button + prestige_confirm_dialog exports, _refresh_prestige_button, _on_prestige_tapped, _on_prestige_confirmed, _on_prestige_state_changed; currency_changed handler also triggers refresh)
- Evidence doc: production/qa/evidence/s05-10-prestige-button-evidence.md (screenshot checklist pending scene wiring)
- Tech debt logged: None
- Sprint 05 status: S05-01 ✅, S05-02 ✅, S05-05 ✅, S05-09 ✅, S05-10 ✅ — 5/17 done
- Remaining must-haves: S05-03 (difficulty-curve review), S05-04 (CI badge), S05-06 (food widget), S05-07 (farm plot UI), S05-08 (save/load round-trip test)
- Next recommended: S05-08 (save/load sprint-04 round-trip test, no blockers) OR S05-06 (food inventory widget, no blocker now S05-02 done)

## Session Extract — /dev-story S05-08 2026-05-22
- Story: production/epics/save-system/story-s05-08-save-load-round-trip.md — Save/Load Round-Trip Sprint-04 Fields (C04-06)
- Story file created first (was missing — only sprint task existed)
- Root cause fixed: _serialise_game_state() was missing food_inventory + farm_plots keys; _populate_game_state() was missing the same two fields
- Files changed: src/core/save_system.gd (added food_inventory + farm_plots to both _serialise_game_state and _populate_game_state), tests/integration/core/save_load_sprint04_test.gd (created, 8 test functions)
- Test written: tests/integration/core/save_load_sprint04_test.gd (8 tests — AC-1 through AC-8)
- Blockers: None
- Sprint 05 status: S05-01 ✅, S05-02 ✅, S05-05 ✅, S05-08 ✅, S05-09 ✅, S05-10 ✅ — 6/17 done
- Remaining must-haves: S05-03 (difficulty-curve review), S05-04 (CI badge), S05-06 (food inventory widget), S05-07 (farm plot UI)
- Next: /story-done production/epics/save-system/story-s05-08-save-load-round-trip.md then S05-06 (food inventory widget)

## Session Extract — /dev-story S05-06 2026-05-22
- Story: production/epics/hud/story-004-food-inventory-widget.md — Food Inventory Widget
- Files changed: src/ui/hud.gd (Story-004 section: _food_counts, _food_labels, register_food_label, get_food_count, _refresh_food_display, _update_food_label, _on_food_harvested, _on_food_used), src/core/food_system.gd (emit EventBus.food_used after successful deduction in feed_rabbit)
- Test written: None — UI story; evidence doc at production/qa/evidence/s05-06-food-widget-evidence.md
- Deviation: story referenced rabbit_fed signal (doesn't exist) → used food_used(food_id) instead (already in event_bus.gd, now emitted by feed_rabbit)
- Blockers: None
- Next: /story-done production/epics/hud/story-004-food-inventory-widget.md then S05-07 (farm plot progress UI)

## Session Extract — /story-done S05-08 2026-05-22
- Verdict: COMPLETE
- Story: production/epics/save-system/story-s05-08-save-load-round-trip.md — Save/Load Round-Trip Sprint-04 Fields
- Tech debt logged: None
- Closes QA condition C04-06
- Next recommended: S05-06 — HUD story-004 Food Inventory Widget (production/epics/hud/story-004-food-inventory-widget.md)

## Session Extract — /dev-story + /story-done S05-07 2026-05-22
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/hud/story-005-farm-plot-progress-ui.md — Farm Plot Progress UI
- Files changed: src/ui/hud.gd (Story-005 section: plot_slot_labels/buttons exports, _countdown_timer, _refresh_all_plots, _render_plot, _render_empty, _update_countdowns, on_plot_tapped, farm_plots_updated wired), src/core/food_system.gd (added harvest_plot())
- Evidence doc: production/qa/evidence/s05-07-farm-plot-ui-evidence.md (screenshots pending scene wiring)
- Advisory: farm_plots_updated carries no params — HUD reads via get_farm_plot_state() (ADR-0003 compliant)
- Tech debt logged: None
- Sprint 05 status: S05-01 ✅, S05-02 ✅, S05-05 ✅, S05-06 ✅, S05-07 ✅, S05-08 ✅, S05-09 ✅, S05-10 ✅ — 8/17 done
- Remaining must-haves: S05-03 (difficulty-curve review), S05-04 (CI badge)
- Next recommended: S05-03 (difficulty-curve design review) OR S05-11 (PrestigeSystem _load_from_text, should-have)

## Session Extract — /design-review difficulty-curve.md 2026-05-22
- Verdict: MAJOR REVISION NEEDED → all 6 blockers resolved in-session (doc now v1.1)
- Specialists: game-designer, systems-designer, economy-designer, qa-lead, creative-director
- Critical fixes: (1) trait_effects_multiplier added to CC formula; (2) get_harvest_bonus() crash fixed → get_active_multipliers()["production_mult"]; (3) Winter offline_mult dead path fixed → _get_offline_season_multiplier(); (4) prestige formula corrected to show two terms; (5) pity counter scope/cascade specified (per-account, independent counters); (6) cleanliness stub documented
- Files changed: design/difficulty-curve.md (v1.1), src/core/idle_production_system.gd (get_harvest_bonus bug + offline season mult), design/gdd/systems-index.md (created), design/gdd/reviews/difficulty-curve-review-log.md (created)
- S05-03 CLOSED
- Sprint 05 status: S05-01 ✅, S05-02 ✅, S05-03 ✅, S05-05 ✅, S05-06 ✅, S05-07 ✅, S05-08 ✅, S05-09 ✅, S05-10 ✅ — 9/17 done
- Remaining must-have: S05-04 (CI badge — human action required)
- Advisory open items: Autumn dominant strategy, prestige bonus size, Tier3→4 ramp, missing Cliffs 2 and 4
- Next recommended: S05-04 (CI badge, human-side) then sprint close-out sequence
