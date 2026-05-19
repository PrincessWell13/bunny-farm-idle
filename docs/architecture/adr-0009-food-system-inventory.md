# ADR-0009: FoodSystem Inventory Model and Farm Plot Timer

## Status
Accepted

## Date
2026-05-18

## Last Verified
2026-05-18

## Decision Makers
GDScript Specialist, Gameplay Programmer

## Summary
`FoodSystem` needs a concrete data model for food inventory counts and farm plot grow timers so that feeding, harvesting, and save/load can all operate on the same canonical state. The decision stores food inventory as `Dictionary[String, int]` in `GameState.food_inventory` and farm plots as `Array[Dictionary]` in `GameState.farm_plots`, with `FoodSystem` owning all mutations and `TimeManager.tick` driving plot completion.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — `Dictionary[String, int]` typed dict syntax available from Godot 4.0+; no post-cutoff APIs |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm `Dictionary[String, int]` serialises via `JSON.stringify()` correctly in SaveSystem — iterate keys explicitly, do not rely on Godot's typed dict auto-serialisation |

> **Note**: Knowledge Risk is LOW. No re-validation required unless engine is upgraded past 4.6.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameState owns `food_inventory` + `farm_plots`; FoodSystem is autoload after EconomyManager), ADR-0003 (food_harvested signal via EventBus), ADR-0004 (balance.json holds all food definitions — stat effects, grow times, costs, max stack), ADR-0005 (RabbitSystem.feed_rabbit applies stat effects; FoodSystem delegates to it) |
| **Enables** | Any story implementing feeding, farm plot UI, or food-driven stat effects |
| **Blocks** | TR-food-001 stories cannot begin until this ADR is Accepted |
| **Ordering Note** | EconomyManager autoload must be registered before FoodSystem in the Godot project settings autoload order, because FoodSystem calls EconomyManager to spend Coins when seeding plots |

## Context

### Problem Statement
The food pipeline spans three concerns: inventory counts (how many of each food the player holds), farm plot timers (when planted food becomes harvestable), and feeding (deducting inventory and applying stat effects to a rabbit). Without a canonical data model these concerns have no agreed storage location, making save/load unreliable and creating ambiguity about which system is the authority for mutations.

### Current State
No food system exists. This is a greenfield decision made before any food-related code is written.

### Constraints
- `GameState` must be the serialisation source — `SaveSystem` reads only from `GameState` fields (ADR-0001)
- All food definitions (stat effects, grow time, seeding cost, max stack) live in `balance.json` — never hardcoded (ADR-0004)
- Stat effects on rabbits are owned by `RabbitSystem.feed_rabbit()` — `FoodSystem` must not write to `RabbitData` fields directly (ADR-0005)
- Android/iOS primary — data structures must be JSON-serialisable without custom Godot serialisers
- Inventory capped at `balance.json food.max_stack` (default 99) per food type to bound save data size

### Requirements
- Store per-food-type quantity counts accessible by food_id key
- Store per-plot state: which food is growing, when it started, how long it takes
- Tick plots against real time and emit a signal when a plot completes
- Deduct inventory when feeding a rabbit; reject the call if count is zero
- Spend Coins via EconomyManager to seed a new plot
- Support offline catch-up: plot timers use Unix timestamps so elapsed time is computable after an offline period
- Maximum inventory per food type: `balance.json food.max_stack` (default 99)

## Decision

Food inventory is a `Dictionary[String, int]` stored at `GameState.food_inventory`, keyed by `food_id` string, value is current quantity. Farm plots are stored as `Array[Dictionary]` at `GameState.farm_plots` — each element is a plain Dictionary with three keys: `food_id: String`, `started_at: float` (Unix timestamp), `duration: float` (seconds until harvest). `FoodSystem` owns all mutations to both structures. `FoodSystem` does NOT store food effect definitions — those are looked up from `balance.json` at feed time. Plot ticking is driven by `TimeManager.tick`; when a plot's elapsed time exceeds its `duration`, `FoodSystem` removes the plot entry, increments `GameState.food_inventory[food_id]`, clamps to `max_stack`, and emits `EventBus.food_harvested(food_id, quantity)`.

### Architecture

```
GameState
├── food_inventory: Dictionary[String, int]   ← FoodSystem mutates; SaveSystem serialises
└── farm_plots: Array[Dictionary]             ← FoodSystem mutates; SaveSystem serialises

FoodSystem (Autoload)
├── _on_time_manager_tick(delta)
│     ├── iterate farm_plots
│     ├── elapsed = Time.get_unix_time_from_system() - plot.started_at
│     ├── if elapsed >= plot.duration:
│     │     remove plot, increment inventory (clamped to max_stack)
│     │     emit EventBus.food_harvested(food_id, quantity)
│     └── emit EventBus.farm_plots_updated() for UI refresh
│
├── feed_rabbit(rabbit_id, food_id) → bool
│     ├── check inventory[food_id] > 0
│     ├── deduct inventory[food_id] -= 1
│     ├── lookup food definition from balance.json
│     ├── delegate: RabbitSystem.feed_rabbit(rabbit_id, food_definition)
│     ├── emit EventBus.food_used(food_id)
│     └── return true; return false if no stock or rabbit not found
│
├── seed_plot(food_id) → bool
│     ├── lookup cost from balance.json
│     ├── EconomyManager.spend_coins(cost) → bool
│     ├── if success: append plot dict to GameState.farm_plots
│     └── return false if insufficient coins
│
├── get_inventory() → Dictionary[String, int]
└── get_farm_plot_state() → Array[Dictionary]

balance.json (read-only at runtime)
└── food definitions: stat_effects, grow_time, seed_cost, max_stack

EventBus (Autoload, ADR-0003)
├── food_harvested(food_id: String, quantity: int)
├── food_used(food_id: String)
└── farm_plots_updated()
```

### Key Interfaces

```gdscript
# src/core/food_system.gd
class_name FoodSystem extends Node

# --- Public API ---

## Deducts one unit of food_id from inventory and delegates stat effects
## to RabbitSystem.feed_rabbit(). Returns false if inventory is zero or
## rabbit_id does not exist.
func feed_rabbit(rabbit_id: String, food_id: String) -> bool

## Returns current inventory snapshot. Callers must not mutate the returned dict.
func get_inventory() -> Dictionary

## Returns current farm plot array snapshot. Each dict has keys:
##   food_id: String, started_at: float, duration: float
## Callers must not mutate the returned array or its elements.
func get_farm_plot_state() -> Array

## Spends Coins via EconomyManager and appends a new plot to GameState.farm_plots.
## Returns false if EconomyManager.spend_coins() fails (insufficient funds).
func seed_plot(food_id: String) -> bool

# --- GameState fields (owned by GameState, mutated only by FoodSystem) ---
# GameState.food_inventory: Dictionary  (runtime type: Dictionary[String, int])
# GameState.farm_plots: Array           (runtime type: Array[Dictionary])

# --- EventBus signals (ADR-0003) ---
# signal food_harvested(food_id: String, quantity: int)
# signal food_used(food_id: String)
# signal farm_plots_updated()
```

### Implementation Guidelines

- Connect to `TimeManager.tick` in `FoodSystem._ready()`, not to `_process`. Plot ticking is coarse-grained (seconds), not per-frame.
- Use `Time.get_unix_time_from_system()` (returns float) for `started_at` so offline catch-up works correctly: on load, elapsed = `current_unix_time - started_at`, which accounts for time spent offline.
- When incrementing inventory on harvest, always clamp: `min(current + quantity, max_stack)`. Read `max_stack` from the loaded `balance.json` food definition dict; fall back to 99 if key is absent.
- `FoodSystem` must call `GameState.mark_dirty()` after every inventory or plot mutation so `SaveSystem` knows to persist.
- Never iterate `GameState.farm_plots` and mutate it in the same loop. Collect completed-plot indices first, then process removals in reverse-index order to avoid index shifting bugs.
- Food definitions are loaded from `balance.json` once in `_ready()` into a private `_food_defs: Dictionary` cache. All lookups go through this cache — never re-read the file during gameplay.
- `feed_rabbit()` must check `RabbitSystem.get_rabbit(rabbit_id) != null` before deducting inventory. Deduct first only after confirming both the rabbit exists and the food count is positive; roll back the deduction if `RabbitSystem.feed_rabbit()` returns false.

## Alternatives Considered

### Alternative 1: Resource-based FoodItem objects

- **Description**: Each food type is a `FoodItem extends Resource` with typed fields for quantity, effects, grow time. `GameState.food_inventory` stores `Array[FoodItem]`.
- **Pros**: Type-safe; IDE autocomplete on all fields; consistent with `RabbitData` pattern (ADR-0005).
- **Cons**: Food inventory is fundamentally a count-per-type lookup, not a list of objects. A `Dictionary[String, int]` is semantically correct and far simpler. `Resource` adds allocation and serialisation overhead (manual `_to_dict()` required per ADR-0005 findings) that is not justified for what is effectively a key-value store. Food effect definitions do not need to be instanced per save — they are static config read from `balance.json`.
- **Estimated Effort**: Higher — requires a new `FoodItem` resource file, schema decisions, round-trip serialisation code.
- **Rejection Reason**: Over-engineered for a simple count+timer system. Dictionary is sufficient and matches the data's natural shape.

### Alternative 2: FoodSystem owns farm_plots directly (not via GameState)

- **Description**: `GameState` holds only `food_inventory`. Farm plot timers live as a private `Array[Dictionary]` inside `FoodSystem` itself, not exposed through `GameState`.
- **Pros**: Cleaner encapsulation — FoodSystem fully owns its internal state.
- **Cons**: `SaveSystem` serialises game state by reading from `GameState` fields (ADR-0001). If plot state lives only in `FoodSystem`, `SaveSystem` must reach into a specific autoload — creating a coupling that contradicts ADR-0001's ownership model. Offline catch-up also requires persisting `started_at` timestamps across sessions, which requires saving plot state.
- **Estimated Effort**: Equal effort, but introduces an ADR-0001 violation.
- **Rejection Reason**: SaveSystem needs to serialise plot state. Plot state must live in `GameState` so SaveSystem's single-source serialisation contract (ADR-0001) holds.

## Consequences

### Positive
- `SaveSystem` serialises `food_inventory` and `farm_plots` directly from `GameState` — no special-case serialisation path needed beyond standard dict/array JSON handling
- Unix timestamp approach gives offline catch-up for free: elapsed time is computable from any two instants without storing intermediate tick results
- `balance.json` remains the single source of truth for food definitions — changing grow times or stat effects requires no code changes (ADR-0004)
- `FoodSystem` public API is narrow (4 methods) and fully mockable in GdUnit4 tests without a scene or live TimeManager

### Negative
- `Dictionary` is untyped at the GDScript language level for the inner plot dicts — a typo in a key (`"stared_at"` vs `"started_at"`) is a silent runtime bug, not a compile error
- `Array[Dictionary]` for farm plots provides no IDE autocomplete on plot fields; contributors must consult this ADR or inline comments to know the expected keys
- Manual `_food_defs` cache in `FoodSystem` means adding a new food definition key to `balance.json` also requires updating any code that reads that key — there is no compile-time guarantee that the cache access matches the schema

### Neutral
- FoodSystem emits `farm_plots_updated()` on every tick where any plot is active — UI must connect to this signal rather than polling `get_farm_plot_state()` each frame
- Food inventory and farm plot data are stored as separate `GameState` fields rather than a single combined food state object — consistent with how `GameState` handles rabbits and hutches as independent collections

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Plot dict key typo causes silent harvest failure | MEDIUM | HIGH | Define plot dict keys as `StringName` constants on `FoodSystem` (e.g. `const KEY_FOOD_ID := &"food_id"`) and use only those constants when reading/writing plots |
| Inventory deduction succeeds but RabbitSystem.feed_rabbit() returns false — food lost | LOW | MEDIUM | In `FoodSystem.feed_rabbit()`, deduct after confirming rabbit exists; if RabbitSystem returns false unexpectedly, re-increment inventory and log a warning |
| max_stack not present in balance.json for a new food type — no cap applied | LOW | LOW | Default to 99 if key absent; add a startup assertion that all food definitions include `max_stack` |
| Offline catch-up produces fractional harvest quantities on partial plot completion | LOW | LOW | Plots complete fully or not at all — no partial credit; elapsed >= duration triggers a single full harvest |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (tick time) | n/a — new system | <0.1ms per tick (iterate ≤ 6 plots, simple arithmetic) | 1ms per tick |
| Memory | n/a | <5KB (6 plots × ~3 keys each + inventory dict with ≤20 food types) | 256MB mobile ceiling |
| Load Time | n/a | <0.5ms (deserialise 2 small dicts at boot) | No perceptible impact |

## Migration Plan
Greenfield — no existing food system to migrate. Create in this order:

1. Add `food_inventory: Dictionary` and `farm_plots: Array` fields to `GameState` (`src/core/game_state.gd`). Initialise both to empty in `_reset_state()`.
2. Add serialisation/deserialisation for both fields in `SaveSystem` (`src/core/save_system.gd`). Unit-test round-trip before proceeding.
3. Create `src/core/food_system.gd` with the schema above. Register as autoload after `EconomyManager` in project settings.
4. Add `food_harvested`, `food_used`, and `farm_plots_updated` signals to `EventBus` (`src/core/event_bus.gd`).
5. Connect `FoodSystem._on_time_manager_tick` to `TimeManager.tick` in `FoodSystem._ready()`.

**Rollback plan**: All four files (`game_state.gd`, `save_system.gd`, `food_system.gd`, `event_bus.gd`) are additive changes. Remove the autoload registration and revert the four files to their previous state. No other systems depend on `FoodSystem` at greenfield time.

## Validation Criteria

- [ ] GdUnit4 test: `FoodSystem.feed_rabbit()` returns `false` when `food_inventory[food_id]` is 0
- [ ] GdUnit4 test: `FoodSystem.feed_rabbit()` decrements inventory by 1 and calls `RabbitSystem.feed_rabbit()` when stock > 0
- [ ] GdUnit4 test: plot with `started_at = T`, `duration = D` completes when `Time.get_unix_time_from_system() >= T + D`; `food_harvested` signal fires with correct `food_id` and `quantity`
- [ ] GdUnit4 test: inventory is clamped to `max_stack` on harvest if already near cap
- [ ] GdUnit4 test: `FoodSystem.seed_plot()` returns `false` when `EconomyManager.spend_coins()` returns `false`
- [ ] SaveSystem round-trip test: `food_inventory` and `farm_plots` survive serialise → deserialise with all field values intact
- [ ] GdUnit4 test: offline catch-up — set `started_at` to `Time.get_unix_time_from_system() - duration - 1`; single tick resolves the plot

## GDD Requirements Addressed

| GDD Req ID | GDD Section | Requirement | How This ADR Addresses It |
|------------|-------------|-------------|--------------------------|
| TR-food-001 | Food System | Food inventory + farm plot timers + feeding pipeline | `GameState.food_inventory` (Dictionary) holds counts; `GameState.farm_plots` (Array[Dictionary]) holds timer state; `FoodSystem.feed_rabbit()` wires the deduction-and-delegate feeding pipeline |

## Related Decisions
- ADR-0001: `GameState` owns `food_inventory` and `farm_plots`; FoodSystem is the sole mutator
- ADR-0003: `food_harvested`, `food_used`, `farm_plots_updated` signals emitted via EventBus
- ADR-0004: All food definitions (stat effects, grow time, seed cost, max stack) in `balance.json` — never hardcoded
- ADR-0005: `RabbitSystem.feed_rabbit()` applies stat effects to `RabbitData`; FoodSystem delegates to it rather than writing to `RabbitData` directly
