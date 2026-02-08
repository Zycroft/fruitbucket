# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-07)

**Core value:** The drop-merge-physics loop must feel satisfying and correct -- fruits fall naturally, collide realistically, and merge reliably.
**Current focus:** Phase 1: Core Physics & Merging

## Current Position

Phase: 1 of 8 (Core Physics & Merging)
Plan: 3 of 3 in current phase
Status: Checkpoint pending (human-verify playtest)
Last activity: 2026-02-08 -- 01-03-PLAN.md Task 1 complete, awaiting playtest checkpoint

Progress: [██░░░░░░░░] 13%

## Performance Metrics

**Velocity:**
- Total plans completed: 2 (01-03 Task 1 done, checkpoint pending)
- Average duration: 4min
- Total execution time: 0.2 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-core-physics-merging | 2/3 (3 in progress) | 12min | 4min |

**Recent Trend:**
- Last 5 plans: 01-01 (4min), 01-02 (4min), 01-03 (4min, checkpoint pending)
- Trend: stable

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: 8 phases derived from 37 requirements at comprehensive depth
- [Roadmap]: All 6 critical pitfalls (double-merge, queue_free, RigidBody scaling, stacking, overflow, card combinatorial) addressed in Phase 1 architecture
- [Roadmap]: Card effects split into two phases (Physics/Merge vs Scoring/Economy) for parallel execution potential
- [01-01]: Bucket wall collision extends 12px outside visible art for tunneling prevention
- [01-01]: Bucket floor has higher friction/lower bounce PhysicsMaterial than fruit-to-fruit physics
- [01-01]: OverflowLine drawing in separate Node2D script for separation of concerns
- [01-02]: MergeManager found via group lookup (not autoload) for scene-component composition
- [01-02]: Instance ID tiebreaker ensures exactly one merge request per colliding pair
- [01-02]: 0.5s merge grace period prevents immediate re-merge of freshly spawned fruits
- [01-02]: DropController uses _unhandled_input so future UI can consume events first
- [01-03]: OverflowDetector per-fruit dwell timer (instance ID dictionary) prevents one fruit's bounce from affecting another's accumulated time
- [01-03]: Next-fruit preview via EventBus.next_fruit_changed for DropController-HUD decoupling
- [01-03]: Bucket rim warning enhanced with width increase (5px to 8px) above 80% danger

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 1]: Physics tuning values (solver iterations, friction, bounce, damping) are starting estimates -- will need iteration during execution
- [Phase 1]: If stacking instability persists with 20+ fruits, evaluate Rapier physics plugin as fallback (1:1 API swap)

## Session Continuity

Last session: 2026-02-08
Stopped at: 01-03-PLAN.md Task 2 checkpoint (human-verify playtest)
Resume file: .planning/phases/01-core-physics-merging/01-03-SUMMARY.md
