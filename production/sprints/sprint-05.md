# Sprint 05 — Production UI + Gate Unblock

**Sprint**: 05
**Dates**: 2026-05-21 — 2026-06-05
**Stage**: Production
**Goal**: Build the production HUD UI for food, expeditions, and prestige — replacing the prototype as the playtest target — while closing all sprint-04 QA conditions required to pass the Production → Polish gate.

## Capacity

- Sessions estimated: ~8–10 working sessions (AI-accelerated)
- Buffer (20%): ~1–2 sessions reserved for playtest iterations / balance revisions
- Available: ~7–8 implementation sessions

---

## Sprint Scope

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. | Dependencies | Acceptance Criteria |
|----|------|-------------|------|--------------|---------------------|
| S05-01 | Close sprint-04 open stories — `/story-done` on S04-06, S04-10, S04-11, S04-12 (C04-01) | gdscript-specialist | 0.5 | — | All 4 story files show `Status: Complete` with Completion Notes; sprint-status.yaml updated |
| S05-02 | Add balance.json food keys — `seed_cost`, `grow_time_seconds`, `harvest_quantity` for grass (C04-02) | game-designer / lead-programmer | 0.5 | — | `assets/data/balance.json` contains `food.grass.seed_cost`, `food.grass.grow_time_seconds`, `food.grass.harvest_quantity`; FoodSystem reads these at runtime (no GDScript fallback) |
| S05-03 | Difficulty-curve.md design review + sign-off (C04-04) | game-designer / creative-director | 0.5 | — | `design/difficulty-curve.md` Status updated to Approved; design-lead sign-off recorded in document |
| S05-04 | Confirm CI green badge (C04-05) | devops-engineer / technical-director | 0.25 | — | GitHub Actions tab shows green badge for GdUnit4 run triggered by 2026-05-20 push; badge URL noted in S04-13 story file |
| S05-05 | `/create-stories hud` — scaffold UI stories for food widget + farm plot + expedition panel + prestige button | game-designer | 0.5 | S05-01 | Four story files created in `production/epics/hud/`: story-004-food-inventory-widget, story-005-farm-plot-progress-ui, story-006-expedition-slot-panel, story-007-prestige-button |
| S05-06 | HUD story-004 — Food inventory widget | gdscript-specialist / godot-specialist | 1 | S05-02, S05-05 | Food inventory (grass count) displays in HUD; updates on `food_harvested` and `rabbit_fed` signals; no hardcoded values; unit test in `tests/unit/ui/` or manual evidence doc |
| S05-07 | HUD story-005 — Farm plot progress UI | gdscript-specialist / godot-specialist | 1 | S05-02, S05-05 | Each farm plot shows a countdown timer and "READY" indicator; tapping a ready plot triggers harvest; `farm_plots_updated` signal drives the display |
| S05-08 | Save/load round-trip integration test for Sprint-04 fields (C04-06) | gdscript-specialist | 0.5 | S05-01 | `tests/integration/core/save_load_sprint04_test.gd` passes; verifies `farm_plots`, `food_inventory`, `active_expeditions` survive a serialise/deserialise cycle |

### Should Have

| ID | Task | Agent/Owner | Est. | Dependencies | Acceptance Criteria |
|----|------|-------------|------|--------------|---------------------|
| S05-09 | HUD story-006 — Expedition slot panel | gdscript-specialist / godot-specialist | 1 | S05-05 | Active expeditions display remaining time per slot; completed slots show "COLLECT" button; `expedition_ready_to_collect` signal drives state change |
| S05-10 | HUD story-007 — Prestige button | gdscript-specialist / godot-specialist | 0.5 | S05-05 | Prestige button visible in HUD; grayed out when `can_prestige()` returns false; tapping calls `execute_prestige()` and shows confirmation |
| S05-11 | Add `_load_from_text()` to PrestigeSystem — testable error path (C04-03) | gdscript-specialist | 0.5 | — | `PrestigeSystem._load_from_text(text: String)` exists; AC-7 `push_error` branch covered by unit test in `tests/unit/core/prestige_system_test.gd` |
| S05-12 | Expedition offline→collect round-trip integration test (C04-07) | gdscript-specialist | 0.5 | S05-08 | Single integration test exercises the full `_resolve_offline_expeditions_at()` → `collect()` path; test in `tests/integration/core/` |
| S05-13 | Mid-game playtests (2 sessions on production build) | qa-tester / game-designer | 1 | S05-06, S05-07 | Two playtest session logs in `production/playtests/` dated Sprint-05; each covers 30–60 min of play; observations address difficulty curve pacing targets from `design/difficulty-curve.md` |
| S05-14 | Performance baseline — `/perf-profile` on production build | performance-analyst | 0.5 | S05-06, S05-07 | Profiling report exists in `production/perf/`; frame time and memory readings captured; any issues over budget flagged |

### Nice to Have

| ID | Task | Agent/Owner | Est. | Dependencies | Acceptance Criteria |
|----|------|-------------|------|--------------|---------------------|
| S05-15 | Feed visual feedback — tween animation when grass consumed by `feed_rabbit()` | gdscript-specialist | 0.5 | S05-06 | Brief tween on food count label when deducted; implemented in food widget; no new signals required |
| S05-16 | Write ADR-0012 — CollectionSystem rabbit encyclopedia model (carry-over S04-14) | technical-director | 0.5 | — | `docs/architecture/adr-0012-collection-system-encyclopedia.md` Status: Accepted |
| S05-17 | `/create-stories collection-system` (carry-over S04-15) | game-designer | 0.5 | S05-16 | Story files in `production/epics/collection-system/` |

---

## Carryover from Sprint 04

| Task | Reason | Disposition |
|------|--------|-------------|
| S04-14 Write ADR-0012 — CollectionSystem | Deprioritised (not on critical path) | Nice to Have S05-16 |
| S04-15 `/create-stories collection-system` | Blocked on ADR-0012 | Nice to Have S05-17 |
| S04-16 `/create-stories farm-map-ui` | Absorbed into farm plot progress UI | Dropped — covered by S05-07 |
| C04-01 Close 4 open story files | Admin deferred post-sprint | Must Have S05-01 |
| C04-02 balance.json food keys | Omitted during backend sprint | Must Have S05-02 |
| C04-03 PrestigeSystem AC-7 seam | No injection seam exists | Should Have S05-11 |
| C04-04 difficulty-curve.md design review | Document is Draft | Must Have S05-03 |
| C04-05 CI badge unconfirmed | Push made 2026-05-20, badge not verified | Must Have S05-04 |
| C04-06 Save/load round-trip unverified | No food UI existed to exercise paths | Must Have S05-08 |
| C04-07 Expedition offline→collect end-to-end | Cross-story path not tested as single path | Should Have S05-12 |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| HUD UI stories need a UX spec or ADR that does not yet exist | High | Medium | Create minimal UX spec for HUD food/expedition/prestige layout before S05-06; reference existing HUD ADR if present |
| Mid-game playtest reveals balance curve is broken (too fast / too slow to prestige) | Medium | High | Schedule playtests early (S05-13 Should Have); deferred balance fixes go to Sprint-06 — do not block gate if difficulty-curve.md is Approved |
| CI badge never turns green (runner config issue) | Low | Medium | S05-04 is a 15-min check: open GitHub Actions tab, read result; if red, create a devops story to fix the runner |
| Production build has no main scene wired for playtesting | Medium | High | Before playtests (S05-13), verify `project.godot` main scene is a playable production scene, not the prototype; update if needed |

---

## Dependencies on External Factors

- GitHub Actions tab accessible to verify CI badge (S05-04)
- A human player available for 2 × 30–60 min playtest sessions (S05-13)

---

## Definition of Done for Sprint 05

- [ ] All Must Have tasks (S05-01 through S05-08) Complete
- [ ] All C04-0x QA conditions resolved or formally deferred
- [ ] `difficulty-curve.md` Status: Approved
- [ ] Food inventory + farm plot UI visible and functional in production build
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] QA plan exists (`production/qa/qa-plan-sprint-05-[date].md`)
- [ ] Smoke check passed: `production/qa/smoke-[sprint-05-date].md`
- [ ] QA sign-off: APPROVED or APPROVED WITH CONDITIONS
- [ ] No S1/S2 bugs in delivered features
- [ ] At least 2 mid-game playtest sessions documented in `production/playtests/`
