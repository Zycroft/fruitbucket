# Quick Task 5: Fix Game Freeze at ~1500 Score — Summary

## Root Cause

The game froze when a score threshold was crossed during an active chain reaction. The signal chain runs inside a physics step:

```
Physics callback (body_entered)
  → MergeManager.request_merge() → emits fruit_merged
  → ScoreManager._on_fruit_merged() → emits score_threshold_reached
  → game.gd._on_score_threshold() → GameManager.change_state(SHOPPING)
  → get_tree().paused = true  ← PAUSES TREE MID-PHYSICS STEP
```

Pausing the tree during a physics step corrupts the physics engine state, leaving the game permanently frozen with a dimmed overlay but no interactive shop UI.

This didn't manifest at the 500 threshold because early-game merges are simple one-offs. By ~1500, chain reactions with multiple concurrent merges make it very likely the threshold is crossed during an active physics callback.

## Fix Applied

**File:** `scenes/game/game.gd`

- Extracted shop opening logic from `_on_score_threshold()` into new `_open_shop()` method
- `_on_score_threshold()` now calls `call_deferred("_open_shop")` instead of opening immediately
- `_open_shop()` re-checks game state since it may change between deferral and execution
- The tree pause now happens between frames (after physics step completes), not mid-physics

## Why This Works

`call_deferred()` queues the function to run at the end of the current frame, after all physics callbacks complete. This ensures:
1. All in-flight merges and physics callbacks finish normally
2. The tree pauses cleanly between frames
3. The shop overlay renders correctly with interactive buttons
