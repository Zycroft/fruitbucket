---
phase: 02-scoring-chain-reactions
plan: 01
subsystem: scoring
tags: [gdscript, signals, chain-reactions, coin-economy, fibonacci-multipliers]

# Dependency graph
requires:
  - phase: 01-core-physics-merging
    provides: "MergeManager emits EventBus.fruit_merged, FruitData resources with score_value field"
provides:
  - "ScoreManager component with chain tracking and accelerating multipliers"
  - "EventBus scoring signals: score_awarded, chain_ended, coins_awarded, score_threshold_reached"
  - "GameManager.coins variable with reset support"
  - "Power-of-2 FruitData score values (1,2,4,8,16,32,64,128)"
  - "Coin economy: 1 coin per 100 cumulative score"
  - "Score threshold milestones [500, 1500, 3500, 7000] for Phase 5 shop"
affects: [02-02-PLAN (HUD/popups consume signals), 05-shop (score_threshold_reached triggers)]

# Tech tracking
tech-stack:
  added: []
  patterns: [signal-driven scoring, Fibonacci chain multipliers, programmatic Timer child]

key-files:
  created:
    - scripts/components/score_manager.gd
  modified:
    - scripts/autoloads/event_bus.gd
    - scripts/autoloads/game_manager.gd
    - scenes/game/game.tscn
    - resources/fruit_data/tier_2_grape.tres
    - resources/fruit_data/tier_3_cherry.tres
    - resources/fruit_data/tier_4_strawberry.tres
    - resources/fruit_data/tier_5_orange.tres
    - resources/fruit_data/tier_6_apple.tres
    - resources/fruit_data/tier_7_pear.tres
    - resources/fruit_data/tier_8_watermelon.tres

key-decisions:
  - "Watermelon vanish awards flat 1000 bonus replacing tier score (not additive)"
  - "Chain multipliers use Fibonacci-like sequence [1,2,3,5,8,13,21,34,55,89] clamped at bounds"
  - "ChainTimer created programmatically in _ready() to keep ScoreManager as script-only component"
  - "Per-merge multiplier application (each merge gets its own chain position multiplier)"

patterns-established:
  - "Signal-driven scoring: ScoreManager listens to fruit_merged and emits score_awarded for downstream UI"
  - "Programmatic Timer: child Timer created in _ready() instead of .tscn for script-only components"
  - "Group-based discovery: score_manager group follows merge_manager pattern"

# Metrics
duration: 2min
completed: 2026-02-08
---

# Phase 2 Plan 1: Score Manager Summary

**ScoreManager with power-of-2 scoring, Fibonacci chain multipliers, and coin economy derived from cumulative score thresholds**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-08T22:02:32Z
- **Completed:** 2026-02-08T22:04:49Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- ScoreManager component wired into game scene, listening to fruit_merged signal and emitting 4 scoring signals
- Power-of-2 score values across all 8 fruit tiers (1 through 128) for exponential scaling
- Fibonacci-like accelerating chain multipliers (up to 89x for 10+ chain) reward cascade play
- Coin economy awarding 1 coin per 100 cumulative score with GameManager tracking
- Score milestones [500, 1500, 3500, 7000] emit threshold signals for future shop integration

## Task Commits

Each task was committed atomically:

1. **Task 1: Add EventBus signals, GameManager coins, and update FruitData score values** - `b0fddad` (feat)
2. **Task 2: Create ScoreManager component with chain tracking and coin economy** - `9f9d26c` (feat)

## Files Created/Modified
- `scripts/components/score_manager.gd` - ScoreManager component: scoring logic, chain tracking, coin economy, threshold signals
- `scripts/autoloads/event_bus.gd` - 4 new signals: score_awarded, chain_ended, coins_awarded, score_threshold_reached
- `scripts/autoloads/game_manager.gd` - Added coins variable with reset support
- `scenes/game/game.tscn` - ScoreManager node added between MergeManager and DropController
- `resources/fruit_data/tier_2_grape.tres` - score_value: 3 -> 2
- `resources/fruit_data/tier_3_cherry.tres` - score_value: 6 -> 4
- `resources/fruit_data/tier_4_strawberry.tres` - score_value: 10 -> 8
- `resources/fruit_data/tier_5_orange.tres` - score_value: 15 -> 16
- `resources/fruit_data/tier_6_apple.tres` - score_value: 21 -> 32
- `resources/fruit_data/tier_7_pear.tres` - score_value: 28 -> 64
- `resources/fruit_data/tier_8_watermelon.tres` - score_value: 36 -> 128

## Decisions Made
- Watermelon vanish awards flat 1000 bonus replacing tier score (not additive per research pitfall #4)
- Chain multipliers use Fibonacci-like accelerating sequence clamped at array bounds (89x max)
- ChainTimer created programmatically in _ready() to keep ScoreManager as a script-only component
- Per-merge multiplier application: each merge in a cascade gets its own chain-position multiplier

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All 4 scoring signals are ready for Plan 02 (HUD and floating score popups) to consume
- score_threshold_reached signal is ready for Phase 5 shop triggers
- Coin economy is fully operational and tracked in GameManager.coins

---
*Phase: 02-scoring-chain-reactions*
*Completed: 2026-02-08*
