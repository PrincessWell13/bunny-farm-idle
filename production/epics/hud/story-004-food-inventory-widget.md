# Story 004: Food Inventory Widget

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.3 FoodSystem, §7 UI/UX)
**Requirement**: `TR-hud-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

> ⚠️ TR-hud-003 is not yet in `tr-registry.yaml`. Add it when running `/architecture-review rtm`.
> Stable ID reserved: `TR-hud-003` — "Food inventory quantity display updates reactively on food_harvested and rabbit_fed signals"

**ADR Governing Implementation**: ADR-0003 (EventBus Signal Architecture), ADR-0001 (Autoload Boot Sequence)
**ADR Decision Summary**: HUD subscribes to EventBus signals (`food_harvested`, `rabbit_fed`) — never reads `FoodSystem._food_inventory` directly. On `_ready()`, reads current inventory via `FoodSystem.get_inventory()` for initial display. Disconnect signals in `_exit_tree()` (ADR-0003 Disconnect Pattern). HUD initialises at boot step 12 — safe to call `FoodSystem.get_inventory()` in `_ready()`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Signal system unchanged in 4.4–4.6. No post-cutoff APIs used. `Label.text` assignment is stable.

**Control Manifest Rules (Presentation layer)**:
- Required: Subscribe to `EventBus.food_harvested` and `EventBus.rabbit_fed` in `_ready()`; disconnect in `_exit_tree()` (F-03)
- Required: All variables and return types statically typed (F-02)
- Required: Initial state populated from `FoodSystem.get_inventory()` on `_ready()` — never assume inventory is 0 at launch
- Forbidden: Direct read of `FoodSystem._food_inventory` — use `get_inventory()` getter only
- Forbidden: Hardcoding the food type key `"grass"` — food type must come from signal data or a named constant
- Forbidden: Calling any method that mutates Core state from HUD
- Guardrail: All interactive elements ≥ 44×44 px; label readable on 1080×1920 portrait

---

## Acceptance Criteria

1. HUD subscribes to `EventBus.food_harvested(food_id, quantity)` and `EventBus.rabbit_fed(rabbit_id, food_id)` in `_ready()` and disconnects both in `_exit_tree()`
2. On `_ready()`, HUD calls `FoodSystem.get_inventory()` and displays the quantity for each food type present (at minimum: grass)
3. Grass count label is always visible, including when grass count is 0 (never hidden on empty)
4. When `food_harvested(food_id, quantity)` fires, the displayed count for `food_id` increments by `quantity`
5. When `rabbit_fed(rabbit_id, food_id)` fires, the displayed count for `food_id` decrements by 1
6. The widget never displays a negative count — if the count would go below 0, it clamps to 0
7. The food type label/icon is driven by the `food_id` value from the signal, not a hardcoded string

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

```gdscript
# In src/ui/hud.gd (or a child node FoodInventoryWidget):
func _ready() -> void:
    # ... other subscriptions ...
    EventBus.food_harvested.connect(_on_food_harvested)
    EventBus.rabbit_fed.connect(_on_rabbit_fed)
    _refresh_food_display()

func _exit_tree() -> void:
    EventBus.food_harvested.disconnect(_on_food_harvested)
    EventBus.rabbit_fed.disconnect(_on_rabbit_fed)

func _refresh_food_display() -> void:
    var inventory: Dictionary = FoodSystem.get_inventory()
    # Update each food label from the inventory dict

func _on_food_harvested(food_id: String, quantity: int) -> void:
    # Increment the display for food_id

func _on_rabbit_fed(rabbit_id: String, food_id: String) -> void:
    # Decrement the display for food_id (clamp to 0)
```

**EventBus signals required** (confirm these exist in `src/core/event_bus.gd`):
- `signal food_harvested(food_id: String, quantity: int)`
- `signal rabbit_fed(rabbit_id: String, food_id: String)`

If either signal is missing from `event_bus.gd`, add it before implementing this story.

**Scene placement**: The food inventory widget should live as a child node within the HUD scene (`src/ui/HUD.tscn`). Do not create a separate autoload.

---

## Out of Scope

- Farm plot timers and harvest interaction — covered in story-005
- Feed visual feedback (tween animation on deduction) — covered in S05-15
- Food storage panel or full inventory screen — future Feature layer story
- Farm seeding UI (cost display, seed button) — future story

---

## QA Test Cases

*Manual verification steps (UI story):*

- **AC-1**: Signal subscription
  - Setup: Launch game to main HUD
  - Verify: Using Godot debugger, confirm `EventBus.food_harvested` and `EventBus.rabbit_fed` have HUD connected as subscriber
  - Pass condition: Both signals show HUD callable in debugger's Connections tab

- **AC-2**: Initial display
  - Setup: Start session with grass count > 0 in save state
  - Verify: Grass count label shows the correct integer immediately on HUD load
  - Pass condition: Displayed count matches `FoodSystem.get_inventory()["grass"]`

- **AC-3**: Always visible at 0
  - Setup: Start fresh session with 0 grass
  - Verify: Grass count label is visible and shows "0" (not hidden)
  - Pass condition: Label visible with text "0"

- **AC-4**: Harvest increment
  - Setup: Start session; wait for or trigger a farm plot harvest
  - Verify: Grass count label increments immediately when `food_harvested` signal fires
  - Pass condition: Count increases by the harvested quantity

- **AC-5**: Feed decrement
  - Setup: Have at least 1 grass; trigger `feed_rabbit()` via game action
  - Verify: Grass count label decrements immediately
  - Pass condition: Count decreases by 1; never shows negative

- **AC-6**: No negative display
  - Setup: Feed rabbit when grass count is exactly 1
  - Verify: Count shows 0 after feed, not -1
  - Pass condition: Clamps to 0

- **AC-7**: No hardcoded "grass" key
  - Setup: Code review of the widget implementation
  - Verify: No literal `"grass"` string in HUD/widget .gd file for the label update logic
  - Pass condition: Food type derived from signal payload `food_id` parameter

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/s05-06-food-widget-evidence.md`
- Screenshot of HUD showing grass count before and after `feed_rabbit()` call
- QA lead sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: S05-02 (balance.json food keys) — `FoodSystem.get_inventory()` reads balance.json keys at runtime; food keys must exist before this story is testable
- Depends on: S05-05 (this story — story file created here, which IS S05-05)
- Unlocks: S05-15 (feed visual feedback extends this widget's signal handler)
