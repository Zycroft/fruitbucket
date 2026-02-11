---
phase: 07-card-effects-scoring-economy
plan: 01
subsystem: gameplay
tags: [scoring, card-effects, chain-bonus, floating-popup, gdscript]

# Dependency graph
requires:
  - phase: 06-card-effects-physics-merge
    provides: "CardEffectSystem with _on_fruit_merged dispatcher, _count_active helper, Wild Fruit constants block"
  - phase: 02-scoring-chain-reactions
    provides: "ScoreManager with chain tracking, FruitData loading pattern, score_awarded signal"
  - phase: 05-card-system-infrastructure
    provides: "CardManager autoload, CardData resources, active_cards array, card shop/pick UI"
provides:
  - "ScoreManager.get_chain_count() public accessor for chain state"
  - "EventBus.bonus_awarded signal for card bonus feedback"
  - "CardEffectSystem scoring dispatcher (_apply_scoring_effects) with Quick Fuse, Fruit Frenzy, Big Game Hunter"
  - "FruitData loading in CardEffectSystem for base_score lookups"
  - "Colored bonus popup system (show_bonus) with purple/green styling"
  - "HUD bonus_awarded handler for popup spawning and score counter update"
affects: [07-card-effects-scoring-economy]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scoring effects apply to base_score only (not chain-multiplied total) to prevent inflation"
    - "Bonus score added directly to GameManager.score independently of ScoreManager"
    - "Bonus popups offset 30px below normal popups with distinct color (purple/green)"

key-files:
  created: []
  modified:
    - scripts/components/score_manager.gd
    - scripts/autoloads/event_bus.gd
    - scripts/components/card_effect_system.gd
    - scenes/ui/floating_score.gd
    - scenes/ui/hud.gd

key-decisions:
  - "Scoring bonuses apply to base_score only (FruitData.score_value), not chain-multiplied total, preventing runaway inflation"
  - "Quick Fuse requires chain_count >= 2 (first merge in chain does NOT qualify)"
  - "Fruit Frenzy +2x is additive bonus (base_score * 2 * count), not multiplicative on chain multiplier"
  - "Big Game Hunter triggers on new_tier >= 6 (created tier is Pear or Watermelon)"
  - "Bonus popups use show_bonus() separate from show_score() for distinct visual treatment"

patterns-established:
  - "Scoring effect dispatcher pattern: _apply_scoring_effects called at end of _on_fruit_merged, extensible for Plan 02 coin effects"
  - "Card bonus feedback pattern: effect -> GameManager.score += -> EventBus.bonus_awarded.emit -> HUD popup + score counter update"

# Metrics
duration: 2min
completed: 2026-02-11
---

# Phase 7 Plan 1: Scoring Card Effects Summary

**Quick Fuse (+25%), Fruit Frenzy (+2x base), Big Game Hunter (+50%) score-bonus card effects with purple floating popups and ScoreManager chain accessor**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-11T00:48:48Z
- **Completed:** 2026-02-11T00:50:57Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- ScoreManager exposes chain_count via public get_chain_count() accessor for card effect conditions
- Three score-bonus card effects (Quick Fuse, Fruit Frenzy, Big Game Hunter) compute correct bonuses based on chain state and fruit tier
- Purple bonus popups spawn at merge positions with 30px vertical offset from normal white/gold score popups
- HUD score counter reflects total score including card bonuses via bonus_awarded signal

## Task Commits

Each task was committed atomically:

1. **Task 1: Add scoring infrastructure and three score-bonus effect methods** - `fa3e6d2` (feat)
2. **Task 2: Add colored bonus popups and HUD bonus wiring** - `02f55ab` (feat)

## Files Created/Modified
- `scripts/components/score_manager.gd` - Added get_chain_count() public accessor for chain state
- `scripts/autoloads/event_bus.gd` - Added bonus_awarded signal with amount, position, bonus_type parameters
- `scripts/components/card_effect_system.gd` - Added FruitData loading, base_score lookup, Quick Fuse/Fruit Frenzy/Big Game Hunter effect methods, and _apply_scoring_effects dispatcher
- `scenes/ui/floating_score.gd` - Added show_bonus() method with purple/green color styling and offset positioning
- `scenes/ui/hud.gd` - Connected bonus_awarded signal, added _on_bonus_awarded handler for popup spawning and score update

## Decisions Made
- Scoring bonuses apply to base_score only (FruitData.score_value), not the chain-multiplied total -- prevents runaway inflation
- Quick Fuse requires chain_count >= 2 (the merge IS part of a chain; first merge does not qualify)
- Fruit Frenzy "+2x" interpreted as additive bonus of base_score * 2 per card (conservative interpretation)
- Big Game Hunter triggers on new_tier >= 6 (the CREATED fruit is Pear or Watermelon, code tiers 6-7)
- Bonus popups use separate show_bonus() method rather than extending show_score() for clean visual separation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Scoring effects infrastructure complete and extensible for Plan 02 coin/mixed effects
- _apply_scoring_effects dispatcher ready to have coin effect methods added
- bonus_awarded signal supports "coins" bonus_type with green popup color already implemented
- show_bonus() method already handles both "score" (purple) and "coins" (green) styling

---
*Phase: 07-card-effects-scoring-economy*
*Completed: 2026-02-11*
