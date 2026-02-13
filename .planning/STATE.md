# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-13)

**Core value:** The drop-merge-physics loop must feel satisfying and correct -- fruits fall naturally, collide realistically, and merge reliably.
**Current focus:** Milestone v1.1 -- Kawaii Art Overhaul, Phase 9 complete, ready for Phase 10 (Bucket Art)

## Current Position

Phase: 9 of 13 (Fruit Sprites) -- COMPLETE
Plan: 09-02 complete (2/2 plans)
Status: Phase 9 complete, ready for Phase 10
Last activity: 2026-02-13 -- Phase 9 complete (kawaii fruit sprites integrated, FaceRenderer removed)

Progress: [#################░] 86% overall (17/17 v1.0 + 2/2 phase 9)

## Performance Metrics

**v1.0 Velocity:**
- Total plans completed: 17
- Average duration: 5min
- Total execution time: 1.25 hours

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [v1.1]: Full visual overhaul scope -- fruits, bucket, background, UI elements
- [v1.1]: Kawaii/chibi art style -- round, blushing, big-eyed cute fruits with expressive faces
- [v1.1]: Runware AI for all art generation -- consistent style, fast iteration
- [v1.1]: Static sprites only (no animation) -- animation deferred to future milestone
- [09-02]: FruitData.color retained for particle effects, not sprite tinting
- [09-02]: Card effect visuals use Color.WHITE base modulate instead of fruit_data.color

### Relevant v1.0 Context

- Fruits display kawaii sprite art (512x512 PNGs) with auto-scaling from FruitData.sprite
- Fruit tier lineup: Cherry(0), Grape(1), Strawberry(2), Orange(3), Apple(4), Peach(5), Pineapple(6), Watermelon(7)
- FruitData.color used for particle effects and card visuals only (not sprite tinting)
- Bucket is Polygon2D trapezoid with Line2D outline
- Background is two-layer ColorRect (beige wall + brown counter)
- FruitData resources define tier, radius, color, mass_override, sprite
- fruit.tscn has Sprite2D + CollisionShape2D under RigidBody2D (FaceRenderer removed in 09-02)
- Sprite scale_factor = fruit_radius / texture_half_width (512px sprite base)
- **Critical**: Never scale RigidBody2D -- scale Sprite2D and CollisionShape2D.shape.radius separately

### Pending Todos

None yet.

### Blockers/Concerns

- [Resolved]: Sprites have RGBA transparent backgrounds (512x512)
- [Resolved]: 512px source scales cleanly to all tier sizes (15px-80px radius)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 1 | Deploy game to zycroft.duckdns.org/bucket via GitHub Actions | 2026-02-12 | d0698fc | [1-deploy-game-to-zycroft-duckdns-org-bucke](./quick/1-deploy-game-to-zycroft-duckdns-org-bucke/) |
| 2 | Add unique cartoon faces to all 8 fruit types | 2026-02-12 | bad8203 | [2-add-faces-to-each-of-the-fruit-types](./quick/2-add-faces-to-each-of-the-fruit-types/) |
| 3 | Playwright automated verification of all phases | 2026-02-12 | 59d45bc | [3-playwright-automated-verification-of-all](./quick/3-playwright-automated-verification-of-all/) |
| 4 | Fix the deployment | 2026-02-13 | 7ee50cd | [4-fix-the-deployment](./quick/4-fix-the-deployment/) |
| 5 | Fix game freeze at ~1500 score | 2026-02-13 | 558d0a7 | [5-fix-the-game-freeze-bug-at-1500-score](./quick/5-fix-the-game-freeze-bug-at-1500-score/) |
| 6 | Fix remaining errors | 2026-02-13 | 9a46a7f | [6-fix-remaining-errors](./quick/6-fix-remaining-errors/) |
| 7 | Create /z:verify Playwright validation command | 2026-02-13 | 94bf808 | [7-create-z-verify-playwright-validation-co](./quick/7-create-z-verify-playwright-validation-co/) |

## Session Continuity

Last session: 2026-02-13
Stopped at: Completed 09-02-PLAN.md (Phase 9 Fruit Sprites complete)
Resume file: None
