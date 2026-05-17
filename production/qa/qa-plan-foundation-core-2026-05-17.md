# QA Plan — Foundation + Core Sprint
**Date**: 2026-05-17
**Sprint**: Foundation + Core (all 9 epics)
**QA Lead**: qa-lead
**Smoke Check**: PASS WITH WARNINGS (`production/qa/smoke-2026-05-17.md`)

---

## Scope

| Field | Value |
|-------|-------|
| Stories in scope | 31 Complete + 1 Blocked |
| Story types | Logic (21), Integration (9), Blocked (1) |
| Visual/Feel stories | 0 |
| UI stories | 0 |
| Config/Data stories | 0 |
| Manual QA required | 0 stories |
| Automated test files | 30 (one per story, all written) |

---

## Story Classification Table

| Story | Epic | Type | Test File | Auto Status | Manual Required |
|-------|------|------|-----------|-------------|----------------|
| Signal Catalogue | event-bus | Logic | `tests/unit/core/event_bus_catalogue_test.gd` | Written, NOT RUN | No |
| Connect/Emit/Disconnect | event-bus | Integration | `tests/integration/core/event_bus_integration_test.gd` | Written, NOT RUN | No |
| Data Structure | game-state | Logic | `tests/unit/core/game_state_init_test.gd` | Written, NOT RUN | No |
| Prestige Reset | game-state | Logic | `tests/unit/core/game_state_prestige_test.gd` | Written, NOT RUN | No |
| Core Time Tracking | time-manager | Logic | `tests/unit/core/time_manager_core_test.gd` | Written, NOT RUN | No |
| Background Detection | time-manager | Logic | `tests/unit/core/time_manager_background_test.gd` | Written, NOT RUN | No |
| Currency Ledger | economy-manager | Logic | `tests/unit/core/economy_manager_ledger_test.gd` | Written, NOT RUN | No |
| Currency Changed Signal | economy-manager | Integration | `tests/integration/core/economy_manager_signal_test.gd` | Written, NOT RUN | No |
| GotoScene Transition | scene-manager | Integration | `tests/integration/core/scene_manager_transitions_test.gd` | Written, NOT RUN | No |
| Overlay Stack | scene-manager | Logic | `tests/unit/core/scene_manager_overlay_test.gd` | Written, NOT RUN | No |
| Boot/Nav Routing | scene-manager | Integration | `tests/integration/core/scene_manager_routing_test.gd` | Written, NOT RUN | No |
| Rabbit Data Schema | rabbit-system | Logic | `tests/unit/core/rabbit_data_schema_test.gd` | Written, NOT RUN | No |
| Roster CRUD | rabbit-system | Logic | `tests/unit/core/rabbit_system_roster_test.gd` | Written, NOT RUN | No |
| Stat Decay | rabbit-system | Logic | `tests/unit/core/rabbit_system_decay_test.gd` | Written, NOT RUN | No |
| Lifecycle | rabbit-system | Integration | `tests/integration/core/rabbit_system_lifecycle_test.gd` | Written, NOT RUN | No |
| Death Signal | rabbit-system | Integration | `tests/integration/core/rabbit_system_death_test.gd` | Written, NOT RUN | No |
| Feed Rabbit | rabbit-system | Logic | `tests/unit/core/rabbit_system_feeding_test.gd` | Written, NOT RUN | No |
| **Aura Bonus** | **rabbit-system** | **—** | **—** | **BLOCKED** | **No** |
| Genome Schema | genetics-system | Logic | `tests/unit/core/genetics_schema_test.gd` | Written, NOT RUN | No |
| Inheritance/Mutation | genetics-system | Logic | `tests/unit/core/genetics_inheritance_test.gd` | Written, NOT RUN | No |
| Breed Preview | genetics-system | Logic | `tests/unit/core/genetics_breed_preview_test.gd` | Written, NOT RUN | No |
| Rarity Tier | genetics-system | Logic | `tests/unit/core/genetics_rarity_test.gd` | Written, NOT RUN | No |
| Trait Stacking | genetics-system | Logic | `tests/unit/core/genetics_trait_stacking_test.gd` | Written, NOT RUN | No |
| Earnings Report Schema | idle-production | Logic | `tests/unit/core/idle_earnings_report_test.gd` | Written, NOT RUN | No |
| Production Formula | idle-production | Logic | `tests/unit/core/idle_production_formula_test.gd` | Written, NOT RUN | No |
| Offline Tiers | idle-production | Logic | `tests/unit/core/idle_offline_tiers_test.gd` | Written, NOT RUN | No |
| Season/Prestige Integration | idle-production | Integration | `tests/integration/core/idle_production_integration_test.gd` | Written, NOT RUN | No |
| Firebase Adapter Interface | save-system | Logic | `tests/unit/core/save_system_adapter_test.gd` | Written, NOT RUN | No |
| Local File I/O | save-system | Logic | `tests/unit/core/save_system_local_io_test.gd` | Written, NOT RUN | No |
| GameState Serialise/Deserialise | save-system | Integration | `tests/integration/core/save_system_round_trip_test.gd` | Written, NOT RUN | No |
| Conflict Resolution | save-system | Logic | `tests/unit/core/save_system_conflict_test.gd` | Written, NOT RUN | No |
| Boot Integration + Auto-Save | save-system | Integration | `tests/integration/core/save_system_boot_test.gd` | Written, NOT RUN | No |

---

## Automated Test Requirements

**Command when environment is ready:**
```bash
godot --headless --script tests/gdunit4_runner.gd 2>&1
```

All 30 test files must produce a green run before the sprint can receive a clean QA sign-off.

---

## Manual QA Scope

None — this sprint contains only Logic and Integration stories. Manual QA is not required by policy.

---

## Out of Scope

- Visual/Feel QA: no stories of this type in scope
- UI walkthroughs: no UI stories in scope
- Playtest session: no runnable build (`project.godot` does not yet exist)
- Performance profiling: no runnable build
- rabbit-system/story-007 Aura Bonus: BLOCKED — GDD aura formula spec missing

---

## Entry Criteria

- [x] All 30 implementable stories marked Complete
- [x] All 30 test files exist at expected paths
- [x] Smoke check: PASS WITH WARNINGS (automated tests NOT RUN — expected at this stage)
- [ ] `project.godot` exists and autoloads registered *(outstanding — BLK-002)*
- [ ] CI configured: `.github/workflows/ci.yml` running GdUnit4 headless *(outstanding — BLK-003)*
- [ ] Automated test suite executes and returns green *(outstanding — requires BLK-002 + BLK-003)*

---

## Exit Criteria

- All 30 Logic/Integration stories: automated test suite executes and passes
- 0 S1/S2 bugs open
- QA sign-off report produced at `production/qa/qa-signoff-foundation-core-2026-05-17.md`

---

## Blockers

| ID | Blocker | Severity | Owner | Resolution |
|----|---------|----------|-------|------------|
| BLK-001 | rabbit-system story-007 Aura Bonus — GDD aura formula spec missing | Story-scoped | game-designer | Write aura formula spec in GDD before Sprint 2 |
| BLK-002 | `project.godot` does not exist — automated tests cannot execute | CI gate | lead-programmer | Create project.godot, register autoloads |
| BLK-003 | No CI pipeline | CI gate | lead-programmer | Add `.github/workflows/ci.yml` with GdUnit4 headless runner |

BLK-002 and BLK-003 must be resolved before the sprint can transition to a clean APPROVED verdict.
