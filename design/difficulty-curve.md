# Difficulty Curve — Bunny Farm Idle

**Version**: 1.0
**Date**: 2026-05-19
**Status**: Draft — pending design-review

---

## 1. Overview

This document defines the pacing and progression design for Bunny Farm Idle. It specifies
the target emotional arc across five time brackets (first hour, first session, day 1,
week 1, first prestige), names the concrete milestone moments where the game must feel
rewarding to retain players, links each pacing target to the `assets/data/balance.json`
tuning knobs that control it, defines what gets harder as progression advances, and
provides warning signs that indicate the curve needs recalibration. The document is the
primary reference for tuning decisions made by the systems designer and economy designer.

The intended experience follows the MDA model: target Aesthetics are **Discovery** (what
new rabbit genetics emerge?) and **Expression** (the player's unique gene chain becomes a
creative signature). These aesthetics require a curve that drip-feeds mechanical depth
without front-loading overwhelm, then sustains long-term investment through compounding
genetic complexity and prestige loop replayability.

---

## 2. Player Fantasy

The player should feel like a scientist-farmer uncovering hidden natural laws. Each time
bracket has its own emotional peak:

- **First hour**: Warmth and delight — "my farm is alive and growing."
- **First session (30–90 min)**: Curiosity — "what do I get if I combine these two?"
- **Day 1**: Anticipation — counting down to the first breeding result.
- **Week 1**: Strategic satisfaction — reading a breeding outcome and knowing exactly why
  it happened.
- **First prestige**: Earned triumph — "I built this; I understand it well enough to reset
  and do it faster."

This arc maps to Csikszentmihalyi's flow channel: mechanical complexity is introduced in
isolated chunks (each new system debuts alone before being combined with others), and
difficulty scales through the genetic depth tree rather than through resource walls or
time gates that feel arbitrary.

---

## 3. Detailed Rules

### 3.1 Time Brackets and Checkpoints

The following table defines what the player must have achieved by each bracket, what
milestone moment defines that bracket, and what a failure state looks like.

| Bracket | Target Checkpoint | Milestone Moment | Failure State (player churns) |
|---------|-------------------|------------------|-------------------------------|
| First 10 min | Tutorial complete; 4 starter rabbits alive; first CC earned | First coin collected from idle production | Player does not understand what to tap next |
| First hour | Tier-2 hutch purchased (500 CC); 6–8 rabbits | "I can afford the upgrade" click | Player has coin but does not know upgrades exist; OR player cannot earn 500 CC in <90 min |
| First session | First breeding pair selected; first offspring born | Offspring card revealed with gene display | Player reaches breeding screen and is confused by the UI; OR gestation timer feels too long |
| Day 1 (2–4 sessions) | First Uncommon rabbit bred; Expedition Near Forest completed at least once | "I got something unusual" reveal moment | Player completes 10 breeding cycles and sees only Common results — perceived luck failure |
| Week 1 (daily sessions) | First Rare rabbit bred; Expedition East Meadow unlocked; Trait synergy discovered | First Rare rabbit card flip | Rare rabbit probability (10%) produces no Rare in 20+ cycles — requires pity timer |
| First prestige (weeks 3–8) | ≥1 Legendary rabbit; 80% Collection; prestige executed | Prestige confirm screen with permanent bonus preview | Player stalls at Late Game with no clear path to Legendary; Guild Boss Raid feels inaccessible solo |

### 3.2 Session Structure Targets

Each play session should deliver a complete meso-loop (5–15 min goal-reward cycle) and
at least one macro-loop milestone (reason to return). Target session durations match the
GDD casual/hardcore split:

- **Casual session (5–20 min)**: Collect idle CC, feed rabbits, plant one farm plot, check
  breeding result if ready. Natural stop: "my rabbits are fed, breeding timer running."
- **Engaged session (30–90 min)**: Casual tasks plus one expedition dispatch, one
  breeding decision with Gene Preview inspection, one hutch upgrade if CC threshold met.
  Natural stop: "expedition dispatched, breeding started, nothing to do for 2–4 hours."
- **Deep session (1–2 hr)**: All of the above plus Gene Journal review, trait synergy
  experimentation, Merchant Caravan interaction. Natural stop: longest pending timer.

### 3.3 Difficulty Scaling Rules

Difficulty in Bunny Farm Idle is not combat difficulty — it is **decision complexity**.
The game gets harder through the following mechanisms:

**What scales upward as the player progresses:**
1. **Gene depth**: Early game has 6 gene slots with 2 alleles each, mostly common
   variations. Mid game introduces Trait tier-2 combinations. Late game requires
   deliberate 3-to-4-generation planning to stack Tier-3 traits and hit specific combos.
2. **Hutch economics**: Each hutch tier costs 10× the previous tier, but capacity
   grows linearly. The player must earn efficiency gains from genetics to maintain
   purchasing velocity.
3. **Expedition requirements**: Each zone adds a qualitative gate (specific trait
   required, specific item required, prestige required) rather than just a coin cost.
   Players cannot brute-force expeditions with CC — they need the right rabbits.
4. **Collection completeness pressure**: The prestige gate at 80% Collection requires
   deliberate variety-seeking. Players who only breed toward one rarity type will stall
   below the prestige threshold.
5. **Opportunity cost**: In Late Game, every rabbit in a hutch is either an expedition
   candidate, a breeding participant, or a prestige candidate. Slot pressure creates
   genuine trade-offs that did not exist in Early Game.

**What does NOT get harder:**
- Core feeding and care loop — routine tasks must stay frictionless
- Gene Preview UI — always available before every breeding decision
- Offline production — hard cap at 40% over 12h prevents over-grinding but does not
  punish casual players for sleeping

### 3.4 Fun Cliff Moments (Must-Deliver Beats)

These are the moments where the game must deliver clear emotional reward or player
retention collapses. Each cliff has a design requirement:

**Cliff 1 — First Offspring (session 1)**
Requirement: The offspring reveal animation must fire before the gestation timer
makes the player feel abandoned. Gestation base is 4 hours (14,400 seconds), which
means first breeding cannot happen in session 1 unless the player is given a starter
breeding pair or a reduced-timer tutorial breed.
Design resolution: Tutorial provides one pre-paired adult couple with a 5-minute
"introduction breed" at 90% reduced timer. The first real 4-hour breed begins after
the player understands the reveal mechanic.

**Cliff 2 — First Hutch Upgrade (hour 1)**
Requirement: The player must be able to reach 500 CC within 60–90 minutes of idle
play from session start. At 4 rabbits × 0.05 CC/s the rate is 0.20 CC/s = 720 CC/hour.
The 500 CC gate is reachable in ~42 minutes with zero feeding bonuses. With feeding
bonuses (+10–15% production from cleanliness) the window tightens to 35–38 minutes.
This cliff must feel earned but not grinding.

**Cliff 3 — First Rare Rabbit (day 1–2)**
Requirement: With a 10% Rare probability per breeding outcome and a ~4-hour gestation,
a player doing 2 sessions/day executes roughly 1–2 breeds per session = 2–4 breeds/day.
Without a pity system, the expected 10 cycles to get one Rare takes 5 days at 2
breeds/day — this is too long. Design resolution: pity timer triggers at cycle 8 with a
guaranteed Uncommon outcome; cycle 15 guarantees Rare if none has appeared. See Section 4.

**Cliff 4 — Trait Synergy Discovery (week 1)**
Requirement: The player must organically discover one trait synergy combination without
reading external documentation. Design resolution: when two synergy-eligible traits
appear in the same offspring, display a brief "Synergy Discovered!" toast with a
+bonus callout. This beat must happen before the player is deep enough in Late Game
that it feels trivial.

**Cliff 5 — Prestige Decision Point (weeks 3–8)**
Requirement: The prestige gate screen must show the permanent bonus preview with a
concrete projected time-save (e.g., "Prestige 1 grants Growth Rate +15% — your
4-hour breed becomes 3.4 hours"). The player must feel the value before clicking
confirm. If the prestige decision is presented as a pure reset with vague "you'll
be stronger," churn spikes here.

---

## 4. Formulas

### 4.1 Idle Production Rate

```
CC_per_second = rabbits_alive × base_cc_per_rabbit_per_second
                × cleanliness_multiplier
                × season_multiplier
                × prestige_bonus_multiplier
```

**Variable definitions:**
- `rabbits_alive` — count of Adult rabbits in all hutches (Baby and Juvenile do not
  produce). Range: 0–24 (max Tier-5 hutch capacity).
- `base_cc_per_rabbit_per_second` — 0.05 (balance.json key:
  `idle_production.base_cc_per_rabbit_per_second`). Range: 0.01–0.20.
- `cleanliness_multiplier` — 1.2 if cleanliness ≥ 0.75; 1.0 if 0.40–0.74;
  0.8 if < 0.40 (balance.json: `habitat.cleanliness_thresholds`).
- `season_multiplier` — 1.5 in Autumn; 1.0 in Spring, Summer; 1.0 base in Winter
  (Winter applies to offline only). Source: `season.multipliers`.
- `prestige_bonus_multiplier` — 1.0 + `prestige_bonuses_per_level[N].offline_production_bonus`.
  Range: 1.0 (no prestige) to 1.25 (prestige 5).

**Example — early game (4 Adult rabbits, clean hutch, Spring):**
```
CC/s = 4 × 0.05 × 1.2 × 1.0 × 1.0 = 0.24 CC/s = 864 CC/hour
```

**Example — mid game (12 Adult rabbits, dirty hutch, Autumn):**
```
CC/s = 12 × 0.05 × 0.8 × 1.5 × 1.0 = 0.72 CC/s = 2,592 CC/hour
```

### 4.2 Time to First Hutch Upgrade (Tier 1 → Tier 2)

```
T_upgrade = hutch_cost / CC_per_second / 3600   (in hours)
```

**Base case (4 rabbits, clean hutch, no bonuses):**
```
CC/s = 4 × 0.05 × 1.2 = 0.24 CC/s
T_upgrade = 500 / 0.24 / 3600 = 0.579 hours ≈ 35 minutes
```

**Worst case (4 rabbits, dirty hutch, not yet cleaned after tutorial):**
```
CC/s = 4 × 0.05 × 0.8 = 0.16 CC/s
T_upgrade = 500 / 0.16 / 3600 = 0.868 hours ≈ 52 minutes
```

Target range: 35–55 minutes for first upgrade. Values outside this range require
adjustment to `base_cc_per_rabbit_per_second` or `habitat.cleanliness_thresholds`.

### 4.3 Time to First Rare Rabbit (Breeding Probability)

Expected breeds to first Rare rabbit without pity:
```
E[breeds] = 1 / P(Rare) = 1 / 0.10 = 10 cycles
```

Each cycle requires two Adult rabbits and 4-hour gestation. At 2 breeds/day:
```
E[days] = 10 / 2 = 5 days
```

This exceeds the Day 1–2 fun cliff target. Pity system corrects this:

```
pity_threshold_uncommon = 8   (guaranteed Uncommon if none in 8 cycles)
pity_threshold_rare = 15      (guaranteed Rare if none in 15 cycles)
```

With pity, worst-case first Rare = 15 cycles = 7.5 days at 2/day. Recommended
target: 5–7 days worst case. Tuning lever: reduce `pity_threshold_rare` to 10 or
increase `genetics.rarity_weights.rare` to 0.15.

### 4.4 Cumulative Hutch Cost Progression

| Tier | Cost (CC) | Cumulative (CC) | Approximate earn time from Tier N-1 capacity |
|------|-----------|-----------------|----------------------------------------------|
| 1 (Chuong Go) | 0 (starter) | 0 | — |
| 2 (Chuong Gach) | 500 | 500 | ~35–55 min (4 Adult rabbits) |
| 3 (Chuong Thuy Tinh) | 2,000 | 2,500 | ~2–3 hours (8 Adult rabbits, clean) |
| 4 (Chuong Sinh Thai) | 10,000 | 12,500 | ~1.5–2 days (12 Adult rabbits) |
| 5 (Chuong Vu Tru) | Prestige-gated | — | Prestige 5 required |

Note: GDD §3.4 lists Tier-4 hutch unlock as "10,000 CC + blueprint." This document
uses 10,000 CC as the numeric gate; the blueprint requirement is a qualitative gate
handled by the expedition system.

### 4.5 Prestige Gate Timeline

```
T_legendary = E[breeds_for_legendary] × gestation_hours / breeds_per_day
```

Legendary rarity weight = 0.01 (1%). Without assistance:
```
E[breeds_for_legendary] = 1 / 0.01 = 100 cycles
breeds_per_day (2 hutches, active player) ≈ 4
T_legendary = 100 / 4 = 25 days
```

With Legendary Blood trait stacking (+0.5% per trait) and Tier-5 hutch Legendary
bonus (+0.1%), effective probability approaches 0.016–0.020, reducing:
```
T_legendary_optimized = 1 / 0.018 / 4 ≈ 14 days
```

This aligns with the GDD target of 1–2 weeks with active optimization. The
Collection requirement (80% of species discovered) is the parallel gate. Players
who rush Legendary breeding without variety will hit the Collection wall first,
encouraging holistic play.

### 4.6 Offline Catch-Up Calculation

```
CC_offline = rabbits_alive × base_cc_per_rabbit_per_second
             × offline_multiplier(T_offline)
             × season_offline_mult
             × min(T_offline, max_offline_seconds)
```

**Offline multipliers** (balance.json `idle_production`):
- Background: 0.75
- < 4h offline: 0.60
- 4–12h offline: 0.50
- > 12h offline: 0.40
- max_offline_hours: 72 (cap prevents runaway earnings)

**Example — 8h offline, 12 Adult rabbits, no season bonus:**
```
CC = 12 × 0.05 × 0.50 × 1.0 × (8 × 3600) = 8,640 CC
```

**Example — 8h offline in Winter (+30% offline bonus):**
```
CC = 12 × 0.05 × 0.50 × 1.3 × (8 × 3600) = 11,232 CC
```

---

## 5. Edge Cases

### 5.1 Player with Zero Adult Rabbits
If all rabbits are Baby or Juvenile, CC production is 0. This can happen if a player
loses all adults (death from starvation) or sells all adults. The game must not present
a dead-state: ensure the starter rabbit grant cannot be sold (mark as `is_starter: true`
in RabbitData). If production is 0 for > 5 minutes, display a hint toast: "Feed your
rabbits to keep them healthy and producing Carrot Coins."

### 5.2 Player Who Never Feeds Rabbits (AFK Stall)
Hunger decays over time. If Hunger reaches 0, Health decays at 1/minute (GDD §3.1).
If Health reaches 0, the rabbit dies. This creates a negative experience for players
returning after a multi-day absence. Resolution: Auto-Feeder item (obtainable in first
expedition) prevents death by stalling Health decay at 10 minimum. The game should
never kill all of a player's rabbits in a single offline session; Health floor at 1 for
offline periods unless the player explicitly has no Auto-Feeder and was gone > 48h.

### 5.3 Pity Counter Reset on Prestige
The pity counter for breeding rarity tracks per-account, not per-prestige cycle. A
prestige reset must NOT clear the pity counter — doing so would make prestige feel
punishing for players close to a Rare or Legendary trigger.

### 5.4 Season Transition During Long Offline Period
If the player is offline for 7+ real-time hours and balance.json sets
`season.seconds_per_day` to 3,600 (1 in-game day = 1 real hour), a 7-hour offline
period spans an entire season. The offline CC calculation must use the season multiplier
active at the moment of the last login (the start of offline), not the season at return.
This prevents exploiting season transitions by logging in at season change boundaries.

### 5.5 Tier-5 Hutch Capacity and Rabbit Count
Max visible rabbits per scene is 24 (technical preference ceiling). Tier-5 hutch holds
24 rabbits. The balance.json `habitat.capacity_by_level` array is currently `[4, 8, 12,
16, 20, 24]` — the index-5 value of 24 matches the scene cap. If the designer wants to
add a Tier-6 hutch above 24, this requires a rendering architecture review; do not
simply increment the array without coordinating with the lead programmer.

### 5.6 Collection Gate Below 80% at Prestige Eligibility
If the player has a Legendary rabbit but only 60% Collection, the prestige gate is
blocked. The UI must show both conditions (Legendary rabbit: check / Collection 80%:
X of Y species) and highlight the Collection requirement clearly. The game should
surface the missing species categories to the player, not just the percentage, to give
actionable guidance.

### 5.7 Breeding With No Available Adult Pair
If a player has only one Adult rabbit (the other is on expedition, dead, or not yet
adult), the breed button must be disabled with a clear reason label: "Need 2 Adults to
breed — your second rabbit is on expedition." This prevents confusion on a mechanic the
player may have just unlocked.

### 5.8 Degenerate Strategy: Selling All Rabbits for One-Time CC
A player could sell all rabbits for a lump sum of CC, buy a higher hutch tier, then
have no rabbits to fill it. The design handles this through the starter rabbit
protection (`is_starter`) and through hutch upgrade cost curves: Tier-3 costs 2,000 CC
and requires 8 rabbits to be productive, so a player who sells 8 rabbits to reach 2,000
CC nets nothing — they immediately need to reacquire rabbits. No intervention required
beyond UI guidance.

---

## 6. Dependencies

This document directly governs the tuning of:

| Dependent System | Direction | Contract |
|-----------------|-----------|----------|
| `IdleProductionSystem` (src/core/idle_production_system.gd) | Reads from balance.json; pacing document defines target outputs | This doc sets time-bracket targets; IdleProductionSystem formula delivers them |
| `GeneticsSystem` (src/core/genetics_system.gd) | Pity counter logic specified here; rarity weights in balance.json | Pity thresholds defined in Tuning Knobs §7; genetics system must implement counter and reset on pity trigger |
| `HabitatSystem` (src/core/habitat_system.gd) | Hutch tier costs and capacity affect the Tier-2 upgrade timing formula | Hutch cost curve (§4.4) must match values in balance.json `habitat.capacity_by_level` |
| `SeasonSystem` (src/core/season_system.gd) | Season multipliers feed into offline CC formula | Autumn production_mult and Winter offline_mult are pacing levers; changes here must update §4.6 |
| `FoodSystem` (src/core/food_system.gd) | Feeding behavior affects cleanliness and thus cleanliness_multiplier | Auto-Feeder item behavior (edge case §5.2) requires FoodSystem to implement Health floor |
| `design/gdd/bunny-farm-idle-master.md` | Source of record for progression targets, hutch tiers, expedition zones | This document must not contradict §3.4, §3.6, §4, §5 of the master GDD |
| `design/gdd/systems-index.md` | Systems index lists this document | Update systems-index when this document status changes |
| `assets/data/balance.json` | All numeric tuning knobs reference specific JSON keys | Every knob in §7 maps to an exact balance.json path |

---

## 7. Tuning Knobs

All knobs map to `assets/data/balance.json` unless marked (design doc only).

### Feel Knobs (playtest-driven)

| Knob | JSON Path | Current Value | Safe Range | Gameplay Effect |
|------|-----------|---------------|------------|-----------------|
| Tutorial breed timer reduction | (design only — not yet in balance.json) | 90% reduction | 80–95% | First offspring reveal speed; too fast = no tension; too slow = session ends without reveal |
| Breed reveal animation duration | `ui.breed_reveal_duration` | 1.5 s | 0.8–3.0 s | Emotional impact of offspring card flip |
| Offline return toast display | (design only) | 5 s | 3–8 s | How long the "you earned X while away" message shows |

### Curve Knobs (math-model-driven)

| Knob | JSON Path | Current Value | Safe Range | Gameplay Effect |
|------|-----------|---------------|------------|-----------------|
| Base CC per rabbit per second | `idle_production.base_cc_per_rabbit_per_second` | 0.05 | 0.02–0.12 | Controls Tier-2 hutch time (§4.2); primary pacing lever for early game |
| Rare rarity weight | `genetics.rarity_weights.rare` | 0.10 | 0.06–0.18 | Probability of Rare outcome per breed; affects Day 1–2 cliff |
| Legendary rarity weight | `genetics.rarity_weights.legendary` | 0.01 | 0.005–0.025 | Prestige gate timeline (§4.5); do not exceed 0.025 without reviewing prestige balance |
| Pity threshold — Uncommon | (design doc — not yet in balance.json) | 8 cycles | 5–12 | Guarantees first Uncommon; lower = faster gratification |
| Pity threshold — Rare | (design doc — not yet in balance.json) | 15 cycles | 10–25 | Worst-case path to first Rare; must fire before player churns |
| Autumn production multiplier | `season.multipliers.autumn.production_mult` | 1.5 | 1.1–2.0 | Harvest season CC burst; affects Day 7 income spike |
| Winter offline multiplier | `season.multipliers.winter.offline_mult` | 1.3 | 1.1–1.8 | Rewards overnight players; too high narrows summer/spring relevance |
| Max offline hours | `idle_production.max_offline_hours` | 72 | 24–96 | Soft cap on offline farming; lower punishes legitimate multi-day absence |

### Gate Knobs (session-length-driven)

| Knob | JSON Path | Current Value | Safe Range | Gameplay Effect |
|------|-----------|---------------|------------|-----------------|
| Gestation base time | (design doc — not yet in balance.json; currently implied by RabbitSystem lifecycle threshold) | 14,400 s (4h) | 7,200–28,800 s | Breeding cycle length; governs session return cadence |
| Tier-2 hutch cost | (balance.json hutch cost not yet defined — needs hutch_costs array) | 500 CC | 300–800 CC | First upgrade gate; must be reachable in session 1 |
| Prestige Collection requirement | (design doc only) | 80% | 65–90% | Breadth requirement for prestige; lower = faster prestige, less variety incentive |
| Near Forest expedition duration | (design doc — not yet in balance.json) | 1,800 s (30 min) | 900–3,600 s | First expedition return; must fire within a single session |

**Note on missing balance.json keys**: Several knobs listed here (gestation, hutch costs,
pity thresholds) are currently specified in the GDD only and have no corresponding
balance.json entries. These must be added before Sprint 04 implementation of Breeding
and Expedition systems. The systems designer should create a `breeding` and `hutch_costs`
namespace in balance.json before those epics begin.

---

## 8. Acceptance Criteria

### Functional Criteria (automated or smoke-check verifiable)

- **AC-1**: With 4 starter rabbits, clean hutch, and no bonuses, a player accumulates
  500 CC within 40 minutes of idle production. Verify by running IdleProductionSystem
  for 2,400 ticks (40 min at 1/s), confirming `EconomyManager.balance(CC) >= 500`.
- **AC-2**: The Rare pity counter increments on each breed cycle and fires a guaranteed
  Rare outcome at exactly cycle 15 if no Rare has appeared. Verify via GeneticsSystem
  unit test with seeded RNG set to never produce Rare naturally.
- **AC-3**: Offline CC earnings for an 8-hour session with 12 Adult rabbits fall within
  8,000–9,200 CC (no season bonus). Verify via `idle_production_system.calculate_offline_earnings()`.
- **AC-4**: Season multiplier transitions do not apply retroactively to offline earnings
  that began before the season changed. Verify via integration test spanning a season
  boundary.
- **AC-5**: Health floor at 1 applies to offline periods when rabbit is without food,
  preventing total rabbit death during offline sessions up to 72 hours. Verify via
  RabbitSystem unit test with hunger decay disabled and health decay running over
  simulated 72-hour period.
- **AC-6**: Hutch capacity at each tier matches `habitat.capacity_by_level` array:
  indices 0–5 = [4, 8, 12, 16, 20, 24]. Verify via HabitatSystem unit test.

### Experiential Criteria (playtest validation)

- **AC-7**: In a 3-person playtest, all 3 players reach 500 CC and purchase the Tier-2
  hutch within 60 minutes of their first session without hints beyond the tutorial.
  Target: 3/3 players succeed. Acceptable: 2/3 with observer notes on friction point.
- **AC-8**: In a 3-person playtest, all 3 players trigger at least one breeding and
  understand what the Gene Preview is showing before confirming breed. Target: 3/3
  players verbalize understanding unprompted ("I can see the chances"). Acceptable: 2/3.
- **AC-9**: In a 5-session longitudinal playtest (1 player, 5 sessions over 3 days),
  the player breeds their first Rare rabbit by session 5. If not, record cycle count
  and compare to pity threshold — verify pity is triggering correctly or tighten
  `pity_threshold_rare`.
- **AC-10**: Playtest observers must not witness a player hitting a "now what?" idle
  state (no pending timers, no available actions, no visible goal) in the first 3
  sessions. If this state is observed, the tutorial hint system or first expedition
  unlock timing needs revision.
- **AC-11**: At the prestige gate, a playtest player can articulate the permanent bonus
  they will receive before clicking confirm, without reading external documentation.
  The prestige confirm screen must communicate the bonus in plain language.

---

*End of document.*
*Related files: `assets/data/balance.json`, `design/gdd/bunny-farm-idle-master.md`,
`src/core/idle_production_system.gd`, `src/core/genetics_system.gd`*
