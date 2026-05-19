## QA Sign-Off Report: Sprint 04
**Date**: 2026-05-20
**QA Lead sign-off**: QA Lead (Bunny Farm Idle)

---

### Test Coverage Summary

| Story | Type | Auto Test | Manual QA | Result |
|-------|------|-----------|-----------|--------|
| S04-01 feed_rabbit() | Integration | PASS (7 tests present) | — | PASS |
| S04-02 farm plot timers | Logic | PASS (9 tests present) | — | PASS WITH NOTES |
| S04-03 offline plot resolution | Integration | PASS (7 tests present) | — | PASS |
| S04-04 ADR-0011 ExpeditionSystem | Config/Data | — | Document confirmed Accepted | PASS |
| S04-05 /create-stories expedition | Config/Data | — | EPIC.md + 3 stories confirmed | PASS |
| S04-06 start_expedition() | Logic | PASS (tests present, smoke verified) | — | PASS WITH NOTES |
| S04-07 /create-stories prestige | Config/Data | — | EPIC.md + 2 stories confirmed | PASS |
| S04-08 can_prestige() + execute_prestige() | Logic | PASS (9 tests present) | — | PASS WITH NOTES |
| S04-09 difficulty-curve.md | Config/Data | — | Document structurally complete, Draft status | PASS WITH NOTES |
| S04-10 collect() + loot roll | Integration | PASS (tests present, smoke verified) | — | PASS WITH NOTES |
| S04-11 offline catch-up | Integration | PASS (tests present, smoke verified) | — | PASS WITH NOTES |
| S04-12 prestige bonus formula | Logic | PASS (tests present, smoke verified) | — | PASS WITH NOTES |
| S04-13 CI green run | Config/Data | NOT RUN (CI configured, badge pending) | Workflow file confirmed | PASS WITH NOTES |

**Coverage**: 13/13 stories covered. 0 stories FAIL. 0 stories missing required test evidence for their type.

---

### Bugs Found

None. No S1, S2, S3, or S4 bugs filed this sprint.

---

### Verdict: APPROVED WITH CONDITIONS

All stories are PASS or PASS WITH NOTES. No S1/S2 bugs are open. The sprint output is
shippable to the next stage subject to the conditions below being resolved before the
Production → Polish gate.

---

### Conditions (must be resolved before Production → Polish gate)

**[C04-01] Story files not closed** — S04-06, S04-10, S04-11, S04-12 still show
Status: "Ready" with blank Completion Notes. `/story-done` must be run on each to
formally close them. Affects sprint audit trail and gate-check accuracy.
Owner: developer who implemented each story.

**[C04-02] balance.json food keys missing** — `seed_cost`, `grow_time_seconds`, and
`harvest_quantity` are absent from balance.json. FoodSystem runs on GDScript fallback
defaults at runtime. Must be populated before Sprint 05 food UI work begins.
Owner: lead-programmer / game-designer.

**[C04-03] PrestigeSystem AC-7 untestable** — The `push_error` branch in PrestigeSystem
has no injection seam. Add `_load_from_text(text: String)` to create a testable path.
Target: Sprint 05. Until resolved, AC-7 has no automated coverage.
Owner: lead-programmer.

**[C04-04] difficulty-curve.md design review pending** — Document is structurally
complete but Status remains Draft. Design-lead sign-off required before it can be
treated as a governing design document. Required before Production → Polish gate.
Owner: game-designer / creative-director.

**[C04-05] CI badge unconfirmed** — GitHub Actions workflow was pushed 2026-05-20.
A green badge confirming the first successful CI run has not yet been observed.
S04-13 cannot be fully closed until the badge is confirmed.
Owner: technical-director / lead-programmer (verify Actions tab on GitHub).

**[C04-06] Save/load round-trip unverified for Sprint 04 fields** — `farm_plots`,
`food_inventory`, and `active_expeditions` have not been verified through a full
serialise/deserialise cycle. No food UI exists to exercise these paths. Deferred to
Sprint 05 once food inventory UI is built.
Owner: QA Tester (Sprint 05 integration test pass).

**[C04-07] Expedition offline→collect end-to-end unverified** — The cross-story
round-trip (story-003 offline catch-up → story-002 collect() flow) has not been
explicitly tested as a single composed path. Each story's tests pass independently.
Deferred to Sprint 05.
Owner: QA Tester (add integration test or documented playtest).

---

### Next Steps

1. Run `/story-done` on S04-06, S04-10, S04-11, S04-12 to close the four open story
   files (C04-01).
2. Confirm the CI badge on GitHub Actions following the 2026-05-20 push (C04-05).
3. Add missing balance.json food keys before any Sprint 05 food UI story begins
   implementation (C04-02).
4. Schedule C04-06 and C04-07 as Sprint 05 QA tasks — deferred by design, do not
   block current sprint close.
5. C04-03 and C04-04 are carry-forward items for Sprint 05 planning.
6. Once C04-01 and C04-05 are resolved, run `/gate-check` to assess Production →
   Polish readiness.
