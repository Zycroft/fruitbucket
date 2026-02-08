---
phase: 02-scoring-chain-reactions
plan: 02
subsystem: ui
tags: [gdscript, tween-animation, floating-popups, hud, chain-counter, coin-display, score-animation]

# Dependency graph
requires:
  - phase: 02-scoring-chain-reactions
    plan: 01
    provides: "ScoreManager emitting score_awarded, chain_ended, coins_awarded signals; GameManager.coins"
provides:
  - "FloatingScore popup scene spawning at merge positions with rise-and-fade animation"
  - "Animated HUD score counter with roll-up tween and scale punch"
  - "Chain counter display (CHAIN xN!) appearing during cascades, hidden for single merges"
  - "Coin counter in HUD updating on coins_awarded signal"
  - "PopupContainer Node2D in game scene for world-space popup positioning"
affects: [05-shop (coin display already in HUD), future phases consuming HUD patterns]

# Tech tracking
tech-stack:
  added: []
  patterns: [tween-based UI animation, world-space popups via group lookup, parallel tween composition, pivot_offset for centered scaling]

key-files:
  created:
    - scenes/ui/floating_score.tscn
    - scenes/ui/floating_score.gd
  modified:
    - scenes/ui/hud.tscn
    - scenes/ui/hud.gd
    - scenes/game/game.tscn

key-decisions:
  - "FloatingScore uses random x offset (randf_range -20 to 20) to prevent popup stacking"
  - "PopupContainer discovered via group lookup (popup_container group) matching MergeManager pattern"
  - "Chain label hidden for chain_count < 2 to prevent CHAIN x1 spam"
  - "Coin label styled in dark grey for secondary emphasis, not competing with score"

patterns-established:
  - "Tween-based UI animation: parallel tweens for rise+fade, scale punch for emphasis"
  - "World-space popups: spawn in PopupContainer Node2D (not CanvasLayer) for correct positioning"
  - "pivot_offset set after text assignment so size is correct for centered scaling"
  - "Previous tween kill pattern: always kill_tween before creating new one to prevent overlap"

# Metrics
duration: 5min
completed: 2026-02-08
---

# Phase 2 Plan 2: Scoring HUD & Popups Summary

**Floating score popups at merge points with animated HUD score roll-up, chain counter display, and coin economy readout**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-08
- **Completed:** 2026-02-08
- **Tasks:** 2 (1 auto + 1 human-verify)
- **Files modified:** 5

## Accomplishments
- FloatingScore popup scene spawns at merge positions, rises and fades with tween animation, gold-tinted for chain merges
- HUD score counter animates with roll-up counting and scale punch on updates
- Chain counter ("CHAIN xN!") appears prominently during cascades, hidden for single merges
- Coin counter displays in HUD with scale punch on gain, dark grey secondary styling
- PopupContainer in game scene enables world-space popup positioning via group lookup

## Task Commits

Each task was committed atomically:

1. **Task 1: Create FloatingScore popup scene and update HUD with animated score, chain counter, and coin display** - `07dfa71` (feat)
   - Follow-up fix: `133ce65` (fix) - increase score and coin label font sizes for readability
   - Follow-up fix: `e8747df` (fix) - bigger/longer popups, dark grey coins, larger chain effects
2. **Task 2: Playtest scoring, chains, and coin economy** - checkpoint approved by user

## Files Created/Modified
- `scenes/ui/floating_score.tscn` - FloatingScore popup scene: Label root with outline, mouse_filter IGNORE
- `scenes/ui/floating_score.gd` - Popup animation: show_score() with rise, fade, scale punch, queue_free cleanup
- `scenes/ui/hud.tscn` - Added ChainLabel and CoinLabel nodes with styling
- `scenes/ui/hud.gd` - Animated score roll-up, chain counter, coin display, floating popup spawning via EventBus signals
- `scenes/game/game.tscn` - PopupContainer Node2D added in popup_container group

## Decisions Made
- FloatingScore uses random x offset to prevent popup stacking at same merge point
- PopupContainer uses group-based discovery (popup_container group) matching MergeManager pattern
- Chain label hidden for chain_count < 2 to prevent "CHAIN x1!" spam on single merges
- Coin label styled dark grey for secondary emphasis, keeping score as primary focus
- Font sizes and popup durations increased after playtest feedback for better readability

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Font sizes too small for readability**
- **Found during:** Task 2 (playtest)
- **Issue:** Score and coin label font sizes were too small to read comfortably during gameplay
- **Fix:** Increased font sizes for ScoreLabel, CoinLabel, and ChainLabel
- **Files modified:** scenes/ui/hud.tscn
- **Committed in:** `133ce65`

**2. [Rule 1 - Bug] Popups too small and short-lived, coins label color not distinct**
- **Found during:** Task 2 (playtest)
- **Issue:** Floating popups disappeared too quickly and were hard to see; coin label blended with score
- **Fix:** Increased popup size, extended animation duration, styled coins in dark grey, enlarged chain effects
- **Files modified:** scenes/ui/floating_score.gd, scenes/ui/hud.gd, scenes/ui/hud.tscn
- **Committed in:** `e8747df`

---

**Total deviations:** 2 auto-fixed (2 bug fixes from playtest feedback)
**Impact on plan:** Both fixes improved visual readability during gameplay. No scope creep.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 2 complete: all scoring, chain tracking, visual feedback, and coin economy operational
- HUD patterns (tween animation, group-based popup spawning) established for future UI work
- Coin display already in HUD, ready for Phase 5 shop integration
- score_threshold_reached signal (from Plan 01) ready for Phase 5 shop triggers

## Self-Check: PASSED

All 5 files verified present. All 3 commits verified in history.

---
*Phase: 02-scoring-chain-reactions*
*Completed: 2026-02-08*
