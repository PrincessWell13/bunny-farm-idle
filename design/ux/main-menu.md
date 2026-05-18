# UX Spec — Main Menu

**Version**: 1.0
**Date**: 2026-05-18
**Screen**: Main Menu (first screen after game boot)

---

## 1. Screen Purpose

The main menu is the first thing a player sees after the game boots. It must:
- Communicate the game's visual identity immediately (cozy farm + genetic wonder)
- Get a returning player back to their farm in a single tap
- Give a new player a clear path to start

---

## 2. Layout

### Portrait Orientation (primary — mobile)

```
┌─────────────────────────────────────┐  ← status bar (OS)
│                                     │
│         [GAME TITLE LOGO]           │  ← ~20% from top
│      Bunny Farm Idle                │
│                                     │
│                                     │
│     [Animated farm background]      │  ← full-bleed illustration:
│     [rabbits idle in hutch yard]    │    parallax, subtle motion
│                                     │
│                                     │
│  ┌─────────────────────────────┐    │
│  │   ▶  Continue Farm         │    │  ← primary CTA (Carrot #FF8C42)
│  └─────────────────────────────┘    │    stadium shape, 56px height
│                                     │
│  ┌─────────────────────────────┐    │
│  │      New Game               │    │  ← secondary CTA (ghost button)
│  └─────────────────────────────┘    │    Worn Oak border, 48px height
│                                     │
│  [Settings ⚙]  [Credits ℹ]         │  ← icon buttons, 44×44px targets
│                                     │
│─────────────────────────────────────│  ← home indicator safe area
```

**"Continue Farm" button** appears only when a save file exists.
**"New Game" button** becomes the primary CTA (Carrot fill) when no save exists.

---

## 3. Animated Background

- Full-bleed farm scene — same visual style as the main farm view
- 2–3 rabbits performing idle animations (head bob, ear twitch)
- Subtle parallax on background layers (clouds or tree line drifts slowly)
- Time of day matches real-world clock: morning → afternoon → evening → night palette shift
- No interactive elements in the background — tap goes nowhere (avoids accidental hits)

**Seasonal treatment**: background reflects the current in-game season. If no save exists, defaults to Spring.

---

## 4. Interaction Patterns Used

| Pattern | How Applied |
|---------|-------------|
| IP-09 Toast Notification | If the save file has offline earnings pending, a toast appears 1s after the menu loads: "Welcome back! Tap to collect [X] coins." Tapping the toast navigates to the farm with the offline return summary open. |
| IP-08 Confirm Action Dialog | "New Game" when a save exists shows a confirmation dialog: "This will erase your current farm. Are you sure?" |

---

## 5. Button Behavior

### Continue Farm
- Loads `GameState.load_game()` → navigates to Farm tab
- If offline earnings are pending, the offline return summary (IP-06 Cascade Reveal) appears immediately on the Farm tab
- Loading state: the button label changes to "Loading…" with a spinning indicator; button becomes non-interactive during load

### New Game
- If no save exists: begins tutorial flow immediately
- If save exists: shows IP-08 Confirm Action Dialog before proceeding
  - Confirm label: "Start Fresh"
  - Consequence text: "Your current farm and rabbits will be permanently deleted."
  - Confirm = Carrot fill; Cancel = ghost button (default focus is Cancel)

### Settings
- Opens a full-screen settings panel (slide in from right, 300ms)
- Settings panel contains: Audio (SFX vol, Music vol), Accessibility (Text Size, Colorblind Mode, Simplified Mode), Account (Sign in / link Firebase), About

### Credits
- Opens a scrollable credits panel as a tall bottom sheet (IP-01, 85% height)

---

## 6. Accessibility

- "Continue Farm" and "New Game" buttons meet 44×44px minimum touch target
- The two icon buttons (Settings, Credits) meet 44×44px minimum touch target — the visual icon may be smaller but the tap area must extend to 44×44px
- The primary CTA is identified by fill color AND by being listed first — not color alone
- Background animation respects a "Reduce Motion" setting (post-MVP): if enabled, background is a static illustration

---

## 7. States

| State | Condition | Visible Elements |
|-------|-----------|-----------------|
| New Player | No save file exists | Logo, animated background, "New Game" (primary, Carrot fill), Settings, Credits |
| Returning Player | Save file exists | Logo, animated background, "Continue Farm" (primary, Carrot fill), "New Game" (secondary ghost), Settings, Credits |
| Loading | "Continue Farm" tapped, loading | Logo, background (frozen), "Loading…" button (non-interactive), Settings, Credits |

---

## 8. Edge Cases

- **Corrupted save file**: "Continue Farm" loads normally; if `SaveSystem.load_game()` fails, show an error toast: "Could not load your farm — the save file may be corrupted." Offer "Start Fresh" option.
- **Very slow load**: After 3 seconds with no progress, show: "Still loading… Check your connection." (Firebase sync may be blocking perceived load — though it should not; this is a diagnostic)
- **Small screen (<375px wide)**: Logo scales down. Button text truncates with ellipsis only as a last resort — preferred: reduce font size to 12sp minimum.

---

*Main Menu UX Spec v1.0 — Bunny Farm Idle — 2026-05-18*
