# Sprint 03 — Feature Layer Bootstrap

**Sprint**: 03
**Dates**: 2026-05-19 — 2026-06-01
**Stage**: Production
**Goal**: Bootstrap the Feature layer — create and implement the highest-priority Feature epics so the game loop is playable end-to-end beyond the prototype.

## Capacity

- Sessions estimated: ~6–8 working sessions (AI-accelerated)
- Buffer: 20% (~1–2 sessions reserved for debugging / rework)
- Effective: ~5–6 implementation sessions

---

## Sprint Scope

### Must Have (Critical Path)

| ID | Story / Task | Owner | Est. | Dependencies | Acceptance Criteria |
|----|---|---|---|---|---|
| S03-01 | `/architecture-review` — generate traceability matrix | technical-director | 1 session | — | `docs/architecture/architecture-traceability.md` exists, 0 Foundation layer gaps |
| S03-02 | `/create-epics layer:feature` — 10 Feature epics | producer + game-designer | 1 session | S03-01 | All 10 Feature EPIC.md files in `production/epics/` |
| S03-03 | `/create-stories habitat-system` | game-designer | 0.5 session | S03-02 | Stories for hutch slots, cleanup, capacity unlocks |
| S03-04 | HabitatSystem — hutch slots + rabbit assignment | gdscript-specialist | 1 session | S03-03 | Rabbits can be placed in/removed from hutches; slot capacity enforced |
| S03-05 | `/create-stories food-system` | game-designer | 0.5 session | S03-02 | Stories for food inventory, hunger decay hook |
| S03-06 | FoodSystem — food inventory + feed hook | gdscript-specialist | 1 session | S03-05 | `use_food()` deducts inventory; hooks into `rabbit_system.feed_rabbit()` |
| S03-07 | `/create-stories breeding-ui` | game-designer | 0.5 session | S03-02 | Stories for parent select, preview panel, confirm breed |
| S03-08 | BreedingUI story-001 — parent selector + breed trigger | gdscript-specialist | 1 session | S03-07 | Player can select 2 rabbits, see gene preview, trigger breed |

### Should Have

| ID | Story / Task | Owner | Est. | Dependencies | Acceptance Criteria |
|----|---|---|---|---|---|
| S03-09 | `/create-stories hud` | game-designer | 0.5 session | S03-02 | Stories for coin counter, notification bell, hutch status strip |
| S03-10 | HUD story-001 — coin display + offline earnings popup | gdscript-specialist | 1 session | S03-09 | Coins update live via `currency_changed` signal; offline popup shows on boot |
| S03-11 | `/create-stories season-system` | game-designer | 0.5 session | S03-02 | Stories for season clock, multiplier dispatch |
| S03-12 | SeasonSystem story-001 — season clock + active season signal | gdscript-specialist | 1 session | S03-11 | `season_changed` fires on day boundary; `IdleProductionSystem` reads active season |

### Nice to Have

| ID | Story / Task | Owner | Est. | Dependencies | Acceptance Criteria |
|----|---|---|---|---|---|
| S03-13 | `/create-stories prestige-system` | game-designer | 0.5 session | S03-02 | Stories for prestige trigger, bonus grant |
| S03-14 | Push to GitHub → confirm CI green | devops-engineer | 0.5 session | — | CI badge passes; smoke report updated to reflect real test run |
| S03-15 | `/create-stories farm-map-ui` | game-designer | 0.5 session | S03-02 | Stories for hutch grid scene, tap-to-inspect flow |

---

## Carryover from Previous Sprints

| Story | Reason | Disposition |
|---|---|---|
| RabbitSystem Aura Bonus (`rabbit-system/story-007-aura-bonus.md`) | BLK-001: aura formula GDD spec not written | Blocked — remains out of scope until game-designer writes aura formula spec |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Feature epic scope creep (10 epics, each could balloon) | High | High | Run `/scope-check [epic]` after each `/create-stories` before starting dev |
| BreedingUI depends on Godot scene work — harder to test headlessly | Medium | Medium | Integration test via MockSceneTree; advisory-level evidence acceptable |
| No milestone doc — sprint scope is self-defined | Medium | Low | Create `production/milestones/v1-0-mvp.md` (Nice to Have, separate task) |
| Gate concern: tests never executed green on CI | Medium | High | S03-14 (push to GitHub) closes this; unblock before sprint close-out |

---

## Dependencies on External Factors

- Godot 4.6 installed locally (required for S03-14 CI run)
- GitHub remote configured for CI trigger (S03-14)

---

## Definition of Done for Sprint 03

- [ ] All Must Have tasks (S03-01 through S03-08) Complete
- [ ] S03-01 closes gate-check CONCERN (traceability matrix generated)
- [ ] HabitatSystem, FoodSystem, BreedingUI story-001 each have passing automated tests
- [ ] Smoke check passed: `production/qa/smoke-2026-06-01.md`
- [ ] QA sign-off: APPROVED or APPROVED WITH CONDITIONS
- [ ] No S1/S2 bugs in delivered features
- [ ] All deviations from GDD documented in story files
