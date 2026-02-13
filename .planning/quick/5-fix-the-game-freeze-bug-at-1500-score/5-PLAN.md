# Quick Task 5: Fix Game Freeze at ~1500 Score

## Root Cause

The game freezes when a score threshold (e.g., 1500) is crossed during an active chain reaction. The signal chain is:

```
Physics callback (body_entered)
  → MergeManager.request_merge() → emits fruit_merged
  → ScoreManager._on_fruit_merged() → emits score_threshold_reached
  → game.gd._on_score_threshold() → GameManager.change_state(SHOPPING)
  → get_tree().paused = true  ← PAUSES TREE DURING PHYSICS STEP
```

Pausing the tree mid-physics step leaves the physics engine in an inconsistent state. When unpaused, the engine can't properly resume, causing permanent freeze.

This didn't happen at the 500 threshold because early-game merges are simple (few concurrent collisions). By 1500, chain reactions with multiple concurrent merges make it very likely the threshold is crossed during an active physics callback.

## Fix

Defer the shop opening to run after the current physics step completes, using `call_deferred()`.

## Tasks

### Task 1: Defer shop opening in game.gd

**Changes to `scenes/game/game.gd`:**
- Extract shop opening logic from `_on_score_threshold` into `_open_shop()`
- Use `call_deferred("_open_shop")` instead of inline shop opening
- Add state re-check in `_open_shop()` since state may change between deferral and execution

**Commit:** `fix(game): defer shop opening to prevent freeze during physics callbacks`
