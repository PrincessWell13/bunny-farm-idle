# Art Bible — Bunny Farm Idle

**Version**: 1.0
**Date**: 2026-05-18
**Art Director Sign-Off (AD-ART-BIBLE)**: Lean mode — skipped
**Status**: Complete — all 9 sections

---

## Table of Contents

1. [Visual Identity Statement](#section-1-visual-identity-statement)
2. [Mood & Atmosphere](#section-2-mood--atmosphere)
3. [Shape Language](#section-3-shape-language)
4. [Color System](#section-4-color-system)
5. [Character Design Direction](#section-5-character-design-direction)
6. [Environment Design Language](#section-6-environment-design-language)
7. [UI/HUD Visual Direction](#section-7-uihud-visual-direction)
8. [Asset Standards](#section-8-asset-standards)
9. [Reference Direction](#section-9-reference-direction)

---

### Section 1: Visual Identity Statement

#### One-Line Visual Rule

**"Every pixel must feel like it was grown, not manufactured — organic warmth over geometric precision, except where science demands clarity."**

This rule resolves ambiguity in the most common production tension on this project: the farm is alive and handmade, but the genetics system is a laboratory. When decorative choices conflict with legibility of gene data, legibility wins. When aesthetic choices are open, organic warmth wins. No other idle game sits at this specific intersection — most idle games are either pure cozy (Stardew-adjacent) or pure scientific abstraction. This game must hold both.

---

#### Visual Principle 1: Legibility Before Charm

**Principle:** A rabbit's rarity tier must be identifiable in under one second at its smallest rendered size, even before the player reads any text.

**Design test:** A 32×32px rabbit sprite is rendered in a grid of 12 others on a medium-brightness pastel background. If a playtester cannot point to the Rare or higher rabbit within one second of the grid appearing, the visual signal is insufficient — add a secondary cue (outline weight, particle layer, silhouette complexity) before committing to ship.

**Pillar served:** Collection mastery — players cannot develop rarity intuition if tier signals are ambiguous at glance.

---

#### Visual Principle 2: The Farm Breathes

**Principle:** Every idle-state visual element must suggest life and gentle motion — static backgrounds are never acceptable in the main farm view.

**Design test:** Take a screenshot of the main farm view and count how many distinct elements are animated at any given moment (grass blades, rabbit ear flicks, floating particles, cloud shadows, water ripples in habitat). The minimum is four simultaneous ambient animations. If the screenshot looks like a painting rather than a living place, ambient animation layers must be added before visual review.

**Pillar served:** Cozy caretaking — attachment to the farm requires the farm to feel alive even when the player is doing nothing.

---

#### Visual Principle 3: Genetic Wonder Escalates Deliberately

**Principle:** Visual complexity and spectacle must increase with rarity in a continuous, perceptible gradient — no two adjacent rarity tiers may feel visually similar.

**Design test:** Present all six rarity tiers side by side with color removed (grayscale only). A first-time viewer should be able to rank them from simplest to most complex by silhouette complexity, outline treatment, and animation count alone. If any two adjacent tiers cannot be distinguished in grayscale, the shape/animation differentiation is insufficient regardless of how different their colors are.

**Pillar served:** Deep genetics — the reward of creating higher-rarity rabbits must be immediately visually legible; the visual upgrade must feel proportional to the genetic mastery required.

---

### Section 2: Mood & Atmosphere

#### Game State 1: Main Farm View (Idle)

**Emotional target:** The contented feeling of checking a garden you planted yourself and seeing everything quietly thriving — not excitement, but the deep satisfaction of things being as they should be.

**Lighting character:** Midday soft overcast or late morning. Color temperature warm (4800–5500K range, expressed as slight amber tint on lit surfaces). Contrast low — no harsh shadows, light feels diffused through thin cloud cover. Shadows are soft and short.

**Atmospheric adjectives:** Unhurried. Sunlit. Inhabited.

**Mandatory mood carrier:** Animated rabbit idle behaviors must be visible in the frame at all times — at least two rabbits doing distinct non-repetitive behaviors (eating, grooming, sniffing). A frame with all rabbits stationary violates this state's emotional contract.

---

#### Game State 2: Breeding Screen (Gene Mixing / Anticipation)

**Emotional target:** The specific tension of a scientist who has done all the preparation correctly and is waiting for an experiment result — controlled excitement, not anxiety. The feeling that you are about to see something that has never existed before.

**Lighting character:** Dimmer ambient environment with a focused cool-white laboratory light source from above or center, illuminating the breeding interface. Color temperature shifts cooler than the main farm (5500–7000K). Contrast medium-high — the breeding UI is the lit focal point, surroundings fall into soft shadow.

**Atmospheric adjectives:** Anticipatory. Clinical-but-warm. Focused.

**Mandatory mood carrier:** The gene visualization UI (the display showing parent traits combining) must have at minimum one active animation at all times during the wait state — swirling particle trails between parent portraits, or pulsing glow on trait icons. A static breeding screen breaks the emotional contract of this state.

---

#### Game State 3: Legendary Reveal Moment

**Emotional target:** The exact feeling of opening a foil card in a physical card pack — a brief private triumph that feels disproportionately large, followed immediately by the impulse to show someone. Personal, spectacular, earned.

**Lighting character:** The entire screen goes dark (not black — deep violet-navy `#1A0A2E`) for one beat, then the reveal burst. The rabbit is lit from multiple rim light sources simultaneously. All other UI disappears. Color temperature is irrelevant during burst — pure white core, then the rabbit's signature colors bloom outward.

**Atmospheric adjectives:** Theatrical. Explosive. Singular.

**Mandatory mood carrier:** A full-screen dramatic flash followed by particle explosion is non-negotiable (confirmed in GDD art notes). The screen must go dark before the reveal; a reveal that happens on the normal farm background is a failed reveal regardless of how elaborate the particles are.

---

#### Game State 4: Offline Return Screen (Coming Back to Growth)

**Emotional target:** The warmth of coming home to find that something you set in motion has quietly accomplished more than you expected — the gentle surprise of abundance discovered, not earned in the moment.

**Lighting character:** Soft golden-hour light, as if the farm has been running through a full cycle of time. Warm amber (3500–4200K). Contrast low, everything bathed in even golden wash. Suggests morning light finding the farm at the start of a new day.

**Atmospheric adjectives:** Abundant. Golden. Welcoming.

**Mandatory mood carrier:** The offline summary presentation must use a cascade reveal animation — production results appearing one category at a time with rising totals, not a static list. Showing a static summary screen eliminates the return satisfaction.

---

#### Game State 5: Winter / Death / Rabbit Loss Moment

**Emotional target:** Quiet grief without melodrama — the feeling of a small and real loss that the game acknowledges with respect rather than punishing or ignoring. Close to the feeling of finding a withered plant in a pot you forgot to water.

**Lighting character:** Desaturated ambient light, slight cool blue-gray cast (7000K+). Contrast medium but with reduced saturation across the scene — colors do not disappear entirely but lose approximately 40–60% of their saturation. A single pale shaft of light may fall on the empty space.

**Atmospheric adjectives:** Muted. Still. Respectful.

**Mandatory mood carrier:** The rabbit's hutch tile must show a visual state change — a subtle empty indicator (a small wilted flower, a dim lantern, a closed hutch door) that persists until the player acknowledges the loss. The farm must not simply continue looking normal as if nothing happened.

---

#### Game State 6: Cosmic Hutch / Post-Prestige Late Game

**Emotional target:** The awe of realizing you have exceeded the original scope of what you set out to build — the feeling of a scientist who opened a door expecting a corridor and found a universe. Pride mixed with vertigo.

**Lighting character:** Self-illuminated, bioluminescent-style — the environment generates its own light rather than receiving it from a sun. Cool indigo-to-cyan gradient ambient with deep contrast. Stars and nebula particles provide the only warm accents (gold pinpoints against purple-black). Contrast high.

**Atmospheric adjectives:** Infinite. Luminous. Transcendent.

**Mandatory mood carrier:** The background parallax must have a fourth layer in the Cosmic hutch that does not appear in any other habitat — a slow-moving star field or nebula that drifts independently of all other layers. Without this layer, the Cosmic hutch reads as merely a recolored version of earlier habitats.

---

### Section 3: Shape Language

#### 3.1 Character Silhouette Rules

**Readability at 32×32px — non-negotiable requirements:**

A rabbit sprite must contain exactly one guaranteed readable silhouette element: the ear pair. Ear shape, angle, and length are the primary species identifier and must never be obscured by costume, hat, or equipment items. At 32×32px, ears must occupy a minimum of 8 pixels in height to register at a glance.

Body posture reads as a second silhouette signal: idle/sitting rabbits use a rounded compact shape (roughly circular massing); alert/active rabbits use an elongated horizontal or rearing shape. These two base postures must be distinguishable at 16×16px (the minimum thumbnail size for collection screens).

**Mandatory silhouette element per rarity tier:**

| Tier | Silhouette Signature | Rationale |
|------|----------------------|-----------|
| Common | Smooth round body, plain upright ears, no extras | Baseline — all other tiers escalate from here |
| Uncommon | One pattern break in the outline (a tuft, a curl in one ear, a tail with volume) | Readable patterning without added complexity |
| Rare | Slight body glow aura that adds 2–3px soft halo — the silhouette reads larger than the body | Metallic sheen must not require color to communicate |
| Epic | Wispy particle trails extend from body outline — the silhouette is not fully contained | Galaxy effect bleeds past the sprite boundary |
| Legendary | Outline itself is animated — chromatic shimmer means the edge is never a single color | Aurora effect makes the boundary feel alive |
| Mythic | Multiple concentric halos; the rabbit's core body is smaller than all the energy surrounding it | Cosmic tier inverts the density relationship |

**Life stage silhouette differentiation at thumbnail:**

- **Baby (kit):** Head-to-body ratio approximately 1:1. Ears proportionally short (equal to head height). Sits lower in the sprite frame. Reads as sphere with small stumps.
- **Adult:** Standard proportions. Head-to-body ratio approximately 1:1.5. Ears at full height (1.5× head height for upright breeds). Occupies full 32px height when upright.
- **Elder:** Slightly hunched posture lowers maximum height by 3–4px. One ear may droop. Body massing shifts — rounder in the middle, suggesting age without caricature.

---

#### 3.2 Habitat / Environment Geometry

**Fundamental geometry rule:** All farm environments use a soft-organic architectural vocabulary — curves are preferred over right angles, and where right angles must exist (walls, floors), they are softened by overlapping organic elements (vines, hay bales, flower clusters, crystal formations).

**Architectural vocabulary per habitat tier:**

| Tier | Primary Material Language | Geometry Character | Angular Treatment |
|------|--------------------------|-------------------|--------------------|
| Wooden Hutch | Weathered timber planks, straw, hand-cut edges | Imprecise — joints slightly uneven, boards have visible knots | No true right angles; all corners chamfered or overlapped by natural material |
| Brick Hutch | Mortared stone blocks, clay tiles, iron hinges | Semi-regular — brick courses uniform but weathering breaks monotony | Hard corners softened by moss, creeping plants |
| Glass Hutch | Tempered glass panels, metal frames, terrarium feel | Precise and rectilinear for the glass, offset by organic plant growth inside | Right angles present but always paired with an organic counterpoint |
| Eco Hutch | Living wood, moss walls, waterfall features | Fully organic — the building is partly alive | No straight lines anywhere; walls curve, roofs are thatched mounds |
| Cosmic Hutch | Crystalline energy constructs, light panels, zero gravity | Pure geometric — hexagons, triangles, perfect circles | Angular precision is the point; this habitat earns its geometry by being explicitly non-physical |

The progression from Wooden to Cosmic is a deliberate movement from organic imprecision to geometric precision — the Cosmic hutch looks the way it does because it has transcended the physical world.

---

#### 3.3 UI Shape Grammar

**Core rule:** The game UI uses a distinct panel language from the farm environment, communicating "interface" rather than "world." This separation is intentional.

**Panel shape vocabulary:**

- **Primary action panels** (breeding interface, gene lab, upgrade screens): Rounded rectangles with a corner radius of 12–16px at reference resolution, with a wood-grain or parchment texture overlay.
- **Informational panels** (stat readouts, tooltip cards, rabbit profiles): Pill-shaped or with one rounded corner and one flat corner, creating an asymmetry that visually signals "read this, do not tap this."
- **Toast notifications** (offline gains, achievements): Banner shape — full-width, low height, flat top edge, softly curved bottom.
- **Action buttons** (primary CTA): Circular (icon-only, single-action) or stadium (labeled actions like "Breed," "Harvest," "Upgrade"). Circles are never used for labeled text buttons.
- **Tab bars**: Trapezoidal tabs (wider at top, narrower at bottom where it meets the panel edge).

**Separation signal:** UI panels always have a soft drop shadow (3–5px offset, 20–30% opacity black) that world elements never have. Drop shadow = interface. No shadow = world.

---

#### 3.4 Rarity Signal Shapes (Colorblind-Safe Escalation)

Rarity must communicate through three parallel channels simultaneously: color, shape complexity, and animation complexity. Color is never the sole signal.

**Geometric escalation ladder:**

| Tier | Outline Treatment | Badge Shape | Particle System Shape |
|------|------------------|-------------|----------------------|
| Common | Single-pixel flat outline, no glow | Circle | None |
| Uncommon | Two-pixel outline with subtle color variation at corners | Diamond | None |
| Rare | Soft glow added to outline (bloom effect) | Diamond with inner circle | Occasional single sparkle points |
| Epic | Dashed/interrupted animated outline | Hexagon | Continuous slow particle trail (5–8 particles) |
| Legendary | Animated outline — the line itself moves in a slow wave | Octagram / star | Dense particle system (15–20 particles), radiating outward |
| Mythic | No outline — the rabbit emits its own edge light | Concentric rings (3 rings, animated rotation) | Orbital particles (orbit the rabbit rather than trailing) |

Even with color removed, Common through Mythic must rank correctly by outline weight, badge vertex count, and particle complexity.

---

### Section 4: Color System

#### 4.1 Primary Palette — 7 Named Colors

| Name | Hex | Role | Primary Game Context |
|------|-----|------|---------------------|
| **Meadow** | `#B8E4B8` | The living world's neutral background — the color of healthy grass. Not a UI color. | Background fill for Wooden/Brick/Eco habitats; ambient light tint in main farm view |
| **Hearthstone** | `#F5E6D3` | Warmth and safety — the color of the hutch interior, tutorial backgrounds, anything conveying "home." | Interior backgrounds, tooltip backgrounds, offline return screen wash |
| **Parchment** | `#FAFAF5` | Neutral information surface — the closest to white used in UI. Cold whites are forbidden. | Panel backgrounds, text fields, card faces, dialog boxes |
| **Worn Oak** | `#8B6B4A` | Structure and reliability — frames, borders, dividers, the material of things built to last. | Button outlines, panel borders, tab bars, section dividers |
| **Carrot** | `#FF8C42` | Action and appetite — the call-to-action color, the color of things requiring attention right now. | Primary CTAs, notification badges, harvest indicators, hunger alerts |
| **Lavender Gene** | `#9B72CF` | Scientific mystery and genetic potential — the color of the unknown, of traits not yet expressed. | Gene pool UI, breeding anticipation effects, Epic+ rarity accents, prestige/research features |
| **Hutch Shadow** | `#3D2E1E` | Depth and grounding — the darkest value in the game. Never used as a fill. | Body text, UI outlines at maximum weight, deepest shadow layer on environmental objects |

---

#### 4.2 Semantic Color Vocabulary

**Red / Orange (Carrot `#FF8C42` and alert variant `#E84545`):**
Orange = "this needs your attention but is not an emergency." Red (alert variant, used sparingly) = "act now or lose something." Red is never decorative.

**Gold / Yellow (`#F4C542` and rarity gold `#D4AF37`):**
Value and reward. Bright yellow-gold for UI currency and rewards; deeper antique gold for the Rare rarity tier's metallic sheen. Yellow is never used for negative states.

**Green (Meadow `#B8E4B8` and health green `#5CB85C`):**
Growth and health. Meadow green is the world's baseline — it signals "this is normal and good." Health green is the specific signal for a rabbit's health bar being full. Green means the system is working as intended.

**Purple (Lavender Gene `#9B72CF` and deep prestige `#5C2D91`):**
Mystery and mastery. Light lavender signals genetic potential. Deep prestige purple signals post-prestige content, Legendary/Mythic rarity. Purple means "this goes deeper than what you see."

**Blue / Cool (`#72A4CF` — sky reflection, and `#1A0A2E` — cosmic void):**
Time and the beyond. Cool blue appears in time-related UI (cooldowns, offline timers). Cosmic void (`#1A0A2E`) is the background color of the reveal moment and Cosmic hutch.

**White (Parchment `#FAFAF5` and pure `#FFFFFF`):**
Parchment white is the game's working white — used for all UI surfaces. Pure `#FFFFFF` is reserved for two uses only: the initial flash frame of the Legendary reveal moment, and the Snow Bunny (Winter seasonal rabbit). Pure white in any other context is a production error.

---

#### 4.3 Rarity Color Escalation

| Tier | Primary Color | Secondary / Accent | Transition Mechanism |
|------|--------------|-------------------|---------------------|
| Common | Natural coat colors: white `#F0EDE8`, brown `#8B6347`, gray `#9B9B9B` | None | Pure hue — no VFX |
| Uncommon | Two-tone combinations from Common palette | Pattern color (spots/stripes) in contrasting neutral | Pure hue pattern — no VFX |
| Rare | Metallic gold `#D4AF37` and/or silver `#C0C0C0` | Warm highlight `#FFF0A0` on specular points | **First VFX threshold:** Soft static glow, 8px blur radius, 40% opacity |
| Epic | Deep space blue `#1E3A5F` to violet `#6B3FA0` gradient | Star point highlights `#E8D5FF` scattered across body | **Animated VFX:** Slow nebula swirl on coat surface, particle trail on movement |
| Legendary | Full spectrum cycling — hue rotates slowly through 360° | White-core chromatic fringing on outline | **Full VFX:** Animated chromatic outline, dense particle system, coat surface animation |
| Mythic | Shifts between deep void `#050014` and transcendent white-violet `#E8D5FF` | Multiple simultaneous chromatic layers | **Maximum VFX:** Orbital particles, bloom affecting surrounding pixels, partially transparent coat |

**Transition rules:** No VFX below Rare. A Legendary rabbit should never be mistaken for Epic, and Epic should never be mistaken for Rare, from across the screen at full zoom-out.

---

#### 4.4 Seasonal Color Palette Shift Rules

Seasonal shifts apply to the environment and ambient lighting only. UI palette does not shift. Rabbit coat colors do not shift. The shift affects: background layers, ground tile tint, ambient particle color, sky/lighting color temperature.

**Spring (Fertility Season):**
- Hue temperature: Warm-neutral (slight green lean)
- Saturation shift: +15% above base palette on all environmental colors
- Specific changes: Meadow `#B8E4B8` intensifies to `#8FD88F`; blossom particle color `#FFB7C5`; sky tint pale cerulean `#C9E8F0`

**Summer (Growth Season):**
- Hue temperature: Warmest of all seasons; amber-gold lean
- Saturation shift: +25% above base on greens and yellows; maximum vibrancy
- Specific changes: Ground tiles shift toward warm golden-green `#AACF6B`; sky tint deep warm blue `#87CEEB`; ambient light gains slight golden tint `#FFF5D6`

**Autumn (Harvest Season):**
- Hue temperature: Warm-cool shift — greens replaced by orange-golds and russets
- Saturation shift: Greens desaturate by -30%; warm colors (orange, gold, red) saturate by +20%
- Specific changes: Ground tiles shift to amber-tan `#C4954A`; tree/bush elements shift orange-red `#C0533A`; sky shifts to low warm overcast `#DFC08A`
- Mandatory: At least one visual element in every environment tile must reference autumn harvest

**Winter (Offline Production Season):**
- Hue temperature: Coolest season; blue-white lean
- Saturation shift: All environmental colors desaturate by -40%; world approaches near-monochrome with blue cast
- Specific changes: Ground tiles become snow-white `#E8EDF5`; sky becomes pale gray-blue `#B8C8D8`; ambient particle color `#AED6E8`
- Mandatory: Snow accumulation overlay on all hutch roofs and environmental surfaces

---

#### 4.5 Colorblind Safety

**Identified unsafe pairs** (deuteranopia / protanopia):

| Unsafe Pair | Why Unsafe | Backup Cue |
|-------------|-----------|------------|
| Carrot orange (hunger alert) vs. Health green (full health) | Both shift toward similar yellow-brown in deuteranopia | **Shape:** Full health uses a heart icon; hunger uses a bowl/carrot icon |
| Meadow green (environment) vs. Carrot orange (CTA button) | Both shift toward yellow-tan, reducing button discoverability | **Pattern:** CTA buttons always have Worn Oak `#8B6B4A` 2px border; environmental elements never have this border |
| Common brown coat vs. Uncommon pattern colors | Pattern colors using green/red-adjacent tones lose distinctiveness | **Pattern redundancy:** Uncommon patterns must use geometric shapes at sufficient contrast to be visible in grayscale |
| Epic nebula blue-violet vs. Rare metallic gold | May merge in tritanopia | **Animation:** Epic is always animated (coat surface movement); Rare is always static glow only |
| Spring green accent vs. Summer yellow-green environment | Seasonal distinction may collapse for deuteranopes | **Temperature + Icon:** Each season uses a mandatory season icon in HUD (flower bud, sun, leaf, snowflake) |

**Global colorblind rule:** Any information conveyed by color alone in the UI is a production defect. Every color signal must have a paired non-color signal. This rule is enforced at visual review via deuteranopia simulation filter.

---

### Section 5: Character Design Direction

> Design philosophy for this section: Rabbits are the stars. Every visual rule here exists to make them readable, memorable, and emotionally resonant within a 32×32px canvas. The player's presence is a whisper; every rabbit is a sentence.

---

#### 5.1 Player Character / Farm Owner

**Visual Archetype**

The farm owner does not exist as a persistent on-screen avatar. They are represented as an **abstract icon portrait**: a circular frame (28×28px interior, 2px border in Worn Oak `#8B6B4A`) containing a small top-down silhouette of a figure in a lab coat, rendered in no more than 4 colors. The coat is Parchment `#FAFAF5` (not pure white), with Carrot `#FF8C42` accent stitching to signal warmth and care rather than clinical coldness.

The face is a minimal 3-pixel expression — two 1px dot eyes, no mouth at resting state, with a micro-smile added only in celebration states (achievement unlock, first legendary reveal). At 64×64px (guild profile/achievement screens), the figure gains hands at the bottom of the frame holding a small carrot downward — "I feed them" without needing text.

**Art Style Consistency**

The portrait uses the same pixel density and outline weight as the rabbit sprites. 1px dark outline in Hutch Shadow `#3D2E1E`, no anti-aliasing, palette locked to the established 7 primaries. The portrait must never animate beyond a single looping blink (2-frame, 90-frame interval). It should always be smaller, less saturated, and less animated than any rabbit on screen.

---

#### 5.2 Rabbit Visual Archetypes Per Role

**Baby / Kit**

- **Body type:** Maximum circle compression. Width-to-height ratio 1.1:1. Body occupies roughly 18×16px of the 32×32 canvas. Limbs are implied only: two 1px nubs at the base for feet.
- **Ear treatment:** Short and floppy, tilting outward at ~30 degrees. Maximum ear height 6px (below the adult 8px minimum). Ear width 3px, rounded top.
- **Expression default:** Wide open eyes (3×2px white with 1px pupil), slight upward curve to the mouth line (1px arc, 3px wide). Permanently looks mildly surprised.
- **Distinguishing detail:** A single oversized spot in a color 30% lighter than the base coat, always centered on the back. This spot shrinks proportionally as the rabbit ages and disappears entirely at Adult — a visual growth meter requiring no UI.

**Adult Standard**

- **Body type:** Full upright proportion. Body is 20×18px. Defined shoulder line and slight neck indent. Stance is alert: weight forward, hindquarters slightly elevated. The visual baseline all other roles deviate from.
- **Ear treatment:** Full height (minimum 8px), upright and parallel. Slight inner ear color (1–2px lighter than coat base) visible. Ear tips are flat-cut — the adult sharpness signal.
- **Expression default:** Alert neutral. Eyes are 2×2px with a 1px pupil. No visible mouth line at resting state.
- **Distinguishing detail:** None — the Adult Standard deliberately has no unique mark. Every deviation from this archetype is meaningful.

**Elder**

- **Body type:** 1px hunch at the shoulder line. Body slightly wider (22px) and lower (16px height). Hindquarters lower, creating a resting-weight posture.
- **Ear treatment:** Slight outward lean (3–5 degrees) and a 1px horizontal crease midway up — a fold line that does not appear on younger rabbits. Ear tips remain full height (8px minimum).
- **Expression default:** Soft eyes. 2×2px but with pupils 1px larger than Adult, giving a deeper, quieter look. One eyelid drops 1px on one side (asymmetric half-lid). Slight neutral downward curve to the mouth — not sad, settled.
- **Distinguishing detail:** A 1px ring of lighter fur around the base of both ears — the "crown ring." Appears at no other life stage. Color is base coat lightened by 40% in HSL.

**Breeding Pair During Active Breeding**

- **Body type:** No change to body shape. Role is communicated through animation and overlay, not silhouette.
- **Ear treatment:** Ears tilt inward toward each other by 10 degrees (mirrored pair). This is a 1-frame pose shift from idle — only the ear pixels reposition.
- **Expression default:** Eyes are half-closed (top eyelid drops 1px). No blush or heart particles — the game tone is scientist-farmer, not romance simulation.
- **Distinguishing detail:** A subtle Lavender Gene `#9B72CF` shimmer overlay at 20% opacity cycles over the sprite at 8-frame intervals (slow pulse). This is the genetics system signaling that inheritance calculations are active.

**Expedition Rabbit**

- **Body type:** Adult Standard base with a 2px raised posture — chin line 1px higher, ears 1px more vertical. Communicates alertness and readiness.
- **Ear treatment:** Standard Adult ears but with a small item attached to one ear: a 3×3px tag in Carrot `#FF8C42` with a 1px Hutch Shadow dark dot.
- **Expression default:** Eyes are narrowed — 2×1px slits, still with pupil. Focused, outward-looking.
- **Distinguishing detail:** A small 4×4px satchel silhouette at the rabbit's lower right side, in Worn Oak `#8B6B4A` with a 1px Carrot latch. Appears on all expedition rabbits regardless of rarity tier.

**Sick Rabbit**

- **Body type:** Posture collapses to the Elder hunch pattern (shoulder drops 1px) regardless of life stage. Body width reduces by 1px on each side.
- **Ear treatment:** Both ears droop outward at 20 degrees, ear height reduces by 2px. The strongest negative posture signal in the visual language.
- **Expression default:** 2×2px eyes with pupils reduced to 1×1px shifted 1px downward — unfocused, glazed. Asymmetric: one eye shows a 1px shine dot that is absent on the other.
- **Distinguishing detail:** 35% desaturation filter over the full sprite, plus a 2px diameter pale green dot (Meadow `#B8E4B8` at 80% opacity) floating 2px above the rabbit's head on a 4-frame bob cycle.

---

#### 5.3 Trait Expression System

**The Decision: Traits Have Optional Visual Echoes, Not Mandatory Markings**

Traits are visible as subtle physical echoes, not badge systems or overlays. Reasons:
1. At 32×32px, adding visible trait markers risks violating Principle 1 — rarity must always be the first read.
2. The genetic wonder of the game is discovery, not legibility. A player should notice a trait echo after 10 hours, not in the first second.
3. With 24 traits, a mandatory badge system at small sizes becomes visual noise.

**Visibility Rule**: Tier 3 Legendary traits always produce a visible echo. Tier 1 and Tier 2 traits produce echoes present but legible only at the 64×64px tap-to-inspect view.

**Trait Echo Examples**

*Tier 1 — Common Traits*

- **Fast Eater**: Body is 1px wider at the belly line only. During eating animation, the head-nod cycle runs at 1.25× speed relative to standard.
- **Calm Temperament**: The ear splay angle at rest is reduced by 5 degrees. The blinking interval in the idle animation is 20 frames longer (blinks less frequently — more settled).

*Tier 2 — Advanced Traits*

- **Night Grazer**: The pupil on this rabbit's eyes is rendered as a vertical 1×2px slit rather than the standard 1×1px round dot. At 32×32px barely legible — at 64px tap-to-inspect clearly distinctive.
- **Strong Bones**: The shoulder silhouette line is 1px higher than the standard Adult archetype — a straighter, more squared-off back profile. Hind legs are 1px taller.

*Tier 3 — Legendary Traits*

- **Genesis Coat**: The coat cycles through a 3-color gradient over 24 frames (slow, barely perceptible at rest, obvious during Happy jump animation). The 3 colors are the rabbit's base coat, a lighter (+30% L in HSL) variant, and a desaturated (−40% S) variant.
- **Ancestor's Memory**: A ghost trail — a 4px ghost echo of the rabbit's previous position fades over 6 frames when the rabbit moves. The ghost uses the coat color at 25% opacity with no outline. Implemented as a shader trail, not a particle system.

---

#### 5.4 Aura Visualization

**Aura on the Elder Rabbit Itself**

An Elder rabbit with an active Aura trait renders a **radial soft border pulse**: a 1px ring of Lavender Gene `#9B72CF` pixels placed 1px outside the rabbit's existing outline, cycling in opacity from 0% to 60% and back over 32 frames. Implemented as an alternating outline pass on the sprite renderer — no glow shader required.

The Lavender ring does not replace the rarity outline. Rarity outline remains on the inner edge; the aura ring sits 1px further out. The aura ring adds 2px to each dimension — the visual footprint becomes 34×34px at peak pulse. This must be accounted for in hutch layout spacing.

For Elder rabbits with Tier 2 or Tier 3 aura traits, 2–4 small **Lavender Gene particles** (1×1px dots) orbit the rabbit in a slow ellipse path. Orbit radius is 5px from sprite edge. Particle count: Tier 2 = 2 particles, Tier 3 = 4 particles. Simple circular orbit path updated each frame — no physics simulation.

**Effect on Nearby Rabbits**

Nearby rabbits within the Elder's aura range receive a **subtle warmth wash**: a 10% opacity overlay of Hearthstone `#F5E6D3` applied to the full sprite via `CanvasItem.modulate` — no additional draw calls. Steady-state while in range, fades over 8 frames when a rabbit exits range.

**Elder Without Aura Trait vs. With Aura Trait**

- **Without aura trait**: Elder renders with the crown ring and standard rarity outline only. No Lavender ring, no particles, no warmth wash on neighbors.
- **With aura trait**: The Lavender ring activates, visually superseding the crown ring in prominence during pulse cycles. The visual contrast between an Elder with and without an aura trait must be legible within 1 second of observation.

**Performance Constraint:** Maximum 3 Elders active simultaneously in a single hutch scene (design constraint, not technical). Total additional draw calls for a worst-case 3-Elder scene: approximately 9 extra passes — within the < 50 draw calls per frame budget.

---

#### 5.5 Seasonal Rabbit Design Rules

**Immediate Season Recognition**

Each seasonal rabbit carries one primary color signal and one silhouette accessory:

- **Spring Rabbit**: Coat shifts to soft moss green — Meadow `#B8E4B8` tone, shadow `#7DB87D`. Silhouette accessory: a 3×3px flower (4-petal pixel shape in pale pink `#FFD4E8`) worn behind one ear.
- **Summer Rabbit**: Coat shifts to warm sand — Hearthstone `#F5E6D3` base with Carrot `#FF8C42` on ear tips and tail. Silhouette accessory: a 4×4px sun hat between the ears. Brim extends 1px beyond the ear line on each side.
- **Autumn Rabbit**: Coat is rich amber — seasonal color `#C8741A` (the only seasonal color permitted outside the 7-color palette). Silhouette accessory: a 2×4px bundle of tiny leaves (alternating `#C8741A` and `#8B6B4A`) tucked behind one ear.
- **Winter Rabbit**: Coat is Parchment `#FAFAF5` (not pure white — remains visually distinct from Snow Bunny). Shadow pixels in cool pale blue `#C8D8E8`. Silhouette accessory: a 4×2px scarf in Lavender Gene `#9B72CF` wrapped around the neck line.

**What Seasonal Rabbits Must Share With Regular Rabbits**

- Ear pair at minimum 8px height (non-negotiable species identifier)
- Adult standard body proportion unless in a non-Adult life stage
- Rarity tier outline system — season does not override rarity tier legibility
- All role-specific visual markers (expedition tag, sick state, breeding shimmer) apply on top of seasonal coat
- Standard blink and ear-wiggle idle animation cycles

**Interaction with Seasonal Environment Palette**

Seasonal rabbits must maintain **figure-ground contrast** against their season's environment:

- **Spring**: Spring environment is Meadow-green dominant; mandatory Carrot `#FF8C42` ear tips and pink `#FFD4E8` flower provide contrast.
- **Summer**: Summer environment uses Hearthstone and Carrot tones; Summer Rabbit receives a 2px Hutch Shadow outline (instead of standard 1px) specifically when placed on Summer background tiles.
- **Autumn**: Amber environment matches rabbit coat; Autumn Rabbit's ear interiors are rendered in Parchment `#FAFAF5` for contrast.
- **Winter**: Cool-pale environment matches Parchment coat; mandatory Lavender Gene `#9B72CF` scarf plus a unique micro-shiver animation (1px body oscillation, 4-frame cycle, 2px amplitude) provides motion contrast.

---

### Section 6: Environment Design Language

> **One-line rule**: The farm is a living record of the player's choices — every surface, worn path, and glowing crystal tells a story that needs no caption.

---

#### 6.1 Farm Layout Visual Grammar

**Ground Tile Language**

The farm ground is composed of short-cut grass with natural variation. Base tile is 16×16 pixels. Four distinct grass tile variants to prevent visible repetition:

- `env_ground_grass_base` — standard mid-green (`#A8D878`), sparse blade detail
- `env_ground_grass_dense` — slightly darker (`#90C060`), more blade density, used in untrafficked areas
- `env_ground_grass_worn` — bleached lighter (`#C8DC98`), fewer blades, used under and adjacent to habitats
- `env_ground_grass_clover` — base tile with 1–3 clover sprites overlaid, placed randomly at roughly 1-in-12 frequency

Tile placement: 50% base, 25% dense, 15% worn, 10% clover. No 2×2 block may be the same variant.

**Habitat Footprint vs Open Farm**

Two overlapping visual signals define the boundary:
1. **Worn ground apron**: A 2-tile-wide ring of `env_ground_grass_worn` surrounds every placed habitat.
2. **Shadow base**: Every habitat casts a shallow angled drop shadow (2px offset, south-southeast direction, `#3D2E1E` at 40% opacity) anchored to the ground plane as a static sprite.

**Path Language**

3-tile-wide worn dirt strips (`env_path_dirt_worn`, `#C4A882`) with irregular edges (no straight pixel lines). A 1px-wide `env_path_grass_border` (`#90C060`) runs along both sides. Paths emerge over time as environmental storytelling (see Section 6.6) — they are not placed by the player.

**Farm Edge Treatment**

Natural terrain fall-off, not a hard fence line:
- Inner edge zone (2 tiles): `env_ground_grass_worn` → `env_ground_grass_dense`
- Middle edge zone (2 tiles): `env_edge_tallgrass` (16×24px) at increasing density, color shifting to `#70A840`
- Outer edge zone (1 tile): `env_edge_treeline` sprites — simplified tree silhouettes at 16×32px, flat dark color `#3A5C28`
- Corners: `env_edge_wildflower_cluster` sprites in Lavender Gene `#9B72CF` and Carrot `#FF8C42` accents

---

#### 6.2 Habitat Exterior Design Per Tier

**Wooden Hutch (Tier 1 — 4 rabbits)**

- **Roofline:** Pitched roof with single asymmetric peak, slightly off-center. Ridge line has deliberate 1–2px warp. Alternating shingles in `#8B6B4A` and `#7A5C3D`. No two identical rows.
- **Wall texture:** Horizontal plank siding (3px tall with 1px darker gap `#6A4F35`). Planks have occasional knot sprites (1px dark dot with 2px halo). Color: `#A67C52`.
- **Entrance:** Rounded-top door opening with a short fabric curtain (`#F5E6D3` with small pattern stripe) that animates with a gentle sway — 4-frame loop, 0.8s cycle.
- **Surroundings:** 2–3 small flower boxes in Carrot and white, a worn food bowl sprite near the entrance.
- **Upgrade transition:** Wooden planks visually crack and fall away (6-frame animation), revealing brick layer beneath. Dust particle VFX. Duration: ~1.2 seconds.

**Brick Hutch (Tier 2)**

- **Roofline:** Low gabled roof with clay tile rows, slightly rounded lower edge. Terracotta `#C47A5A`. Visible as warm red-orange mass with regular horizontal bands from above.
- **Wall texture:** Running bond brickwork (6×3px bricks, 1px mortar `#D4C4A8`). Moss sprites (`#6B8C42`) at base course and 1–2 corner clusters.
- **Entrance:** Low brick arch. No door — open passage with wrought iron hook holding a lantern sprite that emits a warm flicker (3-frame loop, 1.2s cycle).
- **Surroundings:** Short stone wall on one side, climbing vine sprites on the corner wall (6-frame leaf sway), a water trough near the entrance.
- **Upgrade transition:** Wall brightens in 2-frame flash; glass panels grow from base upward over 8 frames. Climbing vines fade as ghost sprites.

**Glass Hutch (Tier 3)**

- **Roofline:** Flat or very low-slope roof with visible structural beams (`#8B6B4A`) forming a grid. Glass panels between beams have a 3-frame shimmer sequence on a slow staggered timer.
- **Wall texture:** Large glass panes in Worn Oak frames. Glass color: `#D4EEF7` at 70% implied opacity. Interior plants visible as silhouette sprites.
- **Entrance:** Sliding door tracks visible as two horizontal Worn Oak rails. A small chime sprite hangs in the doorway, 3-frame sway animation.
- **Surroundings:** Potted large-leaf plants flanking the entrance, a decorative weather vane on the roof apex, small grow beds with carrot top leaf rustle (4-frame, 2s cycle).
- **Upgrade transition:** Glass panels crack radially (8-frame animation), shatter outward into particle sprites. The Eco Hutch's living wall material grows in from the ground upward over 10 frames.

**Eco Hutch (Tier 4 — 16 rabbits)**

- **Roofline:** Living green roof covered in moss, small flowers, and grass. Irregular bumps and dips. Butterflies (2-frame sprite) orbit the rooftop on a slow 8s path.
- **Wall texture:** Woven wicker and packed earth (diagonal crosshatch of `#A67C52` over `#C4A882`). Living branches emerge from the wall with leaf clusters on a gentle 3s sway cycle.
- **Entrance:** Living archway of woven branches. Hanging moss. Warm amber glow from within (2-frame flicker). Firefly sprites (1×1px, `#FFFFA0`) float near the entrance.
- **Surroundings:** Small pond or puddle sprite with 3-frame ripple animation. Mushroom clusters at wall bases. An occasional bird perches and flies away after 4–6 seconds.
- **Upgrade transition:** An aurora-like light sweeps across the structure left to right over 12 frames, leaving crystalline geometric growth in its wake. Organic forms crystallize into the Cosmic Hutch geometry. This should feel like transcendence, not destruction.

**Cosmic Hutch (Tier 5 — 24 rabbits)**

- **Roofline:** Hexagonal dome or faceted geometric cap. Each facet cycles slowly through deep violet `#4B2D8C`, midnight blue `#1A1A4E`, and near-black with star pixel noise. Facet lines in Lavender Gene `#9B72CF`.
- **Wall texture:** Crystal growth panels between dark metal-like structural ribs. Each crystal panel has a 2-frame shimmer. Slow-rising Lavender Gene particles at 1px size rise from base to mid-wall and fade.
- **Entrance:** Arched passage with no physical door. Two tall crystal spires frame the arch, pulsing with a slow 4-frame light cycle (2s). The passage interior shows a subtle color shift.
- **Surroundings:** 3–4 orbiting crystal fragments (8×8px hexagons) slowly rotate around the hutch on a 12s timer. A circular rune pattern radiates from the base in faint Lavender Gene. Star sprites appear in the ground immediately around the hutch.

---

#### 6.3 Specialty Habitat Visual Language

**Meditation Hutch**

Circular or oval structure with a low, smooth rounded roof. Pale grey-green clay dome (`#B8C8A8`). Smooth plaster walls (`#E8DCC8`). A ring of raked sand or gravel (`#D4C4A4`) surrounds in a 3-tile radius. Falling cherry blossom petal sprites (pale pink `#F7C8C8`) drift downward at all times, not season-locked. Distinguishing read from overhead: circular form + sand ring.

**Lab Hutch**

Rectilinear flat-roofed building. Dark grey flat roof (`#4A4A5A`) with exhaust pipe sprites emitting slow-rising vapor particles (3-frame loop). Smooth concrete panels (`#8A8A9A`) with a Lavender Gene horizontal stripe at mid-height. Porthole-style blue-tinted windows (`#B0C8E0`) with interior equipment silhouettes visible. Concrete apron ground surround. Distinguishing read: flat roof with rooftop equipment + concrete apron.

**Sanctuary**

Wide, low, stone-built structure. Shallow pitched stone slate roof (`#6A7A6A`, 40% moss coverage). Dressed stone blocks (`#8A9A8A`) with carved rabbit silhouettes set into 2–3 wall stones. Large stone arch with two torch brackets — the 4-frame flame loop (`#FF8C42` to `#FFCC44`) is the primary ambient animation. Smooth flagstone pavement (`#A0A890`) as ground surround with small tribute offerings. Distinguishing read: flagstone apron + wide footprint + two torch light pool sprites.

**Nursery**

Rounded hip roof in pale warm yellow (`#F0DC88`). Smooth painted wood walls in Hearthstone `#F5E6D3` with a painted mural band of carrot and clover motifs at ground level. Large windows with warm interior glow; mobile sprite (geometric shapes on strings) in one window — 6-frame slow rotation. Dutch door with top half open. High-density flower sprites in the surroundings using pastel Carrot and Lavender Gene. Distinguishing read: pale yellow hip roof + highest flower density on the farm.

---

#### 6.4 Parallax Layer System

| Layer | Scroll Multiplier | Elements |
|-------|------------------|----------|
| Layer 1 (foreground) | 1.05× | Tall grass clumps, large foreground flowers, treeline leading edges, butterflies/fireflies |
| Layer 2 (midground — primary) | 0.6× | All habitats, paths, interactive items, rabbits, farm ground tiles |
| Layer 3 (background) | 0.25× | Rolling hills silhouettes, distant forest, sky gradient, slow cloud sprite (30–45s cycle) |
| Layer 4 (Cosmic hutch only) | 0.05× | Deep space star field + nebula clouds + distant planet/moon sprite |

Layer 3 is a single wide sprite at 2× the viewport width, not a tile. Layer 4 activates exclusively in the Cosmic Hutch background region — the near-static deep-space layer communicating that this habitat is a threshold.

**Seasonal Layer 1/3 variants:** Spring adds cherry blossom branch sprites at top-screen edges. Summer adds heat shimmer on tall grass. Autumn replaces green grass clumps with orange-brown variants. Winter removes most sprites and adds snow accumulation.

---

#### 6.5 Expedition Location Visual Themes

**Nearby Forest**
- Color temperature: Cool-neutral. Meadow green desaturates by 20%. Ambient shadow `#2E3E28` (cooler than farm).
- Unique element: Ancient hollow tree stumps (32×24px) with visible hollow interiors and mushroom growth.
- Mood: Filtered. Dappled. Deep.
- Complexity: Simplest expedition location — 2 parallax layers, single tile variant. Appropriate for early-game players.

**Eastern Meadow**
- Color temperature: Warmest expedition location. Meadow green shifts toward golden-green `#C8DC78`.
- Unique element: Tall windmill silhouette (48×64px) in far background, slowly rotating — 8-frame loop, 8s cycle.
- Mood: Open. Golden. Abundant.

**Snow Mountain**
- Color temperature: Cool-to-cold. Strong blue-white shift. Ground tiles shift to snow-covered `#E4EEF4`. Rock surfaces `#7A8A9A` (blue-grey).
- Unique element: Ice crystal formations (16×24px, faceted, `#C8E4F4`) embedded in rock faces — a deliberate visual echo of the Cosmic Hutch crystal panels.
- Mood: Stark. Silent. Thin.
- Complexity: Three full parallax layers + new rock material not seen in lower locations.

**Ancient Land**
- Color temperature: Warm-amber, aged. Sepia cast. Ground color `#C4A86A`. Shadow `#4A3A20` (warmer than farm shadow).
- Unique element: Ruined stone architecture fragments — partially collapsed arches, fallen column sections (32×16px), carved stone faces worn smooth. Implies a pre-existing civilization with history.
- Mood: Ancient. Dry. Layered.
- Complexity: Most visually dense non-prestige location. Four distinct ground tile variants plus visible dust haze sprite.

**Rabbit Universe (Post-Prestige)**
- Color temperature: Beyond temperature. Deep space blacks, Lavender Gene purples, occasional bursts of pure white. Warm farm colors absent except for trace Carrot orange in one nebula formation (a deliberate callback).
- Unique element: Visible rabbit constellation formations in the background — groups of star pixels arranged in recognizable rabbit silhouette shapes (standing, sleeping, leaping). Static sprites in Layer 3.
- Mood: Limitless. Mythic. Returned.
- Complexity: Highest visual complexity, but achieved through scale and density of small elements (star fields, multiple nebula layers, constellation sprites) rather than tile variety — the rules of the world have changed.

---

#### 6.6 Environmental Storytelling Guidelines

**Rule 1: The Farm Accumulates Evidence of Time**

- **Paths appear and deepen**: Early farm has only the `env_ground_grass_worn` apron around each habitat. Once a habitat has been present beyond a defined time threshold, a dirt path segment extends from its entrance toward the farm's center path. A late-game farm has a fully connected worn-dirt path network; an early farm has only grass.
- **Trees at the farm edge mature**: `env_edge_treeline_young` (narrow, sparse crowns) transitions to `env_edge_treeline_mature` (wider, denser, lower canopy) across defined milestones. A late-game farm has a full, deep tree border.
- **Ambient wildlife density increases**: The number of ambient creature sprites (birds, butterflies, fireflies) scales with total farm development — from 1–2 in early farm to the full ambient suite in a late farm.

**Rule 2: A Long-Occupied Hutch Shows Its History**

Three static sprite overlays added at defined occupancy thresholds:
1. `env_detail_worn_threshold` (8×4px, `#B4946A`) at the hutch entrance — worn patch from many rabbit feet.
2. Weathering overlay on the lower 25% of wall — slightly darker and less saturated than wall base.
3. Personalization sprites: chewed corner on door frame, small hay pile near entrance, scratch marks on wooden post. Fixed positions, non-randomized between sessions.

**Rule 3: A Legendary Hutch Leaves a Mark**

When a Legendary-quality rabbit occupies a hutch, a permanent golden star sprite (`env_detail_legendary_mark`, 8×8px, `#FFCC44` with `#8B6B4A` outline) is embedded in the hutch wall near the entrance. Very slow 4-frame pulse animation (5% brightness oscillation over 4 seconds).

Mark stacking: up to 5 individual stars; a sixth Legendary causes all five to merge into a larger golden disc (`env_detail_legendary_mark_major`, 12×12px) with a more visible pulse.

The mark uses each tier's material language: burned brand on Wooden Hutch, gold-colored tile inset on Brick Hutch, etched star on Glass Hutch, luminescent flowers on Eco Hutch, star-shaped crystal inclusion on Cosmic Hutch.

---

### Section 7: UI/HUD Visual Direction

The governing principle for all UI: **UI is a window into the farm, not a frame around it.** Panels should feel grown from the same world as the rabbits, except in the genetics lab, where precision earns its own visual register.

---

#### 7.1 Diegetic vs. Screen-Space Philosophy

The main farm HUD occupies a middle position on the diegetic spectrum, best described as **"world-informed screen-space"**: panels are not physically embedded in the farm world but adopt the visual materials of the farm (parchment surfaces, wood-grain borders, chalk-like iconography) so they feel continuous with the environment.

**Elements that should feel like natural farm objects:**
- The bottom navigation bar reads as a **wooden signpost plank**.
- Rabbit stat bars use organic fill metaphors (grain filling a bucket, grass growing in a field).
- Toast notifications use a **chalkboard banner** aesthetic.
- Idle-production collection indicators (floating coin icons above a hutch) are fully diegetic — they exist inside the world layer, no drop shadow.

**Elements that are unambiguously screen-space UI:**
- Header bar (player name, currency, notifications)
- All panel overlays (rabbit card, shop, guild, quest screens)
- Modal dialogs and confirmation prompts

These carry the **drop shadow rule from Section 3**: drop shadow = interface. No shadow = world.

**The genetics lab interface is explicitly screen-space and deliberately so.** The player is meant to feel they have entered a different cognitive mode. The genetics UI uses the Lavender Gene `#9B72CF` palette range, sharper corner radii (4–8px instead of 12–16px), and a slightly cooler tint on panels. The diegetic metaphor for the genetics lab UI is a **research notebook with printed data tabs**, not a farm object.

---

#### 7.2 Header / Status Bar Design

The header is a **parchment strip** — `#FAFAF5` surface, 2px Worn Oak `#8B6B4A` bottom border, subtle texture overlay.

**Visual hierarchy of currencies:**

Carrot Coin is primary (20sp numeral, 24px icon, leftmost position after player name). Crystal Gem is secondary (16sp numeral, 20px icon, to the right). Gene Fragments and Star Dust do not appear in the persistent header — they appear contextually in the relevant screen.

**Currency amount animations:**
- **Carrot Coins**: Counter rolls up (digit-by-digit flip animation, 200ms per digit, easing out). Coin icon bounces once with 10% scale overshoot on final value landing.
- **Crystal Gem**: Gem icon emits a brief sparkle burst (3–4 pixel-art star particles, 300ms) on gain. Numeral cross-fades to the new value.
- **On loss (spend)**: Both currencies do a brief red flash on the numeral (`#E05252`, 100ms). No scale animation on loss.

**Notification bell states:**

| State | Visual Treatment |
|---|---|
| Read | Outline-style bell, Worn Oak `#8B6B4A` stroke, no fill |
| Unread | Solid-fill bell, Carrot `#FF8C42` fill, circular badge with white numeral count |
| Urgent | Solid-fill bell pulsing between `#FF8C42` and `#E05252` at 1Hz; badge present; shake animation (3px horizontal, 200ms) every 8 seconds |

The bell state communicates through shape (outline vs. fill) and motion (still vs. pulsing vs. shaking) — never color alone.

**Mobile safe zone:** Dynamic top padding equal to the device's safe area inset (`DisplayServer.get_display_safe_area()`). Header parchment color bleeds into notch/island region but no interactive elements appear above the safe boundary. Minimum header height (excluding safe area padding) is 52px.

---

#### 7.3 Bottom Navigation Bar

**Wooden plank panel** — Worn Oak `#8B6B4A` base color with wood-grain pixel texture, 3px top border in Hutch Shadow `#3D2E1E`, 8px rounded corners on top-left and top-right of the bar as a whole.

Dynamic bottom padding equal to the home indicator safe area inset.

**Active vs. inactive tab visual treatment:**

| Property | Active Tab | Inactive Tab |
|---|---|---|
| Background | Parchment `#FAFAF5`, raised (3px top protrusion, trapezoidal) | Worn Oak `#8B6B4A`, flush with bar surface |
| Icon | Filled, full Hutch Shadow `#3D2E1E` | Outline-only, `#FAFAF5` at 60% opacity |
| Label | 11sp, Hutch Shadow `#3D2E1E`, visible | 10sp, `#FAFAF5` at 60% opacity |

The active tab's raised protrusion is the primary shape signal. Color alone does not distinguish active from inactive.

**Tab transition animation:** Previously active tab drops back flush (60ms ease-in); newly active tab raises up (80ms ease-out, 1px overshoot before settling).

**Badge / notification dot:** 10px diameter, Carrot `#FF8C42` fill, white border 1.5px, Hutch Shadow numeral. Counts above 9 display as "9+". Scales in with 20% overshoot (spring, 150ms) on first appearance.

**Locked tab visual treatment:** Padlock icon replaces the normal icon; label replaced with "???" at 40% opacity; tab surface uses `#6B5238`; registers a tap but shows a tooltip "Unlocks at Level [X]".

**Bar-to-world connection:** Clean hard-edge separation at the 3px Hutch Shadow top border. The wooden plank metaphor makes this separation feel intentional and physical. Fully opaque at all times — no transparency or blur.

---

#### 7.4 Rabbit Card / Profile Visual System

Full-panel modal that slides up from the bottom of the screen (300ms ease-out, spring finish). Rounded rect, 16px corner radius on top corners only, parchment `#FAFAF5` surface, 2px Worn Oak `#8B6B4A` border on top and sides.

**Card layout (top to bottom):**
```
[ Rabbit Portrait — centered, 96×96px sprite in circular frame ]
[ Name (18sp heading) + Life Stage Badge (right-aligned) ]
[ Rarity Indicator ]
[ Stat Bars: Hunger | Happiness | Health | Cleanliness — 2×2 grid ]
[ Gene Slots: 6 slots in 2 rows of 3 ]
[ Action Buttons: Feed | Play | Clean | Breed — full-width row ]
```

**Stat bar visual treatment** (180px wide, 12px tall, 4px rounded end caps):

| Stat | Fill Color | Icon |
|---|---|---|
| Hunger | `#FF8C42` (Carrot) | Small carrot icon |
| Happiness | `#F7C948` (warm yellow) | Small star icon |
| Health | `#5BB85D` (meadow green) | Small leaf icon |
| Cleanliness | `#72BADF` (sky blue) | Small water drop icon |

**State thresholds:** 100% — clean fill, no treatment. 50% — neutral. 25% — icon gains exclamation badge; bar fill pulses at 0.5Hz. 0% — fill changes to `#E05252`; thin 2px red outline on the track; icon badge pulses urgently at 1Hz.

**Gene display — 6 slots (2 rows of 3, 44×44px each):**

| Allele State | Visual Treatment |
|---|---|
| Revealed, dominant | Lavender Gene `#9B72CF` fill; allele letter in white; solid border `#7A58A8` |
| Revealed, recessive | `#9B72CF` at 40% opacity fill; allele letter in `#7A58A8`; dashed border |
| Unknown / hidden | Dark parchment fill `#C8B89A`; question mark icon in Worn Oak; solid border |
| Locked | `#3D2E1E` fill at 80% opacity; padlock icon in `#8B6B4A` |

**Life stage badges:**

| Stage | Background | Label |
|---|---|---|
| Baby | `#F7C948` | Baby |
| Juvenile | `#5BB85D` | Juvenile |
| Adult | `#4A90D9` | Adult |
| Elder | `#8B6B4A` | Elder |

8sp white bold text. Pill shape (fully rounded ends) consistent with read-only informational elements per Section 3.

**Rarity treatment on the card:**

| Rarity | Portrait Frame | Card Top Border | Additional |
|---|---|---|---|
| Common | Worn Oak `#8B6B4A`, 2px solid | Standard 2px Worn Oak | None |
| Uncommon | `#5BB85D`, 3px solid | 3px green | Subtle green tint on gene slot row background |
| Rare | `#4A90D9`, 3px solid + 1px outer glow | 3px blue | Card surface has faint shimmer animation |
| Epic | `#9B72CF`, 4px solid + 2px animated shimmer | 4px purple | Gene slot rows glow faintly purple |
| Legendary | Animated gold gradient `#F7C948` → `#FF8C42`, 4px | 4px animated gold | Full card top-edge glow; name in gradient gold text |

---

#### 7.5 Breeding Interface Visual Design

The breeding screen uses the genetics lab visual register throughout: cooler panel tones, Lavender Gene `#9B72CF` accents, sharper corners (8px radius), grid-aligned layout.

**Parent selection area:** Two parent panels side by side in the top third (rounded rect 8px radius, `#FAFAF5` surface with Lavender Gene `#9B72CF` 2px border, 120×120px). Each panel shows: 64×64px rabbit portrait, name in 12sp, three primary stat mini-bars. Between panels: a "×" symbol in 20sp Lavender Gene indicating "these two will combine." An empty parent slot shows a dashed-border panel with a "+" icon and "Tap to select" in 10sp.

**Gene combination visualization:** Below the parent panels, a 3-column gene grid shows all 6 gene loci. Each locus row: `[ Gene Name ] [ Parent A allele ] × [ Parent B allele ] → [ Outcome probabilities ]`. The outcome probabilities are shown as a **horizontal segmented bar** — segment width proportional to probability, color-coded: dominant = Lavender Gene `#9B72CF` fill, recessive = `#9B72CF` at 35% opacity, unknown = `#C8B89A`.

**Outcome preview:** A compact predicted offspring card below the gene grid with desaturated treatment (85% saturation) and subtle animated shimmer ("not yet real"). Probability summary above: "Most likely: Uncommon (62%)" in 12sp Lavender Gene `#9B72CF`.

**Breed button:** Full-width stadium button, Lavender Gene `#9B72CF` fill, white label 14sp bold, 2px `#7A58A8` border. On press: brief scale-down pulse (95%, 80ms), then: both parent portraits slide to center (200ms), sparkle burst at center (Lavender Gene palette, 8–10 particles, 400ms), center "×" morphs to glowing egg icon (300ms), egg bobs (±3px, 600ms loop) until result resolves or player navigates away.

---

#### 7.6 Typography Direction

**Font 1 — Farm voice: "Cozy Serif Pixel"**
Chunky pixel serif typeface with round letterforms. Used for all farm-adjacent UI: rabbit names, hutch labels, item names, toast messages, navigation labels, in-world signage.

**Font 2 — Science voice: "Clean Mono / Technical Sans"**
Clean monospace or technical sans. Used exclusively in the genetics lab, gene displays, stat values, probability readouts, and any numerical formula output.

The font switch between farm voice and science voice mirrors the diegetic shift established in Section 7.1.

**Type hierarchy — 4 levels:**

| Level | Font | Size | Weight | Color | Usage |
|---|---|---|---|---|---|
| H1 — Screen Heading | Farm Serif Pixel | 20sp | Bold | Hutch Shadow `#3D2E1E` | Screen titles, rabbit names on card, modal headings |
| H2 — Section Subheading | Farm Serif Pixel | 15sp | Bold | Hutch Shadow `#3D2E1E` | Section labels within panels, category headers |
| Body | Farm Serif Pixel | 13sp | Regular | Hutch Shadow `#3D2E1E` | Descriptions, flavor text, notifications |
| Label / Small | Science Mono or Farm Serif Pixel (context) | 11sp | Regular | Worn Oak `#8B6B4A` (farm) / Lavender Gene (lab) | Stat values, counts, gene labels, timestamps |

**Minimum readable sizes:** Body text: never below 12sp. Labels: never below 11sp. In-world floating text: never below 10sp. Gene lab data values: never below 11sp with monospace alignment.

**Accessibility scaling:** 0.85× / 1.0× / 1.25× scale factors. All sp values above are base (1.0×). Layouts must accommodate 1.25× without truncation.

---

#### 7.7 Dark Mode / Light Mode Rules

Dark mode is triggered by the device's system preference. **UI-layer changes only** — the farm world rendering does not change.

**Elements that stay fixed in both modes:** Farm world background, terrain, hutches, rabbit sprites, diegetic elements, rarity border colors, gene slot Lavender Gene accents, all iconography.

**Elements that change:**

| Token | Light Mode | Dark Mode |
|---|---|---|
| Parchment (primary UI surface) | `#FAFAF5` | `#2A2018` (deep warm brown — not pure black) |
| Worn Oak (structural / borders) | `#8B6B4A` | `#C4956A` (lightened for legibility on dark surface) |
| Hutch Shadow (text / deep outline) | `#3D2E1E` | `#EDE4D4` (light warm cream — primary text on dark surface) |
| Carrot (CTA / attention) | `#FF8C42` | `#FF9D5C` (slightly lighter for dark-mode contrast) |
| Panel drop shadow | `rgba(61,46,30, 0.25)` | `rgba(0,0,0, 0.45)` |
| Tab bar wooden plank | Worn Oak `#8B6B4A` | `#1E160E` (dark walnut) |

**Dark mode does not create a "night farm" environment.** The farm world's lighting is governed by the time-of-day system and is entirely independent of the UI mode. These two systems coexist independently.

---

#### 7.8 UX Alignment Notes

**Note 1 — Touch target risk:** The 44×44px gene slot size in Section 7.4 is the floor — do not reduce this under any circumstance. If the card layout is tight on small screens (320px width), the gene slot grid shifts to a single horizontal row of 6 (scrollable) before any slot size reduction is permitted.

**Note 2 — Colorblind mode:** Substitutions applied across the UI:
- Stat bars: Each gains a unique pattern fill (Hunger: diagonal hatch; Happiness: dot grid; Health: horizontal lines; Cleanliness: wave lines). At 0%, the stat icon gains a unique outline shape badge (X / sad face / cross / alert triangle).
- Gene slots: Dominant vs. recessive distinguished by border style (solid = dominant, double-dashed = recessive) in addition to opacity.
- Rarity borders: Each tier gets a unique border pattern (Common: solid; Uncommon: dash-dot; Rare: double line; Epic: animated dash; Legendary: animated gradient + particle).

**Note 3 — Simplified mode:** For new players' first 5 sessions (or until manually disabled). Gene slots on the rabbit card are hidden and replaced by a "Genes: Tap to explore" prompt pill. The breeding screen shows only the outcome prediction without the allele-by-allele grid. A small "Simplified" pill badge appears on any panel where complexity has been removed — tappable to explain and link to Settings.

**Note 4 — Thumb zone compliance:** All frequent-action elements must be reachable in the bottom 60% of the screen. The card action buttons are pinned to the bottom of the rabbit card modal — they do not scroll away. If card content is longer than visible area, stat bars and gene slots scroll inside the card container while action buttons remain fixed.

**Note 5 — Minimum contrast compliance:** All text must meet WCAG AA contrast ratio (4.5:1 normal text, 3:1 large text) in both light and dark modes. The Lavender Gene `#9B72CF` used as a text color against Parchment `#FAFAF5` must be verified at implementation time for 11sp — may require a darkened variant (`#7A58A8`) for small label usage.

---

### Section 8: Asset Standards

This section defines the binding technical standards for all art assets. Every specification here is derived from the hard platform constraints (256MB RAM ceiling, < 50 draw calls per frame, 30 FPS stable on mobile). Deviations require explicit sign-off from both the Art Director and Technical Artist.

---

#### 8.1 Sprite Standards

##### Base Rabbit Sprite

The canonical rabbit sprite is **32×32 pixels** at 1:1 art resolution, with **no padding between frames**. Frames are packed **left-to-right, single row per animation state**. Each animation state occupies its own row. Frame 0 is always the "rest" or "start" frame of that state. This maps directly to Aseprite's tag system and imports cleanly into Godot SpriteFrames.

**Canonical animation state list** (these become the Aseprite tag names and Godot SpriteFrames animation names):

| Animation State | Min Frames | Max Frames | Target FPS | Notes |
|----------------|-----------|-----------|-----------|-------|
| `idle` | 4 | 8 | 6 | Subtle breathing, ear twitch. Looping. |
| `eating` | 6 | 8 | 8 | Chew cycle. Looping while condition active. |
| `happy` | 6 | 8 | 10 | Bounce/hop. Play once then return to idle. |
| `sad` | 4 | 6 | 6 | Droop ears, slumped posture. Looping. |
| `legendary_reveal` | 8 | 12 | 12 | One-shot reveal animation. Never loops. |
| `breeding_active` | 4 | 8 | 8 | Heart effect integrated into sprite. Looping. |
| `sleeping` | 4 | 6 | 4 | Very slow breathing. Looping. |
| `sick` | 4 | 6 | 6 | Shiver/slumped. Looping. |
| `expedition_away` | 4 | 6 | 8 | Walking cycle, used in expedition summary UI. |

`legendary_reveal` is the only one-shot animation; Godot SpriteFrames `loop` property must be set to `false` for this state only.

##### Rarity VFX Overlay Sprites

VFX overlay sprites are **separate sprite sheet assets** layered above the base rabbit sprite. This allows the base sheet to remain a single shared atlas regardless of rarity.

| Rarity Tier | VFX Sprite Required | Max VFX Sprite Envelope | Notes |
|------------|-------------------|------------------------|-------|
| Common | No | — | No VFX layer |
| Uncommon | No | — | Color palette shift only (Godot shader modulate) |
| Rare | Yes | 48×48px | Subtle shimmer ring, 1–2 frame loop |
| Epic | Yes | 64×64px | Glow aura, 4-frame loop |
| Legendary | Yes | 80×80px | Animated particle halo baked into sprite sheet, 8-frame loop |
| Mythic | Yes | 96×96px | Orbital ring + bloom overlay, 8–12 frame loop. Second VFX layer permitted. |

##### Seasonal Rabbit Sprites

Seasonal variants use **palette swap, not separate sprite sheets**. The base rabbit `.aseprite` file is the single source of truth. Artists deliver a **seasonal palette file** (one `.pal` per season variant per color group). Exception: if a seasonal variant requires geometry changes (e.g., a scarf that alters silhouette), a dedicated seasonal sprite sheet is permitted with Art Director + Technical Artist approval.

---

#### 8.2 Texture Atlas Requirements

**Primary rabbit atlas maximum size: 2048×2048px** (holds all 24 rabbit base sprite sheets comfortably: 24 × 9 states × 12 max frames × 32×32px = ~2.5M px², within 4.2M px² capacity).

**VFX overlay sprites:** Secondary VFX atlas, maximum **1024×1024px**.

**Packing priority rule** (when primary atlas approaches capacity):
1. `idle` (always present — highest frequency)
2. `eating`, `happy`, `sad`, `sleeping`
3. `sick`, `breeding_active`
4. `expedition_away` (UI-context only)
5. `legendary_reveal` (one-shot — first candidate for secondary atlas overflow)

| Atlas | Contents | Max Size |
|-------|----------|----------|
| `rabbit_primary.atlastex` | Base rabbit sprites (all states, all colors) | 2048×2048px |
| `rabbit_secondary.atlastex` | Overflow rabbit frames (expedition, reveal) | 1024×1024px |
| `vfx_primary.atlastex` | Rarity VFX overlays (Rare–Mythic) | 1024×1024px |
| `habitat_[name]_primary.atlastex` | Habitat tiles, props, BG layers | 2048×1024px |
| `habitat_[name]_secondary.atlastex` | Habitat overflow (Cosmic only expected) | 1024×1024px |
| `ui_primary.atlastex` | All UI elements | 2048×2048px |
| `ui_secondary.atlastex` | UI overflow | 1024×1024px |

UI assets are kept in a **dedicated UI atlas, separate from all game-world atlases** — mixing them forces extra draw calls.

**Estimated total texture memory budget:** ~158MB against the 256MB ceiling, leaving ~98MB headroom.

---

#### 8.3 File Naming Convention

All asset filenames use **snake_case** exclusively. No spaces, no hyphens, no uppercase.

**Rabbit sprite sheets:** `rabbit_[rarity]_[color_group]_[animation_state].aseprite`
- When a single `.aseprite` contains all animation states as Aseprite tags (preferred): `rabbit_[rarity]_[color_group].aseprite`
- Example: `rabbit_legendary_aurora.aseprite`

Valid `[rarity]` values: `common`, `uncommon`, `rare`, `epic`, `legendary`, `mythic`

**Seasonal variant palettes:** `rabbit_[color_group]_palette_[season].pal`
- Example: `rabbit_golden_palette_winter.pal`

**Habitat sprites:**
- Tilesets: `habitat_[habitat_name]_tileset.aseprite`
- Props: `habitat_[habitat_name]_prop_[prop_name].aseprite`
- Background layers: `habitat_[habitat_name]_bg_layer[N].aseprite` (N = 1 farthest, 4 nearest)

**UI assets:**
- Icons: `icon_[category]_[item_name].aseprite`
- Buttons: `btn_[state]_[action].aseprite` (states: `default`, `pressed`, `disabled`)
- Panels: `panel_[panel_name].aseprite`
- HUD: `hud_[element_name].aseprite`

**VFX assets:** `vfx_[rarity]_[effect_name].aseprite`
- Example: `vfx_mythic_orbital_ring.aseprite`

**Exported Godot resources:** Replace `.aseprite` with `_sheet.png` (texture) and `_frames.tres` (SpriteFrames resource).

---

#### 8.4 Color Palette Lock

**Master palette file:** `assets/art/palettes/master_palette.pal` (Aseprite RIFF format, authoritative). Human-readable JSON mirror at `assets/data/master_palette.json` (generated from `.pal`, never edited directly).

**Enforcement:** Artists must load `master_palette.pal` in Aseprite with **"Lock palette" mode enabled**. Technical enforcement via a pre-export linting step (`tools/asset-pipeline/validate_palette.py`) that asserts every pixel color in the exported `.png` is present in `master_palette.json`. Palette violations block the Godot import.

**Color count limit:** Maximum **16 unique colors per individual sprite frame**. VFX overlay sprites are permitted up to **24 colors** for gradient-heavy glow effects.

**Exception rule:** Colors outside the master palette are permitted only for (1) VFX glow overlays for Legendary and Mythic tiers — up to 8 additional colors with Art Director approval, documented in `assets/art/palettes/vfx_extended_palette.json`; and (2) formal Art Director + Technical Artist approved palette expansions.

---

#### 8.5 Texture Resolution Tiers

| Category | Art Creation Size | Game Display Size | Half-Res Trigger | Memory Estimate (Uncompressed) |
|----------|------------------|-------------------|-----------------|-------------------------------|
| Rabbit base sprite (full sheet, 9 states, 12-frame max) | 32×32px per frame | 32–64px on screen | Never | ~430KB per rabbit sheet |
| VFX overlay sprite (Mythic worst case, 12-frame loop) | 96×96px per frame | 96×96px on screen | Never | ~440KB per VFX sheet |
| Habitat exterior / foreground prop | 64×64 to 128×128px per prop | Scales with hutch zoom | Use 64×64 on mobile when prop count > 30 | ~512KB total per habitat prop set |
| Background parallax layer | 512px tall × 1024px+ wide | Full screen width | Use 512px-wide on ≤720p devices | ~2MB per layer; 3 layers = ~6MB per habitat |
| UI panels | 9-sliced source at 48×48 to 256×256px | Variable stretch | N/A | ~4MB total for UI atlas |
| Icons (currency, trait, etc.) | 16×16 or 32×32px | 16–32px on screen | Never | ~0.5MB for 128 icons |
| VFX particle sheet (Rare–Epic tiers) | 48×48 or 64×64px per frame | Matches VFX envelope | N/A | Within 1024×1024 VFX atlas = ~4MB |

---

#### 8.6 Godot-Specific Import Rules

> **Engine Version Warning**: The project targets Godot 4.6. Import system settings received changes across 4.4, 4.5, and 4.6 (texture compression defaults, shader texture type declarations). **Verify all settings below against Godot 4.6 release notes and project import presets before locking the pipeline.**

**Rabbit sprite sheets:**
```
texture_filter = 0           # Nearest — mandatory for pixel art
compress/mode = 0            # Lossless (PNG) — pixel art cannot tolerate lossy artifacts
mipmaps/generate = false     # OFF — pixel art uses integer scaling; mipmaps cause blurring
detect_3d/compress_to = 0   # Never auto-convert to 3D
```

**Background parallax layers:**
```
texture_filter = 0           # Nearest
compress/mode = 0            # Lossless for authored pixel art BG layers
mipmaps/generate = false
repeat/enabled = true        # Required for horizontally-tiling parallax layers
repeat/tile_x = true
repeat/tile_y = false        # Parallax layers tile horizontally only
```
> **Verify against Godot 4.6**: The `repeat` import flag behavior may differ from 4.3. The recommended approach is to set `texture_repeat` on the `Sprite2D` node rather than relying on the import flag. Confirm which method takes precedence in 4.6.

**UI textures:**
```
texture_filter = 0           # Nearest
compress/mode = 0            # Lossless
mipmaps/generate = false
```
9-slice (StyleBoxTexture) is used for all panel and button assets. Margins defined in the `.tres` StyleBoxTexture resource, not baked into source art.

**VFX particle textures:**
```
texture_filter = 0           # Nearest
compress/mode = 1            # Lossy acceptable for VFX
compress/lossy_quality = 0.9 # High quality
mipmaps/generate = false
process/premult_alpha = true # Required for correct additive blending in GPUParticles2D
```
> **Verify against Godot 4.6**: Premultiplied alpha handling in the particle system was subject to changes across 4.4–4.6. Confirm `process/premult_alpha` behavior with `GPUParticles2D` in 4.6 before finalizing VFX shader setup.

---

#### 8.7 Performance Budget Per Asset Category

**Animated element budget:**

| Element Category | Max Simultaneous Count |
|-----------------|----------------------|
| Rabbit base sprites (animated) | 24 |
| Rabbit VFX overlay sprites (animated) | Up to 24 (1 per visible rabbit) |
| UI animated elements (timers, pulsing icons) | 8 |
| Background parallax layer auto-scroll | 3 (4 in Cosmic hutch) |
| **Total animated sprite nodes** | **59 max (63 in Cosmic hutch)** |

**VFX particle system budget per rarity (GPUParticles2D nodes, per-scene total):**

| Rarity Tier | VFX Mechanism | Simultaneous Particle Systems (Scene Total) |
|------------|--------------|---------------------------------------------|
| Common | None | 0 |
| Uncommon | Shader modulate only | 0 |
| Rare | Sprite overlay only | 0 |
| Epic | 1× GPUParticles2D per rabbit | Max 4 simultaneous |
| Legendary | 1× GPUParticles2D per rabbit | Max 3 simultaneous |
| Mythic | 2× GPUParticles2D per rabbit | Max 2 simultaneous (hard cap) |
| **Scene total** | | **Max 14** (enforced by visibility/LOD system) |

**VFX LOD rule:** If a rarity-tier rabbit is not in the player's current viewport focus, its `GPUParticles2D` nodes are **paused** (`emitting = false`). Each rabbit scene includes a `VisibleOnScreenNotifier2D` that drives particle emitter state.

> **Verify against Godot 4.6**: Confirm `VisibleOnScreenNotifier2D` node name and signal names (`screen_entered`, `screen_exited`) are unchanged in 4.6.

**Draw call allocation (< 50 total budget):**

| Rendering Layer | Allocated Draw Calls |
|----------------|---------------------|
| Background parallax layers | 3–4 |
| Habitat foreground / ground props | 2–3 |
| Rabbit base sprites (all 24) | 1–3 (atlas batching) |
| Rabbit VFX overlays (sprite-based, Rare–Epic) | 1–2 |
| Rabbit VFX particles (Legendary–Mythic) | 2–14 |
| UI panels and backgrounds | 4–6 |
| UI icons and text | 3–5 |
| HUD overlays | 2–3 |
| Reserved / engine overhead | 5 |
| **Total worst-case** | **~37–43** |

**`CanvasGroup` usage rule:** Any set of 3+ UI elements that always render together and share no per-element material override must be wrapped in a `CanvasGroup` to collapse their draw calls into one. Drop shadows on UI panels are implemented via `CanvasGroup` with a shadow shader on the group.

> **Verify against Godot 4.6**: Confirm that batching behavior with `CanvasGroup` and the D3D12 default backend (introduced as default on Windows in 4.6) behaves identically to Vulkan for 2D CanvasItem batching.

---

### Section 9: Reference Direction

The following references are not mood boards or aesthetic targets — they are precision surgical tools. Each reference solves exactly one visual problem for Bunny Farm Idle. An artist should study only the named element in each source, then put the reference away.

---

#### Reference 01: Stardew Valley — Cozy Idle Farm Environment

**Source:** Stardew Valley (ConcernedApe, 2016) — specifically the interior barn and coop scenes at late afternoon (4–6pm in-game clock cycle)

**What to take:** The two-temperature interior light pool system: a single warm amber/ochre overlay layer at ~40% opacity above the base tile palette creates the illusion of a single-direction candlelight source without any dynamic lighting calculation. Every surface in the light pool shifts toward yellow-orange, every shadow toward deep cool purple-brown. Study specifically how the hay floor tiles use dithering at the edges of the light pool rather than a hard edge — the warmth "bleeds" into surrounding tiles through alternating warm/cool pixels at 1:1 ratio.

**What to avoid:** The Stardew character sprite proportions — the tall, thin human silhouette. Bunny Farm Idle characters are rabbits with compressed, round, chibi proportions. Also avoid the muddy green-grey that dominates Stardew's exterior grass tiles — Bunny Farm Idle's farm exteriors run warmer and more saturated, closer to crayon than watercolor.

**Why this source:** The two-temperature interior light system solves the problem of making hutch interiors feel warm and inhabited without requiring shader work that would hurt mobile performance.

---

#### Reference 02: Celeste — Pixel Rabbit Character Design

**Source:** Celeste (Maddy Thorson & Noel Berry, 2018) — specifically the idle and climb animation frames of Madeline's sprite

**What to take:** The principle that a pixel character reads its emotional state primarily through silhouette deformation, not through facial expression. In Madeline's idle animation, the entire body sways 1–2 pixels, the hair group shifts as a single mass, and the hands settle in rounded fist shapes — no individual finger pixels. Study the Celeste idle specifically to understand how few frames (3–4) create convincing biological breath rhythm. For rabbit sprites: ears are the primary emotional silhouette element. The ear silhouette must read correctly at 16×16 and at 64×64 after scaling.

**What to avoid:** The high-contrast black outline that defines every pixel in Celeste's sprite against the environment. Bunny Farm Idle's rabbits live against warm, relatively clean farm backgrounds — a hard black outline will make rabbits look stamped-on rather than placed-in. Use color-shifted outlines instead: a darkened, saturated version of the rabbit's dominant coat color as the border.

**Why this source:** Celeste's Madeline solves the core problem of making a small pixel character convey distinct personality and biological life at resolutions where individual pixels carry enormous expressive weight.

---

#### Reference 03: Into the Breach — Genetics/Science UI Visual Problem

**Source:** Into the Breach (Subset Games, 2018) — specifically the mech loadout and pilot assignment screen

**What to take:** The compositional rule that scientific/tactical information UI should use a dark desaturated panel background (near-black with a slight cool tint, approximately HSB 220°, 15%, 18%) with data elements presented in high-contrast single-color categories — one color per information type. Study how the mech detail panel organizes hierarchy: category label (small, dim) → value (large, bright) → context (small, medium dim). That three-level hierarchy in a compact vertical space is the exact pattern needed for genetics trait display.

**What to avoid:** The flat, near-monochrome coldness of Into the Breach's overall palette applied to the entire game screen. In Bunny Farm Idle, the science UI shift is a localized zone — the genetics lab panel — surrounded by warm farm context. The cool scientific panel language applies only within the genetics lab panel boundary. The panel's outer frame should still use warm wood or aged metal to bridge into the farm context.

**Why this source:** Into the Breach's mech loadout screen is the best existing example in pixel games of making complex mechanical data feel precise and authoritative without becoming sterile or unreadable at small screen sizes.

---

#### Reference 04: Hollow Knight — Rarity Escalation and Legendary Reveal Spectacle

**Source:** Hollow Knight (Team Cherry, 2017) — specifically the Dream Nail cutscene when striking a Shade and the White Palace environmental reveal

**What to take:** The layered particle-on-void technique. In the Dream Nail cutscene, a black-on-black background uses two or three layers of slowly drifting particles at different opacity levels (~80%, 40%, 15%) to create the illusion of infinite depth without any 3D rendering. The particles are simple: 2×2 pixel soft-edged dots in a single desaturated color. The layers move at slightly different speeds (parallax at 1.0×, 0.6×, 0.3× scroll rates). For Bunny Farm Idle's Cosmic tier rabbits, this is the background reveal technique — the hutch environment should dissolve to this layered void as the rabbit materializes.

**What to avoid:** Hollow Knight's color palette's pervasive cool grey-brown desaturation applied to the particles themselves. Hollow Knight's void reads as melancholy and threatening. Bunny Farm Idle's Cosmic reveal should read as transcendent and celebratory. The particle colors should shift from the rabbit's own dominant coat color toward near-white luminous tones — the void is that rabbit's personal cosmos, not an abyss.

**Why this source:** No pixel game has solved the "small sprite, enormous stakes reveal" problem more elegantly — Team Cherry demonstrates how environmental context transformation, not sprite complexity alone, makes a reveal feel legendary in scale.

---

#### Reference 05: Kirby's Dream Land 2 (Game Boy Color) — Seasonal Color System

**Source:** Kirby's Dream Land 2 (HAL Laboratory, 1995) — specifically the Game Boy Color enhanced version's world map and stage transition screens, studied as a palette system rather than an art style

**What to take:** The discipline of committing to a fixed limited palette per world zone and never exceeding it, even for UI elements that appear within that zone. Study specifically how the Ripple Star world uses a consistent pastel lavender mid-tone across disparate elements — floor tiles, Kirby's blush coloring, enemy highlight colors — to unify a scene without making everything the same color. Bunny Farm Idle's seasonal system requires the same discipline: Spring's palette must govern everything visible on screen during Spring.

**What to avoid:** The extremely high chroma saturation spikes on Kirby enemy sprites — the bright reds and pure yellows. That technique is a Game Boy Color compensation for low-resolution display contrast that is no longer needed on modern mobile screens and will read as garish on OLED panels. All season palettes should have a slightly softened saturation ceiling — approximately 75–80% maximum HSB saturation, with legendary rabbit coats as the only elements permitted to push toward full chroma.

**Why this source:** Kirby's Dream Land 2 remains the clearest existing demonstration that a fixed zone-committed color palette produces instant environmental legibility — the player knows what season they are in from peripheral vision alone.

---

#### Anti-References

Three visual spaces the art team must consciously avoid inhabiting:

**Hay Day (Supercell)** is the primary trap. Its rounded cartoon characters, bright primary-color palette, and clean outlined farm buildings represent the dominant visual language of the mobile idle-farm genre. Any rabbit sprite or environment tile that feels "Hay Day-adjacent" will cause the game to disappear into the genre's visual noise. The specific danger is rounded rectangular UI panels with drop shadows and thick outlines — that combination is Hay Day's visual fingerprint, and it must be avoided in favor of more irregular organic panel shapes with dithered or textured edges.

**Pokémon (pixel era, Generation 3–4)** is the character design trap. Pokémon's pixel sprites are designed for a grid-based combat system that demands instant aggressive/passive legibility. Bunny Farm Idle rabbits are pets, not combatants. Sprites must prioritize softness and roundness over the silhouette-readability rules that govern Pokémon design. If a rabbit sprite looks like it belongs in a battle screen, redesign it.

**A Short Hike (adamgryu)** is the palette trap. Its soft pastel, slightly washed-out color language sits dangerously close to what Bunny Farm Idle's cozy farm aesthetic could become if the seasonal palette discipline is not maintained. A Short Hike's colors are uniformly desaturated across all elements, which creates a dreamy detachment. Bunny Farm Idle's palette must have clear warm-cool contrast and rarity-driven saturation escalation. If every element looks equally "gentle," the rarity escalation from Common to Cosmic loses its visual grammar entirely.

---

*Art bible v1.0 — Bunny Farm Idle — 2026-05-18*
*Authored with art-director and technical-artist agents. Review mode: lean (AD-ART-BIBLE skipped).*
*Next step: `/consistency-check` to validate GDDs against this art bible's visual rules.*
