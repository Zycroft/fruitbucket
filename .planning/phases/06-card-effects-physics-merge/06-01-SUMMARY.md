---
phase: 06-card-effects-physics-merge
plan: 01
subsystem: gameplay
tags: [godot, rigidbody2d, physics-material, impulse, card-effects, gdshader]

# Dependency graph
requires:
  - phase: 05-card-system-infrastructure
    provides: "CardManager autoload with active_cards array, CardData resources with card_id strings"
  - phase: 01-core-physics-merging
    provides: "Fruit RigidBody2D with shared PhysicsMaterial, MergeManager merge pipeline, FruitContainer group"
provides:
  - "CardEffectSystem component with event-driven effect dispatch"
  - "Bouncy Berry effect: per-fruit PhysicsMaterial bounce modification for tiers 0-2"
  - "Cherry Bomb effect: radial impulse on cherry merges with shockwave visual"
  - "fruit.gd is_wild/is_heavy flags and _can_merge_with() merge rule extension"
  - "Rainbow outline shader for wild fruit visual (used by Plan 02)"
  - "EventBus signals for card effect coordination (heavy_hitter_charges_changed, wild_fruit_marked/unmarked, cherry_bomb_triggered)"
affects: [06-02-PLAN, 07-card-effects-scoring-economy]

# Tech tracking
tech-stack:
  added: [gdshader-rainbow-outline]
  patterns: [event-driven-card-effects, per-fruit-physics-material, radial-impulse-with-tween-visual]

key-files:
  created:
    - scripts/components/card_effect_system.gd
    - resources/shaders/rainbow_outline.gdshader
  modified:
    - scenes/fruit/fruit.gd
    - scripts/autoloads/event_bus.gd
    - scenes/game/game.tscn

key-decisions:
  - "CardEffectSystem as scene-local Node (not autoload) for automatic cleanup on scene reload"
  - "Per-fruit PhysicsMaterial.new() to avoid shared resource mutation (Pitfall 1)"
  - "Always calculate bounce from base values to prevent exponential stacking (Pitfall 7)"
  - "Cherry Bomb triggers on old_tier == 2 (tier_3_cherry.tres tier=2, 0-indexed)"
  - "Shockwave ring via Line2D circle + tween (no separate .tscn needed)"

patterns-established:
  - "Event-driven card effects: connect EventBus signals, dispatch by card_id via _count_active() helper"
  - "Per-fruit physics override: create PhysicsMaterial.new() per affected fruit, restore _default_physics_material on revert"
  - "Radial impulse pattern: iterate FruitContainer children, distance check, linear falloff, apply_central_impulse"
  - "Tween-based VFX: Node2D + Line2D circle, scale tween + alpha fade, queue_free on complete"

# Metrics
duration: 3min
completed: 2026-02-09
---

# Phase 6 Plan 01: CardEffectSystem + Bouncy Berry + Cherry Bomb Summary

**CardEffectSystem component with event-driven Bouncy Berry bounce modification (tiers 0-2, +50% per card) and Cherry Bomb radial impulse on cherry merges with expanding shockwave ring**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-10T02:46:41Z
- **Completed:** 2026-02-10T02:49:24Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- CardEffectSystem component in game scene tree with signal-driven effect dispatch and _count_active() card stacking helper
- Bouncy Berry effect: per-fruit PhysicsMaterial with 0.15 + 0.5*N bounce formula, retroactive on purchase/sell, tier 0-2 only
- Cherry Bomb effect: 800*N force radial impulse on cherry merges with 200px radius and linear falloff
- Expanding shockwave ring visual via Line2D circle with scale/alpha tween
- fruit.gd merge rule extension: _can_merge_with() supporting wild fruit adjacent-tier merges (Plan 02)
- Rainbow outline shader created for wild fruit visual (Plan 02)

## Task Commits

Each task was committed atomically:

1. **Task 1: CardEffectSystem scaffold + fruit.gd infrastructure + EventBus signals + rainbow shader** - `eca1095` (feat)
2. **Task 2: Bouncy Berry effect + Cherry Bomb effect with shockwave** - `cda351b` (feat)

## Files Created/Modified
- `scripts/components/card_effect_system.gd` - Central card effect processor with Bouncy Berry and Cherry Bomb logic
- `scenes/fruit/fruit.gd` - Added is_wild/is_heavy flags and _can_merge_with() method
- `scripts/autoloads/event_bus.gd` - 4 new signals for card effect coordination
- `scenes/game/game.tscn` - Added CardEffectSystem node after MergeFeedback
- `resources/shaders/rainbow_outline.gdshader` - Rainbow cycling outline shader for wild fruit

## Decisions Made
- CardEffectSystem placed as scene-local Node (not autoload) for automatic state cleanup on scene reload -- no manual reset needed
- Per-fruit PhysicsMaterial.new() pattern to avoid mutating the shared fruit_physics.tres resource
- Bounce always calculated from base (0.15) + bonus*N, never from current value, preventing exponential stacking
- Cherry Bomb triggers on old_tier == 2 (cherry is tier index 2 in code, despite "tier 3" filename)
- Shockwave ring drawn procedurally via Line2D with 32 circle points rather than a separate .tscn scene
- EventBus signal types use RigidBody2D instead of Fruit for wild_fruit_marked/unmarked to avoid cyclic class references

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CardEffectSystem is ready for Heavy Hitter and Wild Fruit effects (Plan 02)
- _can_merge_with() is in place for wild fruit adjacent-tier merges
- Rainbow shader is ready for runtime application to wild fruits
- EventBus signals for heavy_hitter_charges_changed and wild_fruit_marked/unmarked are declared

## Self-Check: PASSED

All 6 files verified present. Both task commits (eca1095, cda351b) verified in git log. Key patterns confirmed: _can_merge_with in fruit.gd, heavy_hitter_charges_changed in event_bus.gd, CardEffectSystem in game.tscn, shader_type canvas_item in rainbow_outline.gdshader, _count_active in card_effect_system.gd.

---
*Phase: 06-card-effects-physics-merge*
*Completed: 2026-02-09*
