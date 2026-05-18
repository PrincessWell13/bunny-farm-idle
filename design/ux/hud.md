# UX Spec — HUD (In-Game Head-Up Display)

**Version**: 1.0
**Date**: 2026-05-18
**Screen**: HUD — persistent overlay visible during all main gameplay tabs

---

## 1. Purpose

The HUD provides at-a-glance access to the player's resources, notification state, and season information without requiring navigation. It is always visible during Farm, Breeding, Guild, Shop, and Quest tabs (except when a tall bottom sheet — 85% — is open).

---

## 2. Layout

### HUD Header Strip (top of screen)

```
┌──────────────────────────────────────────────────────┐  ← status bar safe area
│ [Season Icon] │ [🥕 Coins] │ [💎 Gems] │ [🔔 Bell] │
└──────────────────────────────────────────────────────┘
   ← 44px → ←── flex ──→ ←── flex ──→ ← 44px touch →
```

**Height**: 48px content area + top safe area inset
**Background**: Parchment `#FAFAF5` strip with 1px Worn Oak `#8B6B4A` bottom border
**Full width** — spans edge to edge

### HUD Footer (bottom navigation bar)

Defined separately in `interaction-patterns.md` IP-02. The tab bar is part of the HUD system.

---

## 3. HUD Header Elements

### Season Icon (left)

- 24×24px icon (flower bud / sun / leaf / snowflake per season)
- Always visible regardless of colorblind mode setting — this is the canonical season signal (per accessibility requirements)
- Tapping the season icon opens a tooltip: "[Season Name] — Day [X] of [total]"
- Tooltip dismisses on tap-outside (150ms fade-out)
- Touch target: 44×44px (icon is visually smaller; tap area extends)

### Coin Counter (center-left)

- Layout: `🥕 [value]` — carrot icon 20×20px + numeric value
- Icon source: `ui` atlas
- Value display:
  - < 1,000: show exact value (`452`)
  - 1,000–999,999: show abbreviated (`1.2K`, `45K`)
  - ≥ 1,000,000: show abbreviated (`1.2M`)
- Value updates via roll-up animation when coins arrive (triggered by `EventBus.coins_earned`): number counts up from old value to new value over 300ms ease-out
- Read-only — not tappable (exempt from 44×44px requirement per accessibility doc §2.1)

### Gem Counter (center-right)

- Layout: `💎 [value]` — gem icon 20×20px + numeric value
- Always shows exact integer value (gems are never abbreviated — they are premium and players track them carefully)
- Same roll-up animation on `EventBus.gems_spent` (counts down)
- Read-only — not tappable

### Notification Bell (right)

- Bell icon 24×24px, touch target 44×44px
- **States**:
  - Idle: outline bell, no badge
  - New notification: filled bell + numeric badge (count of unread notifications, max "9+") — badge at top-right of icon, Carrot `#FF8C42` fill
  - Urgent (rabbit health critical): filled bell + pulsing animation (scale 1.0→1.1→1.0, 800ms loop) + exclamation badge (replaces number badge in colorblind mode per accessibility requirements)
- Tapping opens the Notification Log as a tall bottom sheet (IP-01, 85% height)
- Notification Log shows all recent events in reverse-chronological order

---

## 4. When the HUD Is Hidden

| Condition | HUD Component Hidden |
|-----------|----------------------|
| Tall bottom sheet open (85%) | Bottom navigation bar hidden; header strip remains |
| Full-screen Legendary reveal (IP-11) | Both header and footer hidden — no UI during reveal |
| Tutorial overlay (first session) | Header and footer visible; tutorial highlight masks non-relevant elements |
| Loading transition between tabs | Header and footer remain visible (maintains spatial orientation) |

---

## 5. Interaction Patterns Used

| Pattern | How Applied |
|---------|-------------|
| IP-09 Toast Notification | Toasts appear below the header strip — they slide down from the header's bottom edge |
| IP-02 Tab Bar Navigation | The tab bar is the footer portion of the HUD system |
| IP-06 Cascade Reveal | Offline earnings summary overlays the farm view below the HUD |

---

## 6. Currency Animation Detail

When `EventBus.coins_earned` fires (e.g., from a collection tap via IP-03):
1. The flying icon from IP-03 completes its arc and arrives at the coin counter position
2. On arrival: counter plays roll-up (300ms, ease-out, counts from old to new value)
3. The counter briefly scales up to 1.05× and back to 1.0× (100ms bounce, ease-out)
4. No sound required (audio cue is on the collection tap itself, not the counter update)

When `EventBus.coins_spent` fires (purchase, upgrade cost):
1. Counter plays roll-down (same 300ms, counts down from old to new value)
2. No scale animation on decrease — only increases get the bounce

---

## 7. Accessibility

- Season icon is always visible as a non-color signal — satisfies colorblind mode requirement
- Notification bell urgent state adds exclamation badge in colorblind mode (shape signal, not color alone)
- Currency counters are read-only and exempt from touch target requirements
- Season icon tap target is 44×44px despite 24×24px visual size
- Bell tap target is 44×44px
- HUD header strip has sufficient contrast: Worn Oak `#8B6B4A` text on Parchment `#FAFAF5` = approximately 5.2:1 (passes WCAG AA)
- All HUD text is minimum 13sp at Medium text scale; at 1.25× Large scale, values may shorten (K/M abbreviation triggers earlier)

---

## 8. Dark Mode

At night (post-8pm real-world clock):
- HUD header background shifts to a darker parchment: `#E8E4D8` (not full dark mode — the farm theme stays warm)
- No separate "dark mode" toggle for the HUD — the night palette shift is automatic and tied to time of day

---

## 9. Edge Cases

- **Very large coin values** (post-prestige): abbreviation handles up to `999T` before switching to scientific notation `1.0e12` (unlikely in early builds — plan for it)
- **Notification count > 99**: show "99+" not the exact number
- **Tab bar hidden behind system gesture bar** (Android edge-to-edge): bottom navigation bar has dynamic bottom padding equal to system gesture safe area inset (per IP-02 accessibility)
- **Landscape orientation**: HUD header collapses to icon-only mode — values hidden until tapped; tab bar icons only (no labels). Landscape is not a primary use case but must not break.

---

*HUD UX Spec v1.0 — Bunny Farm Idle — 2026-05-18*
