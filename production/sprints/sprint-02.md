# Sprint 02 — Foundation Completion

**Sprint**: 02
**Dates**: 2026-05-19 — 2026-06-01
**Stage**: Production
**Goal**: Implement all remaining Foundation layer stories. Every story closes with passing automated tests. No new scope until all 11 carry-overs are Complete.

---

## Sprint Scope

### Must Have (11 stories — all carry-overs from Sprint 01)

**Foundation — TimeManager**

| Story | Path | Status | Type |
|-------|------|--------|------|
| TimeManager Core Tracking | `production/epics/time-manager/story-001-core-time-tracking.md` | Ready | Logic |

**Foundation — SaveSystem**

| Story | Path | Status | Type |
|-------|------|--------|------|
| SaveSystem Firebase Adapter Interface | `production/epics/save-system/story-001-firebase-adapter-interface.md` | Ready | Logic |
| SaveSystem Local File I/O | `production/epics/save-system/story-002-local-file-io.md` | Ready | Logic |
| SaveSystem GameState Serialisation | `production/epics/save-system/story-003-gamestate-serialisation.md` | Ready | Integration |
| SaveSystem Conflict Resolution | `production/epics/save-system/story-004-conflict-resolution.md` | Ready | Logic |
| SaveSystem Boot Integration + Autosave | `production/epics/save-system/story-005-boot-integration-autosave.md` | Ready | Integration |

**Foundation — SceneManager**

| Story | Path | Status | Type |
|-------|------|--------|------|
| SceneManager goto_scene | `production/epics/scene-manager/story-001-goto-scene.md` | Ready | Logic |
| SceneManager Overlay Stack | `production/epics/scene-manager/story-002-overlay-stack.md` | Ready | Logic |
| SceneManager Boot + Nav Routing | `production/epics/scene-manager/story-003-boot-nav-routing.md` | Ready | Integration |

**Foundation — EconomyManager**

| Story | Path | Status | Type |
|-------|------|--------|------|
| EconomyManager Currency Ledger | `production/epics/economy-manager/story-001-currency-ledger.md` | Ready | Logic |
| EconomyManager Currency Changed Signal | `production/epics/economy-manager/story-002-currency-changed-signal.md` | Ready | Logic |

---

### Blocked (carry-over)

| Story | Path | Blocker |
|-------|------|---------|
| RabbitSystem Aura Bonus | `production/epics/rabbit-system/story-007-aura-bonus.md` | BLK-001: Aura Bonus GDD spec not yet written |

---

### Out of Scope This Sprint

- Feature layer epics (create when Core is ≥70% complete)
- Presentation layer epics (create after Feature layer ≥70% complete)
- New story creation — do not add scope until all 11 Must Have stories are Complete

---

## Suggested Implementation Order

Implement in dependency order within each epic:

1. **EconomyManager 001 → 002** — no dependencies, fast Logic stories
2. **TimeManager 001** — no dependencies
3. **SceneManager 001 → 002 → 003** — 003 depends on 001 and 002
4. **SaveSystem 001 → 002 → 003 → 004 → 005** — each builds on the previous; 005 depends on all prior

---

## Sprint Close-Out Sequence

Run these in order once all 11 Must Have stories are Complete:

1. `/smoke-check sprint` — verify critical path end-to-end
2. `/team-qa sprint` — full QA cycle + sign-off report
3. `/gate-check production` — advance to Feature layer once QA approves

Do not run `/gate-check` until `/team-qa` returns APPROVED or APPROVED WITH CONDITIONS.

---

*Sprint 02 — Bunny Farm Idle — 2026-05-19 to 2026-06-01*
