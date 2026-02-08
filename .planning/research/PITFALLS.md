# Pitfalls Research

**Domain:** Suika-style physics puzzle game with roguelike card modifiers (Godot 4.5 / GDScript)
**Researched:** 2026-02-07
**Confidence:** MEDIUM-HIGH (verified against Godot issue tracker, official docs, community implementations)

## Critical Pitfalls

### Pitfall 1: Double-Merge Race Condition

**What goes wrong:**
When two identical fruits collide, both fruits detect the collision simultaneously via `body_entered`. Both attempt to destroy the other and spawn a merged fruit, resulting in either: (a) two merged fruits spawning instead of one, (b) a crash from calling `queue_free()` on an already-freed node, or (c) one merge succeeding and the other silently failing but leaving orphaned state.

**Why it happens:**
Godot's `body_entered` signal fires on both colliding RigidBody2D nodes in the same physics frame. There is no built-in mechanism to determine which body "owns" the collision. Additionally, the `body_shape_entered` signal has a confirmed bug (godotengine/godot#98353, still OPEN) where it fires multiple times in the same frame for the same shape, compounding the problem.

**How to avoid:**
- Use `body_entered` (not `body_shape_entered`) to avoid the duplicate-signal bug.
- Implement a single-responsibility merge pattern: only ONE fruit handles the merge. Use a deterministic tiebreaker -- compare instance IDs (`get_instance_id()`). The fruit with the lower instance ID initiates the merge; the other ignores it.
- Before merging, validate that both fruits still exist and are valid (`is_instance_valid(other_fruit)`).
- Use a `merging` flag on each fruit. Set it `true` immediately when merge begins. Check `if merging or other.merging: return` before processing.

```gdscript
func _on_body_entered(body: Node) -> void:
    if body is Fruit and body.fruit_type == fruit_type:
        if merging or body.merging:
            return
        # Deterministic: lower instance_id wins
        if get_instance_id() < body.get_instance_id():
            _execute_merge(body)

func _execute_merge(other: Fruit) -> void:
    merging = true
    other.merging = true
    var spawn_pos = (global_position + other.global_position) / 2.0
    other.queue_free()
    queue_free()
    # Emit signal for GameManager to spawn next-tier fruit at spawn_pos
    EventBus.fruit_merged.emit(fruit_type + 1, spawn_pos)
```

**Warning signs:**
- Score jumps by double the expected amount on a single merge.
- Occasional crash logs referencing freed objects during collision callbacks.
- Two fruits of the next tier appearing where only one should.
- Intermittent "merge doesn't happen" bugs where both fruits ignore the collision.

**Phase to address:** Phase 1 (Core Physics / Fruit Merge). This is THE foundational mechanic. Get it right before anything else.

---

### Pitfall 2: queue_free() Crash During Physics Callbacks

**What goes wrong:**
Calling `queue_free()` on a RigidBody2D inside `body_entered`, `_integrate_forces`, or any physics callback can crash the physics server. The node is scheduled for deletion, but the physics engine still holds references to it. If `contact_monitor` is enabled, the engine tries to clean up collision exceptions on a node that no longer exists, producing `"Condition '!body' is true"` errors or outright crashes.

**Why it happens:**
`queue_free()` defers deletion to the end of the frame, but the physics server processes collision exceptions before the node is fully removed. This is a long-standing issue documented across Godot 3.x and 4.x (godotengine/godot#15904, #77793, #6676). The combination of `queue_free()` + `set_contact_monitor(true)` is the specific trigger.

**How to avoid:**
- Do NOT call `queue_free()` directly inside physics callbacks.
- Instead, disable the fruit immediately (set `visible = false`, disable collision shape, freeze the body) and call `queue_free()` via `call_deferred("queue_free")`.
- Better yet: use object pooling. Instead of destroying fruits, reset and hide them. This sidesteps the crash entirely and improves performance on mobile.
- If you must use `queue_free()`, remove collision exceptions first: `set_contact_monitor(false)` before calling `queue_free()`.

```gdscript
func _deactivate() -> void:
    set_contact_monitor(false)
    freeze = true
    $CollisionShape2D.set_deferred("disabled", true)
    visible = false
    call_deferred("queue_free")
```

**Warning signs:**
- Intermittent crashes that are hard to reproduce.
- Error messages mentioning physics body or collision exceptions in the debugger output.
- Crashes that only appear when many merges happen in quick succession.

**Phase to address:** Phase 1 (Core Physics). Bake the safe-deletion or pooling pattern into the Fruit base class from day one.

---

### Pitfall 3: RigidBody2D Cannot Be Scaled at Runtime

**What goes wrong:**
When a card effect or merge animation tries to scale a RigidBody2D node (e.g., `scale = Vector2(1.5, 1.5)`), the physics engine immediately resets the scale back to `Vector2(1, 1)`. The visual might flash at the new size for one frame, then snap back. This is by design -- RigidBody nodes maintain scale 1 to preserve physics calculation accuracy (godotengine/godot#5734, #89898, closed as "expected behavior").

**Why it happens:**
The physics engine owns the transform of a RigidBody2D. Every physics frame, it writes its calculated transform (including scale=1) back to the node, overwriting any manual scale changes. This is fundamental to how Godot's physics works, not a bug.

**How to avoid:**
- NEVER scale the RigidBody2D node itself. Instead, create each fruit tier as a separate scene with the correct-sized CollisionShape2D and sprite baked in.
- For dynamic size changes (card effects like "grow fruit"), modify the `CollisionShape2D.shape.radius` directly for CircleShape2D, and scale the sprite child node independently.
- For merge animations: use a Tween on the sprite child's scale for visual effect, while the actual physics body uses the correct final size from the start.

```gdscript
# WRONG - will be reset by physics engine
scale = Vector2(2.0, 2.0)

# RIGHT - modify shape and sprite independently
func set_fruit_size(new_radius: float) -> void:
    $CollisionShape2D.shape.radius = new_radius
    $Sprite2D.scale = Vector2(new_radius / base_radius, new_radius / base_radius)
```

**Warning signs:**
- Fruits visually "flicker" or "pop" when a size-change card effect activates.
- Card effects that should change fruit size appear to do nothing.
- Physics collisions don't match visual fruit sizes.

**Phase to address:** Phase 1 (Fruit system design). Define the sizing architecture before implementing any card effects. Every fruit tier must have its own pre-defined shape radius, not rely on runtime scaling.

---

### Pitfall 4: Stacking Instability -- Jitter, Overlap, and Vibrating Piles

**What goes wrong:**
When many RigidBody2D fruits pile up in the container (common late-game state), the default Godot physics solver produces visible jitter, overlapping bodies, and vibrating piles. Fruits shake against each other, overlap their collision shapes, and the pile looks unstable. This is a known, long-standing issue with Godot's built-in 2D physics (godotengine/godot#2092, #80603, #72063).

**Why it happens:**
Godot's default constraint solver struggles with many simultaneous contact points between stacked bodies. The solver iterations are not sufficient to resolve all contacts cleanly in one frame, causing residual forces that manifest as jitter. Smaller bodies are particularly affected.

**How to avoid:**
- Use CircleShape2D for all fruits (not rectangles or polygons). Circle-circle collisions are the most stable and cheapest to compute. This also matches the Suika aesthetic.
- Increase physics solver iterations in Project Settings: `Physics > 2D > Solver > Solver Iterations` from default 16 to 32 (test performance impact).
- Ensure `can_sleep = true` on all fruits so settled piles stop consuming solver time.
- Set appropriate `linear_damp` and `angular_damp` values to help fruits settle faster (try 0.5-1.0 for both).
- Consider Godot Rapier Physics plugin as a drop-in replacement if default physics is unacceptable. Rapier handles ~5,000 2D circle bodies at 30fps vs ~2,900 for default Godot physics. However, Rapier adds a plugin dependency -- evaluate whether the stability gain justifies it.
- Set reasonable `physics_material_override` with `friction` between 0.5-0.8 and `bounce` at 0.0-0.1 to reduce energy in the system.

**Warning signs:**
- Fruits visibly vibrate when the pile is 8+ fruits deep.
- Score randomly increases (merges triggered by jitter-induced collisions).
- Mobile framerate drops significantly in late-game states.
- Fruits appear to overlap or phase into each other.

**Phase to address:** Phase 1 (Core Physics). Tune physics parameters early with a stress test: drop 30+ fruits and observe the pile. If default physics is unacceptable, switch to Rapier before building anything else on top.

---

### Pitfall 5: Game-Over Overflow Detection False Positives

**What goes wrong:**
An Area2D "kill line" at the top of the container triggers game over when any fruit touches it. But fruits naturally bounce above the line during drops, merges, and chain reactions. Players get unfair instant game overs when a fruit briefly bounces through the detection zone during a merge cascade -- the most exciting moment in the game becomes the most frustrating.

**Why it happens:**
Naive implementation uses `body_entered` on the Area2D and immediately triggers game over. This doesn't account for transient physics events. The original Suika game uses a timer-based approach: game over only triggers if a fruit remains above the line for a sustained period (approximately 2-3 seconds).

**How to avoid:**
- Implement a dwell-time system: start a timer when a fruit enters the overflow zone, cancel it when the fruit exits.
- Only trigger game over if a fruit stays in the zone for 2+ seconds continuously.
- Ignore the currently-dropping fruit (the one the player is positioning) -- it is above the line by definition.
- Ignore fruits that were just spawned from a merge for a brief grace period (~0.5s).
- Use `body_entered` / `body_exited` pair to track which fruits are currently in the zone.

```gdscript
# OverflowZone.gd (Area2D at top of container)
var fruits_in_zone: Dictionary = {}  # fruit_id -> timer

func _on_body_entered(body: Node) -> void:
    if body is Fruit and not body.is_dropping and not body.merge_grace:
        fruits_in_zone[body.get_instance_id()] = 0.0

func _on_body_exited(body: Node) -> void:
    fruits_in_zone.erase(body.get_instance_id())

func _physics_process(delta: float) -> void:
    for id in fruits_in_zone.keys():
        fruits_in_zone[id] += delta
        if fruits_in_zone[id] >= OVERFLOW_DURATION:  # 2.0 seconds
            game_over.emit()
            return
```

**Warning signs:**
- Playtesters report "unfair" game overs.
- Game overs happen during chain reactions when the container is not actually full.
- Game overs triggered by the fruit the player is currently positioning.

**Phase to address:** Phase 1 (Core Game Loop). Must be designed alongside the merge system since merge chain reactions directly affect overflow detection timing.

---

### Pitfall 6: Card Effect Combinatorial Explosion

**What goes wrong:**
With even a modest set of 15-20 card types and 3-5 active slots, the number of possible card combinations grows explosively. Some combinations produce degenerate gameplay (infinite score loops, trivially easy runs, or completely broken physics). With 20 cards and 5 slots, there are ~15,000 possible loadouts. Testing every interaction is impossible, and untested combinations ship as bugs.

**Why it happens:**
Each card effect modifies some aspect of gameplay (physics properties, merge behavior, scoring). When multiple modifiers stack, they can interact in unintended ways. For example: "Bouncy Fruit" (high restitution) + "Giant Fruit" (larger radius) + "Multi-Merge" (merges with adjacent same-type) could create a fruit that bounces endlessly, triggering cascading merges that crash the game or produce absurd scores.

**How to avoid:**
- Design cards to modify ORTHOGONAL properties. Group effects into categories: Physics (bounce, weight, friction), Merge (behavior, chain rules), Scoring (multipliers, bonuses), Spawning (which fruits appear). Limit active cards to ONE per category to prevent intra-category conflicts.
- Implement a card effect pipeline with explicit ordering: Physics modifiers apply first, then merge modifiers, then scoring. Never rely on signal execution order (Godot does not guarantee signal callback order).
- Cap effect values. Every modifier should have min/max bounds. "Bouncy" sets restitution to 0.8, not "adds 0.5 to restitution" (which stacks unboundedly).
- Build a test harness early: an autoplay mode that randomly selects cards and drops fruits to detect degenerate combinations automatically.
- Start with 8-10 simple cards. Add complexity only after the base set is balanced. Slay the Spire spent 2.5 years in Early Access balancing their card pool.

**Warning signs:**
- One card combination dominates all runs (always picked, always wins).
- Physics breaks (fruits flying off screen, infinite bounce loops, stuck fruits).
- Score variance between runs is extreme (100x difference between best and worst).
- Players report "the game plays itself" with certain card combos.

**Phase to address:** Phase 3 (Card System). But the architecture for applying modifiers must be designed in Phase 1 so that fruit properties are data-driven and externally modifiable from the start.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoded fruit sizes/properties in scene files | Quick to set up 11 fruit types | Cannot be modified by card effects; requires editing 11 scenes for any balance change | Never -- use a FruitData Resource array from day one |
| Using `queue_free()` instead of object pooling | Simpler code, no pool management | Crashes in physics callbacks, GC pressure on mobile, frame hitches from instantiation | Prototype only; replace before mobile testing |
| Scaling RigidBody2D nodes for size effects | Intuitive API (`node.scale = ...`) | Does not work -- physics resets scale every frame | Never -- this is a hard engine limitation |
| Putting card effect logic inside Fruit scripts | Fast to prototype first card | Fruit class becomes god object; every new card requires modifying Fruit.gd | Never -- use external modifier system from start |
| Skipping merge animation (instant swap) | Avoids animation timing complexity | Players cannot see what merged; feels cheap and confusing | MVP prototype only; add animation in Phase 2 |
| Testing only with mouse input | Works fine on desktop | Touch input has different timing, precision, and multi-touch edge cases; surprises on mobile | Early development only; test touch by Phase 2 |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Too many active RigidBody2D without sleep | Framerate drops below 30fps | Ensure `can_sleep = true`; default Godot 2D physics handles ~2,900 circles at 30fps | 20+ unsleeping fruits in container (common late-game) |
| `contact_monitor = true` with high `max_contacts_reported` | Each monitored body adds O(n) contact tracking overhead | Set `max_contacts_reported` to minimum needed (4-8, not 16+); disable contact monitoring on fruits that are settled | 15+ fruits all monitoring contacts simultaneously |
| Spawning fruits with `instantiate()` every drop | Frame hitches on mobile during instantiation | Pre-instantiate a pool of 30-40 fruit nodes at game start; reuse them | Noticeable on low-end Android after 20+ drops |
| Unoptimized collision layers | Every fruit checks collision against every other fruit AND container walls | Use 3 layers: Container (1), ActiveFruits (2), SettledFruits (4). Only check ActiveFruits vs everything; move settled fruits to layer 4 | 25+ fruits, especially on mobile |
| Running card effect calculations every physics frame | Modifier lookups and property recalculations each tick | Cache modified values. Recalculate only when card loadout changes, not every frame | 5 active cards with complex modifier chains |
| Large textures for fruit sprites on mobile | Memory pressure, slow loading | Use texture atlases; keep individual fruit sprites under 256x256. Use mipmaps. | Mobile devices with limited VRAM |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No visual feedback during merge | Players don't understand what happened; feels like fruits disappeared randomly | Brief scale-up tween on merging fruits, particle burst, screen shake, and spawn animation for the new fruit |
| Touch target too small for fruit positioning | Frustrating on mobile; finger obscures the drop zone | Use an offset drop preview -- show the fruit above the player's finger, not under it. Minimum touch target 48x48dp |
| Instant game over with no warning | Players feel cheated, especially during chain reactions | Flash the overflow zone red, play warning sound when fruit is near line, use the dwell-time system described above |
| Card descriptions too text-heavy | Players skip reading cards, then surprised by effects | Use icons + 1-line description. Show effect preview (e.g., highlight affected fruits). Max 15 words per card |
| No indication of which cards are active | Players forget what modifiers are running | Persistent HUD showing active card icons with brief tooltip on tap. Animate card icon when its effect triggers |
| Drop position snaps to grid or feels laggy | Breaks the satisfying "precision physics" feel | Use direct 1:1 input mapping for horizontal position. No smoothing or interpolation on the drop cursor. Clamp to container bounds only |

## "Looks Done But Isn't" Checklist

- [ ] **Merge detection:** Tested with 3+ same-type fruits colliding simultaneously (not just pairs) -- verify only correct number of merges occur
- [ ] **Chain reactions:** Tested merge cascades (fruit A+B merge into C, which immediately touches another C) -- verify score counts all merges, no double-spawns
- [ ] **Overflow detection:** Tested during active chain reactions -- verify no false game overs during merge bounces
- [ ] **Fruit sizing:** All 11 fruit tiers have correct collision shape radii matching their sprites -- verify no visual/physics mismatch
- [ ] **Touch input:** Tested on actual mobile device (not just emulated) -- verify drop position accuracy, no input lag
- [ ] **Card effects:** Tested all active cards being removed mid-game (e.g., when replaced) -- verify fruit properties revert correctly
- [ ] **Container walls:** Tested fruits at high velocity hitting container walls -- verify no tunneling (enable CCD with Cast Ray, not Cast Shape which is broken per godotengine/godot#72674)
- [ ] **Physics sleep:** Verified settled fruits actually enter sleep state -- use Godot's debug draw to visualize sleeping bodies
- [ ] **Object lifecycle:** Stress test 50+ merges in rapid succession -- verify no memory leaks, no orphaned nodes, no physics crashes
- [ ] **Mobile performance:** Profile on lowest-target Android device with 25+ fruits and 5 active cards -- verify 60fps (or 30fps minimum)

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Double-merge race condition | LOW | Add instance ID tiebreaker and `merging` flag to Fruit script; no architectural change needed |
| queue_free crash | MEDIUM | Refactor to object pooling pattern; requires adding pool manager and changing all spawn/despawn call sites |
| RigidBody2D scaling | HIGH if discovered late | Requires redesigning how card effects modify fruit properties; must use shape.radius instead. If discovered after 10+ card effects are built, each must be rewritten |
| Stacking jitter | MEDIUM-HIGH | If default physics is inadequate, switching to Rapier requires adding plugin dependency and retesting all physics interactions. Better to evaluate early |
| Overflow false positives | LOW | Add timer-based dwell system to OverflowZone; no architectural impact |
| Card combinatorial explosion | HIGH | If cards are designed without orthogonal categories, rebalancing requires redesigning the entire card pool. Prevention is far cheaper |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Double-merge race condition | Phase 1: Core Physics | Unit test: spawn 3 same-type fruits in contact simultaneously; assert exactly 1 merge occurs |
| queue_free crash | Phase 1: Core Physics | Stress test: trigger 50 merges in 10 seconds; zero crash rate across 100 runs |
| RigidBody2D scaling limitation | Phase 1: Fruit Data Architecture | Verify card effects modify `shape.radius` and sprite scale independently; node scale remains Vector2(1,1) |
| Stacking jitter | Phase 1: Physics Tuning | Visual inspection: 30-fruit pile settles within 3 seconds with no visible jitter. Profile FPS on mobile |
| Overflow false positives | Phase 1: Game Over Logic | Playtest: chain reaction of 5+ merges near top; no false game over triggers |
| Card combinatorial explosion | Phase 3: Card Design (architecture in Phase 1) | Automated test: random card loadout + autoplay 100 runs; no physics breaks, score within 10x variance |
| Touch input precision | Phase 2: Input System | Test on 3 physical devices; drop position matches finger within 5px consistently |
| Contact monitor performance | Phase 1: Physics Tuning | Profile with 25 fruits: contact monitoring overhead < 2ms per physics frame |
| CCD for container walls | Phase 1: Core Physics | Test: apply impulse to fruit toward wall; no tunneling at any velocity up to 2000px/s |
| Card effect signal ordering | Phase 3: Card System | Test: 5 cards active; effects apply in documented order regardless of signal timing |

## Sources

- [Godot Issue #98353: body_shape_entered fires multiple times in same frame](https://github.com/godotengine/godot/issues/98353) -- OPEN, confirmed bug
- [Godot Issue #15904: Crash from queue_free + contact_monitor interaction](https://github.com/godotengine/godot/issues/15904) -- long-standing
- [Godot Issue #77793: Collision exception error after queue_free](https://github.com/godotengine/godot/issues/77793) -- fixed in 4.1 docs
- [Godot Issue #89898: RigidBody2D scaling is reset by physics engine](https://github.com/godotengine/godot/issues/89898) -- closed as expected behavior
- [Godot Issue #5734: RigidBody ignores scaling at runtime](https://github.com/godotengine/godot/issues/5734) -- confirmed design decision
- [Godot Issue #72674: RigidBody2D CCD Cast Shape is non-functional](https://github.com/godotengine/godot/issues/72674) -- use Cast Ray instead
- [Godot Issue #2092: Pile of RigidBody2Ds overlapping and shaking](https://github.com/godotengine/godot/issues/2092) -- long-standing
- [Godot Issue #80603: Small RigidBody instability and extreme jitter](https://github.com/godotengine/godot/issues/80603) -- closed, consolidated
- [Godot Rapier Physics Performance Benchmarks](https://godot.rapier.rs/docs/documentation/performance/) -- 1.7x faster than default
- [Godot Forum: RigidBody2D collision registering extra times](https://forum.godotengine.org/t/rigidbody2d-collision-problem/75989) -- timer debounce workaround
- [Godot Forum: Complex card effects architecture](https://forum.godotengine.org/t/add-complex-cards-effects-in-a-card-game/69245) -- callable + dictionary pattern
- [Drygast: Basic Suika Clone in Godot](https://drygast.net/blog/post/godot_ahballs) -- fruit sizing challenges documented
- [GameDeveloper: Slay the Spire data-driven balancing](https://www.gamedeveloper.com/design/how-i-slay-the-spire-i-s-devs-use-data-to-balance-their-roguelike-deck-builder) -- 2.5 years of balancing
- [Godot 4 2D Mobile Optimization Guide](https://www.normansoven.com/post/godot-4-2d-mobile-optimization) -- pooling, collision layers, sleep
- [Godot Docs: Troubleshooting Physics Issues](https://docs.godotengine.org/en/stable/tutorials/physics/troubleshooting_physics_issues.html)
- [KidsCanCode: RigidBody2D Drag and Drop](https://kidscancode.org/godot_recipes/4.x/physics/rigidbody_drag_drop/index.html) -- freeze mode for drag

---
*Pitfalls research for: Suika-style physics puzzle game with roguelike card modifiers*
*Researched: 2026-02-07*
