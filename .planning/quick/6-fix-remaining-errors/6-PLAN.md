---
phase: quick-6-fix-remaining-errors
plan: 1
type: execute
wave: 1
depends_on: []
files_modified: [scripts/components/merge_manager.gd]
autonomous: true
must_haves:
  truths:
    - "No physics callback errors logged during gameplay"
    - "Merges complete successfully without Godot warnings"
    - "Fruits are safely removed from simulation after merging"
  artifacts:
    - path: "scripts/components/merge_manager.gd"
      provides: "Safe physics state deactivation"
      min_lines: 107
  key_links:
    - from: "fruit.gd (body_entered callback)"
      to: "merge_manager.gd (_deactivate_fruit)"
      via: "Deferred operations instead of direct calls"
      pattern: "set_deferred.*contact_monitor|freeze"
---

<objective>
Fix BUG-1: Physics callback errors from direct state modifications during physics frame.

Purpose: Eliminate 482 errors per session caused by modifying RigidBody2D physics properties directly inside physics callbacks.
Output: Clean error-free gameplay with safe fruit deactivation during merges.
</objective>

<execution_context>
@/home/zycroft/.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@/mnt/c/Users/zycro/OneDrive/Documents/Apps/godot/bucket/CLAUDE.md
@/mnt/c/Users/zycro/OneDrive/Documents/Apps/godot/bucket/scripts/components/merge_manager.gd
</context>

<tasks>

<task type="auto">
  <name>Fix physics state modifications in _deactivate_fruit()</name>
  <files>scripts/components/merge_manager.gd</files>
  <action>
In `merge_manager.gd`, update the `_deactivate_fruit()` method (lines 99-107) to defer the two physics-state-modifying operations that are currently called directly during the physics callback.

Current problematic code (lines 103-104):
```gdscript
fruit.set_contact_monitor(false)
fruit.freeze = true
```

These direct calls happen inside the physics callback chain (body_entered → fruit.request_merge() → _deactivate_fruit()). Godot throws errors: "Can't disable contact monitoring during in/out callback" and "Can't change this state while flushing queries".

Change to deferred calls:
```gdscript
fruit.set_deferred("contact_monitor", false)
fruit.set_deferred("freeze", true)
```

Leave lines 105-107 unchanged (CollisionShape2D disable and queue_free are already deferred, visible is cosmetic).

The corrected method should be:
```gdscript
func _deactivate_fruit(fruit: Fruit) -> void:
	## Safely removes a fruit from physics simulation and queues it for deletion.
	## CRITICAL: Never call queue_free() directly from a physics callback.
	## This pattern prevents the "flushing queries" crash.
	fruit.set_deferred("contact_monitor", false)
	fruit.set_deferred("freeze", true)
	fruit.get_node("CollisionShape2D").set_deferred("disabled", true)
	fruit.visible = false
	fruit.call_deferred("queue_free")
```
  </action>
  <verify>
Run the game in Godot editor (scenes/game/game.tscn) for 2-3 minutes, trigger multiple merges by dropping fruits of the same tier into the bucket and observing them merge. Watch the Output panel (bottom of Godot editor) for physics-related errors. There should be NO errors containing "contact monitoring" or "flushing queries".

Verify the fix programmatically by checking the modified file:
```bash
grep -A 6 "func _deactivate_fruit" /mnt/c/Users/zycro/OneDrive/Documents/Apps/godot/bucket/scripts/components/merge_manager.gd | grep "set_deferred"
```
Both `contact_monitor` and `freeze` should appear with `set_deferred`.
  </verify>
  <done>
The _deactivate_fruit() method defers both contact_monitor and freeze operations to the next frame (outside the physics callback). Running gameplay for 2-3 minutes with multiple merges produces zero physics callback errors in the Godot Output panel.
  </done>
</task>

</tasks>

<verification>
After completing the task:
1. Visual check: Run game.tscn, create 2-3 merges, observe no red error messages in Output panel
2. Grep check: Confirm set_deferred appears for both contact_monitor and freeze
3. Logical check: All three deactivation steps (contact monitor, freeze, collision disable, free) are now in deferred queue, safe from physics callback interference
</verification>

<success_criteria>
- Zero "Can't disable contact monitoring during in/out callback" errors in Godot Output after 2-3 minutes of gameplay
- Zero "Can't change this state while flushing queries" errors during merge operations
- merge_manager.gd lines 103-104 use set_deferred() instead of direct calls
- Game continues to function normally: merges still occur, fruits still vanish cleanly
</success_criteria>

<output>
After completion, create `.planning/quick/6-fix-remaining-errors/6-SUMMARY.md` with:
- Task completed status
- Error count before/after (from Playwright session: 482 → 0)
- Code changes made
- Test results
</output>
