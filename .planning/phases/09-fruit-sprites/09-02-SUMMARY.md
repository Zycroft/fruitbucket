---
phase: 09-fruit-sprites
plan: 02
subsystem: ui
tags: [sprites, kawaii, fruit-data, godot-resources, visual-overhaul]

# Dependency graph
requires:
  - phase: 09-01
    provides: "8 kawaii fruit sprite PNGs (512x512) in assets/sprites/fruits/"
provides:
  - "All 8 FruitData .tres files updated with kawaii sprites, new fruit names, and effect colors"
  - "Fruit scene cleaned of FaceRenderer and color tinting -- sprites render naturally"
  - "New fruit tier lineup: Cherry, Grape, Strawberry, Orange, Apple, Peach, Pineapple, Watermelon"
affects: [10-bucket-art, 11-background-art, 12-ui-overhaul]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Sprite-based fruit rendering: $Sprite2D.texture = data.sprite with auto-scaling from 512px source"
    - "FruitData.color used for particle effects and card visuals only, not sprite tinting"

key-files:
  created: []
  modified:
    - resources/fruit_data/tier_1_cherry.tres
    - resources/fruit_data/tier_2_grape.tres
    - resources/fruit_data/tier_3_strawberry.tres
    - resources/fruit_data/tier_4_orange.tres
    - resources/fruit_data/tier_5_apple.tres
    - resources/fruit_data/tier_6_peach.tres
    - resources/fruit_data/tier_7_pineapple.tres
    - resources/fruit_data/tier_8_watermelon.tres
    - scenes/fruit/fruit.gd
    - scenes/fruit/fruit.tscn
    - scenes/ui/hud.gd
    - scenes/ui/hud.tscn
    - scripts/components/merge_manager.gd
    - scripts/components/score_manager.gd
    - scripts/components/merge_feedback.gd
    - scripts/components/card_effect_system.gd
    - scenes/ui/run_summary.gd
    - resources/fruit_data/fruit_data.gd

key-decisions:
  - "FruitData.color retained for particle effects and card visuals, not removed entirely"
  - "Card effect modulate visuals updated to use Color.WHITE base instead of fruit_data.color"
  - "placeholder_fruit.png kept as fallback texture in fruit.tscn (harmless, overridden at runtime)"

patterns-established:
  - "Fruit visual rendering: Sprite2D.texture set from FruitData.sprite, no modulate tinting, auto-scaled from texture resolution"
  - "Fruit tier lineup: Cherry(0), Grape(1), Strawberry(2), Orange(3), Apple(4), Peach(5), Pineapple(6), Watermelon(7)"

# Metrics
duration: 5min
completed: 2026-02-13
---

# Phase 9 Plan 2: Fruit Sprite Integration Summary

**Integrated 8 kawaii fruit sprites into all tier data, renamed fruit lineup (cherry through watermelon), and removed procedural FaceRenderer + color tinting system**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-13T18:54:31Z
- **Completed:** 2026-02-13T19:00:25Z
- **Tasks:** 2
- **Files modified:** 18

## Accomplishments
- All 8 fruit tiers display unique kawaii sprite art instead of placeholder white circles
- Fruit names updated to final lineup: Cherry, Grape, Strawberry, Orange, Apple, Peach, Pineapple, Watermelon
- FaceRenderer procedural face system completely removed (162-line script deleted, nodes removed from fruit and HUD scenes)
- Color tinting removed from fruit initialization -- sprites show natural baked-in colors
- Physics properties (radius, mass, score_value, is_droppable) preserved identically at every tier
- Sprite scaling auto-adapts: 512px source textures scale correctly to all fruit sizes (15px-80px radius)

## Task Commits

Each task was committed atomically:

1. **Task 1: Rename tier files, update names/colors/sprites, and fix all path references** - `1d69047` (feat)
2. **Task 2: Remove FaceRenderer and color tinting from fruit scene** - `35a7a6c` (feat)

## Files Created/Modified
- `resources/fruit_data/tier_1_cherry.tres` - Tier 0 FruitData: Cherry sprite, deep red color
- `resources/fruit_data/tier_2_grape.tres` - Tier 1 FruitData: Grape sprite, purple color (unchanged name)
- `resources/fruit_data/tier_3_strawberry.tres` - Tier 2 FruitData: Strawberry sprite, red-orange color
- `resources/fruit_data/tier_4_orange.tres` - Tier 3 FruitData: Orange sprite, orange color
- `resources/fruit_data/tier_5_apple.tres` - Tier 4 FruitData: Apple sprite, green color
- `resources/fruit_data/tier_6_peach.tres` - Tier 5 FruitData: Peach sprite, peach pink color
- `resources/fruit_data/tier_7_pineapple.tres` - Tier 6 FruitData: Pineapple sprite, golden color
- `resources/fruit_data/tier_8_watermelon.tres` - Tier 7 FruitData: Watermelon sprite (unchanged name)
- `scenes/fruit/fruit.gd` - Removed modulate tinting and FaceRenderer call from initialize()
- `scenes/fruit/fruit.tscn` - Removed FaceRenderer node, reduced load_steps 5->4
- `scenes/fruit/face_renderer.gd` - DELETED (162-line procedural face drawing system)
- `scenes/ui/hud.gd` - Updated path arrays, removed NextFaceRenderer call and modulate tinting
- `scenes/ui/hud.tscn` - Removed NextFaceRenderer node, reduced load_steps 8->7
- `scripts/components/merge_manager.gd` - Updated FruitData path array
- `scripts/components/score_manager.gd` - Updated FruitData path array
- `scripts/components/merge_feedback.gd` - Updated FruitData path array
- `scripts/components/card_effect_system.gd` - Updated path array, fixed modulate visuals for kawaii sprites
- `scenes/ui/run_summary.gd` - Updated TIER_NAMES to match new lineup
- `resources/fruit_data/fruit_data.gd` - Updated tier comment

## Decisions Made
- **FruitData.color retained for effects:** Color field now serves particle effects and card visuals only (not sprite tinting). This preserves the effect system without washing out kawaii sprites.
- **Card effect visuals updated:** Heavy Hitter uses a subtle reddish-brown tint; Bouncy Berry uses slight brightness boost via modulate > 1.0; both restore to Color.WHITE when inactive.
- **placeholder_fruit.png kept:** Still referenced as default texture in fruit.tscn but overridden at runtime by FruitData.sprite. Harmless, can be cleaned up later.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed stale fruit names in run_summary.gd**
- **Found during:** Task 1 (path reference updates)
- **Issue:** run_summary.gd had hardcoded TIER_NAMES array with old names (Blueberry, Pear)
- **Fix:** Updated TIER_NAMES to match new lineup (Cherry, Grape, Strawberry, Orange, Apple, Peach, Pineapple, Watermelon)
- **Files modified:** scenes/ui/run_summary.gd
- **Verification:** grep confirmed no remaining "Blueberry" or "Pear" references in game code
- **Committed in:** 1d69047 (Task 1 commit)

**2. [Rule 1 - Bug] Fixed FaceRenderer references in HUD scene**
- **Found during:** Task 2 (FaceRenderer removal)
- **Issue:** hud.tscn and hud.gd had NextFaceRenderer node and face_renderer.gd reference that would crash after deletion
- **Fix:** Removed NextFaceRenderer node from hud.tscn, removed set_face() call and modulate tinting from hud.gd, reduced load_steps
- **Files modified:** scenes/ui/hud.tscn, scenes/ui/hud.gd
- **Verification:** grep confirmed no FaceRenderer references in any .gd/.tscn/.tres files
- **Committed in:** 35a7a6c (Task 2 commit)

**3. [Rule 2 - Missing Critical] Updated card effect modulate visuals for kawaii sprites**
- **Found during:** Task 2 (color tinting removal)
- **Issue:** card_effect_system.gd used fruit_data.color for Heavy Hitter and Bouncy Berry visual indicators -- would wash out kawaii sprites
- **Fix:** Heavy Hitter uses subtle Color(0.7, 0.5, 0.5) tint; Bouncy Berry uses brightness boost > 1.0; restores to Color.WHITE instead of fruit_data.color
- **Files modified:** scripts/components/card_effect_system.gd
- **Verification:** Confirmed no remaining fruit_data.color references in modulate assignments
- **Committed in:** 35a7a6c (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical)
**Impact on plan:** All auto-fixes prevent runtime crashes or visual corruption. No scope creep.

## Issues Encountered
None - plan executed smoothly after accounting for the deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 9 (Fruit Sprites) is now complete -- all 8 fruits display kawaii art
- Ready for Phase 10 (Bucket Art) -- the bucket visual overhaul
- FruitData.color values are tuned for new fruit colors, ready for particle effects in future phases

## Self-Check: PASSED

All 18 modified/created files verified present. face_renderer.gd confirmed deleted. Both task commits (1d69047, 35a7a6c) confirmed in git log.

---
*Phase: 09-fruit-sprites*
*Completed: 2026-02-13*
