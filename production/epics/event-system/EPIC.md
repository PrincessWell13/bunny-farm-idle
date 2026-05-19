# Epic: EventSystem

> **Layer**: Feature
> **GDD**: design/gdd/bunny-farm-idle-master.md §3.8
> **Architecture Module**: `src/core/event_system.gd`
> **Status**: Blocked — ADR-0013 (EventSystem scheduler) not yet written
> **Stories**: Not yet created — run `/create-stories event-system`
> **Control Manifest Version**: 2026-05-18

## Overview

EventSystem manages time-limited world events: seasonal festivals, community goals, and special breeding windows. It checks the event schedule against TimeManager's in-game day counter, activates/deactivates events, and tracks community goal progress (synced to Firebase for world events). `get_active_events()` returns the list of currently running events for UI display. `contribute_to_event()` records player contribution. World events use FirebaseAdapter for community totals; solo events (e.g. personal breeding challenges) are local-only.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | EventSystem boots after TimeManager and SeasonSystem | LOW |
| ADR-0008: Firebase Local-First Save | World event community totals synced via FirebaseAdapter | MEDIUM |
| ~~ADR-0013~~: EventSystem Scheduler | **MISSING** — event schedule storage model, community vs solo split not decided | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-event-001 | Time-limited world events | ❌ No ADR (ADR-0013 needed) |

## Definition of Done

This epic is complete when:
- Active events are correctly determined by schedule + in-game day
- `event_started` / `event_ended` signals fire on EventBus
- Community contributions sync correctly via FirebaseAdapter
- All Logic stories have passing tests in `tests/unit/`

## Next Step

1. Write ADR-0013: `/architecture-decision "EventSystem scheduler and community goal model"`
2. Then: `/create-stories event-system`
