# Accessibility Requirements — Bunny Farm Idle

**Version**: 1.0
**Date**: 2026-05-18
**Accessibility Tier**: Standard

---

## Committed Accessibility Tier: Standard

**Standard** tier means:

- All critical gameplay information is available via at least two sensory channels (not just color or just sound)
- All interactive elements meet the 44×44px minimum touch target on primary platforms
- Text is scalable without loss of functionality
- A colorblind mode exists that replaces color-only signals with shape/pattern backups
- Notifications are non-disruptive and dismissable
- No timed actions require faster response than 3 seconds on standard difficulty

**Out of scope for this tier** (would require Advanced tier):
- Full screen reader support
- Haptic-only feedback paths
- Motor accessibility remapping (no physical controls on mobile)

---

## 1. Visual Accessibility

### 1.1 Text Size Scaling

Three scales supported (user-configurable in Settings):
- **Small**: 0.85× base type sizes
- **Medium** (default): 1.0× base type sizes  
- **Large**: 1.25× base type sizes

Layouts must accommodate the 1.25× scale without truncation or overflow. Any text that cannot fit must scroll or use abbreviated form with a tooltip, never get clipped silently.

**Minimum text sizes (at Medium scale):**
- Body text: 13sp minimum
- Labels and secondary text: 11sp minimum
- In-world floating text (collection indicators): 10sp minimum, decorative only

### 1.2 Colorblind Mode

Colorblind mode is a user-configurable setting (Settings → Accessibility → Colorblind Mode).

When active, the following substitutions are applied across the UI:

**Stat bars** — each bar gains a unique pattern fill in addition to its color:
- Hunger bar: diagonal hatch pattern
- Happiness bar: dot grid pattern
- Health bar: horizontal line pattern
- Cleanliness bar: wave line pattern

At 0% (critical state), the stat icon gains a unique outline shape badge:
- Hunger: X icon
- Happiness: sad face icon
- Health: cross/plus icon
- Cleanliness: alert triangle icon

**Gene slots** — dominant vs. recessive distinction uses border style in addition to opacity:
- Dominant allele: solid border
- Recessive allele: double-dashed border

**Rarity borders** — each rarity tier uses a unique border pattern in addition to color:
- Common: solid single border
- Uncommon: dash-dot border
- Rare: double line border
- Epic: animated dash border
- Legendary: animated gradient border with particle elements

**Notification bell** — urgent state adds an animated exclamation mark badge to the bell center in addition to the pulsing color change.

**Seasonal HUD icon** — a dedicated season icon always appears in the HUD corner regardless of colorblind mode (flower bud / sun / leaf / snowflake). This ensures seasonal identity is communicated without relying on the environment palette shift.

### 1.3 Contrast Requirements

All text must meet WCAG AA contrast ratio:
- Normal text (below 18sp): minimum 4.5:1
- Large text (18sp and above): minimum 3:1
- This applies in both Light Mode and Dark Mode

Known borderline: Lavender Gene `#9B72CF` used as a small label color against Parchment `#FAFAF5` — must be verified at implementation and may require the darkened variant `#7A58A8` for labels below 13sp.

### 1.4 No Flashing / Strobing

The Legendary reveal animation uses a full-screen flash followed by particle explosion. The flash duration must not exceed 3 frames (at 12 FPS reveal playback = ~250ms). A single flash event of this duration is within safe photosensitivity limits (Harding test threshold requires ≥3 flashes per second to be flagged).

If a Reduce Motion setting is implemented in a future version, the flash would be replaced by a slower fade-in, but this is not required for the Standard tier.

---

## 2. Touch / Motor Accessibility

### 2.1 Touch Target Minimum

All interactive elements on the primary platforms (Android/iOS) must have a minimum touch target of **44×44px** (per Apple HIG and Android Material Design guidelines).

Known risk areas requiring explicit implementation verification:
- Gene slots on the rabbit card: defined at 44×44px — must not be reduced
- Stat bar area on rabbit card: stat bars are not tappable, only the action button row below them is
- Navigation tab icons: must meet 44×44px inclusive of tap area, even if the visual icon is smaller
- Currency icons in header: read-only (not interactive), exempt from this requirement

### 2.2 One-Hand Usability

All frequent-action elements (actions performed multiple times per session) must be reachable by thumb in the bottom 60% of the screen in portrait mode.

Non-negotiable layout rules:
- Bottom navigation bar is permanently thumb-accessible
- Rabbit card action buttons (Feed / Play / Clean / Breed) are pinned to the bottom of the card modal and do not scroll away
- The Breed button on the breeding screen sits above the bottom navigation area
- No primary CTA buttons are placed in the header or top 40% of the screen

### 2.3 No Timed-Response Actions Required for Core Loop

The core loop (care for rabbits, collect resources, breed) must not require timed input faster than 3 seconds for any action. Mini-games (Speed Feed, Carrot Dash) that have fast input requirements are clearly labeled as optional mini-games and are not on the critical path for progression.

---

## 3. Cognitive Accessibility

### 3.1 Simplified Mode

Simplified mode is offered to new players during their first 5 sessions, or available at any time in Settings → Accessibility → Simplified Mode.

When active:
- Gene slots on the rabbit card are hidden and replaced by a single "Genes: Tap to explore" prompt pill
- The breeding screen shows only the outcome prediction ("Most likely: Uncommon") without the allele-by-allele probability grid
- Probability percentage labels are hidden; only the segmented bar remains

A "Simplified" pill badge appears on any panel where complexity has been removed — tappable to explain what was hidden and provide a link to Settings.

### 3.2 No More Than 2 Taps for Frequent Actions

Per GDD UX principles: any action performed multiple times per play session must be reachable in 2 taps from the main farm view. Verified critical paths:
- Feed a rabbit: Farm view → Tap rabbit → Tap Feed button (2 taps from farm)
- Collect idle production: Farm view → Tap collection indicator (1 tap)
- Start breeding: Farm view → Tap Breeding tab → Select parents → Tap Breed (3 taps from farm — acceptable as breeding is a deliberate decision, not a frequent micro-action)

### 3.3 Notification Frequency

Notifications must be non-disruptive. Rules:
- No forced full-screen interrupts except for the first-time tutorial
- Push notifications (when app is backgrounded) are opt-in and rate-limited to a maximum of 2 per 4-hour period
- In-app notification badge on the nav bar — does not pause or interrupt gameplay
- Urgent alert (rabbit health critical) plays an ambient audio cue and shows the notification badge; it does not show a modal dialog

---

## 4. Audio Accessibility

Standard tier does not require full audio description or screen reader support. However:

- All tutorial instructions must be conveyed via both text and visual demonstration (not audio alone)
- All game state information conveyed by audio must also be conveyed visually
- Audio cues are supplementary to visual cues, never the sole channel for critical information
- Volume controls for SFX and music are separate and accessible from the main settings screen

---

## 5. Localization Accessibility

All player-facing text must pass through the localization system — no hardcoded strings in `src/`. This ensures that text scaling, right-to-left support, and language-specific typographic rules can be applied consistently.

At launch, the game ships in Vietnamese (development language) and English. Additional languages may be added in post-launch localization sprints.

---

## 6. Testing Requirements

Before any screen passes visual review, the following accessibility checks must be run:

1. **Deuteranopia simulation**: Apply a deuteranopia color filter to all UI screens and verify that every color-coded signal has a non-color backup cue. Any screen that fails this check has a production defect.
2. **44×44px touch target audit**: Use an overlay grid to verify all interactive elements in every screen.
3. **Large text scale test**: Set text scale to 1.25× and run through all major screens verifying no truncation or overflow.
4. **1-hand reach test**: Verify all frequent-action elements are reachable in the bottom 60% of the screen on a standard phone form factor (375px wide portrait reference).

---

*Accessibility tier: Standard — committed 2026-05-18*
*Review this document when adding any new screen or major UI feature.*
