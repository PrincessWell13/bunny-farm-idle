# Epic: GameState

> **Layer**: Foundation
> **GDD**: design/gdd/bunny-farm-idle-master.md
> **Architecture Module**: `src/core/game_state.gd`
> **Status**: Ready
> **Control Manifest Version**: pending — run `/create-control-manifest` to assign
> **Stories**: 2 stories created

## Overview

GameState is the authoritative owner of all persistent player data: the full rabbit array, hutch array, prestige count, collection registry, active expeditions, settings, and the dirty flag that triggers saves. It is autoload #4 in the boot sequence — initialised empty by its own `_ready()`, then populated by SaveSystem immediately after. Every system that reads player data reads from GameState. Every system that mutates player data calls a GameState method and calls `mark_dirty()`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | GameState is autoload #4; data tree allocated in `_ready()`; populated by SaveSystem; mark_dirty() is the sole dirty-flag path | LOW |
| ADR-0008: Firebase Local-First Save | GameState data tree is the source serialised to `user://savegame.json`; `pending_offline_report` field stores offline reward for UI | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-save-001 | Full game state serialisation/deserialisation | ADR-0001 ✅, ADR-0008 ✅ |
| TR-prestige-002 | Selective reset — keep some data, wipe rest on prestige | ADR-0001 ✅ |
| TR-idle-002 | Offline delta available before first scene runs | ADR-0001 ✅ |

> Note: TR IDs not yet in `docs/architecture/tr-registry.yaml` — run `/architecture-review` to populate.

## Key Interfaces

```gdscript
class_name GameState extends Node

var rabbits: Array[RabbitData] = []
var hutches: Array[HutchData] = []
var prestige_count: int = 0
var collection_registry: Dictionary = {}
var active_expeditions: Array[Dictionary] = []
var settings: Dictionary = {}
var last_save_timestamp: int = 0
var is_dirty: bool = false
var pending_offline_report: EarningsReport = null  # set by SaveSystem on boot

func mark_dirty() -> void          # sole entry point to set is_dirty = true
func prestige_reset(keep: Dictionary) -> void  # selective wipe for prestige
```

## Forbidden Patterns (from Architecture Registry)

- `bypassing_mark_dirty` — never write `GameState.is_dirty = true` directly
- `direct_cross_system_state_write` — only GameState methods write GameState fields
- `upward_direct_method_calls` — GameState may not call Feature or Presentation methods

## Definition of Done

This epic is complete when:
- [ ] All stories are implemented, reviewed, and closed via `/story-done`
- [ ] `GameState` autoload is registered as #4 in Godot Project Settings
- [ ] `mark_dirty()` is the only code path that sets `is_dirty = true` (grep verified)
- [ ] `prestige_reset()` wipes correct fields and preserves specified keys
- [ ] GdUnit4: GameState instantiates in isolation with no dependency errors
- [ ] GdUnit4: `mark_dirty()` sets `is_dirty = true`; direct `is_dirty = true` assignment is absent from `src/` (except in save_system.gd where it is reset to false)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Data structure + initialization](story-001-data-structure.md) | Logic | Complete | ADR-0001 |
| 002 | [prestige_reset() selective wipe](story-002-prestige-reset.md) | Logic | Complete | ADR-0001 |

## Next Step

Run `/dev-story production/epics/game-state/story-001-data-structure.md` to begin implementation.
