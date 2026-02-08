# Phase 1: Core Physics & Merging - Research

**Researched:** 2026-02-08
**Domain:** Godot 4.5 2D physics (RigidBody2D, StaticBody2D, Area2D) for a Suika-style fruit-dropping puzzle game
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Bucket/trapezoid shape -- wider at top, narrower at bottom, funnels fruits together and matches the game name
- Visible bucket art with thickness and material -- the container is a drawn object, not just invisible collision walls
- Overflow indicator: dashed line near the top of the bucket interior as a static reference, PLUS the bucket rim glows/changes color (e.g., turns red) as fruits approach the danger zone -- escalating warning
- Themed background scene behind the bucket (kitchen counter, picnic table, or similar setting) -- gives the game world and context
- Flat/vector art style -- clean geometric shapes with bold colors, easy to read at any size
- 8 fruit tiers in the merge chain (e.g., blueberry -> grape -> cherry -> strawberry -> orange -> apple -> pear -> watermelon)
- Only tiers 1-5 appear as drops (per ROADMAP requirements)
- Fruit follows cursor/finger position above the bucket (WYSIWYG aiming)
- Faint vertical drop line extends from the fruit down into the bucket, showing exactly where it will land
- Next-fruit preview displayed above the bucket near the drop zone -- keeps the player's eyes in one place
- Two max-tier fruits (watermelon) merging triggers a dramatic vanish with special VFX celebration and bonus -- this is the big payoff moment
- Chain reactions have linked visual effects (flash/line/ripple connecting merge points) so consecutive merges read as a connected chain, not isolated events

### Claude's Discretion
- Whether fruits have faces/expressions (kawaii-style or plain)
- Size progression curve across the 8 tiers (gradual vs dramatic scaling)
- Drop cooldown timing (if any) between consecutive drops
- Drop speed / initial velocity after release
- How merging fruits disappear (instant pop vs shrink-to-midpoint)
- How the new merged fruit appears (instant vs scale-up animation)
- Themed background specific scene choice
- Bucket material/texture (metal, wood, ceramic, etc.)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

## Summary

Phase 1 delivers the irreducible core of the game: droppable, stackable, mergeable fruits inside a trapezoid bucket with overflow detection. This is a pure physics and collision phase -- no scoring logic, no chain multipliers, no visual juice, no card system. The goal is to make fruits feel right: they fall naturally, stack without jitter, merge reliably with exactly one new fruit spawning per collision pair, and the game ends only when a fruit genuinely lingers above the overflow line.

The implementation uses Godot 4.5's built-in 2D physics: each fruit is a RigidBody2D with CircleShape2D, the bucket is a StaticBody2D with CollisionPolygon2D segments forming a trapezoid, and the overflow zone is an Area2D with a dwell timer. All five critical Phase 1 pitfalls (double-merge, queue_free crash, RigidBody2D scaling, stacking jitter, overflow false positives) have well-documented solutions that must be baked in from day one. The MergeManager gatekeeper pattern prevents double-merge race conditions, call_deferred prevents physics callback crashes, fruit sizing operates through shape.radius and sprite scale (never RigidBody2D node scale), solver iterations are tuned for stacking stability, and the overflow detector uses a 2-second continuous dwell timer with grace periods.

The 8-tier fruit chain (down from the standard 11) means each tier jump is more significant, which favors a moderately aggressive size progression curve. The bucket's trapezoid shape funnels fruits together, increasing merge opportunities compared to straight-walled containers but also increasing stacking pressure.

**Primary recommendation:** Build a single reusable fruit scene configured by FruitData resources, route all merges through a MergeManager gatekeeper, use CollisionPolygon2D segments for the trapezoid bucket walls, and stress-test with 25+ fruits before moving to Phase 2.

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Godot Engine | 4.5 stable | Game engine, 2D physics, scene system | Project requirement. Built-in RigidBody2D physics handles Suika-style fruit stacking. |
| GDScript | 4.5 (static typing) | Scripting language | Project requirement. Use typed variables (`var x: int`) everywhere for editor autocomplete and 2-3x perf vs untyped. |
| GodotPhysics2D | 4.5 built-in | 2D physics solver | Zero-dependency starting point. Sufficient for 20-40 CircleShape2D bodies. Switch to Rapier only if stacking is unacceptable. |
| Compatibility renderer | OpenGL | Rendering backend | Broadest device support (web, old Android). Simple 2D game gains nothing from Vulkan. |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| Tween (built-in) | 4.5 | Merge animations on Sprite2D children | Every merge event. Animate sprite scale, never RigidBody2D scale. |
| Timer (built-in) | 4.5 | Overflow dwell timer, drop cooldown, merge grace period | All timed gameplay events. Use node-based Timer for persistent timers, not `await get_tree().create_timer()`. |
| Line2D / draw_dashed_line | 4.5 | Drop guide line | Static overflow reference line (dashed) and vertical drop preview line. Godot 4 has native `draw_dashed_line()` on CanvasItem. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| GodotPhysics2D | Godot Rapier Physics 2D (GDExtension) | 2-3x faster solver, better stacking stability. 1:1 API swap (change one Project Setting). Trade: added plugin dependency, ~2MB export size increase. Evaluate only if stacking jitter persists after tuning. |
| CollisionPolygon2D for bucket | Multiple CollisionShape2D (RectangleShape2D) rotated | Simpler setup for straight walls. But cannot form smooth trapezoid angles. CollisionPolygon2D gives precise wall placement. |
| Sprite2D + texture swap | AnimatedSprite2D | AnimatedSprite2D adds frame-by-frame state tracking overhead. Fruits use static sprites per tier; Tween handles any animation. Sprite2D is lighter. |

## Architecture Patterns

### Recommended Project Structure (Phase 1 only)
```
res://
+-- project.godot                    # Physics settings, autoloads, input map
+-- scenes/
|   +-- game/
|   |   +-- game.tscn                # Root game scene (assembles everything)
|   |   +-- game.gd                  # Game loop, state machine (DROPPING, IDLE, GAME_OVER)
|   +-- fruit/
|   |   +-- fruit.tscn               # Single reusable fruit (RigidBody2D + Sprite2D + CollisionShape2D)
|   |   +-- fruit.gd                 # Fruit behavior: collision detection, merge request
|   +-- bucket/
|   |   +-- bucket.tscn              # Trapezoid container (StaticBody2D + CollisionPolygon2D segments + visual art)
|   |   +-- bucket.gd                # Bucket visual state (rim glow for overflow warning)
|   +-- ui/
|       +-- hud.tscn                 # Score label, next-fruit preview, overflow line visual
|       +-- hud.gd
+-- scripts/
|   +-- autoloads/
|   |   +-- event_bus.gd             # Signal-only autoload for cross-system events
|   |   +-- game_manager.gd          # Score, game state enum, run lifecycle
|   +-- components/
|       +-- drop_controller.gd       # Input handling, cursor tracking, fruit spawning
|       +-- merge_manager.gd         # Merge gatekeeper: validates, deduplicates, executes
|       +-- overflow_detector.gd     # Dwell timer logic for game-over detection
+-- resources/
|   +-- fruit_data/
|   |   +-- fruit_data.gd            # FruitData custom Resource class
|   |   +-- tier_1_blueberry.tres    # Tier 1 config
|   |   +-- tier_2_grape.tres        # Tier 2 config
|   |   +-- tier_3_cherry.tres       # Tier 3 config
|   |   +-- tier_4_strawberry.tres   # Tier 4 config
|   |   +-- tier_5_orange.tres       # Tier 5 config
|   |   +-- tier_6_apple.tres        # Tier 6 config
|   |   +-- tier_7_pear.tres         # Tier 7 config
|   |   +-- tier_8_watermelon.tres   # Tier 8 config
+-- assets/
    +-- sprites/
    |   +-- fruits/                   # 8 flat/vector fruit PNGs
    |   +-- bucket/                   # Bucket art (sides, floor, rim)
    |   +-- background/              # Themed background scene art
    |   +-- ui/                       # Overflow line, drop guide
    +-- fonts/
```

### Pattern 1: FruitData Resource Model
**What:** Each fruit tier is a custom Resource (.tres) containing tier number, name, collision radius, sprite texture, mass, score value, and tint color. A single `fruit.tscn` scene reads its FruitData at spawn time and configures itself.
**When to use:** Always. This is the foundation of the fruit system. Never hardcode fruit properties in scenes or scripts.

```gdscript
# resources/fruit_data/fruit_data.gd
class_name FruitData
extends Resource

@export var tier: int = 0                     # 0-7 (8 tiers, 0-indexed)
@export var fruit_name: String = ""
@export var radius: float = 15.0              # CollisionShape2D circle radius in pixels
@export var sprite: Texture2D                 # Flat/vector fruit image
@export var score_value: int = 1              # Points awarded when this tier is CREATED by merging
@export var color: Color = Color.WHITE        # Tint for particles/effects (future phases)
@export var mass_override: float = 1.0        # RigidBody2D mass
@export var is_droppable: bool = true          # Only tiers 0-4 are droppable
```

```gdscript
# scenes/fruit/fruit.gd
class_name Fruit
extends RigidBody2D

var fruit_data: FruitData
var merging: bool = false          # Flag to prevent double-merge
var is_dropping: bool = false      # True while player is positioning this fruit
var merge_grace: bool = false      # True briefly after spawning from a merge

func initialize(data: FruitData) -> void:
    fruit_data = data
    $Sprite2D.texture = data.sprite
    # Create unique shape instance (shared shapes cause cross-fruit modification bugs)
    var shape := CircleShape2D.new()
    shape.radius = data.radius
    $CollisionShape2D.shape = shape
    mass = data.mass_override
```

### Pattern 2: MergeManager Gatekeeper
**What:** A single MergeManager node receives ALL merge requests from fruit collision callbacks. It deduplicates using a pending-merge dictionary keyed by instance ID, validates both fruits still exist, calculates the midpoint, removes both fruits safely, and spawns the next-tier fruit. No fruit ever executes its own merge.
**When to use:** Always. This is THE critical correctness pattern. Without it, double-merge bugs are guaranteed.

```gdscript
# scripts/components/merge_manager.gd
class_name MergeManager
extends Node

var _pending_merges: Dictionary = {}   # instance_id -> true
var _fruit_scene: PackedScene = preload("res://scenes/fruit/fruit.tscn")
var _fruit_types: Array[FruitData] = []  # Indexed by tier, loaded in _ready()

func request_merge(fruit_a: Fruit, fruit_b: Fruit) -> void:
    var id_a := fruit_a.get_instance_id()
    var id_b := fruit_b.get_instance_id()

    # Already pending? Skip.
    if _pending_merges.has(id_a) or _pending_merges.has(id_b):
        return

    # Lock both
    _pending_merges[id_a] = true
    _pending_merges[id_b] = true
    fruit_a.merging = true
    fruit_b.merging = true

    var merge_pos := (fruit_a.global_position + fruit_b.global_position) / 2.0
    var old_tier := fruit_a.fruit_data.tier
    var new_tier := old_tier + 1

    # Safe removal (disable before queue_free to avoid physics crash)
    _deactivate_fruit(fruit_a)
    _deactivate_fruit(fruit_b)

    # Spawn merged fruit (unless max tier -- watermelon pair vanishes)
    if new_tier < _fruit_types.size():
        var new_fruit := _spawn_fruit(new_tier, merge_pos)
        new_fruit.merge_grace = true
        # Clear grace after 0.5s
        get_tree().create_timer(0.5).timeout.connect(func():
            if is_instance_valid(new_fruit):
                new_fruit.merge_grace = false
        )

    # Notify other systems
    EventBus.fruit_merged.emit(old_tier, new_tier, merge_pos)

    # Cleanup pending locks (deferred so queue_free processes first)
    call_deferred("_cleanup_pending", id_a, id_b)

func _deactivate_fruit(fruit: Fruit) -> void:
    fruit.set_contact_monitor(false)
    fruit.freeze = true
    fruit.get_node("CollisionShape2D").set_deferred("disabled", true)
    fruit.visible = false
    fruit.call_deferred("queue_free")

func _cleanup_pending(id_a: int, id_b: int) -> void:
    _pending_merges.erase(id_a)
    _pending_merges.erase(id_b)
```

### Pattern 3: Trapezoid Bucket with CollisionPolygon2D
**What:** The bucket is a StaticBody2D with multiple CollisionPolygon2D children forming the trapezoid walls and floor. Each wall segment is a thin polygon (not just a line) to prevent tunneling. The visual bucket art is a separate Sprite2D or Polygon2D that renders the themed bucket material.
**When to use:** This phase. The trapezoid shape is a locked decision.

```
Bucket Scene Structure:
  Bucket (StaticBody2D)
    +-- BucketArt (Sprite2D or Polygon2D)     # Visual: the drawn bucket with thickness/material
    +-- LeftWall (CollisionPolygon2D)          # Angled left wall (wider at top, narrower at bottom)
    +-- RightWall (CollisionPolygon2D)         # Angled right wall (mirror of left)
    +-- Floor (CollisionPolygon2D)             # Flat bottom
    +-- RimGlow (Node2D with shader/modulate)  # Overflow warning visual on the rim
```

Wall polygon points define a thin trapezoid segment with ~8-12px thickness. Example for the left wall (assuming bucket is ~300px wide at top, ~200px wide at bottom, ~400px tall):
```gdscript
# Left wall outer-edge to inner-edge polygon points (clockwise)
# These would be set in the editor, not in code, but shown here for clarity:
# Outer top-left, outer bottom-left, inner bottom-left, inner top-left
var left_wall_points := PackedVector2Array([
    Vector2(0, 0),        # outer top-left
    Vector2(50, 400),     # outer bottom-left (angled inward)
    Vector2(60, 400),     # inner bottom-left (10px thickness)
    Vector2(10, 0),       # inner top-left
])
```

### Pattern 4: Drop Controller with Freeze Pattern
**What:** The fruit being positioned follows the cursor while frozen (freeze = true, freeze_mode = KINEMATIC). On click/release, freeze is set to false and the fruit enters physics simulation. The cursor is clamped to the bucket opening width.
**When to use:** For the fruit drop mechanic. WYSIWYG aiming per locked decision.

```gdscript
# scripts/components/drop_controller.gd
extends Node2D

var _current_fruit: Fruit = null
var _next_fruit_data: FruitData = null
var _can_drop: bool = true
var _drop_cooldown: float = 0.15  # seconds between drops (see Discretion section)

@onready var _fruit_container: Node2D = %FruitContainer
@onready var _drop_guide: Line2D = %DropGuide   # Vertical dashed line

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and _current_fruit:
        var clamped_x := clampf(event.position.x, _bucket_left, _bucket_right)
        _current_fruit.global_position.x = clamped_x
        _update_drop_guide(clamped_x)

    if event is InputEventMouseButton and event.pressed and _can_drop and _current_fruit:
        _drop_fruit()

func _drop_fruit() -> void:
    _current_fruit.freeze = false
    _current_fruit.is_dropping = false
    _current_fruit = null
    _can_drop = false
    # Start cooldown
    await get_tree().create_timer(_drop_cooldown).timeout
    _can_drop = true
    _spawn_preview()

func _spawn_preview() -> void:
    # Instantiate next fruit, frozen, at drop position
    _current_fruit = _fruit_scene.instantiate()
    _current_fruit.initialize(_next_fruit_data)
    _current_fruit.freeze = true
    _current_fruit.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
    _current_fruit.is_dropping = true
    _fruit_container.add_child(_current_fruit)
    _current_fruit.global_position = Vector2(_last_x, _drop_y)
    _roll_next_fruit()  # Pick random tier 1-5 for next preview
```

### Pattern 5: Overflow Detection with Dwell Timer
**What:** An Area2D positioned at the overflow line inside the bucket. Tracks which fruits are inside using body_entered/body_exited. A _physics_process accumulates dwell time per fruit. Game over triggers only when ANY fruit has stayed continuously for 2.0 seconds. Ignores dropping fruits and freshly-merged fruits (merge_grace flag).
**When to use:** Always. False positives are the most frustrating bug in Suika games.

```gdscript
# scripts/components/overflow_detector.gd
extends Area2D

const OVERFLOW_DURATION: float = 2.0
var _fruits_in_zone: Dictionary = {}  # instance_id -> accumulated_time

func _on_body_entered(body: Node) -> void:
    if body is Fruit and not body.is_dropping and not body.merge_grace and not body.merging:
        _fruits_in_zone[body.get_instance_id()] = 0.0

func _on_body_exited(body: Node) -> void:
    if body is Fruit:
        _fruits_in_zone.erase(body.get_instance_id())

func _physics_process(delta: float) -> void:
    var to_remove: Array[int] = []
    for id in _fruits_in_zone:
        # Validate fruit still exists (may have been merged/freed)
        if not is_instance_valid(instance_from_id(id)):
            to_remove.append(id)
            continue
        var fruit: Fruit = instance_from_id(id) as Fruit
        if fruit == null or fruit.is_dropping or fruit.merge_grace or fruit.merging:
            to_remove.append(id)
            continue
        _fruits_in_zone[id] += delta
        if _fruits_in_zone[id] >= OVERFLOW_DURATION:
            EventBus.game_over_triggered.emit()
            set_physics_process(false)  # Stop checking
            return
    for id in to_remove:
        _fruits_in_zone.erase(id)
```

### Anti-Patterns to Avoid
- **Fruit-to-fruit direct merge (no gatekeeper):** Both fruits detect collision and both spawn a merged fruit. ALWAYS route through MergeManager.
- **Hardcoded fruit properties in scene files:** Creating 8 separate .tscn files with hardcoded radii. Use one fruit.tscn + FruitData resources.
- **Scaling RigidBody2D node for size changes:** Physics engine resets scale to (1,1) every frame. Modify shape.radius and sprite.scale independently.
- **queue_free() inside body_entered:** Crashes the physics server. Use _deactivate_fruit pattern (disable contact_monitor, freeze, disable shape, call_deferred queue_free).
- **Polling fruit positions for overflow:** Checking every fruit's Y position in _process is wasteful. Use Area2D body_entered/exited signals.
- **Shared CircleShape2D instances across fruits:** Modifying one fruit's shape.radius would change ALL fruits sharing that resource. Always create new shape instances with `CircleShape2D.new()`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Physics simulation | Custom gravity + collision response | Godot RigidBody2D + GodotPhysics2D | Stacking, bouncing, friction, sleep -- thousands of edge cases. RigidBody2D handles all of it. |
| Circle-circle collision detection | Manual distance checks | CircleShape2D on RigidBody2D with contact_monitor | Physics engine does broadphase + narrowphase. Manual checks miss sleeping, tunneling, contact normals. |
| Merge deduplication | Per-fruit `already_merged` flag only | MergeManager gatekeeper with instance ID dictionary | Flags on fruits alone have race conditions within a single physics frame. Centralized gatekeeper is atomic. |
| Dashed line rendering | Custom draw loop with manual spacing | Godot 4 native `draw_dashed_line()` on CanvasItem | Built-in since Godot 4.0, handles antialiasing and line width correctly. |
| Timer-based delays | Manual delta accumulation in _process | Timer node or SceneTreeTimer | Timer nodes integrate with pause, tree lifecycle, and the editor inspector. |

**Key insight:** Godot's physics engine, Resource system, and built-in drawing API cover the entire Phase 1 feature set. The only custom logic needed is the MergeManager gatekeeper and the overflow dwell-time tracker.

## Common Pitfalls

### Pitfall 1: Double-Merge Race Condition
**What goes wrong:** When two identical fruits collide, both fire `body_entered` in the same physics frame. Without a gatekeeper, two merged fruits spawn instead of one, or one merge crashes trying to free an already-freed node.
**Why it happens:** Godot fires `body_entered` on BOTH colliding bodies. There is no built-in "this body owns the collision" concept. Additionally, `body_shape_entered` has a confirmed bug (#98353, OPEN) where it fires multiple times per frame for the same shape pair.
**How to avoid:** Route ALL merges through MergeManager. Use instance ID dictionary to lock fruits the instant a merge is requested. Set `merging = true` on both fruits before any processing. Use `body_entered` (NOT `body_shape_entered`) to avoid the duplicate-signal bug.
**Warning signs:** Score jumps by double expected amount. Two fruits of the next tier appear where one should. Intermittent crashes referencing freed objects.
**Confidence:** HIGH -- verified against Godot issue tracker #98353 and multiple community Suika implementations (Drygast, yokai-suika).

### Pitfall 2: queue_free() Crash During Physics Callbacks
**What goes wrong:** Calling `queue_free()` on a RigidBody2D inside `body_entered` or `_integrate_forces` crashes the physics server with "Condition '!body' is true" errors. The physics engine still holds references to the node being freed.
**Why it happens:** `queue_free()` defers deletion to end-of-frame, but the physics server processes collision exceptions before the node is fully removed. Documented in Godot issues #15904, #77793, #6676.
**How to avoid:** Never call `queue_free()` directly in physics callbacks. Instead: (1) set `contact_monitor = false`, (2) set `freeze = true`, (3) disable collision shape via `set_deferred("disabled", true)`, (4) set `visible = false`, (5) call `call_deferred("queue_free")`. This is the `_deactivate_fruit()` pattern shown above.
**Warning signs:** Intermittent crashes during rapid merge sequences. Error messages about physics bodies or collision exceptions. Crashes that only appear with many simultaneous merges.
**Confidence:** HIGH -- verified against Godot issue tracker #15904, #77793.

### Pitfall 3: RigidBody2D Scale Reset
**What goes wrong:** Setting `scale` on a RigidBody2D node has no effect -- the physics engine resets it to Vector2(1,1) every physics frame. Visual flickers for one frame then snaps back. This is by design, not a bug (Godot issues #5734, #89898, closed as "expected behavior").
**Why it happens:** The physics engine owns the transform of RigidBody2D nodes. It writes its calculated transform (including scale=1) back to the node every frame.
**How to avoid:** NEVER scale the RigidBody2D node. Instead: (1) set `$CollisionShape2D.shape.radius` for physics size, (2) set `$Sprite2D.scale` for visual size. For merge animations, tween the Sprite2D child's scale, not the RigidBody2D. The RigidBody2D node's scale must ALWAYS remain Vector2(1,1).
**Warning signs:** Fruits visually flicker when any size-change logic runs. Physics collisions don't match visual sizes.
**Confidence:** HIGH -- confirmed as permanent Godot design decision.

### Pitfall 4: Stacking Jitter with Many Fruits
**What goes wrong:** When 10+ RigidBody2D fruits pile up, the default physics solver produces visible jitter, overlapping bodies, and vibrating piles. Documented in Godot issues #2092, #80603, #72063.
**Why it happens:** The default solver doesn't have enough iterations to resolve all contact constraints in one frame. Residual forces cause bodies to bounce/vibrate against each other.
**How to avoid:** (1) Use CircleShape2D exclusively -- circles are the most stable and cheapest shape. (2) Increase solver iterations to 6-8 (Project Settings > Physics > 2D > Solver > Solver Iterations). (3) Set `can_sleep = true` on all fruits so settled piles stop consuming solver time. (4) Apply linear_damp 0.5-1.0 and angular_damp 1.0-2.0 to help fruits settle. (5) Use PhysicsMaterial with friction 0.6 and bounce 0.1-0.2. (6) Stress test with 25+ fruits. If jitter persists, switch to Rapier (1:1 API swap).
**Warning signs:** Fruits visibly vibrate when pile is 8+ deep. Merges triggered by jitter-induced collisions. Mobile framerate drops in late-game.
**Confidence:** HIGH -- well-documented long-standing Godot physics behavior.

### Pitfall 5: Overflow False Positives
**What goes wrong:** Game over triggers unfairly when a fruit briefly bounces above the overflow line during a merge or drop, even though the container isn't actually full.
**Why it happens:** Naive `body_entered` immediately triggers game over without accounting for transient physics events.
**How to avoid:** Implement dwell-time system (fruit must stay in overflow zone for 2.0 seconds continuously). Ignore fruits with `is_dropping = true` (being positioned by player). Ignore fruits with `merge_grace = true` (just spawned from a merge). Reset timer when fruit exits zone.
**Warning signs:** Playtesters report "unfair" game overs. Game over during chain reactions. Game over triggered by the preview fruit.
**Confidence:** HIGH -- standard Suika implementation pattern.

### Pitfall 6: Tween on RigidBody2D Suppresses Physics
**What goes wrong:** Tweening ANY property on a RigidBody2D node (scale, position, modulate) can interfere with physics processing. Linear velocity, gravity, and applied forces may not take effect until the tween completes.
**Why it happens:** Tween writes to the node's transform every frame, competing with the physics server's transform writes.
**How to avoid:** ONLY tween child nodes (Sprite2D scale, Sprite2D modulate), NEVER the RigidBody2D itself. For merge animations: tween the Sprite2D children of the merging fruits (shrink to midpoint), then spawn the new fruit's Sprite2D at small scale and tween it up. The RigidBody2D physics body uses its correct final size from the instant it spawns.
**Warning signs:** Merged fruit hangs in the air during animation. Physics stops working for all fruits temporarily.
**Confidence:** HIGH -- confirmed in Godot forum discussions and issue tracker.

## Code Examples

### Fruit Collision Detection (requests merge, never executes it)
```gdscript
# scenes/fruit/fruit.gd -- collision handler
func _on_body_entered(body: Node) -> void:
    if not body is Fruit:
        return
    if merging or body.merging:
        return
    if body.fruit_data.tier != fruit_data.tier:
        return
    # Deterministic tiebreaker: lower instance_id requests the merge
    # This prevents BOTH fruits from calling request_merge
    if get_instance_id() < body.get_instance_id():
        MergeManager.request_merge(self, body)
```
**Source:** Adapted from Drygast Suika clone pattern + yokai-suika architecture. Instance ID tiebreaker from Godot community best practice.

### Safe Fruit Deactivation (prevents physics crash)
```gdscript
# Called by MergeManager before queue_free
func _deactivate_fruit(fruit: Fruit) -> void:
    fruit.set_contact_monitor(false)  # Stop tracking collisions
    fruit.freeze = true                # Remove from physics solver
    fruit.get_node("CollisionShape2D").set_deferred("disabled", true)
    fruit.visible = false              # Hide immediately
    fruit.call_deferred("queue_free")  # Free at end of frame
```
**Source:** Godot issue #15904 workaround, verified pattern from community.

### Fruit Initialization from Resource
```gdscript
func initialize(data: FruitData) -> void:
    fruit_data = data
    $Sprite2D.texture = data.sprite
    # CRITICAL: Create new shape instance (never share shapes between fruits)
    var shape := CircleShape2D.new()
    shape.radius = data.radius
    $CollisionShape2D.shape = shape
    mass = data.mass_override
    # Scale sprite to match physics radius
    # Assumes sprite is authored at a reference size (e.g., 64x64)
    var sprite_natural_radius: float = $Sprite2D.texture.get_width() / 2.0
    var scale_factor: float = data.radius / sprite_natural_radius
    $Sprite2D.scale = Vector2(scale_factor, scale_factor)
```
**Source:** yokai-suika resource-based architecture pattern.

### Overflow Dwell Timer
```gdscript
# Area2D at the overflow line
const OVERFLOW_DURATION: float = 2.0
var _fruits_in_zone: Dictionary = {}

func _on_body_entered(body: Node) -> void:
    if body is Fruit and not body.is_dropping and not body.merge_grace:
        _fruits_in_zone[body.get_instance_id()] = 0.0

func _on_body_exited(body: Node) -> void:
    if body is Fruit:
        _fruits_in_zone.erase(body.get_instance_id())

func _physics_process(delta: float) -> void:
    for id in _fruits_in_zone.keys():
        if not is_instance_valid(instance_from_id(id)):
            _fruits_in_zone.erase(id)
            continue
        _fruits_in_zone[id] += delta
        if _fruits_in_zone[id] >= OVERFLOW_DURATION:
            EventBus.game_over_triggered.emit()
            return
```
**Source:** Standard Suika pattern adapted from pitfall research.

### Dashed Overflow Reference Line
```gdscript
# In the HUD or bucket scene, using Godot 4's native draw_dashed_line
func _draw() -> void:
    draw_dashed_line(
        Vector2(_bucket_left_inner, _overflow_y),
        Vector2(_bucket_right_inner, _overflow_y),
        Color(1, 0.3, 0.3, 0.5),  # Semi-transparent red
        2.0,                        # Line width
        8.0                         # Dash length
    )
```
**Source:** Godot 4 CanvasItem native API.

### Drop Guide Line
```gdscript
# Vertical line from fruit preview down into bucket
# Using Line2D node with 2 points, updated each frame
func _update_drop_guide(x_pos: float) -> void:
    _drop_guide.clear_points()
    _drop_guide.add_point(Vector2(x_pos, _drop_y))       # Top: where fruit sits
    _drop_guide.add_point(Vector2(x_pos, _bucket_floor_y)) # Bottom: bucket floor
    _drop_guide.default_color = Color(1, 1, 1, 0.2)       # Faint white
    _drop_guide.width = 1.5
```

## Discretion Recommendations

These are the areas marked as Claude's Discretion in the CONTEXT. Based on research:

### Fruit Faces/Expressions: Plain (no faces)
**Recommendation:** No faces for Phase 1. Plain flat/vector fruits with bold colors.
**Rationale:** Faces add art scope without gameplay value in the physics phase. The flat/vector art decision already establishes a clean geometric identity. Faces can be added as a polish pass in later phases or v2 (EXPR-01 is already in v2 requirements). Plain fruits also read more clearly at small sizes (tier 1-2 fruits are tiny).

### Size Progression: Moderate Geometric Curve
**Recommendation:** Use a geometric progression with ratio ~1.28x per tier, yielding radius range from 15px (blueberry) to ~80px (watermelon).
**Rationale:** With only 8 tiers (vs standard 11), each tier jump should be visually distinct. A geometric curve ensures small fruits feel small and watermelon feels massive, while keeping mid-tiers distinguishable. Linear progression would make adjacent tiers too similar; exponential would make high tiers too large for the bucket.

**Recommended size table (8 tiers):**

| Tier | Fruit | Radius (px) | Approx Diameter | Mass | Score Value |
|------|-------|-------------|-----------------|------|-------------|
| 1 | Blueberry | 15 | 30 | 0.5 | 1 |
| 2 | Grape | 20 | 40 | 0.8 | 3 |
| 3 | Cherry | 27 | 54 | 1.2 | 6 |
| 4 | Strawberry | 35 | 70 | 1.8 | 10 |
| 5 | Orange | 44 | 88 | 2.5 | 15 |
| 6 | Apple | 54 | 108 | 3.5 | 21 |
| 7 | Pear | 66 | 132 | 5.0 | 28 |
| 8 | Watermelon | 80 | 160 | 7.0 | 36 |

Score values follow triangular numbers (1, 3, 6, 10, 15, 21, 28, 36) so higher-tier merges are worth progressively more. Mass increases proportionally to area (radius^2 ratio) so larger fruits push smaller ones realistically.

**Confidence:** MEDIUM -- sizing is a tuning parameter. These values provide a solid starting point. The key constraint is: the bucket must comfortably hold 15-20 tier-1 fruits (total area check: 15+ blueberries at 30px diameter in a ~200-300px-wide bucket floor works). Watermelon at 160px diameter should fill roughly half the bucket width, creating satisfying spatial pressure.

### Drop Cooldown: 0.15 seconds
**Recommendation:** 150ms cooldown between consecutive drops.
**Rationale:** Zero cooldown lets players spam-drop which creates physics chaos and makes the game feel frantic rather than strategic. The original Suika game has a brief natural delay from the drop animation. 150ms is fast enough to feel responsive but prevents double-drops from accidental double-clicks. This also gives a single physics frame for the previous fruit to clear the drop zone.

### Drop Speed / Initial Velocity: Zero (pure gravity drop)
**Recommendation:** Drop the fruit with zero initial velocity (just unfreeze and let gravity take over). Set fruit's gravity_scale to 1.0.
**Rationale:** Zero initial velocity gives a natural, satisfying arc. Adding downward velocity makes drops feel "slammed" which fights the zen Suika feel. The player's control is WHERE to drop, not HOW FAST. Physics gravity at 980 pixels/s^2 provides adequate drop speed. If drops feel too slow during playtesting, increase gravity_scale on the fruit briefly during the first 0.3s (a "fast-fall" grace period), but start with pure gravity.

### Merge Disappearance: Shrink-to-Midpoint
**Recommendation:** Both merging fruits shrink their Sprite2D toward the midpoint over ~0.15 seconds, then the new fruit's Sprite2D scales up from 0.5x to 1.0x over ~0.1 seconds.
**Rationale:** Instant pop feels jarring and provides no visual feedback about what happened. Shrink-to-midpoint clearly communicates "these two became one" and creates a satisfying visual moment. The animation is on Sprite2D children only (never RigidBody2D), so physics is unaffected. The new fruit's RigidBody2D uses its full collision radius from spawn (physics-correct from frame 1), only the visual scales up.

**Implementation approach:**
1. When merge is triggered, tween both old fruits' Sprite2D scale to Vector2(0.1, 0.1) over 0.15s while tweening their Sprite2D position toward the midpoint
2. Simultaneously deactivate both old fruits' physics (freeze, disable shape)
3. Spawn new fruit at midpoint with correct physics size immediately
4. Tween new fruit's Sprite2D scale from Vector2(0.5, 0.5) to Vector2(1.0, 1.0) over 0.1s with ease-out

### New Fruit Appearance: Scale-Up with Ease-Out
**Recommendation:** New merged fruit appears with its Sprite2D at 50% scale and tweens to 100% over 0.1s with EASE_OUT transition.
**Rationale:** Provides a satisfying "pop into existence" feel. 50% starting scale (not 0%) avoids visual confusion where the fruit is invisible on spawn. Ease-out gives a quick snap that reads as energetic. The RigidBody2D collision shape is at full size from frame 1, so physics interactions are immediate and correct.

### Themed Background: Kitchen Counter
**Recommendation:** A warm-toned kitchen counter surface as the background, with the bucket sitting on it.
**Rationale:** A kitchen counter provides natural context for a bucket of fruit. It's visually warm, doesn't compete with the bright fruit colors, and matches the casual/cozy game feel. The flat/vector art style means the background can be simple geometric shapes (counter surface, back wall, maybe a window) without requiring detailed illustration. Other options (picnic table, cutting board) would also work, but kitchen counter is the most universally recognizable "fruit belongs here" setting.

### Bucket Material: Wooden Bucket
**Recommendation:** Light-toned wood (birch or pine aesthetic) with visible plank lines and a darker rim.
**Rationale:** Wood is warm and natural, matching the fruit/kitchen theme. It contrasts well with the bright flat-colored fruits without competing visually. A wooden bucket is the most literal interpretation of the game's name. The darker rim provides a natural visual element for the overflow glow effect (dark rim glowing red is high-contrast and reads clearly). Metal would feel cold/industrial; ceramic would feel fragile; plastic would feel cheap.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `body_shape_entered` for collision | `body_entered` for collision | Godot 4.x (bug #98353 still open) | `body_shape_entered` fires duplicates in same frame. Use `body_entered` to avoid double-merge trigger. |
| `mode = MODE_KINEMATIC` (Godot 3) | `freeze = true` + `freeze_mode = FREEZE_MODE_KINEMATIC` (Godot 4) | Godot 4.0 | Freeze replaces the old mode enum for temporarily removing bodies from physics. |
| Manual draw for dashed lines | `draw_dashed_line()` native API | Godot 4.0 | No longer need custom dashed-line helper functions. |
| `contacts_reported` property name | `max_contacts_reported` property name | Godot 4.0 | Renamed for clarity. Set to 4-8, not the old default of 0. |
| Separate scenes per fruit type | Single scene + Resource data | Godot 4.0 Custom Resources | FruitData .tres files are the standard pattern. One fruit.tscn configures from resource at runtime. |

**Deprecated/outdated:**
- `body_shape_entered` for merge detection: Use `body_entered` instead (avoids duplicate signal bug)
- `mode = MODE_RIGID / MODE_KINEMATIC`: Replaced by `freeze` + `freeze_mode` in Godot 4
- Manual `set_deferred("mode", ...)`: Use `freeze` property directly

## Open Questions

1. **Exact bucket dimensions and aspect ratio**
   - What we know: Trapezoid wider at top, narrower at bottom. Needs to comfortably hold 15-20 small fruits.
   - What's unclear: Exact pixel dimensions depend on target viewport resolution (1080p? 720p? mobile portrait?). The opening-to-floor width ratio affects how aggressively fruits funnel together.
   - Recommendation: Design for a 1080x1920 portrait viewport (mobile-first). Bucket opening ~350px wide, floor ~220px wide, height ~500px. Tune during implementation to feel right with the recommended fruit sizes.

2. **Rapier physics fallback threshold**
   - What we know: Default Godot solver may jitter with 20+ stacked circles. Rapier is 1:1 API swap.
   - What's unclear: At what fruit count does jitter become unacceptable? Depends on bucket size, fruit sizes, and damping values.
   - Recommendation: Stress test with 25+ fruits after initial physics tuning. If jitter is visible at normal play distance, install Rapier. Decision point: during Phase 1 implementation, not before.

3. **Watermelon pair vanish -- what exactly happens?**
   - What we know: Two watermelons merging should "vanish with special VFX celebration and bonus" (locked decision). No tier 9 fruit exists.
   - What's unclear: The VFX celebration is Phase 3 scope (merge feedback/juice). In Phase 1, should the watermelons simply disappear? Should there be a placeholder effect?
   - Recommendation: Phase 1 implements the vanish mechanic (both watermelons deactivated, no new fruit spawned, EventBus.fruit_merged emits with new_tier = -1 or a special signal). Placeholder: flash the screen white briefly. VFX celebration deferred to Phase 3.

4. **Chain reaction detection scope**
   - What we know: CONTEXT says "chain reactions have linked visual effects." The merge system naturally supports chain reactions (merged fruit touches same-tier fruit immediately).
   - What's unclear: Should Phase 1 track chain state (which merges are part of a chain) or just let physics handle it naturally?
   - Recommendation: Phase 1 does NOT track chains. The physics naturally cascades merges. Chain detection (time window, counter, visual linking) is Phase 2 (Scoring & Chain Reactions). Phase 1 just needs correct per-merge behavior.

5. **Fruit random selection weighting for drops**
   - What we know: Only tiers 1-5 are droppable. Next fruit is previewed.
   - What's unclear: Equal probability? Weighted toward smaller fruits? Does it change during a run?
   - Recommendation: Start with equal probability (20% each for tiers 1-5). This is a tuning knob that can change in later phases. Equal weighting is simplest to implement and test.

## Physics Configuration Reference

### Project Settings (project.godot)
```
[physics]
2d/default_gravity = 980
2d/default_gravity_vector = Vector2(0, 1)
2d/solver/solver_iterations = 6
2d/default_linear_damp = 0.5
2d/default_angular_damp = 1.0
common/physics_ticks_per_second = 60
```

### PhysicsMaterial (shared resource for all fruits)
```
[resource]
friction = 0.6
bounce = 0.15
```

### Collision Layer Plan
| Layer | Name | Used By |
|-------|------|---------|
| 1 | Fruits | All fruit RigidBody2D (layer + mask) |
| 2 | Container | Bucket StaticBody2D (layer only) |
| 3 | Overflow | Area2D overflow detector (mask layer 1 only) |

Fruit collision mask: layers 1 + 2 (collide with other fruits and bucket walls).
Container collision mask: none (static, doesn't need to detect).
Overflow area collision mask: layer 1 (detect fruits only).

### RigidBody2D Configuration (per fruit)
```
contact_monitor = true
max_contacts_reported = 4
continuous_cd = CCD_MODE_CAST_RAY      # Prevent wall tunneling
can_sleep = true                        # Let settled fruits sleep
gravity_scale = 1.0
freeze = true (when being positioned)   # Set false on drop
freeze_mode = FREEZE_MODE_KINEMATIC     # Allows position updates while frozen
```

## Sources

### Primary (HIGH confidence)
- [Godot RigidBody2D Docs](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html) -- contact_monitor, freeze, CCD, mass, signals
- [Godot Collision Shapes 2D Docs](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_2d.html) -- CircleShape2D performance, CollisionPolygon2D usage
- [Godot Troubleshooting Physics Issues](https://docs.godotengine.org/en/stable/tutorials/physics/troubleshooting_physics_issues.html) -- solver iterations, stacking stability
- [Godot Issue #98353](https://github.com/godotengine/godot/issues/98353) -- body_shape_entered duplicate signal bug (OPEN)
- [Godot Issue #15904](https://github.com/godotengine/godot/issues/15904) -- queue_free + contact_monitor crash
- [Godot Issue #89898](https://github.com/godotengine/godot/issues/89898) -- RigidBody2D scale reset (by design)
- [Godot Issue #2092](https://github.com/godotengine/godot/issues/2092) -- Stacking jitter with RigidBody2D piles

### Secondary (MEDIUM confidence)
- [Drygast Suika Clone Blog](https://drygast.net/blog/post/godot_ahballs) -- Merge detection with markedForDeletion flag, bowl setup with StaticBody2D
- [yokai-suika (Godot 4.3)](https://github.com/Checkroth/yokai-suika) -- Resource-based fruit architecture, scene-resource binding pattern
- [KidsCanCode RigidBody2D Drag & Drop](https://kidscancode.org/godot_recipes/4.x/physics/rigidbody_drag_drop/index.html) -- freeze mode for positioning, drop with impulse
- [Godot Forum: Tween on RigidBody2D Scale](https://forum.godotengine.org/t/tween-on-rigidbody2d-scale-interrupts-physics-process/120149) -- Confirmed: tween child Sprite2D, never the RigidBody2D
- [Godot Rapier Physics Benchmarks](https://godot.rapier.rs/docs/documentation/performance/) -- 1.7-3x performance vs default, better stacking
- [Godot Forum: Dashed Line Drawing](https://forum.godotengine.org/t/how-to-draw-a-dotted-dashed-line/14078) -- draw_dashed_line() native in Godot 4
- [Godot StaticBody2D Docs (4.5)](https://docs.godotengine.org/en/4.5/classes/class_staticbody2d.html) -- Container wall configuration

### Tertiary (LOW confidence)
- Suika fruit size progression: No public documentation of exact pixel values exists. Recommended sizes are derived from gameplay analysis (Drygast "measured each fruit from screen") and proportional geometric scaling. Treat as starting estimates requiring playtesting.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Godot 4.5 RigidBody2D + CircleShape2D is the proven Suika pattern across multiple implementations
- Architecture: HIGH -- MergeManager gatekeeper, FruitData resources, EventBus are established Godot 4 patterns with official and community documentation
- Pitfalls: HIGH -- All 5 phase-relevant pitfalls verified against Godot issue tracker with issue numbers and confirmed reproduction steps
- Discretion recommendations: MEDIUM -- Sizing, cooldowns, and animation timing are tuning parameters with informed starting values, not absolute answers
- Bucket trapezoid: MEDIUM -- CollisionPolygon2D is the correct tool, but exact dimensions and angle require visual tuning in-editor

**Research date:** 2026-02-08
**Valid until:** 2026-03-08 (stable domain, 30-day validity)
