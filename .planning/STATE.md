# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-07)

**Core value:** The drop-merge-physics loop must feel satisfying and correct -- fruits fall naturally, collide realistically, and merge reliably.
**Current focus:** Phase 3 in progress. Feedback infrastructure built, orchestrator next.

## Current Position

Phase: 3 of 8 (Merge Feedback & Juice) -- IN PROGRESS
Plan: 1 of 2 in current phase (Plan 01 complete)
Status: Phase 3 Plan 01 complete -- ready for Plan 02
Last activity: 2026-02-08 -- Phase 3 Plan 01 executed (2 tasks, shake/SFX/particles infrastructure)

Progress: [███░░░░░░░] 29%

## Performance Metrics

**Velocity:**
- Total plans completed: 6
- Average duration: 3.5min
- Total execution time: 0.35 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-core-physics-merging | 3/3 | 12min | 4min |
| 02-scoring-chain-reactions | 2/2 | 7min | 3.5min |
| 03-merge-feedback-juice | 1/2 | 2min | 2min |

**Recent Trend:**
- Last 5 plans: 01-02 (4min), 01-03 (4min), 02-01 (2min), 02-02 (5min), 03-01 (2min)
- Trend: stable/improving

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
- [02-01]: Watermelon vanish awards flat 1000 bonus replacing tier score (not additive per research pitfall #4)
- [02-01]: Chain multipliers use Fibonacci-like sequence [1,2,3,5,8,13,21,34,55,89] clamped at bounds
- [02-01]: ChainTimer created programmatically in _ready() for script-only component pattern
- [02-01]: Per-merge multiplier application -- each cascade merge gets its own chain-position multiplier
- [02-02]: PopupContainer uses group-based discovery (popup_container group) matching MergeManager pattern
- [02-02]: Chain label hidden for chain_count < 2 to prevent "CHAIN x1!" spam
- [02-02]: Tween-based UI animation with pivot_offset set after text assignment for correct centered scaling
- [02-02]: Coin label styled dark grey for secondary emphasis, score remains primary focus
- [03-01]: SFX bus graceful fallback -- push_warning and use Master if SFX bus missing
- [03-01]: All three play functions reuse same merge_pop.wav with pitch/volume variation per context
- [03-01]: No finished->queue_free in particle scene (editor crash bug #107743); connect at spawn time

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 1 resolved]: Physics stacking stable with solver_iterations=6, playtest confirmed 20+ fruit stacking without jitter
- [Phase 1 lesson]: ColorRect/Control nodes default to mouse_filter=STOP — always set IGNORE on non-interactive UI elements

## Session Continuity

Last session: 2026-02-08
Stopped at: Completed 03-01-PLAN.md (shake/SFX/particles infrastructure). Ready for 03-02-PLAN.md (MergeFeedback orchestrator).
Resume file: None
