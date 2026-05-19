# Sprint 04 — Feature Layer: Food Complete + Expedition + Prestige

**Sprint**: 04
**Dates**: 2026-05-19 — 2026-06-08
**Stage**: Production
**Goal**: Complete the FoodSystem, unblock and start ExpeditionSystem, create and implement PrestigeSystem stories, and produce the Difficulty Curve document — bringing the game loop to the point where the core farm→feed→breed→prestige cycle is fully playable.

## Capacity

- Sessions estimated: ~7–9 working sessions (AI-accelerated)
- Buffer (20%): ~1–2 sessions reserved for debugging / ADR negotiation
- Effective: ~6–7 implementation sessions

---

## Sprint Scope

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. | Dependencies | Acceptance Criteria |
|----|------|-------------|------|--------------|---------------------|
| S04-01 | FoodSystem story-002 — `feed_rabbit()` delegation + rollback | gdscript-specialist | 1 session | story-001 ✅ | `FoodSystem.feed_rabbit()` deducts inventory, delegates to `RabbitSystem.feed_rabbit()`, rolls back on failure; `tests/integration/core/food_system_feed_test.gd` passes |
| S04-02 | FoodSystem story-003 — farm plot timers + `seed_plot()` | gdscript-specialist | 1 session | S04-01 | `seed_plot()` deducts coins, plot progresses per tick, `food_harvested` + `farm_plots_updated` signals emit; `tests/unit/core/food_system_plots_test.gd` passes |
| S04-03 | FoodSystem story-004 — offline plot resolution boot hook | gdscript-specialist | 0.5 session | S04-02 | `_resolve_offline_plots()` runs at boot; elapsed time calculates harvests correctly; `tests/integration/core/food_system_offline_test.gd` passes |
| S04-04 | Write ADR-0011 — ExpeditionSystem async timer + loot resolution | technical-director | 0.5 session | — | `docs/architecture/adr-0011-expedition-system-async-timer.md` Status: Accepted; timer model and loot resolution strategy documented |
| S04-05 | `/create-stories expedition-system` | game-designer | 0.5 session | S04-04 | Stories for `start_expedition()`, `collect()`, offline catch-up in `production/epics/expedition-system/` |
| S04-06 | ExpeditionSystem story-001 — `start_expedition()` + slot model | gdscript-specialist | 1 session | S04-05 | Expedition slots written to GameState; start timestamp recorded; rabbit IDs validated; `tests/unit/core/expedition_system_start_test.gd` passes |
| S04-07 | `/create-stories prestige-system` | game-designer | 0.5 session | — | Stories for `can_prestige()`, `execute_prestige()`, bonus stacking in `production/epics/prestige-system/` |
| S04-08 | PrestigeSystem story-001 — `can_prestige()` + `execute_prestige()` | gdscript-specialist | 1 session | S04-07 | Validates Legendary rabbit + collection threshold; triggers `GameState.prestige_reset()`; increments count + stacks bonus; cap at 20 enforced; `tests/unit/core/prestige_system_test.gd` passes |
| S04-09 | Write `design/difficulty-curve.md` | game-designer | 0.5 session | — | Document exists with pacing targets per hour of play; links to balance.json tuning knobs; required for Production→Polish gate |

### Should Have

| ID | Task | Agent/Owner | Est. | Dependencies | Acceptance Criteria |
|----|------|-------------|------|--------------|---------------------|
| S04-10 | ExpeditionSystem story-002 — `collect()` + loot roll | gdscript-specialist | 1 session | S04-06 | `collect(slot_id)` resolves loot from balance.json weights; grants via EconomyManager; slot cleared; `tests/integration/core/expedition_collect_test.gd` passes |
| S04-11 | ExpeditionSystem story-003 — offline expedition catch-up | gdscript-specialist | 0.5 session | S04-10 | Boot resolves expeditions that elapsed while backgrounded; `tests/integration/core/expedition_offline_test.gd` passes |
| S04-12 | PrestigeSystem story-002 — prestige bonus in production formula | gdscript-specialist | 0.5 session | S04-08 | `IdleProductionSystem` reads `GameState.prestige_count`, applies stacking bonus from balance.json; unit test passes |
| S04-13 | CI green run — push to GitHub | devops-engineer | 0.5 session | — | CI badge passes; smoke report references real test run output (resolves BLK-003) |

### Nice to Have

| ID | Task | Agent/Owner | Est. | Dependencies | Acceptance Criteria |
|----|------|-------------|------|--------------|---------------------|
| S04-14 | Write ADR-0012 — CollectionSystem rabbit encyclopedia model | technical-director | 0.5 session | — | ADR accepted; unblocks `/create-stories collection-system` |
| S04-15 | `/create-stories collection-system` | game-designer | 0.5 session | S04-14 | Stories for rabbit encyclopedia, completion threshold for prestige gate |
| S04-16 | `/create-stories farm-map-ui` | game-designer | 0.5 session | — | Stories for hutch grid scene, tap-to-inspect |

---

## Carryover from Sprint 03

| Story | Reason | Disposition |
|-------|--------|-------------|
| Push to GitHub → CI green (S03-14) | BLK-003: godot not on PATH in CI runner | Promoted to Should Have (S04-13) |
| `/create-stories prestige-system` (S03-13) | Deferred as Nice to Have in Sprint 03 | Promoted to Must Have (S04-07) |
| `rabbit-system/story-007-aura-bonus.md` | BLK-001: GDD aura formula spec not written | Remains blocked — out of scope until aura formula is specified |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| ADR-0011 design takes longer than 0.5 session (timestamp vs Tween tradeoffs) | Medium | Medium | Pre-read ADR-0007 (offline idle) — expedition reuses same timestamp-delta pattern |
| CollectionSystem not done → `can_prestige()` collection threshold untestable end-to-end | High | Low | PrestigeSystem unit tests stub the threshold at 0% for isolation; real integration in Sprint 05 |
| food-system stories 002–004 reveal edge cases in story-001's inventory contract | Medium | Medium | Story-001 tests passing; rollback in story-002 is the main risk — cover with integration test |
| GuildSystem and event-system still blocked (ADR-0014 / ADR-0013 not written) | High | Low | Correctly deferred; not on critical path to Production→Polish gate |

---

## Dependencies on External Factors

- Godot 4.6 installed locally (required for S04-13 CI run)
- GitHub Actions runner accessible (S04-13)

---

## Definition of Done for Sprint 04

- [ ] All Must Have tasks (S04-01 through S04-09) Complete
- [ ] FoodSystem all 4 stories Complete — epic DoD met
- [ ] ExpeditionSystem story-001 Complete — async timer model proven
- [ ] PrestigeSystem story-001 Complete — prestige gate functional
- [ ] `design/difficulty-curve.md` exists with pacing targets
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed: `production/qa/smoke-[sprint-04-date].md`
- [ ] QA sign-off: APPROVED or APPROVED WITH CONDITIONS
- [ ] No S1/S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged

> ⚠️ **No QA Plan**: This sprint was started without a QA plan. Run `/qa-plan sprint`
> before the last story is implemented. The Production → Polish gate requires a QA
> sign-off report, which requires a QA plan.
