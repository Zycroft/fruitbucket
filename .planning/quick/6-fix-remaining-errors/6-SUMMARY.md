# Quick Task 6: Fix Remaining Errors — Summary

## Root Cause

MergeManager's `_deactivate_fruit()` called `set_contact_monitor(false)` and `freeze = true` directly during physics callbacks (the `body_entered` → `request_merge()` → `_deactivate_fruit()` signal chain). Godot logged 482 errors per session:

- `Can't disable contact monitoring during in/out callback` (rigid_body_2d.cpp:599)
- `Can't change this state while flushing queries` (godot_physics_server_2d.cpp:570)

## Fix Applied

**File:** `scripts/components/merge_manager.gd`

Changed two lines in `_deactivate_fruit()`:

```gdscript
# Before (direct calls during physics callback):
fruit.set_contact_monitor(false)
fruit.freeze = true

# After (deferred to next idle frame):
fruit.set_deferred("contact_monitor", false)
fruit.set_deferred("freeze", true)
```

All five deactivation operations are now deferred, safe from physics callback interference:
1. `contact_monitor` — `set_deferred`
2. `freeze` — `set_deferred`
3. `CollisionShape2D.disabled` — `set_deferred` (already was)
4. `visible = false` — cosmetic only, safe immediate
5. `queue_free` — `call_deferred` (already was)

## Result

- **Before:** 482 physics errors per session
- **After:** 0 physics errors per session
