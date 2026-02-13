# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-13)

**Core value:** The drop-merge-physics loop must feel satisfying and correct -- fruits fall naturally, collide realistically, and merge reliably.
**Current focus:** Milestone v1.1 -- Kawaii Art Overhaul, Phase 9 (Fruit Sprites)

## Current Position

Phase: 9 of 13 (Fruit Sprites)
Plan: -- (not yet planned)
Status: Ready to plan
Last activity: 2026-02-13 -- Roadmap created for v1.1 (phases 9-13)

Progress: [################░░] 82% overall (17/17 v1.0 + 0/? v1.1)

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

### Relevant v1.0 Context

- Fruits use Vector _draw() faces on white circle sprites, tinted with FruitData.color
- Bucket is Polygon2D trapezoid with Line2D outline
- Background is two-layer ColorRect (beige wall + brown counter)
- FruitData resources define tier, radius, color, mass_override
- fruit.tscn has Sprite2D + FaceRenderer children under RigidBody2D
- Sprite scale_factor = fruit_radius / texture_half_width (64px sprite base)
- **Critical**: Never scale RigidBody2D -- scale Sprite2D and CollisionShape2D.shape.radius separately

### Pending Todos

None yet.

### Blockers/Concerns

- [Art concern]: Generated images need transparent backgrounds for game integration
- [Art concern]: Fruit sprites must work at multiple sizes (15px blueberry to 80px watermelon radius)

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
Stopped at: Roadmap created for v1.1 Kawaii Art Overhaul (phases 9-13)
Resume file: None
