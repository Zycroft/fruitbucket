---
phase: 05-card-system-infrastructure
plan: 01
subsystem: gameplay, ui
tags: [resource, autoload, card-system, rarity, economy, gdscript]

# Dependency graph
requires:
  - phase: 04-game-flow-input
    provides: GameManager state machine, pause/unpause pattern, EventBus signals
provides:
  - CardData Resource class with Rarity enum (COMMON/UNCOMMON/RARE)
  - 10 card .tres definitions (5 Common, 4 Uncommon, 1 Rare)
  - CardManager autoload (inventory, shop offers, buy/sell pricing)
  - GameManager SHOPPING and PICKING states with tree pause
  - EventBus card lifecycle signals (7 new signals)
  - CardSlotDisplay reusable UI component
affects: [05-02-shop-starter-pick-hud, 05-03-game-flow-integration, 06-card-effects-physics, 07-card-effects-scoring]

# Tech tracking
tech-stack:
  added: []
  patterns: [CardData Resource mirroring FruitData, dictionary-wrapped active_cards for purchase_price tracking, weighted rarity selection with cumulative roll]

key-files:
  created:
    - resources/card_data/card_data.gd
    - resources/card_data/bouncy_berry.tres
    - resources/card_data/quick_fuse.tres
    - resources/card_data/fruit_frenzy.tres
    - resources/card_data/golden_touch.tres
    - resources/card_data/cherry_bomb.tres
    - resources/card_data/heavy_hitter.tres
    - resources/card_data/big_game_hunter.tres
    - resources/card_data/lucky_break.tres
    - resources/card_data/pineapple_express.tres
    - resources/card_data/wild_fruit.tres
    - scripts/autoloads/card_manager.gd
    - scenes/ui/card_slot_display.tscn
    - scenes/ui/card_slot_display.gd
  modified:
    - scripts/autoloads/event_bus.gd
    - scripts/autoloads/game_manager.gd
    - project.godot

key-decisions:
  - "active_cards stores dictionaries {card, purchase_price} not raw CardData -- enables 50% refund of actual paid price"
  - "Sell price based on actual purchase_price, not current inflated price -- transparent to player"
  - "Shop offers avoid duplicate card_ids via re-roll with max attempts safety"
  - "SHOPPING and PICKING states extend the PAUSED pause pattern -- save _previous_state, pause tree"

patterns-established:
  - "CardData Resource: class_name CardData extends Resource with enum Rarity, mirroring FruitData pattern"
  - "Dictionary-wrapped inventory: active_cards[i] = {card: CardData, purchase_price: int} for metadata tracking"
  - "Weighted rarity selection: cumulative randf() roll over RARITY_WEIGHTS per shop level"
  - "CardSlotDisplay: reusable PanelContainer with display_card()/display_empty()/set_sell_mode() API"

# Metrics
duration: 4min
completed: 2026-02-08
---

# Phase 5 Plan 01: Card System Data Layer Summary

**CardData Resource class with 10 card definitions, CardManager autoload for 3-slot inventory and weighted shop offers, GameManager SHOPPING/PICKING states, 7 EventBus card signals, and reusable CardSlotDisplay UI component**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-09T01:42:00Z
- **Completed:** 2026-02-09T01:45:43Z
- **Tasks:** 2
- **Files modified:** 17

## Accomplishments
- CardData Resource class with Rarity enum and 10 card .tres files (5 Common, 4 Uncommon, 1 Rare) with balanced pricing for coin economy
- CardManager autoload: 3-slot inventory with add/remove/get, weighted rarity shop offers avoiding duplicates, buy price inflation by shop level, sell price at 50% of actual purchase price
- GameManager extended with SHOPPING and PICKING states that save _previous_state and pause/unpause the tree, plus CardManager.reset() in reset_game()
- EventBus extended with 7 card lifecycle signals for decoupled UI communication
- CardSlotDisplay reusable scene with rarity-colored borders (grey/green/gold), display_card/display_empty/set_sell_mode API

## Task Commits

Each task was committed atomically:

1. **Task 1: CardData resource, 10 card .tres files, CardManager autoload, EventBus signals, GameManager states** - `8e5710f` (feat)
2. **Task 2: Reusable CardSlotDisplay UI component** - `a9718bb` (feat)

## Files Created/Modified
- `resources/card_data/card_data.gd` - CardData Resource class with Rarity enum (COMMON/UNCOMMON/RARE)
- `resources/card_data/bouncy_berry.tres` - Common, base_price 8 (small fruit bounce)
- `resources/card_data/quick_fuse.tres` - Common, base_price 8 (fast merge score bonus)
- `resources/card_data/fruit_frenzy.tres` - Common, base_price 10 (chain multiplier)
- `resources/card_data/golden_touch.tres` - Common, base_price 10 (bonus coins per merge)
- `resources/card_data/cherry_bomb.tres` - Common, base_price 8 (cherry merge push)
- `resources/card_data/heavy_hitter.tres` - Uncommon, base_price 18 (mass boost)
- `resources/card_data/big_game_hunter.tres` - Uncommon, base_price 20 (high tier score bonus)
- `resources/card_data/lucky_break.tres` - Uncommon, base_price 16 (chance for bonus coins)
- `resources/card_data/pineapple_express.tres` - Uncommon, base_price 18 (pineapple creation reward)
- `resources/card_data/wild_fruit.tres` - Rare, base_price 30 (wild merge flexibility)
- `scripts/autoloads/card_manager.gd` - Card inventory, shop generation, economy management
- `scenes/ui/card_slot_display.tscn` - PanelContainer with styled card layout
- `scenes/ui/card_slot_display.gd` - display_card/display_empty/set_sell_mode API
- `scripts/autoloads/event_bus.gd` - Added 7 card lifecycle signals
- `scripts/autoloads/game_manager.gd` - Added SHOPPING/PICKING states, CardManager.reset() call
- `project.godot` - Registered CardManager autoload

## Decisions Made
- active_cards stores `{card: CardData, purchase_price: int}` dictionaries rather than raw CardData references, enabling sell price to be 50% of what the player actually paid (not current inflated price)
- Shop offers use re-roll with max_attempts safety (count * 5) to avoid duplicate card_ids without risking infinite loops
- SHOPPING and PICKING states follow the exact same pattern as PAUSED: save _previous_state, emit signal, then pause tree
- CardManager placed after SfxManager in autoload order (CardManager._ready() only loads cards and resets state, no cross-autoload dependency in _ready)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed CardSlotDisplay node paths to match scene tree**
- **Found during:** Task 2 (CardSlotDisplay UI component)
- **Issue:** Plan specified `$Content/CardName` but scene tree has MarginContainer between root PanelContainer and Content VBoxContainer
- **Fix:** Updated all node paths to `$MarginContainer/Content/CardName`, `$MarginContainer/Content/Description`, `$MarginContainer/Content/PriceLabel`
- **Files modified:** scenes/ui/card_slot_display.gd
- **Verification:** Node paths now match the .tscn scene tree hierarchy
- **Committed in:** a9718bb (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Node path correction necessary for runtime correctness. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CardData class and 10 .tres files ready for Plans 02/03 to reference
- CardManager API (generate_shop_offers, generate_starter_offers, add_card, remove_card) ready for shop/starter-pick UI
- CardSlotDisplay component ready to instance in HUD card slots and shop/pick overlays
- GameManager SHOPPING/PICKING states ready for game flow integration
- Card system is inert (effects not yet implemented) -- game plays normally until shop/pick UI is wired in Plans 02/03

## Self-Check: PASSED

All 14 created files verified on disk. Both task commits (8e5710f, a9718bb) verified in git log.

---
*Phase: 05-card-system-infrastructure*
*Completed: 2026-02-08*
