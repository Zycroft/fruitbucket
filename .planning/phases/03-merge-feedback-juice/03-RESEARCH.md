# Phase 3: Merge Feedback & Juice - Research

**Researched:** 2026-02-08
**Domain:** Godot 4.5 game juice -- CPUParticles2D burst effects, Camera2D screen shake, AudioStreamPlayer SFX, tween-based visual feedback for GL Compatibility web export
**Confidence:** HIGH

## Summary

Phase 3 transforms the existing merge mechanic from a silent, invisible operation into a multi-sensory spectacle. Every merge must produce three simultaneous feedback channels: a particle burst (colored by fruit tier), screen shake (intensity scaled by tier and chain position), and a sound effect (pitch/volume scaled). Chain reactions must escalate all three channels so a player can feel the difference between a single merge and a 5-chain cascade without looking at the score.

The project currently has NO Camera2D, NO audio infrastructure, and NO particle effects. All three systems must be created from scratch. The existing EventBus signals (`fruit_merged` and `score_awarded`) already carry the data needed to drive feedback: `old_tier`, `new_tier`, `merge_pos`, `chain_count`, and `multiplier`. The architecture is clean: a new "MergeFeedback" component listens to EventBus signals and orchestrates particles, shake, and sound. The particles use CPUParticles2D (not GPUParticles2D) because GPUParticles2D had web export rendering issues in Godot 4.3 that were fixed in 4.4, but CPUParticles2D is the safer, more predictable choice for the GL Compatibility renderer and avoids any lingering edge cases. The screen shake uses a Camera2D with trauma-based noise offset. Sound effects use a small pool of AudioStreamPlayer nodes with pitch/volume variation per tier.

The FruitData resource already has a `color` property on every tier, designed explicitly for "particles and effects (used in future phases)." This is that future phase. Each tier's color drives the particle burst color, creating visually distinct feedback that communicates which tier was created.

**Primary recommendation:** Create a Camera2D with trauma-based shake, a MergeFeedback component that spawns one-shot CPUParticles2D bursts at merge positions, and an SFX pool autoload with pitch scaling by tier -- all driven by existing EventBus signals.

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| CPUParticles2D | Godot 4.5 built-in | One-shot particle bursts at merge positions | CPU-side processing works reliably on GL Compatibility + web export. GPUParticles2D had rendering bugs in web (fixed in 4.4 via PR #96413), but CPUParticles2D is simpler, more predictable, and sufficient for burst effects at merge frequency. |
| Camera2D | Godot 4.5 built-in | Screen shake via offset/rotation | Built-in `offset` property is the standard approach for screen shake. No plugins needed. |
| FastNoiseLite | Godot 4.5 built-in | Smooth noise for camera shake | Replaced OpenSimplexNoise in Godot 4. Produces smooth, natural-looking shake instead of per-frame random jitter. |
| AudioStreamPlayer | Godot 4.5 built-in | Non-positional SFX playback | Merge SFX do not need positional audio (the game is a single-screen view). A pool of AudioStreamPlayer nodes prevents audio cutoff. |
| Tween | Godot 4.5 built-in | Scale punch on merge, flash effects | Already used extensively in HUD (score_awarded, chain label). Same pattern extends to merge flash effects. |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| AudioStreamRandomizer | Godot 4.5 built-in | Pitch/volume variation on SFX | Wrap merge SFX streams to add automatic random_pitch variation (e.g., 0.9-1.1) for organic feel without manual randomization code. |
| Gradient | Godot 4.5 built-in | CPUParticles2D color_ramp for lifetime fade | Particle color transitions from tier color to transparent over lifetime. |
| AudioBus | Godot 4.5 built-in | Separate SFX volume control | Route merge SFX to a dedicated "SFX" bus for independent volume control. Prepares for Phase 4 pause menu volume sliders. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CPUParticles2D | GPUParticles2D | GPU particles are faster for large counts, support ParticleProcessMaterial for complex behaviors. But: web export rendering issues in 4.3 (fixed in 4.4), requires shader compilation on first use, and merge bursts are low particle count (~20-40) where CPU overhead is negligible. |
| AudioStreamPlayer pool | AudioStreamPolyphonic | Polyphonic player handles multiple simultaneous sounds in a single node. Simpler for overlapping SFX. However, had a known issue with pitch_scale (#89210). Pool approach is more proven and gives per-sound control. |
| FastNoiseLite shake | randf_range shake | Random per-frame offset is simpler to implement but produces erratic, unpleasant jitter. Noise-based shake is smooth and professional. The extra 5 lines of code are worth it. |
| Programmatic SFX generation | Pre-recorded audio files | AudioStreamGenerator can synthesize sounds but is CPU-intensive in GDScript (official docs recommend C# or GDExtension). Pre-recorded .wav files are standard for SFX, zero CPU cost, and easy to tune. |

## Architecture Patterns

### Recommended Project Structure (Phase 3 additions)
```
res://
+-- scenes/
|   +-- game/
|   |   +-- game.tscn              # ADD: Camera2D child node
|   +-- effects/                    # NEW: effects scene directory
|       +-- merge_particles.tscn   # CPUParticles2D one-shot burst (preconfigured)
+-- scripts/
|   +-- autoloads/
|   |   +-- sfx_manager.gd         # NEW: SFX pool autoload
|   +-- components/
|       +-- merge_feedback.gd      # NEW: orchestrates particles + shake + sound
|       +-- screen_shake.gd        # NEW: Camera2D shake script
+-- assets/
|   +-- audio/
|       +-- sfx/
|           +-- merge_pop.wav      # Base merge sound effect
|           +-- chain_ding.wav     # Chain escalation accent sound
```

### Pattern 1: MergeFeedback Component (EventBus Listener)
**What:** A single Node component that listens to `EventBus.fruit_merged` and `EventBus.score_awarded`, then dispatches particle bursts, screen shake, and SFX with intensity parameters derived from tier and chain position.
**When to use:** Always. This centralizes all feedback logic. No other system should spawn particles or trigger shake directly.

```gdscript
# scripts/components/merge_feedback.gd
class_name MergeFeedback
extends Node

## Preloaded particle scene for merge bursts.
var _particle_scene: PackedScene = preload("res://scenes/effects/merge_particles.tscn")

## All 8 FruitData resources for color/tier lookups.
var _fruit_types: Array[FruitData] = []

func _ready() -> void:
    add_to_group("merge_feedback")
    _load_fruit_types()
    EventBus.fruit_merged.connect(_on_fruit_merged)

func _on_fruit_merged(old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
    # Determine chain_count from ScoreManager (or listen to score_awarded instead)
    var tier_intensity: float = clampf(float(new_tier) / 7.0, 0.1, 1.0)

    _spawn_particles(merge_pos, new_tier, tier_intensity)
    _trigger_shake(tier_intensity)
    _play_merge_sfx(new_tier, tier_intensity)

func _spawn_particles(pos: Vector2, tier: int, intensity: float) -> void:
    var particles: CPUParticles2D = _particle_scene.instantiate()
    var container: Node2D = get_tree().get_first_node_in_group("fruit_container")
    if container:
        container.add_child(particles)
    particles.global_position = pos
    # Configure per-merge (color, amount, speed scale with tier)
    _configure_particles(particles, tier, intensity)
    particles.emitting = true

func _trigger_shake(intensity: float) -> void:
    var camera: Camera2D = get_tree().get_first_node_in_group("shake_camera")
    if camera and camera.has_method("add_trauma"):
        camera.add_trauma(intensity * 0.3)  # Scale trauma by tier

func _play_merge_sfx(tier: int, intensity: float) -> void:
    SfxManager.play_merge(tier, intensity)
```

### Pattern 2: Trauma-Based Screen Shake (Camera2D)
**What:** A Camera2D added to the game scene with a script that maintains a `trauma` value (0.0-1.0). Trauma is added on merge events and decays every frame. The actual shake amount is `pow(trauma, trauma_power)` applied as noise-driven offset and rotation. This naturally handles overlapping/additive shakes from chain reactions.
**When to use:** For all screen shake. The trauma model means rapid merges (chains) automatically produce escalating shake because trauma accumulates faster than it decays.

```gdscript
# scripts/components/screen_shake.gd
extends Camera2D

## How quickly trauma decays per second.
@export var decay: float = 0.8
## Maximum pixel offset for shake.
@export var max_offset: Vector2 = Vector2(12, 8)
## Maximum rotation in radians for shake.
@export var max_roll: float = 0.02

var trauma: float = 0.0
var trauma_power: int = 2
var _noise: FastNoiseLite = FastNoiseLite.new()
var _noise_y: float = 0.0

func _ready() -> void:
    add_to_group("shake_camera")
    _noise.seed = randi()
    _noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    _noise.frequency = 0.5

func add_trauma(amount: float) -> void:
    trauma = minf(trauma + amount, 1.0)

func _process(delta: float) -> void:
    if trauma > 0.0:
        trauma = maxf(trauma - decay * delta, 0.0)
        _apply_shake()
    else:
        offset = Vector2.ZERO
        rotation = 0.0

func _apply_shake() -> void:
    var amount: float = pow(trauma, trauma_power)
    _noise_y += 1.0
    offset.x = max_offset.x * amount * _noise.get_noise_2d(float(_noise.seed), _noise_y)
    offset.y = max_offset.y * amount * _noise.get_noise_2d(float(_noise.seed * 2), _noise_y)
    rotation = max_roll * amount * _noise.get_noise_2d(float(_noise.seed * 3), _noise_y)
```

### Pattern 3: SFX Pool Autoload
**What:** An autoload singleton with a pool of 8 AudioStreamPlayer nodes. Incoming play requests dequeue an available player, set its stream and pitch_scale, and play. When playback finishes, the player returns to the pool. This prevents audio cutoff when a new merge happens while a previous merge sound is still playing.
**When to use:** For ALL sound effects. Never create AudioStreamPlayer nodes per-merge.

```gdscript
# scripts/autoloads/sfx_manager.gd
extends Node

const POOL_SIZE: int = 8
var _available: Array[AudioStreamPlayer] = []
var _merge_stream: AudioStream = preload("res://assets/audio/sfx/merge_pop.wav")

func _ready() -> void:
    for i in POOL_SIZE:
        var player := AudioStreamPlayer.new()
        add_child(player)
        player.bus = "SFX"
        player.finished.connect(_on_finished.bind(player))
        _available.append(player)

func play_merge(tier: int, intensity: float) -> void:
    if _available.is_empty():
        return
    var player: AudioStreamPlayer = _available.pop_back()
    player.stream = _merge_stream
    # Higher tiers = lower pitch (bigger = deeper), slight random variation
    player.pitch_scale = lerpf(1.3, 0.7, intensity) + randf_range(-0.05, 0.05)
    # Higher tiers = louder
    player.volume_db = lerpf(-6.0, 0.0, intensity)
    player.play()

func _on_finished(player: AudioStreamPlayer) -> void:
    _available.append(player)
```

### Pattern 4: One-Shot CPUParticles2D with Auto-Cleanup
**What:** A preconfigured CPUParticles2D scene with `one_shot = true` and `explosiveness = 1.0` (all particles emit at once for burst effect). The `finished` signal triggers `queue_free()` so the node auto-cleans. Color and intensity are configured per-spawn from MergeFeedback.
**When to use:** Every merge event spawns one instance of this scene.

```gdscript
# Configuring CPUParticles2D at spawn time (in MergeFeedback)
func _configure_particles(particles: CPUParticles2D, tier: int, intensity: float) -> void:
    # Tier color from FruitData
    var color: Color = Color.WHITE
    if tier < _fruit_types.size():
        color = _fruit_types[tier].color

    particles.color = color
    # Color ramp: tier color -> transparent over lifetime
    var gradient := Gradient.new()
    gradient.set_color(0, color)
    gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
    particles.color_ramp = gradient

    # Scale particle count and speed with tier
    particles.amount = int(lerpf(8.0, 30.0, intensity))
    particles.initial_velocity_min = lerpf(40.0, 120.0, intensity)
    particles.initial_velocity_max = lerpf(80.0, 200.0, intensity)
    particles.scale_amount_min = lerpf(1.5, 4.0, intensity)
    particles.scale_amount_max = lerpf(3.0, 8.0, intensity)

    # Auto-cleanup when particles finish
    particles.finished.connect(particles.queue_free)
```

### Pattern 5: Chain Escalation via score_awarded Signal
**What:** The `EventBus.score_awarded` signal already provides `chain_count` and `multiplier`. MergeFeedback can listen to this signal to layer additional chain-specific effects (extra shake, color shift, accent sounds) on top of the base merge feedback.
**When to use:** For chain-specific escalation effects that go beyond the base tier-scaled feedback.

```gdscript
func _ready() -> void:
    EventBus.score_awarded.connect(_on_score_awarded)

func _on_score_awarded(points: int, merge_pos: Vector2, chain_count: int, multiplier: int) -> void:
    if chain_count >= 2:
        # Add extra trauma for chain (additive, so chains naturally escalate)
        var chain_trauma: float = clampf(float(chain_count) * 0.05, 0.0, 0.4)
        _trigger_shake(chain_trauma)
        # Play chain accent sound
        if chain_count >= 3:
            SfxManager.play_chain_accent(chain_count)
```

### Anti-Patterns to Avoid
- **Spawning particles as children of the merging fruit:** The fruit is queue_free'd immediately. Particles must be added to a persistent container (fruit_container or a dedicated effects container).
- **Creating AudioStreamPlayer per merge:** Each merge creates a new node that is never freed. Use a pool.
- **Using GPUParticles2D without testing web export:** While fixed in 4.4, CPUParticles2D is the safer choice for GL Compatibility web export.
- **Shake via viewport transform instead of Camera2D offset:** Modifying canvas_transform directly interferes with UI layers and causes visual artifacts. Camera2D offset only affects the game world.
- **Hardcoding feedback parameters per tier:** Use the FruitData.color and tier index to derive all parameters. Adding a new tier should not require editing the feedback system.
- **Connecting finished to queue_free in the editor inspector:** Known editor crash bug (#107743, #87287). Connect via code in _ready() or at spawn time instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Particle burst effects | Manual Sprite2D spawning and tweening | CPUParticles2D with one_shot + explosiveness = 1.0 | CPUParticles2D handles particle lifetime, color ramps, velocity spread, gravity, scale curves -- dozens of parameters. Manual sprite animation cannot match the visual quality. |
| Screen shake | Randomizing position offset in _process | Camera2D + FastNoiseLite trauma model | Random offset produces jarring jitter. Noise-based trauma model gives smooth, professional-feeling shake that naturally handles additive chain shake. |
| Audio pooling | Creating/freeing AudioStreamPlayer per effect | Pool of 8 pre-created players with finished signal recycling | Pool prevents both node creation overhead and the audio cutoff that happens when you stop one sound to play another. |
| Pitch variation | Manual randf_range on pitch_scale every play call | AudioStreamRandomizer wrapping the base stream | Built-in resource handles random pitch and volume variation automatically. Less code, more consistent results. |
| Color derivation per tier | Lookup tables mapping tier -> color | FruitData.color property (already exists) | The color field was designed for exactly this purpose. It is already populated on all 8 tiers. |

**Key insight:** The most complex part of merge feedback is not any individual effect but the COORDINATION between effects and scaling them consistently by tier and chain position. The MergeFeedback component's value is in being the single orchestration point, not in implementing particles/shake/audio from scratch.

## Common Pitfalls

### Pitfall 1: Particles Spawned on Freed Node
**What goes wrong:** Particles are added as children of the merging fruit. The fruit is `queue_free`'d by MergeManager, which also frees the particles before they can render.
**Why it happens:** Natural instinct is to spawn effects at the object that caused them. But merged fruits are immediately deactivated and freed.
**How to avoid:** Spawn particles on a persistent container node (the existing `fruit_container` or a new `effects_container` group node). Set `global_position` to the merge position AFTER adding to the container.
**Warning signs:** Particles flash for one frame then vanish. No visible particle effect despite code running.

### Pitfall 2: Camera Shake Affecting UI
**What goes wrong:** Screen shake offsets the HUD text, popups, and score displays along with the game world.
**Why it happens:** If shake is implemented by modifying the viewport canvas_transform, everything in the viewport shakes. Or if the HUD is a child of the shaking node.
**How to avoid:** Use Camera2D offset for shake (only affects the game camera's view). The HUD is already a CanvasLayer, which renders independently of Camera2D. CanvasLayer nodes are NOT affected by Camera2D offset/rotation by default. Verify this during testing.
**Warning signs:** Score labels and chain counter jitter during merges. Floating popups shake differently than fruits.

### Pitfall 3: Audio Cutoff During Rapid Chains
**What goes wrong:** Each merge tries to play a sound, but with only one AudioStreamPlayer, the previous sound is stopped to play the new one. Rapid chains produce only the last merge sound.
**Why it happens:** AudioStreamPlayer.play() stops any currently playing stream before starting the new one.
**How to avoid:** Use a pool of 8 AudioStreamPlayer nodes. 8 is sufficient for even the longest chains (the Fibonacci multiplier table has 10 entries, and chain reactions rarely exceed 6-7 in practice).
**Warning signs:** Merge sounds cut off abruptly. Only the final merge in a chain produces a complete sound.

### Pitfall 4: Shake Overload During Long Chains
**What goes wrong:** Each merge adds trauma, and in a long chain (5+ merges in ~1-2 seconds), trauma saturates at 1.0 and stays there, producing nauseating constant maximum shake.
**Why it happens:** Trauma accumulates faster than it decays during rapid cascades.
**How to avoid:** Clamp total trauma addition per chain event. Use diminishing additional trauma for higher chain counts: `chain_trauma = 0.1 / chain_count` instead of flat addition. Also keep max_offset conservative (12px horizontal, 8px vertical) so even maximum shake is comfortable. Test on the web export at 540x960 resolution.
**Warning signs:** Screen vibrates violently during chains. Players report motion sickness or visual discomfort.

### Pitfall 5: CPUParticles2D finished Signal and queue_free in Editor
**What goes wrong:** Connecting `finished` to `queue_free` via the editor inspector causes the node to delete itself from the scene when you toggle emitting in the editor for testing.
**Why it happens:** Known bug (#107743, duplicate of #87287). The signal fires in the editor context, not just at runtime.
**How to avoid:** NEVER connect finished->queue_free in the editor inspector. Always connect via code: `particles.finished.connect(particles.queue_free)` at spawn time. This is runtime-only and safe.
**Warning signs:** Particle scene nodes vanish from the editor after toggling Emitting. Scene file shows missing nodes after save.

### Pitfall 6: Web Audio Autoplay Restrictions
**What goes wrong:** Audio does not play on the first merge in a web export because the browser blocks audio playback until user interaction.
**Why it happens:** Modern browsers require a user gesture (click/tap) before allowing AudioContext to start. Godot handles this internally, but the first sound after page load may be silent.
**How to avoid:** The game already requires a click/tap to drop the first fruit, which satisfies the browser's user gesture requirement before any merge can occur. No special handling needed, but be aware during testing: if you somehow trigger a merge without a prior click (e.g., auto-play testing), audio will not work. Test by playing normally (click to drop, then merge happens).
**Warning signs:** No sound on the very first merge after loading the page. Works fine after that.

### Pitfall 7: Particle Amount Exceeding GL Compatibility Limits
**What goes wrong:** Setting too many particles (100+) per burst on mobile/web causes frame drops because CPUParticles2D processes particles on the CPU main thread.
**Why it happens:** GL Compatibility renderer + web export = constrained CPU budget. Each CPUParticles2D instance processes every particle every frame.
**How to avoid:** Keep particle counts modest: 8-30 per burst depending on tier. Use shorter lifetimes (0.3-0.6s) so particles are processed for fewer frames. Multiple simultaneous bursts (chain reactions) compound the particle count.
**Warning signs:** Frame rate drops during chain reactions. Web export runs noticeably slower than desktop during merges.

## Code Examples

### Adding Camera2D to Game Scene
```
# In game.tscn, add a Camera2D child node:
[node name="ShakeCamera" type="Camera2D" parent="." groups=["shake_camera"]]
position = Vector2(540, 960)  # Center of 1080x1920 viewport
script = ExtResource("screen_shake_script")
```

The Camera2D should be positioned at the center of the viewport (540, 960 for 1080x1920). It does NOT follow any target -- this is a fixed-camera game. The camera exists solely for the shake offset.

### CPUParticles2D Scene Configuration (merge_particles.tscn)
```gdscript
# Key properties for the preconfigured scene:
# Set in editor, overridden per-spawn by MergeFeedback

emission_shape = EMISSION_SHAPE_SPHERE  # Radial burst from center
emission_sphere_radius = 5.0            # Small origin for tight burst
direction = Vector2(0, -1)              # Default upward bias
spread = 180.0                          # Full circle spread (radial burst)
gravity = Vector2(0, 200)               # Slight downward pull for arc
initial_velocity_min = 60.0             # Minimum outward speed
initial_velocity_max = 120.0            # Maximum outward speed
scale_amount_min = 2.0                  # Particle size
scale_amount_max = 4.0
lifetime = 0.4                          # Short burst, quick cleanup
one_shot = true                         # Single emission only
explosiveness = 1.0                     # All particles emit simultaneously
amount = 16                             # Default count (overridden per tier)
```

### SFX Manager with Audio Bus Setup
```gdscript
# In project.godot or via Project Settings > Audio:
# Add "SFX" bus as child of Master bus
# This allows independent volume control for sound effects

# In sfx_manager.gd:
func _ready() -> void:
    # Ensure SFX bus exists
    var sfx_bus_idx: int = AudioServer.get_bus_index("SFX")
    if sfx_bus_idx == -1:
        # Bus not configured -- sounds will route to Master
        push_warning("SfxManager: 'SFX' audio bus not found, using Master")
```

### Tier-to-Intensity Mapping
```gdscript
# Consistent intensity calculation used across all feedback systems.
# tier 0 (blueberry) = subtle, tier 7 (watermelon) = maximum impact.
# Watermelon vanish (new_tier == 8, beyond array) = maximum + bonus.

static func tier_to_intensity(new_tier: int) -> float:
    if new_tier >= 8:  # Watermelon vanish
        return 1.0
    return clampf(float(new_tier) / 7.0, 0.1, 1.0)

# Intensity values per tier:
# Tier 0 (Blueberry): 0.10  -- minimal pop
# Tier 1 (Grape):     0.14  -- tiny pop
# Tier 2 (Cherry):    0.29  -- small pop
# Tier 3 (Strawberry):0.43  -- medium pop
# Tier 4 (Orange):    0.57  -- notable pop
# Tier 5 (Apple):     0.71  -- big pop
# Tier 6 (Pear):      0.86  -- major pop
# Tier 7 (Watermelon):1.00  -- maximum spectacle
# Vanish (2x Wmelon): 1.00  -- maximum + special VFX
```

### Chain Escalation Example
```gdscript
# Chain-specific feedback layering on top of base tier feedback.
# Chain 1 = normal merge (no bonus). Chain 2+ = escalating bonus.

func _apply_chain_feedback(chain_count: int, merge_pos: Vector2) -> void:
    if chain_count < 2:
        return  # No chain bonus for single merges

    # Extra shake: diminishing per chain to avoid overload
    var extra_trauma: float = minf(0.15, 0.08 + float(chain_count - 2) * 0.02)
    _trigger_shake(extra_trauma)

    # Chain accent sound (higher pitch for longer chains)
    SfxManager.play_chain_accent(chain_count)

    # Optional: shift particle color toward white/gold for long chains
    # This provides the "visually distinct" feedback the success criteria requires
```

### Watermelon Vanish Special Effect
```gdscript
# When new_tier >= _fruit_types.size(), two watermelons vanished.
# This is the "big payoff moment" from Phase 1 context decisions.
# Maximum everything + unique visual treatment.

func _on_watermelon_vanish(merge_pos: Vector2) -> void:
    # Extra-large particle burst with gold/white color
    var particles: CPUParticles2D = _particle_scene.instantiate()
    var container: Node2D = get_tree().get_first_node_in_group("fruit_container")
    container.add_child(particles)
    particles.global_position = merge_pos
    particles.amount = 40
    particles.color = Color(1.0, 0.9, 0.3)  # Gold
    particles.initial_velocity_min = 150.0
    particles.initial_velocity_max = 300.0
    particles.lifetime = 0.8
    particles.finished.connect(particles.queue_free)
    particles.emitting = true

    # Maximum shake
    var camera: Camera2D = get_tree().get_first_node_in_group("shake_camera")
    if camera and camera.has_method("add_trauma"):
        camera.add_trauma(0.6)

    # Special vanish sound
    SfxManager.play_watermelon_vanish()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| OpenSimplexNoise for screen shake | FastNoiseLite for screen shake | Godot 4.0 | OpenSimplexNoise removed. FastNoiseLite provides same smooth noise with TYPE_SIMPLEX. |
| GPUParticles2D for all 2D effects | CPUParticles2D for web-safe effects | Godot 4.3-4.4 (bugs fixed) | GPUParticles2D rendering bugs in web export were fixed via PR #96413 in 4.4 milestone, but CPUParticles2D remains the safer choice for GL Compatibility + web. |
| Per-instance AudioStreamPlayer | AudioStreamPlayer pool pattern | Community best practice | Pool prevents creation overhead and audio cutoff. Standard pattern from KidsCanCode Godot 4 recipes. |
| Manual pitch randomization | AudioStreamRandomizer resource | Godot 4.0+ | Built-in resource handles pitch/volume variation automatically when wrapping audio streams. |
| rand_range per-frame shake | Noise-based trauma decay shake | Community standard (2020+) | Trauma model from GDC talks (Squirrel Eiserloh) is the accepted standard for game feel screen shake. |

**Deprecated/outdated:**
- OpenSimplexNoise: Removed in Godot 4. Use FastNoiseLite with TYPE_SIMPLEX instead.
- `AudioStreamRandomPitch`: Godot 3 class. Replaced by AudioStreamRandomizer in Godot 4.
- GPUParticles2D web export workaround shaders: No longer needed in Godot 4.4+ (but project uses 4.5, so not relevant).

## Open Questions

1. **Audio file source for merge SFX**
   - What we know: The game needs at least two sound effects (merge pop, chain accent). WAV format is recommended for SFX (low latency, no decode overhead). Files do not currently exist in the assets directory.
   - What's unclear: Will the developer provide audio files, use free asset packs, or want procedurally generated placeholder sounds?
   - Recommendation: Create placeholder WAV files using a tool like sfxr/jsfxr (free, browser-based). Use simple "pop" and "ding" sounds. File size is minimal (2-10KB per WAV). Replace with polished audio later. The SFX system architecture does not change regardless of audio source.

2. **Effects container node placement**
   - What we know: Particles need a persistent parent node that is not queue_free'd. The existing `fruit_container` group node could serve this purpose, or a dedicated `effects_container` could be added.
   - What's unclear: Should effects be in the same container as fruits (simplest) or separated (cleaner z-ordering)?
   - Recommendation: Add a new `EffectsContainer` Node2D to game.tscn, positioned above FruitContainer in the tree (renders on top). Add to "effects_container" group. This keeps effects visually above fruits and organizationally separate.

3. **Watermelon vanish special treatment scope**
   - What we know: Phase 1 context says "Two max-tier fruits merging triggers a dramatic vanish with special VFX celebration and bonus." The MergeManager already handles the vanish (no new fruit spawned). The ScoreManager awards the WATERMELON_VANISH_BONUS of 1000 points.
   - What's unclear: How "dramatic" should the vanish be? Flash the screen? Unique particle shape? Special camera zoom? This could be a simple scale-up of existing effects or a distinct treatment.
   - Recommendation: For Phase 3, treat watermelon vanish as maximum-intensity version of the standard feedback (40 particles, max shake, gold color, longer lifetime) plus a brief screen flash (white overlay that fades out over 0.2s). This is achievable with existing systems. More elaborate VFX (camera zoom, slow-motion) can be deferred to Phase 8 polish.

4. **Audio bus configuration for web export**
   - What we know: Audio bus effects had issues in web export in Godot 4.4.dev6 (fixed in stable). Project uses 4.5.
   - What's unclear: Whether custom audio buses work reliably in Godot 4.5 web export. The fix was confirmed for 4.4 stable.
   - Recommendation: Create a simple SFX bus with no effects (just volume control). Test web export early. If bus routing fails on web, fall back to Master bus. The SfxManager should handle this gracefully (check bus existence, warn, fall back).

## Sources

### Primary (HIGH confidence)
- [Godot CPUParticles2D Docs (4.5)](https://rokojori.com/en/labs/godot/docs/4.5/godot/cpuparticles2d-class) -- All CPUParticles2D properties: one_shot, explosiveness, emission_shape, color_ramp, finished signal
- [Godot Camera2D Docs](https://docs.godotengine.org/en/stable/classes/class_camera2d.html) -- offset, rotation, position properties for shake
- [Godot FastNoiseLite Docs](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html) -- noise_type, seed, frequency, get_noise_2d
- [Godot AudioStreamRandomizer Docs](https://rokojori.com/en/labs/godot/docs/4.5/godot/audiostreamrandomizer-class) -- random_pitch, random_volume_offset_db, playback_mode, add_stream
- [Godot Issue #96413 / #95797](https://github.com/godotengine/godot/issues/95797) -- GPUParticles web export fix, merged in 4.4 milestone
- [Godot Issue #107743](https://github.com/godotengine/godot/issues/107743) -- CPUParticles2D finished->queue_free editor crash (duplicate of #87287)

### Secondary (MEDIUM confidence)
- [KidsCanCode Screen Shake Recipe](https://kidscancode.org/godot_recipes/4.x/2d/screen_shake/index.html) -- Trauma-based Camera2D shake pattern with FastNoiseLite
- [Camera Shake Gist (Alkaliii)](https://gist.github.com/Alkaliii/3d6d920ec3302c0ce26b5ab89b417a4a) -- Godot 4 FastNoiseLite shake implementation
- [KidsCanCode Audio Manager Recipe](https://kidscancode.org/godot_recipes/4.x/audio/audio_manager/index.html) -- AudioStreamPlayer pool pattern
- [Godot Audio Import Docs](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html) -- WAV for SFX, OGG for music recommendation
- [Additive Camera Shake (Godot Forum)](https://forum.godotengine.org/t/additive-2d-camera-shake-for-overlapping-shakes-in-rapid-succession/108424) -- Chain-friendly additive trauma pattern
- [Godot Issue #100102](https://github.com/godotengine/godot/issues/100102) -- Audio bus web export fix (closed, fixed in 4.4)

### Tertiary (LOW confidence)
- Particle count limits for GL Compatibility web export: No official benchmarks found. Recommendation of 8-30 particles per burst is based on general mobile performance guidance and the constraint that multiple bursts may overlap during chains. Needs validation during implementation.
- Screen shake max_offset values (12px, 8px): Derived from typical values in community implementations scaled to 1080x1920 viewport. May need tuning for comfort on mobile. Needs playtesting.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All components (CPUParticles2D, Camera2D, AudioStreamPlayer, FastNoiseLite) are Godot 4.5 built-ins with stable APIs. Web export compatibility verified through issue tracker research.
- Architecture: HIGH -- EventBus signal-driven pattern matches existing codebase. MergeFeedback component follows established project conventions (group lookup, component script in scripts/components/).
- Pitfalls: HIGH -- CPUParticles2D web issues documented and fixed. Audio pool pattern well-established. Camera shake via Camera2D offset confirmed to not affect CanvasLayer HUD.
- Tuning parameters: MEDIUM -- Particle counts, shake intensity, pitch ranges are starting estimates. The architecture supports easy tuning, but exact values need playtesting.
- Audio format/bus: MEDIUM -- WAV for SFX is standard Godot practice. Audio bus web export fix confirmed in 4.4. But Godot 4.5 web audio has not been independently verified.

**Research date:** 2026-02-08
**Valid until:** 2026-03-08 (stable domain, 30-day validity)
