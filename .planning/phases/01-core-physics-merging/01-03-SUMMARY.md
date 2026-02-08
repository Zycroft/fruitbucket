---
phase: 01-core-physics-merging
plan: 03
subsystem: gameplay, ui
tags: [godot, gdscript, area2d, dwell-timer, overflow-detection, hud, canvaslayer, eventbus]

# Dependency graph
requires:
  - phase: 01-core-physics-merging
    plan: 01
    provides: "Bucket scene with geometry API (get_overflow_y, set_warning_level, RimHighlight), EventBus autoload, GameManager autoload, FruitData resources"
  - phase: 01-core-physics-merging
    plan: 02
    provides: "Fruit scene with is_dropping/merging/merge_grace flags, MergeManager, DropController, game scene"
provides:
  - "OverflowDetector Area2D with 2s continuous dwell timer preventing false game-overs"
  - "HUD CanvasLayer with score display, next-fruit preview, and game-over label"
  - "EventBus.next_fruit_changed signal for DropController-to-HUD communication"
  - "Bucket rim progressive red glow warning with width increase at >80% danger"
  - "Complete Phase 1 game loop: drop, stack, merge, overflow, game over"
affects: [scoring, chain-reactions, game-flow, card-effects, hud-enhancements]

# Tech tracking
tech-stack:
  added: []
  patterns: [area2d-dwell-timer, canvaslayer-hud, eventbus-decoupled-preview]

key-files:
  created:
    - "scripts/components/overflow_detector.gd"
    - "scenes/ui/hud.tscn"
    - "scenes/ui/hud.gd"
  modified:
    - "scripts/autoloads/event_bus.gd"
    - "scripts/components/drop_controller.gd"
    - "scenes/bucket/bucket.gd"
    - "scenes/game/game.tscn"
    - "scenes/game/game.gd"

key-decisions:
  - "OverflowDetector uses Area2D body_entered/body_exited with per-fruit dwell time tracking rather than a single global timer, enabling individual fruit timeout and accurate false-positive prevention"
  - "Next-fruit preview communicated via EventBus.next_fruit_changed signal for decoupling between DropController and HUD"
  - "Bucket rim warning includes both color lerp (brown to red) and width increase (5px to 8px) above 80% danger for extra urgency"

patterns-established:
  - "Area2D dwell timer: per-instance-id time accumulation with invalid entry cleanup each frame"
  - "CanvasLayer HUD: separate scene instanced in game.tscn, listens to EventBus for all updates"
  - "EventBus preview signal: DropController emits next_fruit_changed, HUD listens -- no direct references"

# Metrics
duration: 4min
completed: 2026-02-08
status: complete
---

# Phase 1 Plan 3: Overflow Detection & HUD Summary

**OverflowDetector with 2s per-fruit dwell timer ignoring dropping/merging/grace fruits, HUD CanvasLayer with score and next-fruit preview via EventBus, bucket rim progressive red glow warning, and game-over display -- completing Phase 1 game loop pending playtest verification**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-08T18:58:57Z
- **Completed:** 2026-02-08
- **Tasks:** 2 of 2
- **Files created:** 3
- **Files modified:** 5

## Accomplishments
- OverflowDetector Area2D with per-fruit instance ID dwell tracking, 2s continuous threshold, and automatic cleanup of invalid/dropping/merging/grace-period entries to prevent false game-overs
- HUD CanvasLayer with score label (top center, size 48), next-fruit preview (top right, NEXT label + scaled sprite), and hidden GAME OVER label (center, size 72, red) shown on game_state_changed
- EventBus.next_fruit_changed signal emitted by DropController._roll_next_tier(), listened by HUD for preview sprite/color updates
- Bucket rim set_warning_level enhanced with width increase from 5px to 8px when danger exceeds 80% for extra visual urgency
- Game scene updated with OverflowDetector (Area2D at overflow_y=760, 400x20 RectangleShape2D spanning bucket width) and instanced HUD

## Task Commits

Each task was committed atomically:

1. **Task 1: Create overflow detector with dwell timer and HUD with next-fruit preview** - `700e0d9` (feat)
2. **Task 2: Playtest complete Phase 1 game loop** - APPROVED (human-verify passed)

## Files Created/Modified
- `scripts/components/overflow_detector.gd` - OverflowDetector class: Area2D dwell timer with per-fruit tracking, OVERFLOW_DURATION=2.0s, body_entered/exited guards, _physics_process accumulation
- `scenes/ui/hud.tscn` - HUD CanvasLayer scene with ScoreLabel, NextFruitPreview (NextLabel + NextFruitSprite), GameOverLabel
- `scenes/ui/hud.gd` - HUD script: loads 8 FruitData, connects EventBus signals, update_score, update_next_fruit with consistent 50px scaling
- `scripts/autoloads/event_bus.gd` - Added next_fruit_changed(tier: int) signal
- `scripts/components/drop_controller.gd` - Added EventBus.next_fruit_changed.emit in _roll_next_tier()
- `scenes/bucket/bucket.gd` - Enhanced set_warning_level: added rim width increase (5px to 8px) when danger >80%
- `scenes/game/game.tscn` - Added OverflowDetector Area2D with RectangleShape2D and instanced HUD scene
- `scenes/game/game.gd` - Added HUD @onready reference, removed print("GAME OVER") in favor of HUD display

## Decisions Made
- OverflowDetector tracks dwell time per-fruit via instance ID dictionary rather than a single "any fruit above line" global timer -- this prevents one fruit bouncing briefly from extending another fruit's accumulated time
- Used EventBus.next_fruit_changed for DropController-to-HUD communication instead of direct node reference, maintaining the established decoupling pattern
- Enhanced bucket rim warning with both color lerp AND width increase above 80% danger to provide stronger visual urgency cue

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- **ColorRect mouse_filter bug:** Background ColorRects (Wall, Counter) had default mouse_filter=STOP which consumed all mouse events, blocking DropController._unhandled_input(). Fixed by setting mouse_filter=IGNORE (2) on all background and HUD Control nodes.
- **global_position component assignment:** Changed `_current_fruit.global_position.x = val` / `.y = val` to single `_current_fruit.global_position = Vector2(x, y)` for reliability with RigidBody2D.
- **Window size override:** Added window_width_override=540, window_height_override=960 to project.godot so the 1080x1920 portrait viewport fits on desktop monitors.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Complete Phase 1 game loop implemented and playtested: drop -> stack -> merge -> overflow warning -> game over
- Score display ready for Phase 2 scoring logic (currently shows 0)
- HUD extensible for future enhancements (card slots, timer, etc.)
- EventBus has all cross-system signals needed for Phase 2 chain reactions and scoring

## Self-Check: PASSED

- All 3 created files verified on disk
- All 5 modified files verified on disk
- Commit 700e0d9 (Task 1) verified in git log

---
*Phase: 01-core-physics-merging*
*Completed: 2026-02-08 (playtest approved)*
