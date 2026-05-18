# Character Visual Profiles — Bunny Farm Idle

**Version**: 1.0
**Date**: 2026-05-18

This document defines the visual identity for all characters in the game. "Characters" includes the player avatar, named NPCs, and the rabbit archetypes (which are the primary cast).

All visual decisions here must be consistent with `design/art/art-bible.md` Sections 4–6.

---

## 1. Player Avatar

The player is "the Farmer" — an off-screen presence whose identity is suggested rather than shown. The player never appears as a full sprite in the game world.

### Visual Representation

| Context | Visual Form | Spec |
|---------|-------------|------|
| Main menu / profile | Circular portrait icon, 64×64px | Abstract silhouette in a white lab coat, holding a clipboard. Face hidden under a wide-brim straw hat (farm aesthetic) or goggles (lab aesthetic). Single outline style matching rabbit art. |
| HUD header (future) | 24×24px avatar icon | Simplified to hat + outline only — no face detail visible at this size |
| Dialogue / popup | Not shown — dialogue uses text only | No talking-head cutscene |

### Color Palette (4 colors max per Art Bible rules)

- Outline: Worn Oak `#8B6B4A`
- Lab coat: Parchment `#FAFAF5` with Hearthstone `#F5E6D3` shadow
- Hat: Worn Oak `#8B6B4A` with Hearthstone highlight
- Accent (clipboard or goggles): Lavender Gene `#9B72CF`

### Personality Signal

The dual hat+goggles design communicates the core game tension: farmer (straw hat) + scientist (goggles). Both accessories are always visible. Neither dominates — this is intentional ambiguity reflecting the player's dual role.

---

## 2. Rabbit Archetypes

Rabbits are the primary characters. Each archetype has a defined visual profile that all rabbits of that type must respect. Trait expressions and rarity borders are layered on top of the archetype base.

### 2.1 Baby Rabbit

**Life Stage**: Baby (0 → Adult threshold)
**Sprite Size**: 32×32px (occupies ~12×14px of that space at rest)

| Feature | Spec |
|---------|------|
| Head:body ratio | 2:1 (oversized head — triggers instinctive caregiving response) |
| Eyes | Large, high on head, circular — at least 4px diameter at 32×32 |
| Ears | Short, barely visible above head (≤ 6px tall). Cannot identify breed from ears alone at this stage. |
| Outline | 1px solid Worn Oak `#8B6B4A` |
| Color area | Max 3 colors (base coat + shadow + eye color) |
| Aura | Never has aura at Baby stage |
| Idle animation | Small breath cycle (±1px body scale), ear twitch every 2–3s |

**Baby visual rule**: All babies look similar — breed identity is not readable yet. This is intentional and mirrors real biology.

---

### 2.2 Adult Rabbit

**Life Stage**: Adult (primary gameplay life stage)
**Sprite Size**: 32×32px (occupies ~20×22px of that space)

| Feature | Spec |
|---------|------|
| Head:body ratio | 1:1.2 (body slightly larger than head — mature proportion) |
| Eyes | Medium size, 3px diameter |
| Ears | Full length — this is where breed identity lives. Ear pair shape is the primary silhouette signal (lop, erect, rex). Min 8px tall at 32×32 (per Art Bible Section 3). |
| Outline | 1px solid Worn Oak `#8B6B4A` |
| Color area | Max 5 colors (base coat + shadow + highlight + eye + accent trait if any) |
| Aura | Lavender Gene `#9B72CF` 1px ring outside outline — present for Epic+ rarity, opacity 20–60% breathing cycle |
| Idle animation | Tail bob (2-frame, 60fps cycle), occasional ear turn |

**Rarity visual escalation** (applied as overlay to any Adult archetype):

| Rarity | Border Style | Additional Visual |
|--------|-------------|-------------------|
| Common | Solid 1px Worn Oak | None |
| Uncommon | Solid 1px `#4A7B4A` (green) | None |
| Rare | Solid 2px `#4A6B9B` (blue) | None |
| Epic | Animated dash border `#9B72CF` | Subtle particle trail on movement |
| Legendary | Animated gradient border (gold→amber cycle) | Aura at 60% opacity, glow bloom |
| Mythic/Cosmic | No outline (sprite radiates its own border light) | Concentric ring pulse, orbital particles |

---

### 2.3 Elder Rabbit

**Life Stage**: Elder (final stage; higher production, eventual natural death)
**Sprite Size**: 32×32px (occupies ~22×24px — slightly larger than Adult due to posture)

| Feature | Spec |
|---------|------|
| Head:body ratio | 1:1 (body fills more of the sprite — settled, heavier) |
| Eyes | Same size as Adult but with 1px "tired" line below eye (single pixel drawn below the eye circle) |
| Ears | Same as Adult but drooped by ~2px at tips — any ear type gains a subtle downward angle |
| Outline | 1px Worn Oak `#8B6B4A` |
| Color area | Same as Adult + optional grey muzzle (2×2px area at snout, grey `#A0A0A0`) |
| Aura | Same rules as Adult; intensity unchanged by age |
| Idle animation | Slower breath cycle (±1px, 90fps cycle instead of 60fps) — visually calmer |

**Elder signal rule**: A player must be able to distinguish Elder from Adult at a glance without checking the UI. The drooped ear tips and grey muzzle are the canonical signals. Both must be present on all Elder sprites.

---

### 2.4 Breeding Rabbit (state overlay)

When a rabbit is currently in the Breeding room or assigned as a breeding parent, it receives a visual overlay:

| Feature | Spec |
|---------|------|
| Heart indicator | A 4×4px pink `#FF9EB5` heart badge above the rabbit's head, bob animation (±2px, 1s cycle) |
| Sprite | Standard Adult or Elder sprite — no change to the rabbit itself |
| Aura | Temporarily shifts to pink tint if normally Lavender Gene — returns to normal after breeding |

---

### 2.5 Expedition Rabbit (state overlay)

When a rabbit is away on an expedition, it does not appear in the farm view. In the expedition roster UI, it is shown as:

| Feature | Spec |
|---------|------|
| Sprite | Standard sprite with a 50% opacity desaturation (greyed out) |
| Overlay | A small directional arrow (→) badge at bottom-right, 8×8px, Carrot `#FF8C42` |
| Return timer | Shown below the sprite in the roster (not part of the character sprite itself) |

---

### 2.6 Sick Rabbit (state overlay)

When a rabbit's health drops below 25%, it enters the Sick state:

| Feature | Spec |
|---------|------|
| Sprite | Standard sprite with a greenish tint overlay (`#80FF80` at 15% opacity) |
| Sick indicator | A small cross/plus icon (4×4px, `#FF4444`) above the head, replacing any heart badge |
| Idle animation | Slower, adds occasional "slump" frame (body drops 1px, stays 1 frame) |
| Aura | Temporarily suppressed even on Epic+ rabbits — sick rabbits lose their glow |

---

### 2.7 Legendary Reveal (special state — not an archetype)

The Legendary Reveal sequence (IP-11) uses a special presentation of the rabbit sprite:

| Feature | Spec |
|---------|------|
| Sprite | Full 32×32px sprite centered on a `#1A0A2E` dark screen |
| Scale | Rendered at 3× (96×96px) for the reveal moment — pixel-perfect upscale (nearest filter) |
| Lighting | 4 rim lights drawn as colored pixel highlights around the outline (warm amber top, cool lavender left and right, deep shadow bottom) |
| Particle explosion | White star pixels radiate from the center outward; fade out over 600ms |
| After reveal | Returns to standard 32×32px in the rabbit card bottom sheet |

---

## 3. Named NPCs (Future — Post-MVP)

No named NPCs exist at MVP. The following are planned for post-launch content:

| Character | Role | Design Direction |
|-----------|------|-----------------|
| Dr. Hopsworth | Guild mentor NPC | Older rabbit with glasses and lab coat — the "scientist" pole of the game's tension |
| Rosemary the Herbalist | Quest giver NPC | Human character, warm earth tones, carries a basket of carrots |
| The Cosmic Bunny | Mythic rabbit boss (Guild Raid) | No physical form — represented as a constellation of rabbit silhouettes in a star field |

These characters will receive full visual profiles when their systems enter design.

---

*Character Visual Profiles v1.0 — Bunny Farm Idle — 2026-05-18*
*Update this document when new characters enter design. Reference Art Bible Sections 4–6 for all decisions.*
