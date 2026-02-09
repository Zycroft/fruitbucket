---
phase: 05-card-system-infrastructure
plan: 02
subsystem: ui, gameplay
tags: [card-shop, hud, overlay, buy-sell, economy, gdscript, canvaslayer]

# Dependency graph
requires:
  - phase: 05-card-system-infrastructure
    plan: 01
    provides: CardData Resource, CardManager autoload, EventBus card signals, GameManager SHOPPING/PICKING states, CardSlotDisplay component
provides:
  - Card shop CanvasLayer overlay with buy/sell/skip flows
  - HUD card slots (3 CardSlotDisplay instances) with real-time updates
  - Game.gd score_threshold_reached -> shop open -> shop_closed -> resume wiring
  - PauseMenu guard against Escape during SHOPPING/PICKING states
affects: [05-03-game-flow-integration, 06-card-effects-physics, 07-card-effects-scoring]

# Tech tracking
tech-stack:
  added: []
  patterns: [CanvasLayer overlay following PauseMenu pattern, dynamic HBoxContainer offer rows with CardSlotDisplay + Buy button, gui_input sell interaction on PanelContainer]

key-files:
  created:
    - scenes/ui/card_shop.tscn
    - scenes/ui/card_shop.gd
  modified:
    - scenes/ui/hud.tscn
    - scenes/ui/hud.gd
    - scenes/game/game.tscn
    - scenes/game/game.gd
    - scenes/ui/pause_menu.gd

key-decisions:
  - "Card shop on layer 11 (above PauseMenu layer 10) with process_mode ALWAYS for input during tree pause"
  - "Offer rows built dynamically as HBoxContainer with CardSlotDisplay + Buy button, cleaned up on close"
  - "Player slots use gui_input with bind(slot_index) for sell-on-tap interaction"
  - "Flash feedback (tween modulate to red and back) for insufficient coins or full slots"

patterns-established:
  - "Dynamic offer UI: HBoxContainer rows with CardSlotDisplay + Button, queue_freed on close to prevent leaks"
  - "Sell interaction: gui_input signal on PanelContainer with mouse_filter=STOP, guarded by InputEventMouseButton check"
  - "HUD card slots: 3 CardSlotDisplay instances created in _ready(), updated via EventBus card_purchased/card_sold/active_cards_changed"

# Metrics
duration: 3min
completed: 2026-02-08
---

# Phase 5 Plan 02: Card Shop & HUD Integration Summary

**Card shop overlay with buy/sell/skip on layer 11, HUD card slots with real-time EventBus updates, and game.gd threshold-to-shop wiring for the full shop visit loop**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-09T01:48:44Z
- **Completed:** 2026-02-09T01:51:35Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Card shop CanvasLayer overlay on layer 11 with dark background, 3 card offers with rarity borders and buy buttons, 3 player card slots with tap-to-sell, and a Continue/skip button
- Buy flow validates coins and empty slots with flash feedback, deducts coins, adds card to inventory, and emits EventBus signals
- Sell flow refunds 50% of purchase price, removes card, and emits EventBus signals
- HUD extended with CardSlots HBoxContainer at bottom of viewport, 3 dynamically created CardSlotDisplay instances that update in real-time via card_purchased/card_sold/active_cards_changed signals
- Game.gd wired score_threshold_reached to open shop with generated offers, and shop_closed to resume DROPPING state
- PauseMenu hardened against Escape key during SHOPPING and PICKING states

## Task Commits

Each task was committed atomically:

1. **Task 1: Card shop overlay with buy/sell/skip** - `87b0790` (feat)
2. **Task 2: HUD card slots and game.gd threshold-to-shop wiring** - `ffd80a4` (feat)

## Files Created/Modified
- `scenes/ui/card_shop.tscn` - CanvasLayer overlay (layer 11) with shop UI structure
- `scenes/ui/card_shop.gd` - Shop logic: open, buy, sell, skip, flash feedback, offer cleanup
- `scenes/ui/hud.tscn` - Added CardSlots HBoxContainer at bottom of viewport
- `scenes/ui/hud.gd` - Card slot creation, card_purchased/card_sold/active_cards_changed handlers, SHOPPING/PICKING PauseButton hiding
- `scenes/game/game.tscn` - Added CardShop instance as child of Game (after PauseMenu)
- `scenes/game/game.gd` - score_threshold_reached -> shop open, shop_closed -> resume DROPPING
- `scenes/ui/pause_menu.gd` - Added SHOPPING/PICKING guards to _unhandled_input Escape handler

## Decisions Made
- Card shop on layer 11 (above PauseMenu layer 10) ensures shop is always visible above pause overlay
- Offer rows built dynamically as HBoxContainer with CardSlotDisplay + Buy button, queue_freed on shop close to prevent memory leaks
- Player card slots in shop use gui_input with bind(slot_index) for sell-on-tap, separate from HUD slots which are display-only (mouse_filter=IGNORE)
- Flash feedback uses tween on modulate property (red flash and back) for insufficient coins or full slots -- lightweight, no extra UI needed

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PauseMenu Escape key guard for SHOPPING/PICKING states**
- **Found during:** Task 2 (HUD card slots and game.gd wiring)
- **Issue:** PauseMenu._unhandled_input only checked for GAME_OVER and PAUSED states; pressing Escape during SHOPPING would incorrectly open the pause menu on top of the shop
- **Fix:** Added `GameManager.GameState.SHOPPING` and `GameManager.GameState.PICKING` to the exclusion list in the elif condition
- **Files modified:** scenes/ui/pause_menu.gd
- **Verification:** Escape key now has no effect during SHOPPING or PICKING states
- **Committed in:** ffd80a4 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Bug fix necessary to prevent conflicting overlay states. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Card shop overlay and HUD card slots fully wired and functional
- Score threshold -> shop -> buy/sell/skip -> resume loop complete
- Ready for Plan 03 (starter card pick and game flow integration)
- Card effects still inert (Phase 6/7) -- cards display in slots but don't modify gameplay yet

## Self-Check: PASSED

All 7 files verified on disk. Both task commits (87b0790, ffd80a4) verified in git log.

---
*Phase: 05-card-system-infrastructure*
*Completed: 2026-02-08*
