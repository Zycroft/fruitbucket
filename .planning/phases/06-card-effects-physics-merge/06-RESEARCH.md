# Phase 6: Card Effects -- Physics & Merge - Research

**Researched:** 2026-02-09
**Domain:** RigidBody2D physics modification (bounce, mass, impulse forces), merge rule extension, per-fruit visual effects (shaders, modulate), card effect runtime system (Godot 4.5 / GDScript / GL Compatibility)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Effect Visibility (General)
- Effects should feel **dramatic and fun** -- 50-100% property changes, fruits fly around more
- Whether effects apply retroactively depends on the card:
  - Bouncy Berry: retroactive (all tier 1-3 fruits in bucket get the bounce boost immediately)
  - Heavy Hitter: new drops only (charge-based, applies to next N drops)
  - Wild Fruit: retroactive (selects from fruits already in bucket)
  - Cherry Bomb: trigger-based (activates on cherry merge events)
- Duplicate cards stack linearly (two Bouncy Berrys = double the bounce boost)

#### Bouncy Berry
- Claude's discretion on visual treatment (glow on impact, persistent marker, etc.)
- Affects tier 1-3 fruits
- Retroactive -- existing fruits in bucket gain the bounce boost

#### Heavy Hitter Charges
- 3 charges per activation cycle
- Charge display: **both** card HUD slot (shows remaining count) AND drop preview (fruit looks different when heavy)
- After all 3 charges used: card **recharges after N merges** (not time-based, not one-shot)
- All 3 charges refill at once after the merge threshold
- Claude's discretion on which fruit tiers are affected (all drops vs large only)
- Claude's discretion on whether heavy fruits look different after landing
- Overflow risk from heavy pushes is **intentional** -- risk/reward tradeoff, part of the fun
- Claude's discretion on whether recharge pattern is reusable for future cards or Heavy Hitter-specific

#### Wild Fruit Behavior
- Wild fruits are selected **periodically** (every N merges), not on purchase or on drop
- Rainbow shimmer visual treatment -- cycling rainbow outline/shimmer so wild fruits are eye-catching
- When a wild fruit merges with an adjacent tier, result **always upgrades** to the higher tier's next tier (generous, rewarding)
- Claude's discretion on how many wild fruits can exist simultaneously

#### Cherry Bomb Force
- Triggers only on **cherry (tier 1) merges** -- two cherries merging = explosion
- Blast force is **big and chaotic** -- nearby fruits get launched, can scatter the pile
- Visual: **shockwave ring** expanding from the merge point, clearly showing blast radius
- Chain reactions from the blast are **intentional** -- strategic cherry placement can trigger merge chains
- Part of the card's value is the chain reaction potential

### Claude's Discretion

- Bouncy Berry visual treatment (glow on impact, persistent marker, etc.)
- Heavy Hitter: which fruit tiers affected (all drops vs large only)
- Heavy Hitter: whether heavy fruits look different after landing
- Heavy Hitter: whether recharge pattern is reusable for future cards or Heavy Hitter-specific
- Wild Fruit: how many wild fruits can exist simultaneously

### Deferred Ideas (OUT OF SCOPE)

None -- discussion stayed within phase scope

</user_constraints>

## Summary

Phase 6 implements four card effects that modify the physics and merge systems. This is the first phase where cards have actual gameplay effects (Phase 5 made them "inert" data-only). The core challenge is creating an effect system that bridges CardManager (autoload, data-only) with the runtime physics objects (Fruit RigidBody2D instances, MergeManager merge logic). Each effect touches different parts of the existing architecture:

**Bouncy Berry** modifies the PhysicsMaterial bounce property on tier 0-2 fruits. The current fruit.tscn shares a single `fruit_physics.tres` PhysicsMaterial (bounce=0.15, friction=0.6) across all fruits via ExtResource. To give individual fruits different bounce values, each affected fruit needs a unique PhysicsMaterial instance at runtime. The fruit.gd `initialize()` already creates per-instance CircleShape2D, so the pattern is established -- just extend it to PhysicsMaterial. Retroactive application means iterating `FruitContainer.get_children()` and modifying existing fruits.

**Heavy Hitter** modifies `RigidBody2D.mass` on freshly dropped fruits. The existing `fruit.gd` already sets `mass = data.mass_override` in `initialize()`. Heavy Hitter doubles this value for the next 3 drops, which means intercepting the drop pipeline in DropController or MergeManager.spawn_fruit(). The charge/recharge system needs state tracking -- a merge counter that refills charges after N merges.

**Wild Fruit** extends the merge rule system. Currently, `fruit.gd._on_body_entered()` only merges same-tier fruits (`body.fruit_data.tier != fruit_data.tier` -> return). Wild fruits need to also merge with adjacent tiers (tier +/- 1). This requires either modifying the merge check in fruit.gd or adding a pre-merge hook in MergeManager. The rainbow shimmer visual is best done with a CanvasItem shader on the fruit's Sprite2D, using the GL Compatibility renderer's shader support.

**Cherry Bomb** applies radial impulse to nearby fruits when cherries merge. It hooks into `EventBus.fruit_merged` (already emits old_tier, new_tier, position), checks if old_tier == 2 (cherry, tier index 2 in the code), then finds nearby fruits and calls `apply_central_impulse()` on each with a direction vector pointing away from the merge position. The shockwave ring visual is a simple expanding circle using a draw call or a scaled sprite with a tween.

**Primary recommendation:** Create a central CardEffectSystem component (scene-local Node, like MergeManager) that connects to EventBus signals and CardManager's active_cards array, applying effect logic at the correct hook points. Each card effect is a function or method within this system keyed by `card_id`. Do NOT use Resource subclasses for effects (the ARCHITECTURE.md suggested this but the actual codebase uses flat CardData Resources with `card_id` strings -- effects should be code, not Resources, since each effect has unique behavior).

## Standard Stack

### Core

| System | Version | Purpose | Why Standard |
|--------|---------|---------|--------------|
| RigidBody2D.physics_material_override | Godot 4.5 | Per-fruit bounce modification (Bouncy Berry) | Built-in property. Create unique PhysicsMaterial per fruit at runtime. |
| RigidBody2D.mass | Godot 4.5 | Per-fruit mass modification (Heavy Hitter) | Direct property. Already set in fruit.gd initialize(). |
| RigidBody2D.apply_central_impulse() | Godot 4.5 | Radial blast force (Cherry Bomb) | Built-in impulse method. Applies one-time force without rotation. |
| CanvasItem shader (GDShader) | Godot 4.5 | Rainbow shimmer outline (Wild Fruit) | GL Compatibility supports fragment shaders on Sprite2D. Community rainbow outline shader available. |
| FruitContainer.get_children() | Godot 4.5 | Iterate all fruits for retroactive effects, nearby detection | FruitContainer is a Node2D group; all fruits are direct children. |
| EventBus.fruit_merged signal | Godot 4.5 | Hook point for Cherry Bomb trigger and merge counting | Already exists and emits (old_tier, new_tier, position). |

### Supporting

| System | Version | Purpose | When to Use |
|--------|---------|---------|-------------|
| ShaderMaterial | Godot 4.5 | Attach rainbow shader to wild fruit Sprite2D | When marking a fruit as wild. Create unique ShaderMaterial per wild fruit. |
| Tween | Godot 4.5 | Shockwave ring expansion, bounce glow flash | One-shot visual effects tied to game events. |
| CPUParticles2D | Godot 4.5 | Enhanced merge particles for Cherry Bomb explosion | Already used by MergeFeedback. Extend for explosion burst. |
| CardSlotDisplay | Godot 4.5 | Show charge count on Heavy Hitter HUD slot | Extend existing card_slot_display.gd with optional status text. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-fruit PhysicsMaterial for bounce | Modify shared PhysicsMaterial | Shared material affects ALL fruits, not just tier 0-2. Per-fruit is correct. |
| CanvasItem shader for rainbow | Modulate color cycling in _process | Modulate changes the entire sprite tint uniformly. A shader can do an outline-only effect, which is much more visually distinctive. |
| CardEffectSystem as scene-local Node | CardEffect Resource subclasses with virtual methods | The codebase already uses flat CardData Resources with card_id strings. Adding a parallel Resource hierarchy for effects is unnecessary complexity. A single effect system script with match/if on card_id is simpler and more debuggable for 4 effects. |
| Direct FruitContainer child iteration for blast radius | Temporary Area2D with get_overlapping_bodies() | Area2D requires waiting one physics frame for overlap detection. Direct distance check on FruitContainer children is immediate and simpler. |

## Architecture Patterns

### Recommended Project Structure

```
scripts/
  components/
    card_effect_system.gd    # NEW: Central effect processor, connects EventBus + CardManager
scenes/
  effects/
    shockwave.tscn           # NEW: Expanding ring visual for Cherry Bomb (or draw in code)
  fruit/
    fruit.gd                 # MODIFIED: Add is_wild flag, is_heavy flag, unique PhysicsMaterial
    fruit.tscn               # UNCHANGED (shader attached at runtime)
  ui/
    card_slot_display.gd     # MODIFIED: Add status text display (charge count)
    hud.gd                   # MODIFIED: Update card slots with effect state info
  game/
    game.tscn                # MODIFIED: Add CardEffectSystem node
resources/
  shaders/
    rainbow_outline.gdshader # NEW: Rainbow cycling outline shader for wild fruits
scripts/
  autoloads/
    event_bus.gd             # MODIFIED: Add new signals for effect system
```

### Pattern 1: CardEffectSystem Component (Central Effect Processor)

**What:** A single Node script added to the game scene tree that owns all card effect logic. It reads `CardManager.active_cards` to determine which effects are active, connects to EventBus signals for triggers (fruit_merged, fruit_dropped), and applies modifications to fruits and the merge system.

**When to use:** For all card effect processing. No other system should contain card effect logic.

**Why not Resource subclasses:** The original ARCHITECTURE.md suggested CardEffect Resources with virtual hook methods. However, the actual Phase 5 implementation uses flat CardData Resources with `card_id` strings and no effect logic. Creating a parallel Resource hierarchy now would mean either: (a) replacing CardData with a new class (breaking Phase 5), or (b) maintaining two Resource hierarchies per card. Neither is justified for 4 effects. A single script with card_id-based dispatch is cleaner.

**Example:**
```gdscript
# scripts/components/card_effect_system.gd
class_name CardEffectSystem
extends Node

func _ready() -> void:
    add_to_group("card_effect_system")
    EventBus.fruit_merged.connect(_on_fruit_merged)
    EventBus.fruit_dropped.connect(_on_fruit_dropped)
    EventBus.card_purchased.connect(_on_card_purchased)
    EventBus.card_sold.connect(_on_card_sold)

func _count_active(card_id: String) -> int:
    ## Count how many copies of a card are active (for linear stacking).
    var count: int = 0
    for entry in CardManager.active_cards:
        if entry != null and entry["card"].card_id == card_id:
            count += 1
    return count

func _on_fruit_merged(old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
    # Cherry Bomb check
    if _count_active("cherry_bomb") > 0 and old_tier == 2:
        _apply_cherry_bomb(merge_pos, _count_active("cherry_bomb"))
    # Heavy Hitter merge counter for recharge
    # Wild Fruit periodic selection counter
    # etc.
```

### Pattern 2: Per-Fruit PhysicsMaterial (Bouncy Berry)

**What:** When Bouncy Berry is active, create a unique PhysicsMaterial for each tier 0-2 fruit with increased bounce. The fruit.tscn currently assigns a shared `fruit_physics.tres` (bounce=0.15). To modify bounce per-fruit, duplicate the PhysicsMaterial in code.

**When to use:** On fruit spawn (for new fruits) and retroactively (for existing fruits when card is purchased).

**Critical detail:** The shared PhysicsMaterial from `fruit_physics.tres` MUST NOT be modified directly -- that would change bounce for ALL fruits. Always create a new PhysicsMaterial instance.

**Example:**
```gdscript
func _apply_bouncy_berry_to_fruit(fruit: Fruit, stack_count: int) -> void:
    if fruit.fruit_data.tier > 2:  # Only tier 0-2 (Blueberry, Grape, Cherry)
        return
    var mat: PhysicsMaterial = PhysicsMaterial.new()
    mat.friction = 0.6  # Keep original friction
    mat.bounce = 0.15 + (0.5 * stack_count)  # Base 0.15 + 0.5 per stack (dramatic!)
    fruit.physics_material_override = mat
```

### Pattern 3: Charge/Recharge State Machine (Heavy Hitter)

**What:** Heavy Hitter has a charge system: 3 charges that apply to the next 3 dropped fruits, then recharge after N merges. This requires persistent state tracked in CardEffectSystem.

**When to use:** Any card that has a limited number of uses with a refresh mechanic.

**Key state:**
- `_heavy_charges: int = 3` -- remaining charges
- `_heavy_merge_counter: int = 0` -- merges since last charge depletion
- `HEAVY_RECHARGE_MERGES: int = 5` -- merges required to refill (tunable)

**Example:**
```gdscript
const HEAVY_CHARGES_MAX: int = 3
const HEAVY_RECHARGE_MERGES: int = 5

var _heavy_charges: int = 0
var _heavy_merge_counter: int = 0

func _on_fruit_dropped(tier: int, pos: Vector2) -> void:
    if _count_active("heavy_hitter") > 0 and _heavy_charges > 0:
        _heavy_charges -= 1
        # Apply 2x mass to the just-dropped fruit
        # (find it by position or track reference from DropController)

func _on_merge_for_recharge(old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
    if _count_active("heavy_hitter") > 0 and _heavy_charges <= 0:
        _heavy_merge_counter += 1
        if _heavy_merge_counter >= HEAVY_RECHARGE_MERGES:
            _heavy_charges = HEAVY_CHARGES_MAX
            _heavy_merge_counter = 0
```

### Pattern 4: Merge Rule Extension (Wild Fruit)

**What:** Wild fruits can merge with adjacent tiers (tier +/- 1), not just same tier. This requires modifying the merge check in `fruit.gd._on_body_entered()`. The merge result always upgrades to the higher tier's next tier.

**When to use:** When a fruit has the `is_wild` flag set.

**Critical integration point:** The merge check in `fruit.gd` (line 54) currently does `if body.fruit_data.tier != fruit_data.tier: return`. This needs to become a function call that also checks for wild fruit adjacency.

**Example:**
```gdscript
# In fruit.gd -- modified merge check
func _can_merge_with(other: Fruit) -> bool:
    ## Check if this fruit can merge with another.
    ## Standard: same tier. Wild: same OR adjacent tier.
    if fruit_data.tier == other.fruit_data.tier:
        return true
    if is_wild or other.is_wild:
        return abs(fruit_data.tier - other.fruit_data.tier) <= 1
    return false
```

**Merge result for wild + adjacent:**
```gdscript
# In MergeManager -- modified new_tier calculation
var higher_tier: int = maxi(fruit_a.fruit_data.tier, fruit_b.fruit_data.tier)
var new_tier: int = higher_tier + 1  # Always upgrade from the higher tier
```

### Pattern 5: Radial Impulse (Cherry Bomb)

**What:** When cherries merge (old_tier == 2, since cherry is tier index 2), apply outward impulse to all fruits within a radius. Uses `apply_central_impulse()` with direction vector pointing away from the merge point.

**When to use:** On the `fruit_merged` signal when the Cherry Bomb card is active and old_tier matches cherry.

**Critical detail:** Cherry is tier INDEX 2 in the codebase (tier_3_cherry.tres has `tier = 2`). The tier naming in the requirements says "tier 1" but the code is 0-indexed. The .tres file is named "tier_3_cherry" but `tier = 2`. This is because the CONTEXT says "cherry (tier 1) merges" using the card description's 1-indexed language, but in code cherries are `fruit_data.tier == 2`. **Verify by checking tier_3_cherry.tres: tier = 2.**

**Wait -- re-reading the context:** "Triggers only on cherry (tier 1) merges" -- but looking at the .tres files: tier_1_blueberry (tier=0), tier_2_grape (tier=1), tier_3_cherry (tier=2). The card description says "when cherries merge" and the CONTEXT says "cherry (tier 1)". The 0-indexed tier for cherry in code is `2`. But the CONTEXT might mean "the fruit labeled tier 1 in the game" vs. code's 0-index.

Actually, looking more carefully at the card description: "When cherries merge, push nearby fruits outward." The requirement EFCT-09 says "Cherry Bomb (Common) -- when cherries merge, push all fruits in a small radius outward." The CONTEXT says "Triggers only on cherry (tier 1) merges." Given the filename `tier_3_cherry.tres` with `tier = 2`, and that "tier 1" in the CONTEXT likely refers to the first droppable-only tier or a display convention, **the implementation should trigger on cherry merges, which is `old_tier == 2` in code.** The name is unambiguous.

**Example:**
```gdscript
func _apply_cherry_bomb(merge_pos: Vector2, stack_count: int) -> void:
    var blast_radius: float = 200.0  # Pixels
    var blast_force: float = 800.0 * stack_count  # Big and chaotic, scales with stacks

    var container: Node = get_tree().get_first_node_in_group("fruit_container")
    if not container:
        return

    for child in container.get_children():
        if not (child is Fruit) or not is_instance_valid(child):
            continue
        if child.merging or child.is_dropping:
            continue
        var direction: Vector2 = (child.global_position - merge_pos)
        var distance: float = direction.length()
        if distance > blast_radius or distance < 1.0:
            continue
        # Linear falloff: full force at center, zero at radius edge
        var strength: float = blast_force * (1.0 - distance / blast_radius)
        child.apply_central_impulse(direction.normalized() * strength)
```

### Pattern 6: Shader-Based Visual Marking (Wild Fruit Rainbow)

**What:** Wild fruits get a rainbow cycling outline shader on their Sprite2D. Created as a .gdshader file, applied via ShaderMaterial at runtime when a fruit becomes wild, removed when it merges or loses wild status.

**When to use:** When CardEffectSystem designates a fruit as wild.

**GL Compatibility note:** The GL Compatibility renderer supports CanvasItem fragment shaders. The rainbow outline shader uses only `texture()`, `TEXTURE_PIXEL_SIZE`, `UV`, `TIME`, and basic math -- all supported.

**Example shader (from godotshaders.com, adapted):**
```glsl
shader_type canvas_item;

uniform float line_scale : hint_range(0, 20) = 2.0;
uniform float frequency : hint_range(0.0, 2.0) = 0.8;
uniform float light_offset : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_scale;

    float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
    outline = min(outline, 1.0);

    vec4 rainbow = vec4(
        light_offset + sin(2.0 * 3.14159 * frequency * TIME),
        light_offset + sin(2.0 * 3.14159 * frequency * TIME + radians(120.0)),
        light_offset + sin(2.0 * 3.14159 * frequency * TIME + radians(240.0)),
        1.0
    );

    vec4 color = texture(TEXTURE, UV);
    COLOR = mix(color, rainbow, outline - color.a);
}
```

### Anti-Patterns to Avoid

- **Modifying the shared fruit_physics.tres at runtime:** This would change bounce for ALL fruits, not just Bouncy Berry targets. Always create a NEW PhysicsMaterial instance per affected fruit.

- **Using _physics_process on every fruit for effect checks:** This creates O(fruits * effects) per-frame cost. Instead, apply effects at discrete events (on spawn, on merge, on card purchase) and let Godot's physics engine handle the ongoing simulation with the modified properties.

- **Putting effect logic inside CardData Resource:** CardData is a data class (name, description, rarity, price). Effect logic belongs in CardEffectSystem. Mixing data and behavior in Resources makes them harder to serialize and test.

- **Using an Area2D for Cherry Bomb blast detection:** Would require adding a transient Area2D, waiting a physics frame for overlap detection, then applying impulses. Direct distance calculation on FruitContainer children is immediate and avoids the one-frame delay.

- **Modifying MergeManager.request_merge() directly for Wild Fruit:** The merge rule change belongs in `fruit.gd._on_body_entered()` where the tier check happens. MergeManager should remain a gatekeeper for double-merge prevention, not a rule engine. However, MergeManager DOES need modification for the merge result calculation (higher tier + 1 for wild merges).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rainbow outline visual | Manual _draw() circle outline with color cycling | CanvasItem shader on Sprite2D | Shaders run on GPU, animate smoothly with TIME uniform, work with any texture size. Manual drawing would need per-frame _draw() calls and queue_redraw(). |
| Radial impulse falloff | Custom physics force simulation | `RigidBody2D.apply_central_impulse()` with distance-based strength | apply_central_impulse is a one-shot call. Godot's physics engine handles the resulting motion, collisions, and settling. |
| Charge tracking UI | Custom charge bar widget | Text overlay on existing CardSlotDisplay | We only need to show "3/3" or "0/3" as text. A custom widget is overkill for a number display. |
| Fruit iteration for blast radius | Physics query / Area2D overlap | `FruitContainer.get_children()` + distance check | All fruits are children of FruitContainer. Direct iteration is O(n) and immediate. No physics frame delay. |
| Per-fruit material modification | Custom physics callback override | `PhysicsMaterial.new()` assigned to `physics_material_override` | Built-in Godot property. Setting it takes effect immediately for all future collisions. |

**Key insight:** All four effects are "set-and-forget" property modifications or "one-shot event" responses. None require per-frame processing. Bouncy Berry changes a physics material property. Heavy Hitter changes mass at spawn time. Wild Fruit changes a merge rule check and adds a shader. Cherry Bomb fires a single impulse on a merge event. The physics engine does the ongoing work.

## Common Pitfalls

### Pitfall 1: Shared PhysicsMaterial Mutation

**What goes wrong:** Modifying `fruit_physics.tres` bounce at runtime changes bounce for ALL fruits, not just the targeted tier 0-2 fruits. Every fruit shares the same PhysicsMaterial resource reference.

**Why it happens:** In Godot, Resources loaded from .tres files are shared by default. All fruits that `preload("res://resources/fruit_physics.tres")` get the SAME object in memory. Changing `.bounce` on one fruit's reference changes it for all.

**How to avoid:** Always create a NEW `PhysicsMaterial.new()` and assign it to `fruit.physics_material_override`. Never modify the shared resource. This mirrors how `fruit.gd` already creates a new `CircleShape2D.new()` per fruit (line 29).

**Warning signs:** All fruits start bouncing more, not just small ones. Bounce persists after selling the Bouncy Berry card.

### Pitfall 2: Cherry Bomb Triggering on Wrong Tier

**What goes wrong:** Cherry Bomb triggers on blueberry merges or grape merges instead of cherry merges, or doesn't trigger at all.

**Why it happens:** The naming is confusing. The .tres file is `tier_3_cherry.tres` but `tier = 2` (0-indexed). The context says "cherry (tier 1)" using a different indexing convention. The fruit_merged signal emits `old_tier` which is the 0-indexed tier of the consumed pair.

**How to avoid:** Use the fruit_name for documentation but ALWAYS check `old_tier == 2` in code (matching tier_3_cherry.tres's `tier = 2`). Add a named constant: `const CHERRY_TIER: int = 2`.

**Warning signs:** Explosions happen on blueberry merges (tier 0) instead of cherry merges (tier 2).

### Pitfall 3: Wild Fruit Merge Result Miscalculation

**What goes wrong:** When a wild tier-3 fruit merges with a normal tier-4 fruit, the result is tier-4 (same as normal merge) instead of tier-5 (the intended "always upgrade" behavior).

**Why it happens:** The standard merge logic does `new_tier = old_tier + 1`, where `old_tier` is the tier of both fruits (which are assumed to be the same). For wild merges with adjacent tiers, using the lower tier as old_tier produces the wrong result.

**How to avoid:** For wild merges, the result tier should be `max(fruit_a.tier, fruit_b.tier) + 1`. This ensures the merge always upgrades from the higher of the two tiers. Document this clearly in the merge path.

**Warning signs:** Wild merges feel unrewarding -- the result is the same as a normal merge of the higher-tier pair.

### Pitfall 4: Heavy Hitter Charges Not Resetting Between Runs

**What goes wrong:** Heavy Hitter charge state persists from a previous run. Player starts a new run with 0 charges or a partial merge counter.

**Why it happens:** CardEffectSystem state (charge counts, merge counters, wild fruit references) lives in a scene-local node. If the node is not reset properly when `GameManager.reset_game()` is called, state leaks.

**How to avoid:** CardEffectSystem must connect to game reset and clear all effect state. Since it is scene-local (not an autoload), `reload_current_scene()` destroys and recreates it, which handles reset naturally. BUT: verify that CardManager.reset() (called in reset_game()) happens BEFORE the scene reload, and CardEffectSystem._ready() initializes from the clean CardManager state.

**Warning signs:** Charges show incorrect count at run start. Merge counter is non-zero at run start.

### Pitfall 5: apply_central_impulse Has No Effect on Frozen/Sleeping Bodies

**What goes wrong:** Cherry Bomb explosion does nothing to some fruits. They sit still while others fly.

**Why it happens:** RigidBody2D has `can_sleep = true` in fruit.tscn. Sleeping bodies may not respond to impulses. Also, fruits with `freeze = true` (like the preview fruit being positioned) or `merging = true` (mid-merge) should be skipped.

**How to avoid:** Before applying impulse, check: `not child.freeze and not child.merging and not child.is_dropping`. For sleeping bodies, calling `apply_central_impulse()` should wake them (Godot wakes rigid bodies on force/impulse application), but verify this in testing.

**Warning signs:** Some fruits in the pile don't react to the explosion. The preview fruit gets blasted.

### Pitfall 6: Wild Fruit Shader Not Visible Due to Sprite Scale

**What goes wrong:** The rainbow outline shader is applied but invisible or barely visible on small fruits (tier 0-2).

**Why it happens:** The outline shader samples neighboring texels using `TEXTURE_PIXEL_SIZE * line_scale`. The placeholder_fruit.png is 64x64, but Sprite2D.scale is set to match the fruit radius (e.g., scale 0.47 for blueberry radius 15). The outline may be too thin to see at small scales.

**How to avoid:** Set `line_scale` high enough (3.0-5.0) to be visible on small fruits. Test on all 8 tiers. The shader width is in texel space, so it scales with the sprite. Alternatively, use a separate outline node that doesn't scale down.

**Warning signs:** Wild marker invisible on blueberries. Outline appears only on large fruits.

### Pitfall 7: Stacking Effects Applied Multiple Times

**What goes wrong:** Buying a second Bouncy Berry doubles the bounce again on top of already-modified fruits, resulting in exponential stacking instead of linear.

**Why it happens:** Retroactive application recalculates bounce for existing fruits. If the code adds the bonus without resetting to baseline first, each application compounds.

**How to avoid:** When applying bouncy berry retroactively, always calculate from the BASE bounce value (0.15), not from the fruit's current bounce. Formula: `base_bounce + (bonus_per_stack * stack_count)`. Never read the current bounce value as input to the calculation.

**Warning signs:** Two Bouncy Berrys produce 4x bounce instead of 2x. Fruits bounce to the moon.

## Code Examples

### Counting Active Cards by ID (Linear Stacking)

```gdscript
# Utility used throughout CardEffectSystem
func _count_active(card_id: String) -> int:
    var count: int = 0
    for entry in CardManager.active_cards:
        if entry != null and (entry["card"] as CardData).card_id == card_id:
            count += 1
    return count
```

### Bouncy Berry: Retroactive Application on Purchase

```gdscript
func _apply_bouncy_berry_all() -> void:
    ## Apply Bouncy Berry to all existing tier 0-2 fruits in the bucket.
    var stack_count: int = _count_active("bouncy_berry")
    if stack_count <= 0:
        return
    var container: Node = get_tree().get_first_node_in_group("fruit_container")
    if not container:
        return
    for child in container.get_children():
        if child is Fruit and is_instance_valid(child) and not child.merging:
            _apply_bouncy_to_fruit(child, stack_count)

func _apply_bouncy_to_fruit(fruit: Fruit, stack_count: int) -> void:
    if fruit.fruit_data.tier > 2:  # Only tiers 0, 1, 2
        return
    var mat: PhysicsMaterial = PhysicsMaterial.new()
    mat.friction = 0.6
    mat.bounce = 0.15 + (0.5 * stack_count)  # 50% increase per stack
    fruit.physics_material_override = mat
```

### Heavy Hitter: Mass Modification at Drop Time

```gdscript
func _apply_heavy_hitter_to_fruit(fruit: Fruit, stack_count: int) -> void:
    ## Double the mass (per stack) for the dropped fruit.
    fruit.mass = fruit.fruit_data.mass_override * (1.0 + 1.0 * stack_count)
    # Visual feedback: slightly darker tint
    fruit.get_node("Sprite2D").modulate = fruit.fruit_data.color.darkened(0.3)
```

### Wild Fruit: Modified Merge Check in fruit.gd

```gdscript
# In fruit.gd -- replace the tier check in _on_body_entered
var is_wild: bool = false

func _on_body_entered(body: Node) -> void:
    if not (body is Fruit):
        return
    if merging or body.merging:
        return
    if is_dropping or body.is_dropping:
        return
    if merge_grace or body.merge_grace:
        return

    # Modified merge check: same tier always, adjacent if wild
    if not _can_merge_with(body):
        return

    if get_instance_id() < body.get_instance_id():
        var mm = get_tree().get_first_node_in_group("merge_manager")
        if mm:
            mm.request_merge(self, body)

func _can_merge_with(other: Fruit) -> bool:
    if fruit_data.tier == other.fruit_data.tier:
        return true
    if is_wild or other.is_wild:
        return abs(fruit_data.tier - other.fruit_data.tier) <= 1
    return false
```

### Cherry Bomb: Radial Impulse + Shockwave Visual

```gdscript
func _apply_cherry_bomb(merge_pos: Vector2, stack_count: int) -> void:
    var blast_radius: float = 200.0
    var blast_force: float = 800.0 * stack_count

    var container: Node = get_tree().get_first_node_in_group("fruit_container")
    if not container:
        return

    for child in container.get_children():
        if not (child is Fruit) or not is_instance_valid(child):
            continue
        if child.merging or child.is_dropping or child.freeze:
            continue
        var offset: Vector2 = child.global_position - merge_pos
        var distance: float = offset.length()
        if distance > blast_radius or distance < 1.0:
            continue
        var strength: float = blast_force * (1.0 - distance / blast_radius)
        child.apply_central_impulse(offset.normalized() * strength)

    _spawn_shockwave(merge_pos, blast_radius)

func _spawn_shockwave(pos: Vector2, radius: float) -> void:
    ## Expanding ring visual at the blast center.
    # Implementation: either a Line2D circle that tweens scale,
    # or a simple sprite with a ring texture that scales up and fades out.
    pass  # Detailed in plan task
```

### Applying Rainbow Shader to Wild Fruit

```gdscript
var _rainbow_shader: Shader = preload("res://resources/shaders/rainbow_outline.gdshader")

func _mark_fruit_as_wild(fruit: Fruit) -> void:
    fruit.is_wild = true
    var mat: ShaderMaterial = ShaderMaterial.new()
    mat.shader = _rainbow_shader
    mat.set_shader_parameter("line_scale", 3.0)
    mat.set_shader_parameter("frequency", 0.8)
    mat.set_shader_parameter("light_offset", 0.5)
    fruit.get_node("Sprite2D").material = mat

func _unmark_fruit_as_wild(fruit: Fruit) -> void:
    fruit.is_wild = false
    fruit.get_node("Sprite2D").material = null
```

## Discretion Recommendations

### Bouncy Berry Visual Treatment
**Recommendation:** Persistent subtle glow. When Bouncy Berry is active, affected fruits (tier 0-2) get a slight upward modulate brightness (`color.lightened(0.15)`). This is cheap, visible, and does not require a shader. On impact (body_entered with non-fruit), briefly flash white via tween. The persistent glow tells the player which fruits are bouncy; the impact flash provides satisfying feedback.

### Heavy Hitter Tier Scope
**Recommendation:** All drops. Heavy Hitter should affect every fruit the player drops during the 3 charges, regardless of tier. Limiting to "large only" makes no sense for drops (tiers 0-4 are droppable, and only 0-4 are "small-to-medium"). The fun of Heavy Hitter is seeing any fruit slam into the pile with extra mass. All-tier keeps it simple and impactful.

### Heavy Hitter Post-Landing Visual
**Recommendation:** No visual change after landing. The visual cue matters at drop time (preview shows heavy fruit via darker tint). Once the fruit lands and joins the pile, removing the visual avoids clutter. The mass remains doubled, but the player does not need a persistent indicator -- the heavy impact on landing is the memorable moment.

### Heavy Hitter Recharge Pattern
**Recommendation:** Make the recharge system reusable (a simple charge/recharge state machine in CardEffectSystem). Define it with constants per card: `CHARGES_MAX`, `RECHARGE_TRIGGER_COUNT`, `RECHARGE_TRIGGER_EVENT`. Heavy Hitter uses `{charges: 3, recharge_after: 5, trigger: "merge"}`. Future cards could use the same pattern with different parameters (e.g., "recharge after 3 drops" or "recharge after 1 chain of 3+"). The code cost of making it generic is near-zero (extract constants), and it avoids reimplementing charge logic for future cards.

### Wild Fruit Simultaneous Limit
**Recommendation:** 1 wild fruit per Wild Fruit card owned. With 1 card, 1 wild fruit at a time. With 2 cards, 2 wild fruits. This keeps the effect powerful but bounded. When a wild fruit merges or is destroyed, the next periodic trigger designates a new one. The periodic trigger rate (every N merges) should be ~5 merges, making wild fruit a consistent presence without overwhelming the screen.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CardEffect Resource subclass hierarchy | Flat CardData + procedural effect system | Phase 5 implementation decision | No effect Resources exist in codebase. Effects are code-driven keyed by card_id string. |
| Per-frame physics polling for effects | Event-driven effect application | Godot 4.0+ signal improvements | Connect to EventBus signals for triggers. No _physics_process needed for these 4 effects. |
| Direct queue_free in physics callbacks | Deferred cleanup pattern | Phase 1 lesson (flushing queries crash) | Cherry Bomb blast iteration must skip fruits mid-deactivation. Check is_instance_valid(). |

**Deprecated/outdated:**
- `bounce` property directly on RigidBody2D: Use `PhysicsMaterial.bounce` via `physics_material_override` instead
- `hint_color` in shader uniforms: Godot 4 uses `source_color` hint instead. The community shader example uses `hint_color` (Godot 3 syntax). Update to `source_color` for Godot 4.5.

## Open Questions

1. **What is the exact merge count for Heavy Hitter recharge?**
   - What we know: CONTEXT says "recharges after N merges" but does not specify N.
   - Recommendation: Start at 5 merges. This means roughly every ~10 seconds of active play. At 3 charges per cycle, that is 3 heavy drops per ~15 seconds of play. Tunable via constant. Make it a named constant `HEAVY_RECHARGE_MERGES = 5`.

2. **What is the exact merge count for Wild Fruit periodic selection?**
   - What we know: CONTEXT says "every N merges" but does not specify N.
   - Recommendation: Start at 5 merges. A wild fruit appears roughly every 5 merges, keeping the effect present but not constant. If the wild fruit is consumed by a merge, the counter resets and a new one is designated after the next 5 merges. Tunable via constant `WILD_SELECT_INTERVAL = 5`.

3. **Does Cherry Bomb's "cherry" refer to tier index 2 specifically?**
   - What we know: tier_3_cherry.tres has tier = 2. The card says "when cherries merge." The CONTEXT says "cherry (tier 1)."
   - Recommendation: Trigger on `old_tier == 2` (the cherry fruit). The CONTEXT's "tier 1" likely uses 1-indexed display notation. The code is unambiguous: cherries are tier index 2.

4. **Should the CardEffectSystem be added to game.tscn or be an autoload?**
   - What we know: It needs access to the scene tree (FruitContainer children, fruit references). Autoloads run before scenes load.
   - Recommendation: Scene-local Node in game.tscn, same as MergeManager, ScoreManager, MergeFeedback. This gives direct scene tree access and automatic cleanup on scene reload (reset). It reads CardManager (autoload) for active cards but lives in the scene.

## Sources

### Primary (HIGH confidence)
- Existing codebase analysis: fruit.gd (merge logic, physics initialization), merge_manager.gd (merge pipeline, spawn_fruit), fruit.tscn (shared PhysicsMaterial via ExtResource), FruitData resources (tier indices, mass values), card_manager.gd (active_cards array structure), event_bus.gd (fruit_merged signal signature), drop_controller.gd (drop pipeline)
- [Godot RigidBody2D docs](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html) -- apply_central_impulse, mass, physics_material_override
- [Godot PhysicsMaterial docs](https://docs.godotengine.org/en/stable/classes/class_physicsmaterial.html) -- bounce, friction, absorbent properties
- [Godot CanvasItem shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html) -- fragment shader, TEXTURE_PIXEL_SIZE, TIME, UV
- [Godot shading language](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html) -- GDShader syntax for GL Compatibility

### Secondary (MEDIUM confidence)
- [2D Outline and Rainbow Outline shader](https://godotshaders.com/shader/2d-outline-and-rainbow-outline-2-in-1/) -- Community shader with rainbow cycling outline. CC0 licensed. Tested on Sprite2D.
- [Godot Forum: How does apply_impulse() work on RigidBody2D](https://forum.godotengine.org/t/how-does-apply-impulse-work-on-rigidbody2d/70364) -- Impulse is time-independent, applied instantaneously
- [Godot Forum: PhysicsMaterial shared resource](https://forum.godotengine.org/t/bounce-in-physics-material-override-cannot-be-edited-in-the-demo-for-creating-an-instance/42150) -- PhysicsMaterial must be made unique per instance for per-object modification
- [Godot Forum: Area2D get_overlapping_bodies](https://forum.godotengine.org/t/area2d-get-overlapping-bodies-not-detecting/74632) -- Alternative blast detection approach (decided against; direct iteration is simpler)
- Prior project research: [ARCHITECTURE.md](../../research/ARCHITECTURE.md) -- CardEffect hook system concept, radial impulse pattern

### Tertiary (LOW confidence)
- [RadialImpulse Godot addon](http://kehomsforge.com/tutorials/multi/godot-addon-pack/part10/) -- Reviewed for API design, not adopted. Our implementation is simpler (direct iteration + apply_central_impulse).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All systems use built-in Godot 4.5 physics APIs (RigidBody2D, PhysicsMaterial, apply_central_impulse). Verified through existing codebase patterns.
- Architecture: HIGH -- CardEffectSystem follows established component patterns (MergeManager, ScoreManager, MergeFeedback). Event-driven hooks via existing EventBus signals. No novel patterns.
- Effect implementation: HIGH -- Each effect maps to a well-understood Godot API: bounce property, mass property, impulse method, shader material. All four are "set property" or "call method once" patterns, not complex ongoing simulations.
- Visual effects: MEDIUM -- Rainbow shader is from a community source (godotshaders.com). Needs testing on GL Compatibility renderer. `hint_color` syntax may need updating to `source_color` for Godot 4.5.
- Tuning values: LOW -- Blast radius (200px), blast force (800), recharge merges (5), wild select interval (5) are starting estimates. Will need playtesting.

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (stable Godot features and established project patterns)
