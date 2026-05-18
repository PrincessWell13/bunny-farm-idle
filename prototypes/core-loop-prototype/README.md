# Prototype: Core Loop — Bunny Farm Idle

**Prototype Name**: Core Loop Prototype
**Type**: Vertical Slice — core gameplay validation
**Status**: Implemented — ready for playtesting
**Date Created**: 2026-05-18
**Sprint Target**: Sprint 02

---

## What This Prototype Validates

This prototype answers three questions before the Production stage begins:

1. **Is the idle loop satisfying?** — Does watching coins accumulate and collecting them feel rewarding?
2. **Is the breeding reveal exciting?** — Does the genetics result sequence (cascade reveal + optional Legendary full-screen reveal) land emotionally?
3. **Is caring for rabbits fun?** — Does the Feed / Clean / Play action loop create engagement, or does it feel like a chore?

If all three answers are "yes" from 3+ independent playtesters, the core fantasy is validated and the project advances to Production.

---

## Scope

### Included (minimum to answer the three questions)

- **Farm scene**: 2 hutches visible, 3 rabbits total (1 Baby, 1 Adult, 1 Elder)
- **Idle production**: coins accumulate in real time, floating icon appears over hutch when ready
- **Tap to collect**: IP-03 fly-to-header animation from interaction patterns
- **Rabbit care**: Feed button on rabbit card (IP-01 bottom sheet); hunger visible as stat bar; `rabbit_fed` signal fires
- **Breeding screen stub**: select two parents → trigger breed() → IP-06 cascade reveal of result; if Legendary, IP-11 full-screen reveal
- **HUD**: coin counter in header, session nav bar (Farm / Breeding tabs only for prototype)
- **No save system**: data persists in memory only for the session duration

### Explicitly Out of Scope

- Firebase / save system (in-memory only)
- Guild, Shop, Quest tabs (tab bar shows them locked)
- All 6 habitat tiers (only Meadow Hutch tier 1)
- All seasonal content
- Achievements
- Prestige system

---

## Success Criteria

The prototype is validated when:

1. [ ] A playthrough from launch to first breeding result completes without developer guidance
2. [ ] The game communicates what to do within the first 2 minutes of play
3. [ ] At least 3 playtest sessions are completed with independent testers
4. [ ] At least 1 playtester independently describes the experience as matching the Player Fantasy ("I feel like a bunny scientist" or equivalent) without being prompted
5. [ ] No "fun blocker" bugs (crashes, soft-locks, or completely broken interactions)

---

## Implementation Notes

All game logic for this prototype is already implemented in the Foundation + Core layers (Sprint 01). The prototype wires existing systems to a minimal UI:

- `EconomyManager` (pending Sprint 02) → HUD coin counter
- `IdleProductionSystem` → floating icon + fly-to-header
- `RabbitSystem` → rabbit card stat bars
- `GeneticsSystem.breed()` → breeding result cascade

The prototype uses placeholder art (colored rectangles for rabbits) until Presentation layer assets are ready. Visual fidelity is not a success criterion for this prototype — mechanics and feel are.

---

## How to Run

1. Open the project in Godot 4.6
2. Press F5 (Run Project) — `project.godot` points to `main.tscn` as the main scene
3. The prototype starts immediately on the Farm view with 3 starter rabbits

## Files

```
prototypes/core-loop-prototype/
├── README.md                         ← this file
├── main.tscn                         ← root scene (Node2D + script)
└── core_loop_prototype.gd            ← all UI built programmatically
```

---

## Playtest Protocol

Session length: 15–20 minutes

**Observer notes to capture:**
- Time until first collection (target: < 2 minutes)
- Time until first breeding attempt (target: < 5 minutes)
- Any moment of confusion ("I didn't know what to do")
- Emotional reaction at breeding reveal (facial expression / verbal reaction)
- Unprompted description of the experience after session ends

**Post-session questions:**
1. "What was your favorite moment?"
2. "Was there anything you wanted to do that you couldn't figure out how?"
3. "How would you describe this game to a friend in one sentence?"

---

*Core Loop Prototype v0.1 — Bunny Farm Idle — 2026-05-18*
