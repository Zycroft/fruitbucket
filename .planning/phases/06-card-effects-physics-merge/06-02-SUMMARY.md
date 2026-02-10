---
phase: 06-card-effects-physics-merge
plan: 02
subsystem: gameplay
tags: [godot, rigidbody2d, mass-override, shader-material, card-effects, merge-rules]

# Dependency graph
requires:
  - phase: 06-card-effects-physics-merge
    plan: 01
    provides: "CardEffectSystem with signal dispatch, fruit.gd is_wild/is_heavy flags, _can_merge_with() merge rule extension, rainbow shader, EventBus signals"
  - phase: 05-card-system-infrastructure
    provides: "CardManager autoload with active_cards array, CardData resources with card_id strings"
provides:
  - "Heavy Hitter effect: 3-charge mass boost cycle with 2x multiplier per card, 5-merge recharge"
  - "Wild Fruit effect: periodic random selection with rainbow shader and adjacent-tier merge rule"
  - "MergeManager wild merge calculation: max(tier_a, tier_b) + 1 for generous upgrade"
  - "HUD charge display via CardSlotDisplay set_status_text overlay"
  - "DropController heavy preview visual (darkened fruit when charges available)"
affects: [07-card-effects-scoring-economy]

# Tech tracking
tech-stack:
  added: []
  patterns: [charge-recharge-cycle, periodic-selection-on-merge-counter, shader-material-runtime-application, wild-merge-tier-calculation]

key-files:
  created: []
  modified:
    - scripts/components/card_effect_system.gd
    - scripts/components/merge_manager.gd
    - scripts/components/drop_controller.gd
    - scenes/ui/card_slot_display.gd
    - scenes/ui/hud.gd

key-decisions:
  - "Heavy Hitter mass boost applied to last FruitContainer child (most recently added) for reliable drop targeting"
  - "Wild merge result uses maxi(tier_a, tier_b) for old_tier in EventBus signal so ScoreManager scores the higher tier"
  - "Wild Fruit selection deferred to merge events (every 5 merges) rather than timer-based for predictable behavior"
  - "CardSlotDisplay PriceLabel reused for charge status text in HUD mode (avoids new UI nodes)"
  - "Wild fruit cleanup iterates array copy to safely modify during iteration"

patterns-established:
  - "Charge/recharge cycle: _charges/_recharging/_merge_counter state, decrement on trigger, count merges to refill"
  - "Periodic selection: merge counter threshold, shuffle candidates, fill to capacity"
  - "Runtime ShaderMaterial: create per-fruit, set parameters, assign to Sprite2D.material, null to remove"
  - "HUD status overlay: set_status_text/clear_status_text on CardSlotDisplay via EventBus signal"

# Metrics
duration: 3min
completed: 2026-02-09
---

# Phase 6 Plan 02: Heavy Hitter + Wild Fruit Effects Summary

**Heavy Hitter 3-charge mass boost with HUD counter and 5-merge recharge, plus Wild Fruit periodic rainbow-shimmer designation with adjacent-tier merging at max(tier)+1**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-10T02:52:06Z
- **Completed:** 2026-02-10T02:55:18Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Heavy Hitter charge system: 3 charges per cycle, 2x mass multiplier per card stack, consumes on drop, recharges after 5 merges
- DropController preview darkens when heavy charges available, restores on depletion
- HUD card slot displays "N/3" charge count via CardSlotDisplay status text overlay
- Wild Fruit periodic selection: every 5 merges, picks random non-wild fruit, applies rainbow shader
- MergeManager wild merge calculation: max(tier_a, tier_b) + 1 for adjacent-tier merges (generous upgrade)
- Complete lifecycle management: purchase initializes, sell cleans up, restart resets all state

## Task Commits

Each task was committed atomically:

1. **Task 1: Heavy Hitter charge system with drop-time mass boost and HUD integration** - `cbf8540` (feat)
2. **Task 2: Wild Fruit periodic selection with rainbow shader and adjacent-tier merge logic** - `f94b019` (feat)

## Files Created/Modified
- `scripts/components/card_effect_system.gd` - Heavy Hitter charge/recharge logic, Wild Fruit mark/unmark/select/cleanup methods
- `scripts/components/merge_manager.gd` - Wild merge result calculation (max tier + 1 for adjacent-tier merges)
- `scripts/components/drop_controller.gd` - Heavy preview visual, charge change listener
- `scenes/ui/card_slot_display.gd` - set_status_text/clear_status_text methods for charge overlay
- `scenes/ui/hud.gd` - heavy_hitter_charges_changed signal handler, charge display on HUD card slots

## Decisions Made
- Heavy Hitter targets last FruitContainer child as the just-dropped fruit (reliable since fruit_dropped fires immediately after drop)
- Wild merge old_tier uses maxi(tier_a, tier_b) so downstream scoring rewards the higher tier
- Wild Fruit selection triggered by merge counter (every 5 merges) for predictable, gameplay-connected timing
- Reused existing PriceLabel in CardSlotDisplay for charge status text rather than creating new UI nodes
- Wild fruit array cleanup uses duplicate() + erase pattern for safe iteration during modification

## Deviations from Plan

None - plan executed exactly as written. Wild Fruit methods (mark, unmark, select, cleanup) were included in Task 1 commit alongside Heavy Hitter since they share the same card_effect_system.gd signal handlers. The split is logical (Task 1 = all card_effect_system.gd + UI, Task 2 = merge_manager.gd calculation).

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 4 Phase 6 card effects complete: Bouncy Berry, Cherry Bomb, Heavy Hitter, Wild Fruit
- CardEffectSystem fully operational with linear stacking, purchase/sell lifecycle, and clean restart
- Phase 7 (Scoring/Economy card effects) can build on established event-driven pattern
- _count_active() helper and EventBus signal pattern ready for reuse by scoring cards

## Self-Check: PASSED

All 5 modified files verified present. Both task commits (cbf8540, f94b019) verified in git log. Key patterns confirmed: _heavy_charges (14 occurrences) in card_effect_system.gd, is_wild_merge (2) in merge_manager.gd, has_heavy_charges in drop_controller.gd, set_status_text in card_slot_display.gd, heavy_hitter_charges_changed (2) in hud.gd.

---
*Phase: 06-card-effects-physics-merge*
*Completed: 2026-02-09*
