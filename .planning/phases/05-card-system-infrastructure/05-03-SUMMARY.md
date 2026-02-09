---
phase: 05-card-system-infrastructure
plan: 03
subsystem: ui, gameplay
tags: [starter-pick, card-lifecycle, game-flow, overlay, playtest, gdscript, canvaslayer]

# Dependency graph
requires:
  - phase: 05-card-system-infrastructure
    plan: 02
    provides: Card shop overlay, HUD card slots, threshold-to-shop wiring
provides:
  - Starter card pick CanvasLayer overlay (pick 1 of 3 free cards)
  - Game flow integration (PICKING -> DROPPING state transition)
  - Full card lifecycle verified (pick -> play -> shop -> restart)
  - Free card minimum sell price fix (base_price / 2 floor)
affects: [06-card-effects-physics, 07-card-effects-scoring, 08-card-activation-feedback]

# Tech tracking
tech-stack:
  added: []
  patterns: [Starter pick overlay following CardShop CanvasLayer pattern, generate_starter_offers with shop level 0 weights, maxi-based sell price floor for free cards]

key-files:
  created:
    - scenes/ui/starter_pick.tscn
    - scenes/ui/starter_pick.gd
  modified:
    - scenes/game/game.tscn
    - scenes/game/game.gd
    - scripts/autoloads/card_manager.gd

key-decisions:
  - "Starter pick on layer 11 with process_mode ALWAYS, matching CardShop overlay pattern"
  - "PICKING state before DROPPING at run start; gameplay blocked until card chosen"
  - "Sell price uses maxi(purchase_price/2, base_price/2) so free cards have value"
  - "Starter offers use shop level 0 weights (biased toward Common)"

patterns-established:
  - "Overlay lifecycle: visible=false default, signal-driven show, emit+hide on user action"
  - "Sell price floor: maxi(paid/2, base_price/2) prevents 0-value cards"

# Metrics
duration: ~5min (Task 1) + playtest session with 2 bug fixes
completed: 2026-02-09
---

# Phase 5 Plan 03: Starter Pick & Game Flow Integration Summary

**Starter card pick overlay at run start, full card lifecycle integration, and human-verified playtest with 2 bug fixes**

## Performance

- **Duration:** ~5 min (implementation) + playtest session
- **Tasks:** 2 (1 auto, 1 checkpoint)
- **Files modified:** 5

## Accomplishments
- Starter card pick CanvasLayer overlay on layer 11 showing 3 random card offers (biased toward Common) with Pick buttons
- Game flow updated: READY -> PICKING (tree paused, pick overlay) -> pick card -> DROPPING (tree unpaused, gameplay begins)
- Picked card immediately appears in HUD card slot via EventBus.active_cards_changed
- Full card lifecycle verified via Playwright automated browser testing: starter pick -> gameplay -> shop at 500 threshold -> buy/sell/skip -> coin economy working
- Free card sell price fix: cards obtained for free (e.g. starter pick) now sell for base_price/2 instead of 0

## Task Commits

Each task was committed atomically:

1. **Task 1: Starter card pick overlay and game flow integration** - `6b7812d` (feat)
2. **Task 2: Full card lifecycle playtest** - Human-verified via Playwright automation

## Bug Fix Commits

Two bugs found and fixed during playtest:

1. **card_shop.gd parse error** - `6204f8d` (fix) - `row.theme_override_constants = {}` is not valid GDScript (it's a .tscn serialization key). Prevented card_shop.gd from loading, causing game freeze at 500 points when SHOPPING state paused the tree but no shop appeared.
2. **Free card sell price = 0** - `54eea7d` (fix) - Starter cards had purchase_price=0, making sell price 0 coins. Changed get_sell_price() to use `maxi(purchase_price/2, base_price/2)` so all cards have sell value.

## Files Created/Modified
- `scenes/ui/starter_pick.tscn` - CanvasLayer overlay (layer 11) with pick UI structure
- `scenes/ui/starter_pick.gd` - Pick-one-of-three logic, emits starter_pick_completed
- `scenes/game/game.tscn` - Added StarterPick instance as child of Game
- `scenes/game/game.gd` - PICKING state before DROPPING, starter pick flow integration
- `scripts/autoloads/card_manager.gd` - Sell price floor using maxi(paid/2, base_price/2)

## Decisions Made
- Starter pick overlay follows the same CanvasLayer pattern as CardShop (layer 11, ALWAYS, visible=false)
- PICKING state blocks all gameplay before card selection (tree paused, same as SHOPPING)
- Sell price uses maxi() floor to ensure free cards always have some sell value based on their inherent worth

## Deviations from Plan

### Bug Fixes During Playtest

**1. [Critical] card_shop.gd invalid property assignment**
- **Found during:** Playtest (game froze at ~1478 points)
- **Root cause:** `row.theme_override_constants = {}` in card_shop.gd (from Plan 05-02) is not valid GDScript -- it's a .tscn serialization key
- **Impact:** Entire card_shop.gd script failed to parse, shop_opened signal had no listener, SHOPPING state paused tree with no visible shop
- **Fix:** Removed invalid line; `add_theme_constant_override("separation", 8)` on next line was already correct
- **Committed:** 6204f8d

**2. [UX] Free cards sell for 0 coins**
- **Found during:** Playtest (selling starter card gave no coins)
- **Root cause:** Starter card added with purchase_price=0, sell price = 0/2 = 0
- **Fix:** `get_sell_price()` now returns `maxi(purchase_price/2, base_price/2)` for a meaningful floor
- **Committed:** 54eea7d

---

**Total deviations:** 2 bug fixes (1 critical, 1 UX)
**Impact on plan:** Both fixes were necessary for correct card lifecycle. No scope creep.

## Issues Encountered
None beyond the 2 bugs documented above.

## User Setup Required
None - no external service configuration required.

## Phase 5 Complete
All 3 plans executed. The full card system infrastructure is operational:
- CardData resources + CardManager autoload (Plan 01)
- Card shop with buy/sell/skip (Plan 02)
- Starter pick + full lifecycle verified (Plan 03)
- Card effects still inert (Phase 6/7) -- cards display but don't modify gameplay yet

## Self-Check: PASSED

All 5 files verified on disk. Task commit (6b7812d) and fix commits (6204f8d, 54eea7d) verified in git log.

---
*Phase: 05-card-system-infrastructure*
*Completed: 2026-02-09*
