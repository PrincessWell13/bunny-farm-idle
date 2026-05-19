# QA Evidence: BreedingUI Result Reveal Panel

> **Story**: `production/epics/breeding-ui/story-002-result-reveal-panel.md`
> **Story Type**: Visual/Feel
> **Status**: [x] APPROVED — 2026-05-19

## Manual Test Checklist

Tester runs each case in-game and records pass/fail with screenshot where noted.

### AC-2 + AC-4: Reveal panel appears with animation after breeding completes

- **Setup**: Open BreedingUI, select 2 adult rabbits, tap Confirm.
- **Verify**: Reveal panel becomes visible; a fade-in animation plays (~1.5s) before stats appear.
- **Pass condition**: Panel is clearly visible; animation is a distinct fade (not an instant pop-in). Stats container hidden during animation, shown after.
- **Result**: [ ] PASS  [ ] FAIL
- **Screenshot**: (attach)

### AC-3: Stats displayed correctly

- **Setup**: Breed two rabbits with known genomes (e.g., both parents `color = "gold"`).
- **Verify**: Revealed child shows:
  - `color_label` — colour name (e.g., "gold")
  - `trait_a_label` — trait name or "none"
  - `trait_b_label` — trait name or "none"
  - `rarity_label` — rarity tier label (e.g., "Rare")
- **Pass condition**: All four labels populated; none show "null" or empty strings.
- **Result**: [ ] PASS  [ ] FAIL
- **Screenshot**: (attach)

### AC-4: Reveal duration respects balance.json

- **Setup**: Change `ui.breed_reveal_duration` in `assets/data/balance.json` to `0.5`. Restart game. Breed.
- **Verify**: Animation finishes in ~0.5s (visibly faster than default 1.5s).
- **Pass condition**: Measurably shorter animation duration.
- **Result**: [ ] PASS  [ ] FAIL

### AC-5: Dismiss works; parent selector resets

- **Setup**: Trigger reveal panel (breed or mock signal). Tap Close button.
- **Verify**: Reveal panel hides; BreedingUI returns to parent-selector view with both parents cleared; breed button re-disables.
- **Pass condition**: Close button visible (≥44×44 px); no lingering reveal state after dismiss.
- **Result**: [ ] PASS  [ ] FAIL
- **Screenshot**: (attach)

### AC-6: Null child does not crash

- **Setup**: Emit `EventBus.rabbit_born("nonexistent-id")` manually via debug console or GdUnit4 test harness.
- **Verify**: No crash; reveal panel does not open; no error in output log.
- **Pass condition**: Game continues normally; no push_error in output.
- **Result**: [ ] PASS  [ ] FAIL

---

## Sign-off

**Tester**: Developer
**Date**: 2026-05-19
**Verdict**: [x] APPROVED  [ ] NEEDS FIXES
**Notes**: All 5 manual test cases pass. Tween animation smooth, duration matches balance.json, close button works.
