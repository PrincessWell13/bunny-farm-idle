# UX Spec — Pause Menu

**Version**: 1.0
**Date**: 2026-05-18
**Screen**: Pause Menu (in-game settings and utility overlay)

---

## 1. Purpose

The pause menu provides in-session access to settings, help, and game management without exiting to the main menu. On a mobile idle game, "pause" is less about stopping time (idle games run while away) and more about a utility overlay for adjusting settings mid-session.

**Important**: The game does NOT pause idle production when the pause menu is open. The menu is an overlay, not a true pause state. The visual game world continues to animate behind the dim.

---

## 2. Trigger

- The pause menu has no dedicated button — it is accessed via **Settings ⚙** in the HUD header notification panel, or via a long-press on the HUD header area (post-MVP gesture)
- For MVP: the Settings icon in the main menu leads to the same panel. In-game access is via the notification bell → log panel → Settings gear icon at the bottom of the log.
- Post-MVP: a dedicated settings icon in the HUD header replaces the roundabout path.

---

## 3. Layout

The pause menu opens as a **tall bottom sheet** (IP-01, 85% height) with a dim overlay. It does not use the full-screen modal pattern — the farm world remains partially visible at the top.

```
┌─────────────────────────────────────┐
│ ╱╱╱ [farm world visible, dimmed] ╱╱ │  ← 15% visible
├─────────────────────────────────────┤
│  Settings                        [×]│  ← sheet header, 48px
├─────────────────────────────────────┤
│                                     │
│  AUDIO                              │  ← section header (12sp, Worn Oak)
│  Music    [━━━●━━━━━━]  65%         │  ← slider, thumb 44×44px touch area
│  SFX      [━━━━━━●━━━]  80%         │
│                                     │
│  ACCESSIBILITY                      │
│  Text Size     [S] [M●] [L]         │  ← segmented control, active = filled
│  Colorblind    [Toggle ●OFF]        │  ← toggle switch
│  Simplified    [Toggle ●OFF]        │
│                                     │
│  GAME                               │
│  Account       Google Play / Sign In│  ← row with chevron →
│  Cloud Save    [Sync Now]           │  ← button, ghost style
│  Restore Purchases                  │  ← row with chevron →
│                                     │
│  ABOUT                              │
│  Version       1.0.0 (build 42)     │  ← read-only text
│  Credits       →                    │  ← row with chevron →
│  Privacy Policy →                   │  ← links out to browser
│  Terms of Service →                 │
│                                     │
├─────────────────────────────────────┤
│  [Return to Main Menu]              │  ← ghost button, destructive-adjacent
└─────────────────────────────────────┘
```

**"Return to Main Menu"** is the only potentially destructive action — it does not erase data but does end the current session context. It is styled as a ghost button (not Carrot fill) to reduce prominence.

---

## 4. Interaction Patterns Used

| Pattern | How Applied |
|---------|-------------|
| IP-01 Bottom Sheet Modal | Pause menu is a tall (85%) bottom sheet |
| IP-05 Swipe Dismiss | Swipe down dismisses the pause menu (resumes normal play) |
| IP-08 Confirm Action Dialog | "Return to Main Menu" shows a confirmation: "Return to main menu? Idle production continues while you're away." |

---

## 5. Settings Behavior

### Audio Sliders

- Two sliders: Music Volume (0–100%) and SFX Volume (0–100%)
- Slider thumb has 44×44px touch target regardless of visual size
- Changes apply in real-time as the thumb is dragged — no "Apply" button
- Changes are auto-saved to user preferences immediately on release (not tied to the main game save)

### Text Size (S / M / L)

- Segmented 3-option control: Small (0.85×) / Medium (1.0×, default) / Large (1.25×)
- Active segment: Carrot `#FF8C42` fill, white text
- Inactive segments: Worn Oak border, Worn Oak text
- Change applies to the game UI immediately in real-time — the panel itself re-renders
- Touch targets: each segment is at least 44px tall and 60px wide

### Colorblind Mode Toggle

- Standard toggle switch: off = Worn Oak background; on = Lavender Gene `#9B72CF` background
- Toggle thumb: white circle, 24×24px visual, 44×44px touch target
- Change applies immediately — all color-coded signals gain pattern backups as described in the accessibility requirements
- Label: "Colorblind Mode" — no subtype selection for MVP (single universal mode covering common deficiencies)

### Simplified Mode Toggle

- Same toggle style as Colorblind Mode
- When turned on: a brief explainer appears inline: "Gene complexity is hidden. Enable in Settings → Accessibility to restore full detail."
- Change applies on next screen load (some panels require a re-render — acceptable delay)

### Cloud Save (Sync Now)

- Ghost button, Worn Oak border, label: "Sync Now"
- Triggers manual Firebase sync: `EventBus.save_requested.emit()`
- After sync completes: button label briefly shows "Synced ✓" (2 seconds), then reverts
- If sync fails: inline error text below button: "Sync failed — check your connection"
- No loading spinner visible during sync — the operation runs in background; result appears when done

### Account Row

- If signed in: shows connected platform icon + username; tap opens account management (post-MVP)
- If signed out: shows "Sign In" label; tap opens platform-specific sign-in flow
- For MVP: row is present but sign-in is optional — the game works fully offline

---

## 6. Return to Main Menu

Tap → IP-08 Confirm Action Dialog:
- **Title**: "Return to Main Menu"
- **Body**: "Your farm continues earning while you're away. Progress is saved."
- **Confirm**: "Return" (stadium shape, Worn Oak fill — not Carrot, to reduce urgency)
- **Cancel**: "Stay" (ghost button)
- **Default focus**: Cancel (safe choice)

On confirm: bottom sheet animates out (200ms), then scene transitions to Main Menu.

---

## 7. Accessibility

- All interactive elements (sliders, toggles, segmented control, rows) meet 44×44px touch target
- Sliders use both color (fill) and position (thumb location) to indicate value — not color alone
- Toggle states use shape (thumb position) in addition to background color
- The "×" dismiss button in the sheet header is always present (44×44px) as a tap fallback alongside swipe dismiss
- Text in this panel at the 1.25× Large scale must not overflow or truncate — section labels may wrap; action labels (buttons) must not
- "Return to Main Menu" is never the first interactive element — it sits at the bottom after all settings, reducing accidental taps

---

## 8. Edge Cases

- **Settings panel opened during Cascade Reveal (IP-06)**: Pause menu tap is ignored while a Cascade Reveal is actively animating — must wait for the reveal to complete or be skipped. This prevents accidental interruption of the reveal.
- **Settings changed then device rotated**: Settings persist to user prefs immediately on change — rotation does not reset them.
- **"Sync Now" tapped multiple times rapidly**: debounce 2 seconds — second tap while sync is in flight is ignored.
- **Very long username**: account name truncates at 20 characters with ellipsis in the account row.

---

*Pause Menu UX Spec v1.0 — Bunny Farm Idle — 2026-05-18*
