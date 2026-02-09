---
phase: 04-game-flow-input
plan: 01
subsystem: ui, game-flow
tags: [pause-menu, game-state, touch-input, godot-process-mode, tree-pause]

# Dependency graph
requires:
  - phase: 01-core-physics-merging
    provides: GameManager autoload with GameState enum, DropController input handling
  - phase: 02-scoring-chain-reactions
    provides: ScoreManager and chain state that must survive pause/resume
  - phase: 03-merge-feedback-juice
    provides: MergeFeedback orchestrator that pauses correctly with tree pause
provides:
  - PAUSED state in GameManager with tree pause management and previous-state tracking
  - PauseMenu CanvasLayer scene with Resume/Restart/Quit buttons
  - HUD pause button (touch-friendly, 80x80 on 1080x1920 viewport)
  - EventBus pause_requested and resume_requested signals
  - DropController PAUSED guard and TOUCH_PREVIEW_OFFSET constant
affects: [05-card-system, 06-card-scoring-economy, 07-progression-meta, 08-polish-accessibility]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tree pause for game-wide freeze (get_tree().paused = true/false)"
    - "CanvasLayer with PROCESS_MODE_ALWAYS for overlay UI that works during pause"
    - "Previous-state tracking for correct resume after pause"
    - "Unpause tree before reload_current_scene (critical ordering)"

key-files:
  created:
    - scenes/ui/pause_menu.tscn
    - scenes/ui/pause_menu.gd
  modified:
    - scripts/autoloads/game_manager.gd
    - scripts/autoloads/event_bus.gd
    - scenes/ui/hud.tscn
    - scenes/ui/hud.gd
    - scenes/game/game.tscn
    - scripts/components/drop_controller.gd

key-decisions:
  - "Tree pause for PAUSED state; GAME_OVER does NOT pause tree (fruits settle naturally)"
  - "PauseMenu on CanvasLayer layer 10 with PROCESS_MODE_ALWAYS to receive input while paused"
  - "Overlay ColorRect mouse_filter=STOP blocks click-through; VBoxContainer mouse_filter=IGNORE"
  - "Restart unpauses tree BEFORE reload_current_scene (avoids reloading into paused state)"
  - "TOUCH_PREVIEW_OFFSET=0.0 constant added but not applied (natural 80px gap above bucket rim is sufficient)"

patterns-established:
  - "Pause overlay pattern: CanvasLayer(ALWAYS) > dark overlay(STOP) > centered container(IGNORE) > buttons"
  - "State restore via _previous_state tracking on GameManager"
  - "Belt-and-suspenders input guards: check state even when tree pause should block"

# Metrics
duration: 5min
completed: 2026-02-08
---

# Phase 4 Plan 1: Pause/Resume/Restart Summary

**Pause menu with resume/restart/quit on CanvasLayer, HUD pause button, and PAUSED GameState with tree pause management**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-08
- **Completed:** 2026-02-08
- **Tasks:** 2 (1 auto + 1 human-verify checkpoint)
- **Files modified:** 8

## Accomplishments

- PAUSED state added to GameManager with tree pause management and previous-state restore
- PauseMenu scene with Resume/Restart/Quit buttons on CanvasLayer (process_mode ALWAYS, layer 10)
- Touch-friendly 80x80 HUD pause button with state-driven visibility
- Escape key toggles pause via _unhandled_input on PauseMenu
- Restart correctly unpauses tree before scene reload (critical pitfall avoidance)
- Human playtest verified: pause freezes all physics, resume continues seamlessly, restart produces clean state

## Task Commits

Each task was committed atomically:

1. **Task 1: GameManager PAUSED state, PauseMenu scene, and HUD pause button** - `f94a3a7` (feat)
2. **Task 2: Playtest pause, restart, and touch input** - checkpoint:human-verify (approved by user)

**Plan metadata:** `781ce2a` (docs: complete plan)

## Files Created/Modified

- `scenes/ui/pause_menu.tscn` - PauseMenu CanvasLayer with dark overlay, centered VBoxContainer, Resume/Restart/Quit buttons
- `scenes/ui/pause_menu.gd` - Pause menu logic: Escape toggle, pause/resume/restart handlers, game-over guard
- `scripts/autoloads/game_manager.gd` - PAUSED enum value, _previous_state tracking, tree pause in change_state
- `scripts/autoloads/event_bus.gd` - pause_requested and resume_requested signals
- `scenes/ui/hud.tscn` - 80x80 PauseButton in top-left corner
- `scenes/ui/hud.gd` - PauseButton pressed handler, state-driven visibility (hidden during pause/game-over)
- `scenes/game/game.tscn` - PauseMenu instanced as child after HUD
- `scripts/components/drop_controller.gd` - PAUSED guard in _unhandled_input, TOUCH_PREVIEW_OFFSET constant

## Decisions Made

- Tree pause for PAUSED state; GAME_OVER does NOT pause tree so fruits settle naturally
- PauseMenu on CanvasLayer layer 10 with PROCESS_MODE_ALWAYS to receive input while tree is paused
- Overlay ColorRect mouse_filter=STOP blocks click-through to game; VBoxContainer mouse_filter=IGNORE passes clicks to children
- Restart calls get_tree().paused = false BEFORE reload_current_scene (avoids loading into paused state)
- TOUCH_PREVIEW_OFFSET constant set to 0.0 (not applied) -- natural 80px gap above bucket rim is sufficient per research

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness

- Game flow controls (pause/resume/restart) complete and verified
- Touch input confirmed working via emulate_mouse_from_touch
- Ready for Phase 4 Plan 2 (if any) or Phase 5 (Card System)
- All UI follows touch-friendly sizing (48dp+ minimum)

## Self-Check: PASSED

All 8 files verified present. Commit f94a3a7 verified in git log. Summary file created.

---
*Phase: 04-game-flow-input*
*Completed: 2026-02-08*
