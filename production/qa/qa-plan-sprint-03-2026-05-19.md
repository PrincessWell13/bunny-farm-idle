# QA Test Plan — Sprint 3

**Sprint**: Sprint 3 — Feature Foundation (HabitatSystem, FoodSystem, SeasonSystem, BreedingUI, HUD)
**Date**: 2026-05-19
**Engine**: Godot 4.6 / GDScript
**Prepared by**: QA Lead
**Test Framework**: GdUnit4

---

## Story Classification

| Story ID | Title | Type | Test File | Status |
|---|---|---|---|---|
| habitat-system/001 | HutchData Schema + Instantiation | Logic | `tests/unit/core/hutch_data_schema_test.gd` | COVERED |
| habitat-system/002 | assign_rabbit / remove_rabbit API | Logic | `tests/unit/core/habitat_system_assignment_test.gd` | COVERED |
| habitat-system/003 | Cleanliness Decay via TimeManager Tick | Logic | `tests/unit/core/habitat_system_cleanliness_test.gd` | COVERED |
| habitat-system/004 | get_hutch_bonuses() | Logic | `tests/unit/core/habitat_system_bonuses_test.gd` | COVERED |
| habitat-system/005 | get_capacity() Level-Based Slot Count | Logic | `tests/unit/core/habitat_system_capacity_test.gd` | COVERED |
| food-system/001 | FoodSystem Inventory Schema | Logic | `tests/unit/core/food_system_inventory_test.gd` | COVERED |
| season-system/001 | Season Clock + Day Advancement | Logic | `tests/unit/core/season_system_clock_test.gd` | COVERED |
| season-system/002 | get_active_multipliers() All 4 Seasons | Logic | `tests/unit/core/season_system_clock_test.gd` | COVERED |
| breeding-ui/001 | Parent Selector + Breed Trigger | Integration | `tests/integration/ui/breeding_ui_breed_trigger_test.gd` | COVERED |
| hud/001 | Currency Header Display | Integration | `tests/integration/ui/hud_currency_display_test.gd` | COVERED |
| hud/002 | Bottom Navigation Bar | Integration | `tests/integration/ui/hud_nav_bar_test.gd` | COVERED |
| breeding-ui/002 | Result Reveal Panel | Visual/Feel | `production/qa/evidence/breeding-ui-reveal-evidence.md` | EVIDENCE FILED |
| hud/003 | Notification Toast | UI | `production/qa/evidence/hud-notification-evidence.md` | EVIDENCE FILED |

---

## Automated Test Requirements

All Logic and Integration stories have automated test coverage. No blocking gaps remain.

| Scope | Count | Functions | Gate |
|---|---|---|---|
| Unit tests (Logic stories) | 8 files | ~62 total functions | BLOCKING — must pass |
| Integration tests (Integration stories) | 3 files | 29 total functions | BLOCKING — must pass |

**Run command**: `godot --headless --script tests/gdunit4_runner.gd`

**CI gate**: `.github/workflows/ci.yml` — runs on every push to master. No merge if any test fails.

---

## Manual QA Scope

Two stories require human sign-off. Evidence docs are filed; sign-off is pending.

| Story | Type | Evidence File | Criteria |
|---|---|---|---|
| breeding-ui/002 — Result Reveal Panel | Visual/Feel | `production/qa/evidence/breeding-ui-reveal-evidence.md` | Tween animation plays smoothly; reveal sequence matches spec AC-1 through AC-5 |
| hud/003 — Notification Toast | UI | `production/qa/evidence/hud-notification-evidence.md` | Toast appears, readable, dismisses; thumb-reachable in bottom half; 44×44 px touch target met |

Manual test execution requires a running Godot 4.6 build on Android or PC.

---

## Out of Scope

- food-system/002–004 — not in Sprint 3; carry forward to Sprint 4
- Prestige system — not yet implemented
- Feature-layer epics without ADRs (Expedition, Guild, Event, Merchant, GenePuzzle, Collection)
- Performance profiling and soak testing — deferred to pre-milestone gate
- rabbit-system/007 (Aura Bonus) — blocked on aura formula spec

---

## Entry Criteria

All entry criteria met as of 2026-05-19.

| Criterion | Status |
|---|---|
| Smoke check passed | PASS (blocker resolved 2026-05-19) |
| season-system/002 blocker resolved (3 test functions added) | RESOLVED |
| All Logic/Integration stories have test files | CONFIRMED (11/11) |
| CI workflow configured | CONFIRMED |
| Evidence docs filed for Visual/Feel and UI stories | CONFIRMED (2/2) |

---

## Exit Criteria

Sprint 3 is done when all of the following are true:

| Criterion | Gate Level |
|---|---|
| All unit test functions pass in CI | BLOCKING |
| All integration test functions pass in CI | BLOCKING |
| No S1 or S2 bugs open against Sprint 3 stories | BLOCKING |
| breeding-ui/002 evidence doc signed off | ADVISORY |
| hud/003 evidence doc signed off | ADVISORY |
| `production/qa/qa-signoff-sprint-03-2026-05-19.md` written by QA Lead | BLOCKING |
