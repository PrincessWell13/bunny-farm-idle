# Interaction Pattern Library — Bunny Farm Idle

**Version**: 1.0
**Date**: 2026-05-18

This document is the canonical reference for all interaction patterns used in the game. When designing a new screen or feature, select from these patterns first. Add a new pattern only when an existing one does not adequately serve the interaction need.

---

## Pattern Index

| ID | Pattern | Used In |
|----|---------|---------|
| IP-01 | [Bottom Sheet Modal](#ip-01-bottom-sheet-modal) | Rabbit card, shop panel, quest details |
| IP-02 | [Tab Bar Navigation](#ip-02-tab-bar-navigation) | Main navigation (Farm / Breeding / Guild / Shop / Quest) |
| IP-03 | [Tap to Collect](#ip-03-tap-to-collect) | Idle production collection, harvest |
| IP-04 | [Diegetic World Tap](#ip-04-diegetic-world-tap) | Tapping a rabbit, tapping a hutch |
| IP-05 | [Swipe Dismiss](#ip-05-swipe-dismiss) | Dismissing bottom sheet modals |
| IP-06 | [Cascade Reveal](#ip-06-cascade-reveal) | Offline return summary, breeding result reveal |
| IP-07 | [Gene Slot Select](#ip-07-gene-slot-select) | Breeding screen gene selection |
| IP-08 | [Confirm Action Dialog](#ip-08-confirm-action-dialog) | Irreversible or costly actions (dismantle, prestige) |
| IP-09 | [Toast Notification](#ip-09-toast-notification) | Passive information delivery (achievements, warnings) |
| IP-10 | [Drag to Select Pair](#ip-10-drag-to-select-pair) | Selecting breeding parents from rabbit grid |
| IP-11 | [Full-Screen Reveal](#ip-11-full-screen-reveal) | Legendary rabbit reveal moment |
| IP-12 | [Inline Upgrade Panel](#ip-12-inline-upgrade-panel) | Hutch upgrade, habitat improvement |

---

## IP-01: Bottom Sheet Modal

**Intent:** Present detailed information or secondary actions for a tapped world object without leaving the main view.

**Trigger:** Tap on any interactive world object (rabbit, hutch, item). Also triggered programmatically for screens accessed via the tab bar (Shop, Quest, Guild).

**Behavior:**
- Sheet slides up from the bottom edge of the screen over 300ms (ease-out, spring finish — slight overshoot then settle)
- Sheet height varies: short (40% screen height for simple confirmations), medium (65% for rabbit card), tall (85% for gene lab / shop)
- Background dims to `rgba(0,0,0,0.4)` — tapping the dimmed area dismisses the sheet (see IP-05)
- The farm world remains visible behind the dim — the player retains spatial context
- Bottom navigation bar is hidden while a tall (85%) sheet is open; visible for short and medium sheets

**On dismiss:**
- Sheet slides down over 200ms (ease-in)
- Background dim fades out over 150ms
- Farm returns to its previous state

**Content rules:**
- Action buttons always pinned to the bottom of the sheet — they do not scroll away
- Content area above action buttons is scrollable if it overflows
- Sheet must not cover the entire screen (always leave at least 15% of the farm world visible at the top edge)

**Accessibility:**
- Sheet receives focus when it opens (VoiceOver/TalkBack compatible in future Advanced tier)
- Swipe down gesture for dismiss (IP-05)
- Tap outside to dismiss for short and medium sheets; tall sheets require explicit dismiss button

---

## IP-02: Tab Bar Navigation

**Intent:** Primary navigation between the game's five main areas.

**Tabs:** Farm | Breeding | Guild | Shop | Quest

**Behavior:**
- Always visible at the bottom of the screen (except when a tall bottom sheet is open)
- Active tab raises up (3px protrusion, trapezoidal shape) and shows filled icon + darker label
- Inactive tabs show outline icon + lighter label at 60% opacity
- Tab switch animation: active tab drops back flush (60ms ease-in), new tab raises (80ms ease-out, 1px overshoot)
- Notification badges appear at the top-right of the tab icon for pending actions (see Art Bible Section 7.3)

**Locked tab behavior:**
- Shows padlock icon + "???" label
- Tap shows a "Unlocks at Level [X]" tooltip but does not navigate

**Accessibility:**
- Tab bar has dynamic bottom padding equal to the system home indicator safe area
- All tabs meet 44×44px touch target inclusive of the padding
- Active state communicated by shape (raised) and fill (not color alone)

---

## IP-03: Tap to Collect

**Intent:** One-tap collection of ready resources from the farm world.

**Visual indicator:** A floating animated icon appears above the ready object (coin stack, carrot icon, etc.) with a gentle bob animation (±4px, 1s cycle). Icon spawns as a pop-in animation (scale 0→1.1→1.0, 200ms) and despawns as a pop-out (scale 1.0→0, 150ms) after collection.

**Behavior:**
- Player taps the floating icon directly
- On tap: the icon plays a "fly to header" animation — the icon travels in a curved arc to the currency display in the header (300ms, ease-in acceleration)
- The currency counter in the header increments via the roll-up animation as the icon arrives
- If the player taps the hutch itself (not the floating icon), the collection is also triggered (IP-04 handles the tap; the hutch detects that its production is ready and triggers collection before opening the rabbit card)
- Multiple floating icons can appear simultaneously; each is collected independently

**Accessibility:**
- Collection icons are large enough to tap without precision (minimum 44×44px including tap area)
- Collection can also be triggered by tapping the hutch itself (fallback, lower precision requirement)
- The currency animation provides visual confirmation — no dialog or confirmation step required

---

## IP-04: Diegetic World Tap

**Intent:** Interaction with rabbits and hutches in the farm world.

**On rabbit tap:**
- Rabbit plays a brief "acknowledged" animation (head bob, 2-frame, 200ms)
- The rabbit card bottom sheet opens (IP-01, medium height)
- If the rabbit has urgent needs (health < 25%, hunger at 0%), the sheet opens directly to the stat section with the critical stat highlighted

**On hutch tap:**
- If production is ready: collect it first (IP-03 fly animation), then open the hutch contents panel
- If no production ready: open the hutch contents panel directly as a bottom sheet (IP-01)
- The hutch contents panel shows all rabbits currently in the hutch as a scrollable grid of portrait thumbnails

**On empty farm ground tap:**
- No action. Empty ground taps are consumed without feedback. Do not show an error or "nothing here" message — silence is the correct response.

**Held tap / long press:**
- After 500ms hold: enter "farm management mode" — hutches show a subtle highlight border, allowing the player to drag or rearrange them (feature scope: post-MVP)
- For MVP: long press on a rabbit shows a context menu (quick-actions: Feed, Play, Breed) as a small radial menu centered on the rabbit sprite

---

## IP-05: Swipe Dismiss

**Intent:** Quick gesture to dismiss a bottom sheet modal without tapping an explicit close button.

**Trigger:** Downward swipe beginning inside the bottom sheet, dragging more than 80px toward the bottom of the screen.

**Behavior:**
- As the player swipes, the sheet follows the gesture in real time (1:1 tracking)
- If the player releases before the 80px threshold: sheet springs back to its resting position (spring animation, 250ms)
- If the player releases after the 80px threshold: sheet completes the dismiss animation (slides to off-screen bottom, 200ms ease-in)
- Velocity matters: a fast flick dismisses regardless of distance (if velocity > 800px/s in downward direction at release, dismiss unconditionally)

**Accessibility:**
- Dismiss button (×) is always present in the top-right of the sheet as a tap fallback
- Tapping the dim background also dismisses (for short and medium sheets)
- Tall sheets (85%) require either swipe or explicit × tap — no background-tap dismiss (prevents accidental dismissal of complex screens)

---

## IP-06: Cascade Reveal

**Intent:** Present a multi-part result one item at a time to maximize the emotional satisfaction of discovering growth or outcomes.

**Used for:**
- Offline return summary (production accumulated while the player was away)
- Breeding result breakdown (trait-by-trait reveal before the final offspring card appears)

**Behavior:**
- Screen presents a header ("You were away for X hours" or "Breeding Complete!")
- Items appear one at a time from top to bottom, each with a brief pop-in animation (scale 0→1.1→1.0, 150ms)
- Between items: 120ms pause
- Each item shows a rising counter from 0 to final value (200ms duration, ease-out)
- After all items appear: a summary line with a "Collect All" or "Continue" button fades in (300ms)
- Tapping "Collect All" / "Continue" triggers a single large collection animation — all amounts fly to their respective currency displays simultaneously

**Acceleration:** If the player taps anywhere during the cascade before all items have appeared, the remaining items snap to their final values instantly (the cascade is skippable, not mandatory).

**Accessibility:**
- Cascade can be skipped by tap (important for experienced players who know the results)
- All information is also summarized in the final "Collect All" state — players who skip do not miss data

---

## IP-07: Gene Slot Select

**Intent:** Allow players to inspect and interact with individual gene slots in the breeding and rabbit card interfaces.

**On gene slot tap:**
- Slot plays a brief highlight pulse (Lavender Gene `#9B72CF` border brightens for 200ms)
- A tooltip card slides up or pops up near the slot (appears above the slot, never clipped by screen edge)
- Tooltip shows: gene name (full), allele options for this gene (both parent alleles shown), trait effect if expressed, probability of dominant expression

**Tooltip dismissal:**
- Tapping anywhere outside the tooltip dismisses it (150ms fade-out)
- Tapping a different gene slot dismisses the current tooltip and opens the new one in sequence

**In breeding screen (interactive select):**
- Gene slots in the combination grid are informational (read-only) — tap shows tooltip but does not trigger an action
- Parent selection is handled by tapping the parent portrait panels, not individual gene slots

**Accessibility:**
- Gene slot touch target is 44×44px — non-negotiable (see accessibility requirements)
- Tooltip positioning must never cover the gene slot it describes
- Tooltip appears on the side of the slot with more screen space (auto-positioning)

---

## IP-08: Confirm Action Dialog

**Intent:** Prevent accidental execution of irreversible or high-cost actions.

**Trigger conditions (always require confirmation):**
- Dismantling a rabbit for Gene Fragments (irreversible)
- Initiating Prestige (resets core progress)
- Spending Crystal Gems (premium currency)
- Sending a rabbit on a long expedition (8 hours or more — rabbit is unavailable during this time)
- Selling a Rare or higher rabbit for Carrot Coins

**Dialog design:**
- Appears as a centered modal (not a bottom sheet) with a dim overlay
- Contains: action title, brief consequence statement, two buttons — Confirm (stadium, Carrot `#FF8C42` fill) and Cancel (ghost button, Worn Oak border)
- The Confirm button is never the default focused state — the player must actively move to it
- For Crystal Gem purchases: dialog prominently shows the gem cost and the player's current gem balance before confirming

**What does NOT require confirmation:**
- Feeding a rabbit
- Cleaning a hutch
- Sending a rabbit on a short expedition (< 2 hours)
- Buying common items with Carrot Coins

**Accessibility:**
- Cancel is always the less visually prominent option (ghost button) — favors the safe choice without hiding the confirm action
- Dialog cannot be dismissed by tapping the background — must use Cancel button explicitly

---

## IP-09: Toast Notification

**Intent:** Deliver non-critical, time-sensitive information without interrupting gameplay.

**Visual:** Full-width banner, flat top edge, softly curved bottom. Slides in from the top of the screen over 200ms (ease-out), pauses for 3 seconds, slides out over 200ms (ease-in). Appears below the header bar, above the farm world.

**Variants:**

| Type | Background | Icon | Examples |
|------|-----------|------|---------|
| Info | Parchment `#FAFAF5` | Blue info circle | "Spring season begins!" |
| Success | Meadow `#B8E4B8` | Green checkmark | "Breeding complete!" |
| Warning | Hearthstone `#F5E6D3` | Carrot warning icon | "3 rabbits are hungry" |
| Achievement | Lavender Gene `#9B72CF` | Star | "New achievement unlocked" |

**Rules:**
- Toast notifications do not pause gameplay
- Maximum one toast visible at a time; subsequent toasts queue and display sequentially
- Tapping a toast before it auto-dismisses accelerates dismissal (immediate) and if the toast is actionable (e.g., "Breeding complete — tap to see"), navigates to the relevant screen
- No toast notification for events the player is already watching (e.g., no "Collection ready" toast if the player is looking at the farm and can see the floating icon)

**Accessibility:**
- Toast content is also written to the in-game notification log (accessible via the bell icon in the header)
- No toast is the sole communication channel for any critical game state — they are supplementary

---

## IP-10: Drag to Select Pair

**Intent:** Allow players to quickly select two rabbits from a grid to designate as a breeding pair.

**Trigger:** From the Breeding screen parent selection area, tapping an empty parent slot opens a rabbit selection grid. The grid shows all Adult and Elder rabbits the player owns.

**Behavior in the selection grid:**
- Tapping a rabbit selects it as the parent for the open slot (left or right, depending on which was tapped)
- The selected rabbit gets a Lavender Gene `#9B72CF` highlight ring on its portrait
- Tapping the same rabbit again deselects it
- If the player selects a rabbit that is already selected as the other parent, the selection is prevented with a brief shake animation (3px, 150ms) and an inline message "A rabbit cannot breed with itself"
- After selecting a rabbit, the grid closes and the parent portrait in the breeding panel updates

**Filtering:**
- Filter chips at the top of the selection grid allow filtering by: Life Stage, Rarity, Trait (any)
- Active filter chips are shown in Lavender Gene `#9B72CF` fill; inactive in Worn Oak outline
- The filter bar does not scroll away — it is sticky at the top of the grid

**Accessibility:**
- Rabbit portrait thumbnails in the selection grid are minimum 64×64px (larger than the 44×44px minimum to accommodate the rarity border and the tap target for players with larger fingers)

---

## IP-11: Full-Screen Reveal

**Intent:** Deliver maximum emotional impact for the Legendary rabbit reveal moment.

**Trigger:** A Legendary-tier or higher rabbit is produced by breeding or obtained from an event.

**Sequence:**
1. The normal breeding result interface (IP-06 cascade reveal) completes normally up to the point of showing the offspring rarity
2. When the result is Legendary or higher: all UI transitions out over 300ms
3. The screen goes dark (deep violet-navy `#1A0A2E`) over 400ms — a slow deliberate blackout
4. After the blackout reaches full: 1 beat of silence (200ms)
5. Full-screen white flash (pure `#FFFFFF`, 1 frame at 12 FPS = ~80ms)
6. The rabbit appears in the center of the dark screen, lit from multiple rim directions, particle explosion radiating outward from the reveal point
7. The rabbit's name and rarity tier fade in over 400ms below the portrait
8. The complete reveal screen persists until the player taps to continue (no auto-advance)

**Rules:**
- No other UI appears during the reveal (no currency counts, no navigation bar, no header)
- The reveal sequence must not be skippable until after step 7 (the rabbit is visible and the name has appeared)
- After the name appears, a brief "tap to continue" prompt fades in at the bottom of the screen
- After the player taps to continue: the full reveal collapses to the normal rabbit card bottom sheet (IP-01)

**Accessibility:**
- The full-screen flash (step 5) is limited to a single ~80ms burst — within safe photosensitivity limits
- A "Reduce Motion" setting (post-MVP) would replace the flash with a slow fade-in

---

## IP-12: Inline Upgrade Panel

**Intent:** Present habitat upgrade options and confirm upgrades from within the farm view, without navigating to a separate screen.

**Trigger:** Tapping the "Upgrade" affordance on a hutch (shown as a small hammer icon badge on the hutch when an upgrade is available and the player has sufficient resources).

**Behavior:**
- Opens as a bottom sheet (IP-01, medium height — 65%)
- Shows: current hutch tier (name, capacity, bonuses), next tier (name, capacity, bonuses, cost)
- The difference in capacity and bonuses is highlighted in green (gain) or red (cost) — never shown as only a number, always shown as ±Δ
- Upgrade button: stadium shape, Carrot `#FF8C42` fill, shows the cost inline in the button label ("Upgrade — 500 CC")
- If the player does not have sufficient resources: upgrade button is disabled (ghost style, Worn Oak border, 50% opacity) with an inline note: "Need 200 more CC"

**After upgrade confirmation:**
- The upgrade confirmation dialog (IP-08) appears with cost shown prominently
- On confirm: the bottom sheet dismisses, and the hutch exterior plays its tier-transition animation (see Art Bible Section 6.2)
- A success toast (IP-09) appears: "Hutch upgraded to [Tier Name]!"

**Accessibility:**
- The upgrade cost and current balance are both shown in the sheet — no need to dismiss and check the header
- The disabled upgrade button provides an inline explanation of what is lacking, not just a greyed button

---

*Interaction Pattern Library v1.0 — Bunny Farm Idle — 2026-05-18*
*Add new patterns here before implementing novel interaction patterns. Patterns not listed here require Art Director + UX review before use.*
