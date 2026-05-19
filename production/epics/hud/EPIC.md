# Epic: HUD

> **Layer**: Presentation
> **GDD**: design/gdd/bunny-farm-idle-master.md (§7)
> **Architecture Module**: `src/ui/hud.gd` + `HUD.tscn`
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories hud`
> **Control Manifest Version**: 2026-05-18

## Overview

HUD owns the always-visible game chrome: a header bar showing Carrot Coin and Crystal Gem balances (auto-refreshed via `EventBus.currency_changed`) and a notification area, plus a bottom navigation bar with 5 tabs (Trang trại | Breeding | Guild | Shop | Quest) that dispatches `EventBus.nav_tab_pressed(tab)` — never calling `SceneManager.goto_scene()` directly. HUD contains zero game logic. It is the last scene to initialise (step 12 in boot order per ADR-0001) and subscribes to EventBus on `_ready()`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Autoload Boot Sequence | HUD initialises at step 12 (after all autoloads and Feature systems); calls no autoloads from `_init()` | LOW |
| ADR-0003: EventBus Signal Architecture | Currency display auto-updates via `currency_changed`; nav taps dispatch `nav_tab_pressed(tab)` — never `SceneManager.goto_scene()` directly | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-ui-004 | ≤2 taps for frequent actions | ADR-0003 ✅ |
| TR-hud-001 | Header bar: coin + gem balance display with real-time update | ADR-0003 ✅ (currency_changed signal) |
| TR-hud-002 | Bottom nav bar: 5 tabs dispatching nav events | ADR-0003 ✅ |

> **Note on TR-hud-001 / TR-hud-002**: These are not in `tr-registry.yaml` yet. Add them when running `/architecture-review rtm`.

## Architecture Constraints

From `docs/architecture/architecture.md`:

```gdscript
# HUD
func show_notification(text: String, duration_sec: float = 3.0) -> void
# Currency displays auto-update via EventBus.currency_changed.
# Nav taps → EventBus.nav_tab_pressed(tab) — never calls SceneManager directly.
```

**Bottom nav tabs (NavTab enum from EventBus)**: Farm | Breeding | Guild | Shop | Quest

Touch target rule: all nav buttons ≥ 44×44 px; thumb-reachable in bottom half of screen (one-hand mobile rule from technical-preferences.md).

## Definition of Done

This epic is complete when:
- Header bar displays CC and Gem balances, updating on every `currency_changed` signal
- `show_notification(text, duration)` displays a timed toast notification
- Bottom nav bar dispatches `nav_tab_pressed(tab)` — verified not calling SceneManager directly
- All touch targets ≥ 44×44 px
- All Logic/Integration stories have passing tests in `tests/`
- All UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Currency Header Display](story-001-currency-header.md) | Integration | Ready | ADR-0001, ADR-0003 |
| 002 | [Bottom Navigation Bar](story-002-nav-bar.md) | Integration | Ready | ADR-0003 |
| 003 | [Notification Toast](story-003-notification-toast.md) | UI | Ready | ADR-0003 |

## Next Step

Run `/dev-story production/epics/hud/story-001-currency-header.md` to begin implementation.
