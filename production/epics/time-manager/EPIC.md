# Epic: TimeManager

> **Layer**: Foundation
> **GDD**: design/gdd/bunny-farm-idle-master.md
> **Architecture Module**: `src/core/time_manager.gd`
> **Status**: Ready
> **Control Manifest Version**: pending — run `/create-control-manifest` to assign
> **Stories**: 2 stories created

## Overview

TimeManager is the clock of the entire game. It records the Unix timestamp when each session starts, calculates elapsed offline time when the player returns, drives the 1-second tick that all Core systems listen to, and maintains the in-game day counter that the season system uses. It is autoload #2 — boots immediately after EventBus, before any system that depends on time.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | TimeManager is autoload #2; owns `offline_delta` and `last_seen_timestamp`; `mark_session_start()` called by SaveSystem at boot | LOW |
| ADR-0007: Idle Production + Offline | `was_backgrounded()` flag used by IdleProductionSystem to select background vs offline multiplier | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-idle-002 | Offline delta calculated and available before any scene runs | ADR-0001 ✅ |
| TR-season-001 | In-game day counter drives season transitions | ADR-0001 ✅ (implied by TimeManager ownership) |

> Note: Real-time tick and `was_backgrounded()` are defined in ADRs but have no explicit TR-IDs yet. TR IDs not yet in `docs/architecture/tr-registry.yaml`.

## Key Interfaces

```gdscript
class_name TimeManager extends Node

func get_offline_delta() -> float         # seconds since last session
func mark_session_start() -> void         # called by SaveSystem on load
func was_backgrounded() -> bool           # true if app minimised (not killed)
func get_current_day() -> int             # in-game day number since epoch
func get_unix_time() -> int               # current Unix timestamp

signal tick(delta: float)                 # emitted every 1 second
```

## Forbidden Patterns (from Architecture Registry)

- `calling_later_autoload_in_ready` — TimeManager (autoload #2) may only call EventBus (autoload #1) in `_ready()`; never call EconomyManager, GameState, SaveSystem, or SceneManager
- `upward_direct_method_calls` — TimeManager may not call Core, Feature, or Presentation methods

## Engine Risk Note

`Time.get_unix_time_from_system()` — stable in 4.6. `OS.get_unix_time()` was deprecated in Godot 4.0 and removed by 4.4 — do not use.

## Definition of Done

This epic is complete when:
- [ ] All stories are implemented, reviewed, and closed via `/story-done`
- [ ] `TimeManager` autoload registered as #2 in Godot Project Settings
- [ ] `get_offline_delta()` returns correct elapsed seconds when app closed and reopened (manual test)
- [ ] `was_backgrounded()` returns `true` after minimise, `false` after kill (manual test on Android)
- [ ] `tick` signal fires every ~1 second (GdUnit4 + manual test)
- [ ] GdUnit4: TimeManager instantiates in isolation with no dependency errors

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Core time tracking — offline delta + tick signal](story-001-core-time-tracking.md) | Logic | Complete | ADR-0001 |
| 002 | [Background detection — was_backgrounded() flag](story-002-background-detection.md) | Logic | Blocked | ADR-0007 |

## Next Step

Run `/dev-story production/epics/time-manager/story-001-core-time-tracking.md` to begin implementation.
