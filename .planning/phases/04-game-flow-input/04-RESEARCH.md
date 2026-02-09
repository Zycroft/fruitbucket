# Phase 4: Game Flow & Input - Research

**Researched:** 2026-02-08
**Domain:** Game state management (pause/resume/restart), dual-platform input (mouse + touch)
**Confidence:** HIGH

## Summary

Phase 4 covers two distinct systems: (1) a pause menu with resume, restart, and quit functionality, and (2) dual-platform input so touch works as well as mouse. The good news is that the existing codebase is well-prepared for both. The DropController already uses `_unhandled_input` (explicitly chosen in Phase 1 so UI can consume events first), the GameManager already has a state machine with `reset_game()`, and the project.godot already has a "drop" input action mapped to both `InputEventMouseButton` and `InputEventScreenTouch`.

The pause system is straightforward: Godot's `get_tree().paused = true` freezes the entire physics simulation (RigidBody2D, Area2D signals, _process, _physics_process) while nodes with `process_mode = PROCESS_MODE_ALWAYS` continue to receive input and process. The pause menu is a CanvasLayer with process_mode ALWAYS that sits above the game. The critical subtlety is that `SceneTree.paused` stops the physics server entirely -- there is no way to selectively pause some physics bodies. This is actually desirable for a Suika game: pausing freezes all fruit in place.

For touch input, the project already has `emulate_mouse_from_touch` enabled (default true in Godot 4). This means `InputEventScreenTouch` is automatically translated to `InputEventMouseButton`, and `InputEventScreenDrag` to `InputEventMouseMotion`. Since the DropController already handles `InputEventMouseMotion` and `InputEventMouseButton`, touch works out-of-the-box for the core drop mechanic. The main UX concern is finger occlusion: the success criteria specifically requires "finger does not obscure the drop position." The solution is a vertical offset on the drop preview -- the fruit appears above the finger touch point, not under it.

**Primary recommendation:** Add a PAUSED state to GameManager, build PauseMenu as a CanvasLayer with process_mode ALWAYS, and add a configurable touch Y-offset to DropController so the preview fruit hovers above the finger.

## Standard Stack

### Core

| Library/System | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Godot SceneTree.paused | 4.5 | Freeze gameplay (physics, process, animations) | Built-in engine feature. Stops entire physics server, _process, _physics_process, animations, particles. Exactly what a Suika pause needs. |
| Node.process_mode | 4.5 | Allow pause menu to function while game is paused | PROCESS_MODE_ALWAYS lets the pause menu receive input and process while everything else is frozen. |
| CanvasLayer | 4.5 | Render pause menu above game content | Pause menu needs to overlay the frozen game. CanvasLayer with layer >= 2 ensures it draws on top of game elements and HUD. |
| InputEventMouseMotion / InputEventMouseButton | 4.5 | Desktop input for fruit positioning and dropping | Already implemented in DropController._unhandled_input. |
| emulate_mouse_from_touch | 4.5 | Translate touch to mouse events automatically | Default enabled. InputEventScreenTouch becomes InputEventMouseButton, InputEventScreenDrag becomes InputEventMouseMotion. Single-pointer games like Suika need nothing more. |

### Supporting

| System | Version | Purpose | When to Use |
|--------|---------|---------|-------------|
| Input.is_action_just_pressed("ui_cancel") | 4.5 | Toggle pause on Escape key / Android back button | "ui_cancel" is pre-mapped to Escape and Android back button. Standard Godot pattern for pause toggle. |
| InputMap "pause" action | 4.5 | Custom pause input action | Add a "pause" action in Project Settings mapped to Escape and touch-friendly pause button. |
| get_tree().reload_current_scene() | 4.5 | Restart the game | Reloads the entire scene tree. Must also call GameManager.reset_game() to reset autoload state. |
| ColorRect with modulate alpha | 4.5 | Dim background behind pause menu | Semi-transparent overlay to visually separate paused game from menu. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SceneTree.paused | Manual process_mode toggling per node | More complex, error-prone. SceneTree.paused is simpler and freezes physics server globally which is exactly what we want. |
| emulate_mouse_from_touch | Raw InputEventScreenTouch/Drag handling | Only needed for multi-touch. Suika is single-pointer. Emulation is sufficient and eliminates duplicate input code. |
| reload_current_scene() | Manual node cleanup + re-instantiation | More control but much more code. reload_current_scene() + manual autoload reset is simpler for our case. |
| CanvasLayer for pause menu | Control node in game scene | CanvasLayer guarantees correct draw order independent of game camera position/shake. |

## Architecture Patterns

### Recommended Project Structure

```
scenes/
  ui/
    pause_menu.tscn          # New: CanvasLayer with process_mode ALWAYS
    pause_menu.gd            # New: handles resume/restart/quit buttons
    hud.tscn                 # Existing: add pause button (touch-friendly)
    hud.gd                   # Existing: add pause button handler
scripts/
  autoloads/
    game_manager.gd          # Modified: add PAUSED state, restart logic
    event_bus.gd             # Modified: add pause/unpause signals (optional)
  components/
    drop_controller.gd       # Modified: add touch offset, respect PAUSED state
```

### Pattern 1: SceneTree Pause with ALWAYS-mode Menu

**What:** Use `get_tree().paused = true` to freeze the entire game. The pause menu has `process_mode = PROCESS_MODE_ALWAYS` so it keeps processing and receiving input.

**When to use:** Any time you need gameplay to freeze while UI remains interactive.

**Example:**
```gdscript
# game_manager.gd - Add PAUSED to the existing GameState enum
enum GameState {
    READY,
    DROPPING,
    WAITING,
    PAUSED,       # NEW
    GAME_OVER,
}

func change_state(new_state: GameState) -> void:
    if current_state == new_state:
        return
    current_state = new_state
    EventBus.game_state_changed.emit(new_state)

    match new_state:
        GameState.PAUSED:
            get_tree().paused = true
        GameState.GAME_OVER:
            get_tree().paused = true
        _:
            get_tree().paused = false
```

```gdscript
# pause_menu.gd - Attached to CanvasLayer with process_mode = ALWAYS
extends CanvasLayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if GameManager.current_state == GameManager.GameState.PAUSED:
            _on_resume_pressed()
        elif GameManager.current_state != GameManager.GameState.GAME_OVER:
            _on_pause_pressed()
        get_viewport().set_input_as_handled()

func _on_pause_pressed() -> void:
    visible = true
    GameManager.change_state(GameManager.GameState.PAUSED)

func _on_resume_pressed() -> void:
    visible = false
    GameManager.change_state(GameManager.GameState.DROPPING)

func _on_restart_pressed() -> void:
    visible = false
    get_tree().paused = false
    GameManager.reset_game()
    get_tree().reload_current_scene()
```

### Pattern 2: Touch Offset for Drop Preview

**What:** On touch input, offset the drop preview fruit vertically above the touch position so the player's finger does not obscure it.

**When to use:** Any time touch input needs precision and the interaction point would be hidden under the finger.

**Example:**
```gdscript
# drop_controller.gd - Modified _unhandled_input
const TOUCH_Y_OFFSET: float = -120.0  # Preview appears 120px above finger

func _unhandled_input(event: InputEvent) -> void:
    if GameManager.current_state == GameManager.GameState.GAME_OVER:
        return
    if GameManager.current_state == GameManager.GameState.PAUSED:
        return

    if event is InputEventMouseMotion and _current_fruit:
        var clamped_x: float = clampf(event.position.x, _bucket_left, _bucket_right)
        _current_fruit.global_position = Vector2(clamped_x, _drop_y)
        _last_drop_x = clamped_x
        _update_drop_guide(clamped_x)

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
            and event.pressed and _can_drop and _current_fruit:
        _drop_fruit()
```

**Note:** Because `emulate_mouse_from_touch` is enabled, touch drag events arrive as `InputEventMouseMotion`. The drop preview Y position is already fixed at `_drop_y` (80px above bucket rim), so the fruit is naturally above the touch point. The drop guide line shows exactly where the fruit will land. No additional offset code may be needed if the fixed Y position is sufficiently above typical finger positions.

### Pattern 3: Restart with Autoload State Reset

**What:** When restarting, first reset autoload state, then reload the scene. Autoloads persist across scene reloads -- they are NOT re-initialized.

**When to use:** Any restart/retry functionality.

**Example:**
```gdscript
# game_manager.gd
func reset_game() -> void:
    score = 0
    coins = 0
    change_state(GameState.READY)

# Restart sequence (in pause_menu.gd or game.gd):
func _restart() -> void:
    get_tree().paused = false           # Must unpause BEFORE reload
    GameManager.reset_game()            # Reset autoload state
    get_tree().reload_current_scene()   # Reload scene tree
```

**Critical:** `get_tree().paused` must be set to `false` before `reload_current_scene()`. If you reload while paused, the new scene starts paused with no way to unpause (since the pause menu is also reloaded).

### Anti-Patterns to Avoid

- **Pausing with process_mode DISABLED on individual nodes:** Tedious, error-prone, misses physics. Use `get_tree().paused = true` instead.
- **Using PROCESS_MODE_WHEN_PAUSED for the pause menu:** Creates a split-brain problem. The code that opens the pause menu must run while unpaused, but the code that closes it must run while paused. ALWAYS mode avoids this by processing in both states.
- **Calling reload_current_scene() while paused:** The reloaded scene inherits the paused state but the pause menu is gone. Always unpause first.
- **Resetting ScoreManager/chain state manually:** `reload_current_scene()` destroys and recreates all non-autoload nodes. ScoreManager, MergeManager, OverflowDetector, MergeFeedback, and DropController all re-run `_ready()` and reinitialize. Only autoloads (GameManager, EventBus, SfxManager) persist.
- **Separate touch and mouse code paths:** The emulate_mouse_from_touch setting handles the translation. Writing separate `InputEventScreenTouch` and `InputEventMouseButton` handlers creates duplicate logic and divergent behavior.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pausing physics | Manual per-node freeze toggling | `get_tree().paused = true` | Physics server pauses globally and atomically. Manual approach misses edge cases. |
| Touch-to-mouse translation | Custom InputEventScreenTouch handler that mirrors mouse logic | `emulate_mouse_from_touch = true` (project setting) | Engine handles coordinate conversion, event generation. Eliminates duplicate code paths. |
| Pause button input detection | Custom key listener | `Input.is_action_pressed("ui_cancel")` or custom "pause" action | "ui_cancel" is pre-mapped to Escape and Android back button. Works on all platforms. |
| Scene restart | Manual node deletion + re-instantiation loop | `get_tree().reload_current_scene()` + `GameManager.reset_game()` | Scene reload handles all node cleanup automatically. Only autoloads need manual reset. |
| Dark overlay behind pause menu | Custom shader or Node2D drawing | `ColorRect` with semi-transparent color on CanvasLayer | Standard Godot UI pattern, zero-cost. |

**Key insight:** Both pause and touch input are well-served by built-in Godot systems. The project already has the correct input architecture (`_unhandled_input`, input action maps). The main work is adding UI nodes and wiring game state transitions.

## Common Pitfalls

### Pitfall 1: Reloading Scene While Paused

**What goes wrong:** Calling `get_tree().reload_current_scene()` while `get_tree().paused = true`. The new scene loads in a paused state, but the pause menu (which was part of the old scene) is gone. The game appears frozen with no way to unpause.

**Why it happens:** `get_tree().paused` is a SceneTree property, not a scene property. It persists across scene reloads.

**How to avoid:** Always set `get_tree().paused = false` before calling `reload_current_scene()`.

**Warning signs:** Game appears frozen after restart with no visible pause menu.

### Pitfall 2: Autoload State Not Resetting on Restart

**What goes wrong:** Player restarts, but score shows previous run's score, or GameState is wrong.

**Why it happens:** `reload_current_scene()` only reloads nodes in the scene tree. Autoloads (GameManager, EventBus, SfxManager) are NOT reloaded. Their variables retain previous values.

**How to avoid:** Call `GameManager.reset_game()` before reload. The existing `reset_game()` already resets score and coins. Verify it also resets `current_state` to `READY`.

**Warning signs:** Score, coins, or game state carry over between runs.

### Pitfall 3: Pause Menu Buttons Not Responding

**What goes wrong:** Pause menu shows but buttons do nothing when clicked/tapped.

**Why it happens:** The pause menu's `process_mode` is set to INHERIT or PAUSABLE instead of ALWAYS. When `get_tree().paused = true`, the menu freezes along with everything else.

**How to avoid:** Set the pause menu CanvasLayer's `process_mode` to `Node.PROCESS_MODE_ALWAYS` in `_ready()` or in the Inspector.

**Warning signs:** Menu appears but is unresponsive. Works fine when game is not paused.

### Pitfall 4: UI Elements Blocking Game Input

**What goes wrong:** Touch/click input does not reach the DropController because a UI element (ColorRect, Control, Label) is consuming the event first.

**Why it happens:** Control nodes default to `mouse_filter = STOP` in Godot. Any Control node in the scene tree will consume mouse/touch events before they reach `_unhandled_input`. This was already identified in Phase 1 ([01-01] decision).

**How to avoid:** Set `mouse_filter = IGNORE` (value 2) on ALL non-interactive UI elements (Labels, ColorRects, decorative Controls). Only interactive elements (Buttons, pause button) should have `mouse_filter = STOP`.

**Warning signs:** Clicking/tapping in certain areas does not drop fruit. Works in some positions but not others (depends on UI element positions).

### Pitfall 5: Touch Input Not Working on Web Export

**What goes wrong:** Touch works in the Godot editor but not in the web-exported version running on a mobile browser.

**Why it happens:** Web exports have known quirks with touch input. The `emulate_mouse_from_touch` setting should work for basic touch, but complex gestures may not translate.

**How to avoid:** Test the web export on an actual mobile device (not just desktop browser dev tools). For this Suika game, basic tap and drag should work since we rely only on single-pointer input. Ensure the HTML page has proper touch event handling (Godot's default HTML template handles this).

**Warning signs:** Touch drag does not move the preview fruit. Touch tap does not drop.

### Pitfall 6: DropController Continues Accepting Input While Paused

**What goes wrong:** Player can still move/drop fruits while the pause menu is open because `_unhandled_input` is not checking the PAUSED state.

**Why it happens:** Currently DropController only checks for `GAME_OVER`. If using `get_tree().paused = true`, this is actually handled automatically because `_unhandled_input` stops being called on paused nodes. But if the implementation changes or uses a different pause mechanism, the guard is needed.

**How to avoid:** `get_tree().paused = true` stops `_unhandled_input` on PAUSABLE nodes (the default). Verify DropController's process_mode is INHERIT or PAUSABLE (which it is by default). The DropController should NOT be set to ALWAYS.

**Warning signs:** Fruits drop while pause menu is visible.

### Pitfall 7: Finger Obscuring Drop Position on Mobile

**What goes wrong:** On touch devices, the player's finger covers the exact spot where the fruit preview sits, making precise positioning impossible.

**Why it happens:** Touch input position is at the fingertip contact point. If the preview fruit renders at that same position, the finger hides it.

**How to avoid:** In the current implementation, `_drop_y` is set to `bucket.top_left.y - 80.0` (about 620px), which is the fixed preview Y. On a 1920px tall viewport shown on a phone, this position is in the upper-middle area. The player's finger will typically be lower (in the bucket area). The drop guide line already shows where the fruit will land. This natural offset may be sufficient. If testing reveals the finger still obscures the preview, add a configurable Y-offset for touch input specifically.

**Warning signs:** Playtesters on mobile report difficulty positioning fruit precisely.

## Code Examples

### Complete Pause Menu Scene Structure (pause_menu.tscn)

```
PauseMenu (CanvasLayer) [process_mode = ALWAYS, layer = 10]
  Overlay (ColorRect) [anchors full rect, color = Color(0, 0, 0, 0.5)]
  VBoxContainer (centered)
    PausedLabel (Label) ["PAUSED"]
    ResumeButton (Button) ["Resume"]
    RestartButton (Button) ["Restart"]
    QuitButton (Button) ["Quit"]
```

### GameManager State Additions

```gdscript
# Add PAUSED to existing enum
enum GameState {
    READY,
    DROPPING,
    WAITING,
    PAUSED,       # NEW: pause menu is open
    GAME_OVER,
}

# Modify change_state to handle pause
func change_state(new_state: GameState) -> void:
    if current_state == new_state:
        return
    current_state = new_state
    EventBus.game_state_changed.emit(new_state)

    # Manage SceneTree pause based on state
    match new_state:
        GameState.PAUSED:
            get_tree().paused = true
        GameState.GAME_OVER:
            # Game over does NOT pause the tree (fruits keep settling visually)
            pass
        _:
            get_tree().paused = false
```

### HUD Pause Button (Touch-Friendly)

```gdscript
# In hud.gd - Add pause button handler
# The pause button should be at least 48x48 pixels for touch targets
# Position: top-left or top-right corner, away from gameplay area

func _on_pause_button_pressed() -> void:
    if GameManager.current_state == GameManager.GameState.GAME_OVER:
        return
    EventBus.pause_requested.emit()
```

### Restart Flow

```gdscript
# Complete restart sequence
func _restart_game() -> void:
    # 1. Unpause the tree (CRITICAL: must happen before reload)
    get_tree().paused = false

    # 2. Reset autoload state (these persist across scene reloads)
    GameManager.reset_game()

    # 3. Reload the scene (all non-autoload nodes are destroyed and recreated)
    get_tree().reload_current_scene()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Godot 3 pause_mode property | Godot 4 process_mode property | Godot 4.0 | Enum values changed: PAUSE_MODE_STOP -> PROCESS_MODE_PAUSABLE, PAUSE_MODE_PROCESS -> PROCESS_MODE_ALWAYS. Migration required for Godot 3 tutorials. |
| Manual input type detection | emulate_mouse_from_touch (default true) | Godot 4.0+ | Single-pointer games no longer need separate touch handlers. Touch events auto-translate to mouse events. |
| SceneTree.paused with node-level physics opt-out | SceneTree.paused stops ALL physics globally | Godot 4.0+ (confirmed behavior) | Cannot selectively pause physics. This is by design. For Suika, this is ideal -- all fruit freezes. |

**Deprecated/outdated:**
- `pause_mode` (Godot 3): Replaced by `process_mode` in Godot 4
- `Node.PAUSE_MODE_PROCESS`: Now `Node.PROCESS_MODE_ALWAYS`
- `Node.PAUSE_MODE_STOP`: Now `Node.PROCESS_MODE_PAUSABLE`

## Open Questions

1. **Should game over also pause the tree?**
   - What we know: The existing `_on_game_over()` in game.gd just changes state to GAME_OVER. The DropController checks for GAME_OVER and stops accepting input. Fruits currently keep settling after game over.
   - What's unclear: Whether fruits should freeze in place at game over (pause tree) or keep settling naturally (no pause). The architecture research suggests pausing on game over, but the current implementation does not.
   - Recommendation: Keep current behavior (no tree pause on game over). Fruits settling after game over looks natural. Pause menu restart/quit can still work since those buttons would be on an ALWAYS-mode CanvasLayer anyway. Revisit if Phase 8 run summary screen needs a frozen snapshot.

2. **What does "quit" mean for a web game?**
   - What we know: The game runs as a web export on GitHub Pages. There is no "quit application" on web. Desktop would use `get_tree().quit()`.
   - What's unclear: Should "quit" return to a title/menu screen, or just restart? There is no title screen currently.
   - Recommendation: For now, "quit" means "restart" (same as restart button). When a title screen is added (Phase 5 or later for card starter selection), quit should navigate to it. Implement as a function that can be easily redirected later.

3. **Is the natural drop preview Y-offset sufficient for touch?**
   - What we know: Preview Y is `bucket.top_left.y - 80.0` = approximately Y:620 on a 1920-tall viewport. The bucket opening is at Y:700. On a phone held in portrait, the player's finger would touch roughly in the Y:800-1200 range to be inside the bucket width.
   - What's unclear: Without physical device testing, we cannot confirm the natural offset is enough.
   - Recommendation: The preview is already 80-200px above where the finger would be (finger touches horizontally in the bucket area, preview is above the rim). This should be sufficient. Add a `TOUCH_PREVIEW_OFFSET` constant (default 0) that can be tuned if testing reveals issues, but do not add the offset proactively.

## Sources

### Primary (HIGH confidence)
- Godot official docs: [Pausing games and process mode](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html) -- process_mode values, SceneTree.paused behavior
- Godot GitHub Issue [#72974](https://github.com/godotengine/godot/issues/72974) -- Confirmed: SceneTree.paused stops ALL physics globally, process_mode ALWAYS does NOT exempt RigidBody2D from physics pause
- Godot official docs: [InputEventScreenTouch](https://docs.godotengine.org/en/stable/classes/class_inputeventscreentouch.html) -- Touch input event properties
- Godot GitHub Issue [#97594](https://github.com/godotengine/godot/issues/97594) -- emulate_mouse_from_touch defaults to true
- Existing codebase: project.godot already has "drop" action mapped to both MouseButton and ScreenTouch
- Existing codebase: DropController uses _unhandled_input (Phase 1 decision for UI event priority)

### Secondary (MEDIUM confidence)
- Godot Forum: [How to handle mouse and touch input simultaneously](https://forum.godotengine.org/t/how-to-handle-mouse-and-touch-input-simultaneously/111037) -- Recommendation to use emulate_mouse_from_touch for single-pointer games
- Godot Forum: [How do you handle both touchscreen and mouse inputs](https://forum.godotengine.org/t/how-do-you-handle-both-touchscreen-and-mouse-inputs/81358) -- Community consensus on emulation vs raw touch
- Godot Forum: [reload_current_scene crashes](https://forum.godotengine.org/t/get-tree-reload-current-scene-crashes-game/56999) -- Known issue with reload while paused, autoload state persistence
- Godot Forum: [Autoloads don't reload](https://forum.godotengine.org/t/how-to-make-singletons-autoloads-reload-upon-get-tree-reload-current-scene/65629) -- Confirmed: autoloads persist across reload_current_scene

### Tertiary (LOW confidence)
- Earlier project research: [PITFALLS.md](../../research/PITFALLS.md) -- Touch target sizing (48x48dp minimum), finger occlusion offset technique
- Earlier project research: [STACK.md](../../research/STACK.md) -- Input handling recommendations (emulate_mouse_from_touch, _unhandled_input)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All components use built-in Godot 4.5 systems. No third-party dependencies. Well-documented.
- Architecture: HIGH -- Patterns are standard Godot. Existing codebase already has the right input architecture. Changes are additive (new state, new scene).
- Pitfalls: HIGH -- All pitfalls verified through official docs, GitHub issues, and community reports. The most critical ones (reload-while-paused, autoload persistence) are well-documented.
- Touch input: MEDIUM -- emulate_mouse_from_touch works for single-pointer. Web export touch confirmed working for basic input but needs physical device testing. Finger occlusion assessment based on coordinate analysis, not device testing.

**Research date:** 2026-02-08
**Valid until:** 2026-03-08 (stable Godot features, unlikely to change)
