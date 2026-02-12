---
phase: quick-2
plan: 01
subsystem: ui
tags: [godot, draw, node2d, faces, visual-polish]

# Dependency graph
requires:
  - phase: 01-core-physics-merging
    provides: "Fruit scene with Sprite2D, CollisionShape2D, and fruit.gd initialize()"
provides:
  - "FaceRenderer class_name for drawing cartoon faces via _draw()"
  - "8 unique tier-specific face expressions on all fruits"
  - "Face rendering in both game fruits and HUD next-fruit preview"
affects: [08-polish-balance]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Node2D _draw() for vector face rendering, no external textures needed"]

key-files:
  created:
    - scenes/fruit/face_renderer.gd
  modified:
    - scenes/fruit/fruit.tscn
    - scenes/fruit/fruit.gd
    - scenes/ui/hud.tscn
    - scenes/ui/hud.gd

key-decisions:
  - "Vector _draw() faces instead of texture sprites -- scales perfectly at any size, no asset files needed"
  - "Fixed 25.0 radius for HUD preview face -- consistent preview size regardless of actual fruit radius"

patterns-established:
  - "FaceRenderer pattern: set_face(tier, radius) configures, _draw() renders, queue_redraw() updates"

# Metrics
duration: 2min
completed: 2026-02-12
---

# Quick Task 2: Add Faces to Fruit Types Summary

**8 unique cartoon face expressions drawn via Node2D _draw() on all fruit tiers, visible in game and HUD preview**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-12T16:03:12Z
- **Completed:** 2026-02-12T16:05:14Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Created FaceRenderer script using _draw() for scalable vector faces on all 8 fruit tiers
- Each tier has a unique personality: surprised blueberry, happy grape, cheerful cherry, winking strawberry, confident orange, smug apple, sleepy pear, big happy watermelon
- Faces render in both the game bucket (scaled to fruit radius) and HUD next-fruit preview (fixed 25px radius)
- No external texture assets needed -- pure draw calls that scale perfectly at any size

## Task Commits

Each task was committed atomically:

1. **Task 1: Create FaceRenderer and add to fruit scene** - `246aaca` (feat)
2. **Task 2: Add face to next-fruit HUD preview** - `bad8203` (feat)

## Files Created/Modified
- `scenes/fruit/face_renderer.gd` - FaceRenderer class with 8 tier-specific _draw() face expressions
- `scenes/fruit/fruit.tscn` - Added FaceRenderer Node2D child after Sprite2D
- `scenes/fruit/fruit.gd` - initialize() calls FaceRenderer.set_face(tier, radius)
- `scenes/ui/hud.tscn` - Added NextFaceRenderer Node2D child to NextFruitPreview
- `scenes/ui/hud.gd` - update_next_fruit() configures preview face with fixed 25.0 radius

## Decisions Made
- Used Node2D _draw() for face rendering instead of texture sprites -- scales perfectly at any fruit size without asset files
- All face features use FACE_COLOR (black, 0.85 alpha) for consistent semi-transparent appearance
- Line widths scale proportionally: maxf(1.0, face_radius * 0.04) prevents sub-pixel lines on small fruits
- HUD preview uses fixed 25.0 radius (half of 50px preview target) regardless of actual fruit radius

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Faces are additive visual polish with zero gameplay impact
- FaceRenderer pattern is extensible -- new expressions or animated faces can be added later
- Ready for Phase 8 polish/balance work

## Self-Check: PASSED

All 5 files verified on disk. Both task commits (246aaca, bad8203) confirmed in git log.

---
*Phase: quick-2*
*Completed: 2026-02-12*
