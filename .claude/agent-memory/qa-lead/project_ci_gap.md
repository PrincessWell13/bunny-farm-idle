---
name: project-ci-gap
description: No runnable Godot build or CI pipeline exists; automated tests cannot execute until project.godot is created and CI is configured
metadata:
  type: project
---

As of 2026-05-17, `project.godot` does not exist and the `godot` binary is not on PATH. The `.github/workflows/` directory does not exist. Automated tests (GdUnit4) cannot run in this environment.

**Why:** Foundation sprint established code structure and test files but the Godot project scaffold (project.godot, autoload registration, CI workflow) was not yet created. This is expected for the first sprint but must be resolved before Sprint 2 QA can pass the automated test gate.

**How to apply:** Every smoke check will return PASS WITH WARNINGS (not FAIL) until this is resolved, because unconfirmed NOT RUN is not treated as automatic FAIL per smoke-check protocol. Flag this as a P1 action item at every sprint review until resolved.

Resolution requires: create `project.godot`, register autoloads (GameState, TimeManager, EventBus, EconomyManager, SceneManager), add `.github/workflows/ci.yml` running `godot --headless --script tests/gdunit4_runner.gd`.
