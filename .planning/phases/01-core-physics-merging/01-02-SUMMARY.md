---
phase: 01-core-physics-merging
plan: 02
subsystem: physics, gameplay
tags: [godot, gdscript, rigidbody2d, collision, merge, input, mouse, scene-composition]

# Dependency graph
requires:
  - phase: 01-core-physics-merging
    plan: 01
    provides: "project.godot, EventBus, GameManager, FruitData resources, bucket scene, background, placeholder texture, fruit_physics.tres"
provides:
  - "Reusable Fruit scene (RigidBody2D + CircleShape2D) configured at runtime by FruitData"
  - "MergeManager gatekeeper with double-merge prevention via instance ID locking"
  - "Safe fruit deactivation pattern (no queue_free in physics callbacks)"
  - "spawn_fruit() public API for creating fruits at any tier/position"
  - "DropController with mouse tracking, drop guide line, 0.15s cooldown"
  - "Random tier 0-4 droppable fruit selection"
  - "Game scene assembling Background + Bucket + FruitContainer + MergeManager + DropController"
  - "Main scene set in project.godot for F5 play"
affects: [01-03, overflow-detector, scoring, chain-reactions, game-flow, card-effects]

# Tech tracking
tech-stack:
  added: []
  patterns: [merge-gatekeeper, instance-id-tiebreaker, safe-deactivation, frozen-preview, group-based-lookup]

key-files:
  created:
    - "scenes/fruit/fruit.tscn"
    - "scenes/fruit/fruit.gd"
    - "scripts/components/merge_manager.gd"
    - "scripts/components/drop_controller.gd"
    - "scenes/game/game.tscn"
    - "scenes/game/game.gd"
  modified:
    - "project.godot"

key-decisions:
  - "Fruits find MergeManager via group lookup (get_first_node_in_group) rather than autoload, keeping MergeManager as a scene component"
  - "Instance ID tiebreaker ensures only one fruit of a colliding pair initiates the merge request"
  - "Merge grace period of 0.5s prevents freshly merged fruits from immediately re-merging with adjacent same-tier fruits"
  - "DropController uses _unhandled_input instead of _input to allow UI to consume events first"

patterns-established:
  - "Merge gatekeeper: MergeManager._pending_merges dictionary locks instance IDs during merge, preventing duplicate merge processing"
  - "Safe deactivation: disable contact_monitor, freeze, defer-disable CollisionShape2D, hide, defer queue_free"
  - "Instance ID tiebreaker: lower ID fruit calls request_merge, guaranteeing exactly one merge request per colliding pair"
  - "Frozen preview: spawn_fruit(tier, pos, dropping=true) creates kinematic fruit for player positioning"
  - "Group-based component lookup: merge_manager, bucket, fruit_container groups for cross-component references"

# Metrics
duration: 4min
completed: 2026-02-08
---

# Phase 1 Plan 2: Core Fruit Gameplay Summary

**Reusable RigidBody2D fruit scene with FruitData-driven initialization, MergeManager gatekeeper preventing double-merge via instance ID locking, DropController with mouse positioning and drop guide line, and assembled game scene playable via F5**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-08T18:51:30Z
- **Completed:** 2026-02-08T18:55:08Z
- **Tasks:** 2
- **Files created:** 6
- **Files modified:** 1

## Accomplishments
- Reusable fruit scene (RigidBody2D) with runtime initialization from FruitData resources: sets CircleShape2D radius, sprite texture/color/scale, and mass -- never shares shape instances
- MergeManager gatekeeper with complete double-merge prevention: instance ID locking in _pending_merges dictionary, merging flag on fruits, deterministic tiebreaker (lower instance ID initiates), and 0.5s merge_grace period on newly spawned fruits
- Safe fruit deactivation pattern avoiding physics callback crashes: disable contact_monitor, freeze, deferred disable CollisionShape2D, hide, deferred queue_free
- DropController with mouse cursor tracking (clamped to bucket bounds), faint vertical drop guide Line2D, 0.15s cooldown between drops, random tier 0-4 selection
- Assembled game scene with Background + Bucket + FruitContainer + MergeManager + DropController, set as main scene for immediate F5 playtesting

## Task Commits

Each task was committed atomically:

1. **Task 1: Create reusable fruit scene and MergeManager gatekeeper** - `e2c7f26` (feat)
2. **Task 2: Create DropController with cursor tracking, drop guide, and game scene** - `05a016e` (feat)

## Files Created/Modified
- `scenes/fruit/fruit.tscn` - RigidBody2D fruit scene with CircleShape2D, contact monitor, CCD, body_entered signal
- `scenes/fruit/fruit.gd` - Fruit class with initialize(), collision guards, instance ID tiebreaker merge request
- `scripts/components/merge_manager.gd` - Merge gatekeeper: loads 8 tiers, request_merge with locking, safe deactivation, spawn_fruit API
- `scripts/components/drop_controller.gd` - Mouse tracking, drop guide Line2D, cooldown, random tier 0-4 selection, preview spawn
- `scenes/game/game.tscn` - Root game scene assembling all components with proper groups
- `scenes/game/game.gd` - Game loop: READY -> DROPPING transition, game_over_triggered handler
- `project.godot` - Updated run/main_scene to game.tscn

## Decisions Made
- Fruits find MergeManager via group lookup (`get_first_node_in_group("merge_manager")`) rather than making MergeManager an autoload -- keeps it as a scene component that can be composed differently in testing
- Instance ID tiebreaker pattern: when two same-tier fruits collide, only the one with the lower instance ID calls `request_merge()`, ensuring exactly one merge attempt per pair
- Merge grace period of 0.5s on freshly spawned merge results prevents immediate chain-merging with adjacent same-tier fruits that haven't moved yet
- DropController uses `_unhandled_input` instead of `_input` so future UI elements can consume input events before the drop controller processes them

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Core gameplay loop complete: fruits drop, stack with physics, and merge on same-tier contact
- Plan 01-03 can proceed: OverflowDetector has FruitContainer (group "fruit_container") to scan, Bucket.get_overflow_y() for threshold, EventBus.game_over_triggered for signaling
- MergeManager.spawn_fruit() API ready for any future system that needs to create fruits
- EventBus.fruit_merged and EventBus.fruit_dropped signals ready for scoring (Phase 2) and chain reaction detection
- Game scene is extensible: new components (OverflowDetector, HUD, etc.) can be added as children

## Self-Check: PASSED

- All 6 created files verified on disk
- project.godot modified with correct main_scene path
- Commit e2c7f26 (Task 1) verified in git log
- Commit 05a016e (Task 2) verified in git log

---
*Phase: 01-core-physics-merging*
*Completed: 2026-02-08*
