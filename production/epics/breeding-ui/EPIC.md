# Epic: BreedingUI

> **Layer**: Presentation
> **GDD**: design/gdd/bunny-farm-idle-master.md (§2.1, §3.2, §7)
> **Architecture Module**: `src/ui/breeding_ui.gd` + `BreedingUI.tscn`
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories breeding-ui`
> **Control Manifest Version**: 2026-05-18

## Overview

BreedingUI owns the breeding screen: a parent picker that lists owned adult rabbits and lets the player select parent A and parent B with ≤2 taps, a probability preview panel that calls `GeneticsSystem.get_breed_preview()` and displays trait/color probability output, a confirm-breed button that dispatches `EventBus.breed_requested(a_id, b_id)`, and a result reveal animation that plays when `EventBus.rabbit_born` fires. BreedingUI contains zero game logic — it reads state from `RabbitSystem` and `GeneticsSystem` and dispatches one signal. All rabbit state mutations happen in the Core/Feature layer.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: EventBus Signal Architecture | BreedingUI never calls Core/Feature methods directly; dispatches `breed_requested(a_id, b_id)` via EventBus and listens for `rabbit_born(child_id)` response | LOW |
| ADR-0006: Genetics Allele Model | `get_breed_preview(a, b) → BreedPreview` is a pure read (no RNG); BreedingUI may call it freely without side effects; result includes `color_probabilities`, `trait_probabilities`, `mutation_chance`, `estimated_rarity` | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-genetics-004 | Gene Preview with probability tables before breeding | ADR-0006 ✅ |
| TR-ui-004 | ≤2 taps for frequent actions | ADR-0003 ✅ |
| TR-breeding-ui-001 | Parent picker — select two adult rabbits from roster | ⚠️ No dedicated ADR — governed by architecture principle "Presentation never decides" + ADR-0003 |
| TR-breeding-ui-002 | Result reveal animation triggered on `rabbit_born` event | ⚠️ No dedicated ADR — Visual/Feel story; ADR-0003 governs event source |

> **Note on TR-breeding-ui-001 / TR-breeding-ui-002**: These are not in `tr-registry.yaml` yet. Add them when running `/architecture-review rtm`. Stories can be written using ADR-0003 + ADR-0006 as governing decisions; no separate Presentation-layer ADR is needed for scene structure (deferred per architecture.md §Required ADRs "Can defer to implementation").

## Architecture Constraints

From `docs/architecture/architecture.md` (Presentation Layer, API Boundaries):

```
BreedingUI
│  calls: GeneticsSystem.get_breed_preview(a, b) → displays preview
│  player confirms → emits via EventBus: breed_requested(a_id, b_id)
│  listens: rabbit_born(child_id) → play result reveal animation

Invariant: Presentation never decides.
BreedingUI dispatches breed_requested, never calls GeneticsSystem.breed() directly.
No rabbit state mutations in any BreedingUI method.
```

**Engine ⚠️**: `SubViewport` used for probability chart approach — verify against Godot 4.6 docs before implementing. Touch target rule: all tappable elements ≥ 44×44 px (ADR-0001 / technical-preferences.md).

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- Parent selector lists adult rabbits correctly (filtered, touch-friendly ≥44×44px)
- `get_breed_preview()` output is displayed before confirming
- `breed_requested` signal is emitted on confirm — no direct breed() call
- Result reveal animation plays on `rabbit_born` event
- All Logic/Integration stories have passing tests in `tests/`
- All Visual/Feel stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Parent Selector + Breed Trigger](story-001-parent-selector-breed-trigger.md) | Integration | Ready | ADR-0003, ADR-0006 |
| 002 | [Result Reveal Panel](story-002-result-reveal-panel.md) | Visual/Feel | Ready | ADR-0003 |

## Next Step

Run `/dev-story production/epics/breeding-ui/story-001-parent-selector-breed-trigger.md` to begin implementation.
