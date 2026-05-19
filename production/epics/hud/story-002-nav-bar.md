# Story 002: Bottom Navigation Bar

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§7 UI/UX)
**Requirement**: `TR-hud-002`, `TR-ui-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

> ⚠️ TR-hud-002 is not yet in `tr-registry.yaml`. Add it when running `/architecture-review rtm`.
> Stable ID reserved: `TR-hud-002` — "Bottom nav bar: 5 tabs (Farm | Breeding | Guild | Shop | Quest) dispatching nav events via EventBus"

**ADR Governing Implementation**: ADR-0003 (EventBus Signal Architecture)
**ADR Decision Summary**: Nav tab taps dispatch `EventBus.nav_tab_pressed(tab)` — HUD never calls `SceneManager.goto_scene()` or any SceneManager method directly. This enforces "Presentation never decides" — the scene router (SceneManager) responds to the event, HUD just announces what the player tapped.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Signal system and Button.pressed unchanged in 4.4–4.6. No post-cutoff APIs.

**Control Manifest Rules (Presentation layer)**:
- Required: Nav taps dispatch `EventBus.nav_tab_pressed(tab)` — never `SceneManager.goto_scene()` (F-03)
- Required: All variables and return types statically typed (F-02)
- Forbidden: Calling `SceneManager` from any HUD method — route via EventBus only
- Guardrail: All nav buttons ≥ 44×44 px; thumb-reachable in bottom half of screen (technical-preferences.md)

---

## Acceptance Criteria

*From GDD §7 and architecture.md HUD module spec:*

- [x] AC-1: Bottom nav bar has exactly 5 tab buttons: Farm, Breeding, Guild, Shop, Quest — all visible and tappable
- [x] AC-2: Tapping any tab emits `EventBus.nav_tab_pressed(tab)` with the correct tab integer value
- [x] AC-3: No `SceneManager` method call (e.g. `goto_scene`, `change_scene`) exists anywhere in `hud.gd`
- [x] AC-4: All 5 tab buttons have `custom_minimum_size >= Vector2(44, 44)`
- [x] AC-5: The currently active tab is visually distinguished (e.g. modulate, disabled state, or style override) — tapping the already-active tab does not emit a second signal

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

### NavTab enum
Define the NavTab enum on HUD itself (not on EventBus — the signal uses `int` as a placeholder):
```gdscript
enum NavTab { FARM = 0, BREEDING = 1, GUILD = 2, SHOP = 3, QUEST = 4 }
```

### Tab button setup
```gdscript
@export var farm_button: Button
@export var breeding_button: Button
@export var guild_button: Button
@export var shop_button: Button
@export var quest_button: Button

var _active_tab: int = NavTab.FARM

func _ready() -> void:
    farm_button.pressed.connect(_on_tab_pressed.bind(NavTab.FARM))
    breeding_button.pressed.connect(_on_tab_pressed.bind(NavTab.BREEDING))
    guild_button.pressed.connect(_on_tab_pressed.bind(NavTab.GUILD))
    shop_button.pressed.connect(_on_tab_pressed.bind(NavTab.SHOP))
    quest_button.pressed.connect(_on_tab_pressed.bind(NavTab.QUEST))
    _set_active_tab(NavTab.FARM)

func _on_tab_pressed(tab: int) -> void:
    if tab == _active_tab:
        return  # AC-5: no re-emit on same tab
    _set_active_tab(tab)
    EventBus.nav_tab_pressed.emit(tab)  # AC-2: NO SceneManager call here

func _set_active_tab(tab: int) -> void:
    _active_tab = tab
    # Update button visual states (modulate or style_override)
```

### Touch targets (AC-4)
All 5 buttons must have `custom_minimum_size = Vector2(44, 44)` — set in scene editor or via code.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: CC and Gem balance labels in the header
- Story 003: Notification toast system
- SceneManager routing logic in response to `nav_tab_pressed` — handled by SceneManager (Core layer)

---

## QA Test Cases

*Integration story — automated test specs.*

- **AC-1 + AC-4**: Nav buttons exist with correct minimum size
  - Given: HUD built with 5 Button exports injected
  - When: `_ready()` runs
  - Then: All 5 buttons accessible via @export refs; each has `custom_minimum_size.x >= 44` and `.y >= 44`

- **AC-2**: Correct tab value emitted on tap
  - Given: MockEventBus registered; HUD ready
  - When: `_on_tab_pressed(NavTab.BREEDING)` called
  - Then: `mock_event_bus.nav_tab_pressed_calls` contains `[1]` (BREEDING == 1)
  - Edge cases: Farm=0, Guild=2, Shop=3, Quest=4 — verify each value is distinct

- **AC-3**: No SceneManager reference in hud.gd
  - Given: `src/ui/hud.gd` source file
  - When: grep for "SceneManager"
  - Then: Zero matches

- **AC-5**: Same tab tap does not re-emit
  - Given: `_active_tab == FARM`
  - When: `_on_tab_pressed(NavTab.FARM)` called
  - Then: `mock_event_bus.nav_tab_pressed_calls.size() == 0`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ui/hud_nav_bar_test.gd` — must exist and pass

**Status**: [x] `tests/integration/ui/hud_nav_bar_test.gd` — 10 test functions, all ACs covered

---

## Dependencies

- Depends on: Story 001 DONE (shares `hud.gd` file — story-001 must establish the file first)
- Depends on: EventBus story-001 DONE — `nav_tab_pressed` signal must be defined ✅
- Unlocks: Story 003 (notification toast — same file)

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 5/5 passing
**Deviations**: Active tab highlight uses `modulate = Color(1.0, 0.8, 0.2)` — placeholder; final colour set in scene editor (advisory)
**Test Evidence**: `tests/integration/ui/hud_nav_bar_test.gd` — 10 test functions (GdUnit4)
**Code Review**: Skipped — Lean mode
