# Bunny Farm Idle — Master Architecture

## Document Status
- Version: 1.0
- Last Updated: 2026-05-16
- Engine: Godot 4.6 / GDScript
- GDDs Covered: design/gdd/bunny-farm-idle-master.md
- ADRs Referenced: (none yet — see Required ADRs section)
- Technical Director Sign-Off: 2026-05-16 — APPROVED WITH CONDITIONS
  - Condition: 8 Foundation ADRs must be written before any code is committed
  - Condition: ADRs 9, 10, 12 must be written before their respective systems are built
- Lead Programmer Feasibility: SKIPPED — Lean mode

---

## Engine Knowledge Gap Summary

| Risk | Domain | Key Post-Cutoff Changes |
|------|--------|------------------------|
| HIGH | UI | Dual-focus system (4.6): mouse/touch focus separate from keyboard/gamepad focus |
| HIGH | Rendering | D3D12 default on Windows (4.6); Glow before tonemapping (4.6) |
| HIGH | Accessibility | AccessKit screen reader integration (4.5); FoldableContainer (4.5) |
| MEDIUM | GDScript | Variadic args (4.5); `@abstract` decorator (4.5) |
| MEDIUM | Navigation | Dedicated 2D navigation server (4.5) — reduces binary size |
| MEDIUM | Resources | `duplicate_deep()` added (4.5) for nested resource copies |
| LOW | Audio | No significant post-cutoff changes |
| LOW | Physics 2D | Unchanged (Jolt only affects 3D) |
| LOW | Input | 2D touch input unchanged |

**Mitigation for this project**: Game is touch-primary, no keyboard/gamepad support.
Dual-focus system change does not affect touch-only UIs — no keyboard focus chains needed.
Use `MOUSE_FILTER_STOP` for interactive elements, `MOUSE_FILTER_IGNORE` for decorative ones.

---

## System Layer Map

```
┌─────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                             │
│  FarmMapUI · BreedingUI · HUD · ShopUI · GuildUI · QuestUI     │
│  MiniGameSystem · AccessibilitySystem                           │
├─────────────────────────────────────────────────────────────────┤
│  FEATURE LAYER                                                  │
│  HabitatSystem · FoodSystem · ExpeditionSystem · SeasonSystem  │
│  PrestigeSystem · GuildSystem · EventSystem · MerchantSystem   │
│  GenePuzzleSystem · CollectionSystem                            │
├─────────────────────────────────────────────────────────────────┤
│  CORE LAYER                                                     │
│  RabbitSystem · GeneticsSystem · IdleProductionSystem          │
├─────────────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER                                               │
│  GameState · TimeManager · EventBus · SaveSystem               │
│  EconomyManager · SceneManager                                  │
├─────────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                                 │
│  FirebaseAdapter · IAPAdapter · AdAdapter · NotificationAdapter │
└─────────────────────────────────────────────────────────────────┘
```

### Layer Ownership Summary

**FOUNDATION** — must boot before all other layers:
- `GameState` autoload — all persistent player data; save/load trigger
- `TimeManager` autoload — real clock, delta ticks, offline elapsed time, season counter
- `EventBus` autoload — all cross-system signals; sole inter-system communication bus
- `SaveSystem` — JSON serialization/deserialization; Firebase sync handoff
- `EconomyManager` autoload — 4-currency ledgers; all income/spend transactions
- `SceneManager` — async scene loading, transitions, memory cleanup

**CORE** — fundamental gameplay logic, runs every tick:
- `RabbitSystem` — rabbit entity data, lifecycle stages, stat decay, aura calculations
- `GeneticsSystem` — genome data, allele selection, mutation rolls, trait stacking, rarity
- `IdleProductionSystem` — tick-based production, online/background/offline multipliers, catch-up

**FEATURE** — gameplay systems built on Core:
- `HabitatSystem` — hutch entities, capacity rules, bonus application, cleanliness decay
- `FoodSystem` — food inventory, farm plot timers, feeding, stat effect application
- `ExpeditionSystem` — slot management, timer tracking, loot resolution
- `SeasonSystem` — season clock, global multiplier application, seasonal rabbit spawning
- `PrestigeSystem` — eligibility check, selective state wipe, permanent bonus stacking
- `GuildSystem` — member roster, contribution tracking, async boss raid, marketplace
- `EventSystem` — event schedule, activation logic, community goal tracking
- `MerchantSystem` — random merchant timer, offer generation, expiry
- `GenePuzzleSystem` — challenge tracking, genealogy tree storage
- `CollectionSystem` — species registry, collection completion tracking

**PRESENTATION** — UI, rendering, mini-games (no game logic):
- `FarmMapUI` — scrollable farm viewport, rabbit sprite rendering (≤24), parallax
- `BreedingUI` — gene picker, probability pie chart, result reveal animation
- `HUD` — header bar (currencies, notifications), bottom nav bar (5 tabs)
- `ShopUI / QuestUI / GuildUI` — screen-specific panels
- `MiniGameSystem` — 5 mini-game scene controllers, reward dispatch
- `AccessibilitySystem` — text scale, colorblind palette, simplified mode

**PLATFORM** — thin adapters to external services only:
- `FirebaseAdapter` — HTTP to Firebase Auth + Realtime DB + Cloud Functions
- `IAPAdapter` — Android billing / iOS StoreKit
- `AdAdapter` — rewarded ad SDK (opt-in only)
- `NotificationAdapter` — OS push notification scheduling

### Guild Boss Raid Decision
Treated as **async co-op** — players contribute damage over a 7-day window, not real-time.
Avoids real-time netcode. All guild state managed via Firebase Realtime DB.

---

## Module Ownership

### FOUNDATION LAYER

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| `GameState` | Complete player data tree (rabbits, currencies, hutches, prestige level, collection, settings) | `get_player_data() → Dictionary`; `save_requested` signal; `prestige_reset(keep: Dictionary)` | SaveSystem (read/write), EventBus (broadcast changes) | `Resource`, `FileAccess` |
| `TimeManager` | Last-seen timestamp, current real time, accumulated offline delta, in-game day counter | `get_offline_delta() → float`; `get_current_season() → Season`; `tick` signal (1/sec) | OS time via `Time.get_unix_time_from_system()` | `Time` singleton |
| `EventBus` | Signal registry — all cross-system events defined here | All signals (e.g. `rabbit_fed`, `breeding_completed`, `currency_changed`) | Nothing — emits only | None |
| `SaveSystem` | Serialization logic, save file path, Firebase sync state | `save_game()`, `load_game() → Dictionary`, `sync_to_cloud()` | `GameState` (data source), `FirebaseAdapter` (cloud) | `FileAccess`, `JSON` |
| `EconomyManager` | 4-currency ledgers (CC, Star Dust, Crystal Gem, Gene Fragment) | `add(currency, amount)`, `spend(currency, amount) → bool`, `get_balance(currency) → int` | EventBus (emits `currency_changed`) | None |
| `SceneManager` | Active scene stack, transition state | `goto_scene(path: String)`, `push_overlay(path: String)`, `pop_overlay()` | ResourceLoader (async) | `ResourceLoader.load_threaded_request()` ⚠️ verify async API in 4.6 |

### CORE LAYER

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| `RabbitSystem` | Array of all `RabbitData` resources; lifecycle state machine per rabbit | `get_all_rabbits() → Array[RabbitData]`; `tick(delta)` — advances stats; `rabbit_died`, `rabbit_matured` signals via EventBus | `TimeManager.tick`, `GeneticsSystem` (reads traits), `HabitatSystem` (reads bonuses) | `Resource`, custom `RabbitData` resource |
| `GeneticsSystem` | Breeding logic, genome/allele data structures, trait effect table, rarity table | `breed(parent_a: RabbitData, parent_b: RabbitData) → RabbitData`; `get_breed_preview(a, b) → BreedPreview`; `apply_trait_stacking(rabbit: RabbitData)` | `RabbitSystem` (rabbit data), balance.json (probabilities) | `RandomNumberGenerator` |
| `IdleProductionSystem` | Production tick logic, offline multiplier tiers, per-hutch output calculation | `calculate_offline_earnings(delta: float) → EarningsReport`; `get_tick_earnings() → EarningsReport` | `TimeManager` (delta), `HabitatSystem` (hutch bonuses), `RabbitSystem` (rabbit stats), `SeasonSystem` (multipliers) | None — pure logic |

### FEATURE LAYER

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| `HabitatSystem` | Array of `HutchData` resources; rabbit-to-hutch assignments; cleanliness timers | `get_hutch_bonuses(hutch_id) → HutchBonus`; `assign_rabbit(rabbit_id, hutch_id) → bool`; `get_capacity(hutch_id) → int` | `TimeManager.tick` (cleanliness decay), `RabbitSystem` (rabbit data) | `Resource` |
| `FoodSystem` | Food inventory dictionary; farm plot timers; food effect definitions | `feed_rabbit(rabbit_id, food_id) → bool`; `get_inventory() → Dictionary`; `get_farm_plot_state() → Array` | `EconomyManager` (spend CC), `RabbitSystem` (apply stat effects), `TimeManager.tick` | None |
| `ExpeditionSystem` | Expedition slot state (assigned rabbits, start time, zone); loot tables | `start_expedition(zone_id, rabbit_ids: Array) → bool`; `collect(slot_id) → LootResult`; `get_active_expeditions() → Array` | `TimeManager` (elapsed time), `RabbitSystem` (validate requirements), `EconomyManager` (grant rewards) | None |
| `GuildSystem` | Local cache of guild roster, contribution totals, boss raid HP, marketplace listings | `submit_contribution(amount: int)`; `attack_boss(damage: int)`; `list_item(rabbit_id, price: int)` | `FirebaseAdapter` (read/write guild state), `EconomyManager` (marketplace transactions) | None (all I/O via FirebaseAdapter) |
| `PrestigeSystem` | Prestige count; permanent bonus table | `can_prestige() → bool`; `execute_prestige()` | `RabbitSystem` (Legendary check), `CollectionSystem` (80% check), `GameState` (selective wipe) | None |
| `SeasonSystem` | Current season enum, day-within-season counter | `get_active_multipliers() → SeasonMultipliers`; `get_current_season() → Season` | `TimeManager` (in-game day counter) | None |
| `EventSystem` | Event schedule, activation state, community goal progress | `get_active_events() → Array`; `contribute_to_event(event_id, amount)` | `TimeManager` (schedule check), `FirebaseAdapter` (world event sync) | None |
| `MerchantSystem` | Merchant timer, active offer list | `get_current_offers() → Array[MerchantOffer]`; `accept_offer(offer_id) → bool` | `TimeManager` (spawn timer), `EconomyManager` (transactions), `RabbitSystem` (validate rabbit offers) | None |
| `GenePuzzleSystem` | Challenge definitions, player progress, genealogy tree per rabbit | `get_active_challenges() → Array`; `get_genealogy(rabbit_id) → GeneTree`; `check_challenge_progress(rabbit: RabbitData)` | `RabbitSystem` (rabbit data), `GeneticsSystem` (trait data) | None |
| `CollectionSystem` | Species registry, completion percentage | `get_completion_percent() → float`; `register_rabbit(rabbit: RabbitData)` | `RabbitSystem` (new rabbit events via EventBus) | None |

### PRESENTATION LAYER

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| `FarmMapUI` | Farm viewport scene, rabbit sprite pool (≤24 nodes) | Nothing — reads and displays only | `RabbitSystem` (rabbit list), `HabitatSystem` (hutch layout), EventBus (state changes) | `CanvasItem`, `Sprite2D`, `AnimationPlayer`, `Camera2D` |
| `BreedingUI` | Breeding screen scene, gene slot display, preview chart | Nothing — dispatches `breed_requested(a_id, b_id)` via EventBus | `GeneticsSystem.get_breed_preview()`, `RabbitSystem` (rabbit list) | `Control`, `SubViewport` ⚠️ verify pie chart approach in 4.6 |
| `HUD` | Header bar, bottom nav bar scenes | `show_notification(text: String)` | `EconomyManager` (balance), EventBus (notifications), `SceneManager` (nav) | `Control`, `Label`, `TextureButton` |
| `AccessibilitySystem` | Current accessibility settings (font scale, colorblind palette, simplified flag) | `apply_settings()` — updates theme + palette globally | `GameState` (saved settings) | `Theme`, colorblind shader ⚠️ use `Texture` not `Texture2D` in shader uniforms (4.4+) |

### PLATFORM LAYER

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| `FirebaseAdapter` | HTTP request queue, auth token, base URL | `auth_sign_in(email, password)`, `db_read(path) → Dictionary`, `db_write(path, data)`, `call_function(name, params) → Variant` | Nothing internal | `HTTPRequest` ⚠️ verify `request_completed` signal in 4.6 |
| `IAPAdapter` | Purchase state | `purchase(product_id: String)`, `restore_purchases()` | `EconomyManager` (grant gems on success) | Android/iOS platform plugin |
| `AdAdapter` | Ad loaded state, cooldown timer | `show_rewarded_ad(callback: Callable)` | `TimeManager` (cooldown), `EconomyManager` (grant reward) | Android/iOS platform plugin |
| `NotificationAdapter` | Scheduled notification list | `schedule(title, body, delay_seconds: int)`, `cancel_all()` | `TimeManager` (rabbit hunger timing) | Android/iOS platform plugin |

### Dependency Diagram

```
PLATFORM          FOUNDATION          CORE              FEATURE           PRESENTATION
────────          ──────────          ────              ───────           ────────────
                  GameState ◄──────── RabbitSystem ◄─── HabitatSystem ◄── FarmMapUI
FirebaseAdapter ──► SaveSystem        GeneticsSystem ◄── FoodSystem        BreedingUI
IAPAdapter      ──► EconomyManager    IdleProduction ◄── ExpeditionSystem   HUD
AdAdapter       ──►     │                   │        ◄── SeasonSystem       MiniGames
NotifAdapter    ──►     │                   │        ◄── PrestigeSystem     AccessSystem
                  TimeManager ──────────────┤        ◄── GuildSystem ──► FirebaseAdapter
                  EventBus ◄──────────────── (all modules emit here)
                  SceneManager ◄──────────────────────────────────── HUD nav taps
```

**Layering rule**: Arrows point downward or sideways only. Feature never calls Presentation.
Core never calls Feature. Foundation never calls Core. Only SaveSystem, GuildSystem,
EventSystem, and Platform adapters touch FirebaseAdapter.

---

## Data Flow

### Scenario 1: Frame Update Path (1-second tick)

```
TimeManager._process()
    │  emits: tick(delta)
    ▼
RabbitSystem.tick(delta)
    │  hunger -= hunger_rate * delta  |  health -= 1.0/60 if hunger == 0
    │  happiness = f(cleanliness, play_time)
    │  emits via EventBus: rabbit_stat_changed(rabbit_id)
    ▼
IdleProductionSystem.tick(delta)
    │  earnings = base_rate * rabbit_count * hutch_bonus * season_multiplier
    │  calls: EconomyManager.add(CARROT_COIN, earnings)
    │  emits via EventBus: production_ticked(amount)
    ▼
HabitatSystem.tick(delta)
    │  cleanliness -= decay_rate * delta (per hutch)
    │  emits via EventBus: hutch_dirtied(hutch_id) [threshold]
    ▼
FarmMapUI (listens: rabbit_stat_changed) → updates sprite animation state
HUD (listens: currency_changed) → updates CC label
```

- Synchronous: all tick consumers run in the same frame on the main thread.
- No shared mutable state between systems — each reads GameState, emits to EventBus.
- EventBus is the only broadcast channel; direct calls only go downward.

### Scenario 2: Breeding Flow (player-initiated)

```
BreedingUI
    │  calls: GeneticsSystem.get_breed_preview(a, b) → displays pie chart
    │  player confirms → emits via EventBus: breed_requested(a_id, b_id)
    ▼
GeneticsSystem.breed(a, b)
    │  for each of 6 slots: child alleles = random_pick from each parent
    │  mutation_roll: if hit → randomise one allele from rarity table
    │  apply_trait_stacking(child) → synergies/cancellations resolved
    │  returns: RabbitData (new child, not yet in world)
    ▼
RabbitSystem.add_rabbit(child)
    │  HabitatSystem.find_space() → assigns hutch
    │  stores in GameState.rabbits[]
    │  emits via EventBus: rabbit_born(child_id)
    ▼
CollectionSystem (listens: rabbit_born) → register_rabbit(child)
GenePuzzleSystem (listens: rabbit_born) → check_challenge_progress(child)
FarmMapUI (listens: rabbit_born) → spawns sprite
SaveSystem → GameState marks dirty → queues save on next idle frame
```

- RabbitData is a `Resource` (not a Node). Passed by reference, serialised to JSON by SaveSystem.
- Breeding is synchronous — completes in one frame, no async needed.

### Scenario 3: Save / Load Path

**Save:**
```
GameState dirty flag set by any mutation
    ▼
SaveSystem.save_game()
    │  serializes → JSON.stringify → user://savegame.json (FileAccess)
    │  FirebaseAdapter.db_write("users/{uid}/save", data)  [async, non-blocking]
    ▼
FirebaseAdapter → HTTPRequest to Firebase
    │  success: emits save_synced
    │  failure: queues retry (local file already safe)
```

**Load (app start):**
```
SceneManager (boot) → SaveSystem.load_game()
    │  reads user://savegame.json → JSON.parse → Dictionary
    │  if cloud timestamp newer: fetch from FirebaseAdapter
    │  populates GameState
    ▼
TimeManager → offline_delta = now - last_seen_timestamp
    │  validates: offline_delta <= MAX_OFFLINE_HOURS (anti-cheat cap)
    ▼
IdleProductionSystem.calculate_offline_earnings(offline_delta)
    │  applies tiered multiplier → EconomyManager.add() per currency
    ▼
SceneManager.goto_scene("FarmMap") → main game starts
```

- Local file is authoritative for single-player state; Firebase is backup + sync.
- Offline delta is capped by TimeManager for anti-cheat (not trusted from client alone).
- Firebase is non-blocking — app runs without network; syncs opportunistically.

### Scenario 4: Initialisation Order

```
Autoloads (Project Settings — registered in this exact order):
  1. EventBus          ← first; everything emits to it
  2. TimeManager       ← clock starts before any tick consumer
  3. EconomyManager    ← exists before any spend/earn call
  4. GameState         ← populated before Core reads from it
  5. SaveSystem        ← loads GameState on boot
  6. SceneManager      ← last; launches first scene after state is ready

In-scene (_ready order):
  7. RabbitSystem      ← reads GameState.rabbits[]
  8. GeneticsSystem    ← preloads balance.json
  9. HabitatSystem     ← reads GameState.hutches[]
  10. IdleProductionSystem  ← reads all above; runs first tick
  11. Feature systems  ← each reads from Core on _ready()
  12. Presentation     ← subscribes to EventBus; renders first frame
```

- Autoloads 1–6 registered in Project Settings in this order — no exceptions.
- Platform adapters (FirebaseAdapter etc.) initialise lazily on first call.

---

## API Boundaries

### Cross-Cutting Invariants

1. **No upward calls**: Presentation never calls Feature or Core directly — EventBus signals only.
2. **EconomyManager is the sole ledger**: No system stores currency amounts except EconomyManager.
3. **RabbitData mutation**: Only RabbitSystem methods mutate RabbitData resources. Other systems read only.
4. **Firebase is optional at runtime**: Every FirebaseAdapter call has a local fallback. Game is fully playable offline.
5. **All balance values from `assets/data/balance.json`**: No magic numbers in any contract. Systems load balance data at `_ready()`.

### FOUNDATION

```gdscript
# EventBus (autoload) — all cross-system signals live here only
extends Node
signal rabbit_born(rabbit_id: String)
signal rabbit_matured(rabbit_id: String, new_stage: RabbitStage)
signal rabbit_stat_changed(rabbit_id: String)
signal rabbit_died(rabbit_id: String)
signal currency_changed(currency: CurrencyType, new_balance: int, delta: int)
signal production_ticked(earnings: Dictionary)
signal breed_requested(parent_a_id: String, parent_b_id: String)
signal breeding_completed(child_id: String)
signal hutch_dirtied(hutch_id: String)
signal hutch_upgraded(hutch_id: String, new_level: int)
signal expedition_completed(slot_id: int, loot: LootResult)
signal save_requested()
signal save_synced()
signal nav_tab_pressed(tab: NavTab)
signal notification_requested(text: String)
```

```gdscript
# EconomyManager (autoload)
# Invariant: balances always >= 0. spend() returns false if insufficient.
# Callers MUST check return value of spend() before consuming the item.
enum CurrencyType { CARROT_COIN, STAR_DUST, CRYSTAL_GEM, GENE_FRAGMENT }
func add(currency: CurrencyType, amount: int) -> void
func spend(currency: CurrencyType, amount: int) -> bool
func get_balance(currency: CurrencyType) -> int
func get_all_balances() -> Dictionary
```

```gdscript
# TimeManager (autoload)
enum Season { SPRING, SUMMER, AUTUMN, WINTER }
signal tick(delta: float)  # fires every 1 second
func get_offline_delta() -> float
func get_current_season() -> Season
func get_ingame_day() -> int
func get_unix_now() -> int
func mark_session_start() -> void  # call on boot after SaveSystem loads
```

```gdscript
# SaveSystem (autoload)
# Invariant: save_game() always writes local file first, cloud second.
# load_game() prefers the newer timestamp between local and cloud.
func save_game() -> void
func load_game() -> bool           # false = no save found (new game)
func sync_to_cloud() -> void
func get_last_save_timestamp() -> int
```

### CORE

```gdscript
# RabbitSystem
# Invariant: rabbit_id is a UUID, unique forever (never reused).
# RabbitData is a Resource — callers get a reference, never a copy.
# To mutate a rabbit, call RabbitSystem methods — never write RabbitData directly.
func get_rabbit(rabbit_id: String) -> RabbitData        # null if not found
func get_all_rabbits() -> Array[RabbitData]
func get_rabbits_in_hutch(hutch_id: String) -> Array[RabbitData]
func add_rabbit(data: RabbitData) -> String             # returns assigned rabbit_id
func remove_rabbit(rabbit_id: String) -> void
func feed_rabbit(rabbit_id: String, food: FoodItem) -> bool
func get_aura_bonus(hutch_id: String) -> AuraBonus
```

```gdscript
# RabbitData (Resource)
class_name RabbitData extends Resource
enum RabbitStage { BABY, JUVENILE, ADULT, ELDER, SANCTUARY }
var rabbit_id: String
var name: String
var stage: RabbitStage
var genome: Genome          # 6 GeneSlot resources
var hunger: float           # 0–100
var happiness: float        # 0–100
var health: float           # 0–100
var growth_progress: float  # 0–100
var birth_timestamp: int
var parent_a_id: String
var parent_b_id: String
var hutch_id: String
```

```gdscript
# GeneticsSystem
# Invariant: breed() does not modify either parent. Returns new RabbitData.
# get_breed_preview() is pure — no RNG, probability tables only.
func breed(parent_a: RabbitData, parent_b: RabbitData) -> RabbitData
func get_breed_preview(parent_a: RabbitData, parent_b: RabbitData) -> BreedPreview
func get_trait_effects(rabbit: RabbitData) -> TraitEffects
func get_rarity(rabbit: RabbitData) -> RarityTier
# BreedPreview fields: color_probabilities: Dictionary, trait_probabilities: Dictionary,
#                      mutation_chance: float, estimated_rarity: RarityTier
```

```gdscript
# IdleProductionSystem
# Invariant: calculate_offline_earnings() is pure (no side effects).
# Callers pass result to EconomyManager.add() themselves.
func get_tick_earnings() -> EarningsReport
func calculate_offline_earnings(delta_seconds: float) -> EarningsReport
# EarningsReport fields: carrot_coin: int, star_dust: int,
#                        applied_multiplier: float, source_breakdown: Array
```

### FEATURE (selected)

```gdscript
# HabitatSystem
func get_hutch(hutch_id: String) -> HutchData
func get_all_hutches() -> Array[HutchData]
func assign_rabbit(rabbit_id: String, hutch_id: String) -> bool  # false = full
func unassign_rabbit(rabbit_id: String) -> void
func get_capacity(hutch_id: String) -> int
func get_current_count(hutch_id: String) -> int
func get_hutch_bonuses(hutch_id: String) -> HutchBonus
func upgrade_hutch(hutch_id: String) -> bool
func clean_hutch(hutch_id: String) -> void
```

```gdscript
# GuildSystem
# Invariant: all writes are optimistic-local + Firebase-confirmed.
# On Firebase failure, local state is rolled back and error emitted via EventBus.
func get_guild_info() -> GuildInfo                        # null if not in guild
func submit_contribution(rabbit_id: String) -> void
func attack_boss(damage: int) -> void
func list_item(rabbit_id: String, price_cc: int) -> bool
func buy_listing(listing_id: String) -> bool
func get_leaderboard() -> Array[GuildMember]
```

```gdscript
# ExpeditionSystem
func get_zones() -> Array[ExpeditionZone]
func can_start(zone_id: String, rabbit_ids: Array[String]) -> ExpeditionCheck
func start_expedition(zone_id: String, rabbit_ids: Array[String]) -> bool
func get_active_expeditions() -> Array[ExpeditionSlot]
func is_ready_to_collect(slot_id: int) -> bool
func collect(slot_id: int) -> LootResult
```

### PRESENTATION

```gdscript
# FarmMapUI
# Invariant: never mutates game state. All player actions → EventBus signals.
# rabbit tapped → EventBus.rabbit_tapped(rabbit_id)
# hutch tapped  → EventBus.hutch_tapped(hutch_id)

# HUD
func show_notification(text: String, duration_sec: float = 3.0) -> void
# Currency displays auto-update via EventBus.currency_changed.
# Nav taps → EventBus.nav_tab_pressed(tab) — never calls SceneManager directly.

# AccessibilitySystem
enum ColorblindMode { NONE, DEUTERANOPIA, PROTANOPIA, TRITANOPIA }
func set_font_scale(scale: float) -> void       # clamped 0.8–2.0
func set_colorblind_mode(mode: ColorblindMode) -> void
func set_simplified_mode(enabled: bool) -> void
func apply_settings() -> void
# Settings persisted to GameState.settings automatically on change.
```

---

## ADR Audit

### Existing ADR Quality Check

No formal ADR documents exist yet. Four decisions are recorded informally in
`.claude/docs/technical-preferences.md` (ADR-001 through ADR-004) but none have
engine compatibility sections, version records, or GDD linkage. All four must be
formalised before coding starts.

| ADR | Engine Compat | Version | GDD Linkage | Conflicts | Valid |
|-----|--------------|---------|-------------|-----------|-------|
| ADR-001: GDScript over C# | ❌ | ❌ | ❌ | None | ⚠️ informal only |
| ADR-002: JSON config for balance data | ❌ | ❌ | ❌ | None | ⚠️ informal only |
| ADR-003: Autoload pattern for global systems | ❌ | ❌ | ❌ | None | ⚠️ informal only |
| ADR-004: Signal-based inter-system communication | ❌ | ❌ | ❌ | None | ⚠️ informal only |

### Traceability Coverage

57 / 60 requirements covered. 3 gaps:

| Req ID | Requirement | Status |
|--------|-------------|--------|
| TR-puzzle-003 | Gene Journal shareable with friends/guild | ❌ GAP — no sharing mechanism decided |
| TR-economy-002 | Rabbit sale value formula | ❌ GAP — no module owns valuation computation |
| TR-idle-004 | Item-based offline modifiers (Alarm Bunny, Auto-Feeder) | ❌ GAP — no item inventory module decided |

---

## Required ADRs

### Must have before any coding starts

1. `"Autoload boot sequence and GameState ownership"` → TR-save-001, TR-idle-002, TR-economy-001
2. `"GDScript over C# for Godot 4.6"` → formalises ADR-001
3. `"Signal-based inter-system communication via EventBus"` → formalises ADR-004
4. `"JSON balance data — no hardcoded values"` → formalises ADR-002
5. `"RabbitData as Resource type — immutable from outside RabbitSystem"` → TR-rabbit-001 through TR-rabbit-005, TR-genetics-001
6. `"Genetics allele model and mutation algorithm"` → TR-genetics-001 through TR-genetics-007
7. `"Idle production and offline catch-up calculation"` → TR-idle-001 through TR-idle-003
8. `"Firebase as async-optional backend — local-first save"` → TR-save-002, TR-save-003, TR-net-001 through TR-net-003

### Should have before the relevant system is built

9. `"Rabbit sale value formula and valuation ownership"` → TR-economy-002 (Gap 2)
10. `"Item inventory system and offline modifier application"` → TR-idle-004 (Gap 3)
11. `"Guild boss raid as async co-op — 7-day contribution window"` → TR-guild-003
12. `"Gene Journal sharing mechanism"` → TR-puzzle-003 (Gap 1)
13. `"Scene management and async scene loading strategy"` → SceneManager
14. `"Platform adapter pattern for IAP, ads, and notifications"` → TR-economy-004, TR-economy-005

### Can defer to implementation

15. `"Colorblind mode implementation — shader vs palette swap"` → TR-ui-007
16. `"Mini-game isolation strategy — sub-scenes vs separate scenes"` → TR-minigame-001

---

## Architecture Principles

These five principles govern every technical decision for this project. When in
doubt, apply them in order — earlier principles override later ones.

**1. Local-first, cloud-optional.**
The game must be fully playable with no network connection. Firebase is a sync
layer, never a dependency. Every system that touches Firebase has a local fallback.
Reason: mobile players have unreliable connectivity; a network failure must never
block a play session.

**2. Data down, events up.**
Data flows downward through layers (Foundation → Core → Feature → Presentation).
Cross-layer communication from lower layers to higher layers uses EventBus signals
only — never direct node references or upward method calls. This keeps systems
testable in isolation and prevents circular dependencies.

**3. RabbitData is sacred.**
The genetics and rabbit systems are the core differentiator of the game. RabbitData
resources are never mutated by anything other than RabbitSystem methods. All
balance values that affect rabbits come from balance.json, never from hardcoded
constants. This makes genetics testable, tunable, and auditable.

**4. Idle math must be deterministic and auditable.**
Offline production calculations must produce the same result given the same inputs
every time, regardless of when they run. No system clock drift, no floating-point
variance between sessions. Offline delta is capped and server-validated to prevent
exploitation. EarningsReport always includes a source_breakdown for player-facing
transparency ("You earned 230 CC from 3 hutches over 6 hours").

**5. Presentation never decides.**
UI scenes contain zero game logic. They read state and dispatch events. If a
Presentation module is ever seen calling a Core or Feature method directly (other
than read-only getters), that is a bug. Mini-games are the only exception — they
own their own internal loop, but reward dispatch still goes through EventBus.

---

## Open Questions

All session questions resolved:
- Firebase vs PlayFab: **resolved — Firebase** (confirmed by GDD section 11)
- Guild Boss Raid real-time vs async: **resolved — async** (7-day contribution window)

Remaining open decisions (covered by Required ADRs above):
- Gene Journal sharing mechanism — decide before GenePuzzleSystem is built
- Rabbit sale value formula ownership — decide before ShopUI is built
- Item inventory system scope — decide before PrestigeSystem and offline modifiers are built

