---
name: project-foundation-core-sprint
description: Foundation + Core sprint QA state — 31 stories across 9 epics, smoke check PASS WITH WARNINGS, tests written but not executed
metadata:
  type: project
---

Sprint "Foundation + Core" completed 31 stories across 9 epics (event-bus, game-state, time-manager, economy-manager, scene-manager, rabbit-system, genetics-system, idle-production-system, save-system). All are Logic or Integration type — no Visual/Feel or UI stories.

**Why:** Code-only foundation sprint; no runnable build yet. project.godot does not exist. Smoke check dated 2026-05-17 returned PASS WITH WARNINGS.

**How to apply:** When continuing QA work on this sprint, the primary unresolved gate is automated test execution. CI must be configured and project.godot created before a clean smoke check can pass. rabbit-system story-007 (Aura Bonus) remains BLOCKED pending GDD spec.

Test evidence status: 31 COVERED, 0 MISSING, 1 BLOCKED (rabbit-system story-007).
Smoke check file: `production/qa/smoke-2026-05-17.md`
