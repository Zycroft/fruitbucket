---
phase: 08-card-activation-feedback-starter-kits
plan: 02
subsystem: ui
tags: [godot, gdscript, ui-overlay, game-flow, stats-tracking, tween-animation]

# Dependency graph
requires:
  - phase: 05-card-system-infrastructure
    provides: CardManager autoload, card slots, starter pick overlay
  - phase: 07-card-effects-scoring-economy
    provides: Coin and bonus award signals for stats tracking
provides:
  - Starter kit selection (Physics Kit, Score Kit, Surprise) replacing individual card picks
  - RunStatsTracker component tracking per-run statistics
  - Run summary overlay with celebratory animated stat reveals
  - Play Again / Quit buttons for run restart and page reload
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: [kit-based selection with mystery card resolution, sequential tween stat reveal animation, CanvasLayer overlay at layer 12]

key-files:
  created:
    - scripts/components/run_stats_tracker.gd
    - scenes/ui/run_summary.gd
    - scenes/ui/run_summary.tscn
  modified:
    - scripts/autoloads/card_manager.gd
    - scenes/ui/starter_pick.gd
    - scenes/ui/starter_pick.tscn
    - scenes/game/game.gd
    - scenes/game/game.tscn
    - scenes/ui/hud.gd

key-decisions:
  - "Kit selection uses CardManager.STARTER_KITS constant with card_pool arrays for themed selection"
  - "Surprise kit uses empty card_pool to pick from full card pool"
  - "RunStatsTracker tracks coins from both ScoreManager (coins_awarded) and card bonuses (bonus_awarded with type coins)"
  - "Run summary on CanvasLayer 12 (above CardShop/StarterPick at 11) with PROCESS_MODE_ALWAYS for tween during pause"
  - "2.5s delay before run summary to let fruits settle visually after game over"
  - "GameOverLabel kept in .tscn but never shown (replaced by run summary)"

patterns-established:
  - "Kit-based selection: themed pools with mystery card resolution via get_kit_card()"
  - "Sequential tween reveal: tween_interval between parallel fade+scale tweens with TWEEN_PAUSE_PROCESS"

# Metrics
duration: 3min
completed: 2026-02-12
---

# Phase 8 Plan 2: Starter Kits & Run Summary Summary

**Kit-based starter selection (Physics/Score/Surprise) with celebratory 7-stat run summary screen using sequential tween reveals**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-12T17:47:07Z
- **Completed:** 2026-02-12T17:50:37Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Starter pick now shows 3 themed kits (Physics Kit, Score Kit, Surprise) instead of individual cards -- card inside is hidden until chosen
- RunStatsTracker component accumulates biggest_chain, highest_tier, total_merges, total_coins_earned, cards_used, time_played across run
- Run summary screen with 7 stats animating in one by one with scale punch, Final Score as the big golden reveal
- Play Again cleanly restarts (new kit selection), Quit reloads page (web) or quits (native)

## Task Commits

Each task was committed atomically:

1. **Task 1: Starter kit selection replacing individual card picks** - `d5566ef` (feat)
2. **Task 2: Run stats tracker and celebratory run summary screen** - `fa84043` (feat)

## Files Created/Modified
- `scripts/autoloads/card_manager.gd` - Added STARTER_KITS constant and get_kit_card() method
- `scenes/ui/starter_pick.gd` - Replaced card-based display with kit-based selection
- `scenes/ui/starter_pick.tscn` - Updated title/subtitle text for kit selection
- `scripts/components/run_stats_tracker.gd` - New component tracking per-run stats via EventBus signals
- `scenes/ui/run_summary.gd` - New overlay script with sequential tween stat reveal animation
- `scenes/ui/run_summary.tscn` - New CanvasLayer overlay scene (layer 12) with stat labels and buttons
- `scenes/game/game.gd` - Simplified starter pick call, added game over -> run summary wiring with 2.5s delay
- `scenes/game/game.tscn` - Added RunStatsTracker node and RunSummary scene instance
- `scenes/ui/hud.gd` - Removed GameOverLabel.visible = true (replaced by run summary)

## Decisions Made
- Kit selection uses constant data with card_pool arrays rather than generating offers at runtime
- Surprise kit empty pool triggers full-pool random pick with graceful fallback
- RunStatsTracker connects to both coins_awarded and bonus_awarded to capture all coin sources
- Run summary uses TWEEN_PAUSE_PROCESS so animations play while tree is paused
- 2.5s settling delay matches GAME_OVER not pausing tree (fruits settle visually before summary)
- GameOverLabel node kept in .tscn for backwards compatibility but never displayed

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 8 complete: all card activation feedback (Plan 1) and starter kits + run summary (Plan 2) implemented
- Full game loop: kit selection -> gameplay with card effects + trigger feedback -> game over -> celebratory run summary -> play again
- Ready for final polish, balance tuning, or release

## Self-Check: PASSED

All 9 files verified present. Both task commits (d5566ef, fa84043) verified in git log.

---
*Phase: 08-card-activation-feedback-starter-kits*
*Completed: 2026-02-12*
