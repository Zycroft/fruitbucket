# Stack Research

**Domain:** Suika-style physics puzzle game with roguelike card system
**Researched:** 2026-02-07
**Confidence:** MEDIUM-HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Godot Engine | 4.5 (stable, Sept 2025) | Game engine | Project requirement. Excellent 2D physics, built-in scene system, one-click mobile export. Godot 4.5 adds chunked TileMap physics, stencil buffer, and GDScript strictness improvements. |
| GDScript | 4.5 (static typing mode) | Scripting language | Project requirement. 2-3x faster execution vs GDScript 3.x. Use `@static_unload` and strict typing (`var x: int`) everywhere for performance and editor autocomplete. |
| Godot built-in physics (GodotPhysics2D) | 4.5 | 2D physics simulation | Start here. Zero setup, deeply integrated with editor, sufficient for 11-20 simultaneous RigidBody2D fruits. Only switch to Rapier if stacking instability becomes a problem (see Alternatives). |
| Compatibility renderer | OpenGL | Rendering backend | Use Compatibility (OpenGL) not Forward+ (Vulkan) because: (a) this is a simple 2D game with no advanced shader needs, (b) widest mobile device support, (c) web export support. Forward+ and Mobile renderers use Vulkan which excludes older Android devices. |

### Core Node Architecture

| Node Type | Purpose | Configuration | Confidence |
|-----------|---------|---------------|------------|
| **RigidBody2D** | Each fruit/ball | `contact_monitor = true`, `max_contacts_reported = 8`, `gravity_scale = 1.0`, `continuous_cd = CCD_MODE_CAST_RAY`. Use `body_entered` signal for merge detection. | HIGH -- all Suika Godot clones use this |
| **CircleShape2D** | Collision shape for fruits | One per fruit, radius scales per tier. Circles are the fastest primitive shape in Godot's physics engine -- faster than RectangleShape2D and CapsuleShape2D. Fruits are round, so this is the natural fit. | HIGH -- official docs confirm performance |
| **StaticBody2D** | Container walls and floor | 3-4 instances with RectangleShape2D children forming the bucket. Zero physics overhead since static bodies don't participate in solver. | HIGH |
| **Area2D** | Overflow detection line | Positioned at top of container. `body_entered` signal triggers game-over countdown. Cheaper than polling RigidBody2D positions every frame. | MEDIUM -- standard pattern but needs tuning for "grace period" |
| **Sprite2D** | Fruit visuals | Child of each RigidBody2D. Swap texture per fruit tier. Use AtlasTexture from a single spritesheet for fewer draw calls. | HIGH |
| **GPUParticles2D** | Merge/pop effects | One-shot particle bursts on merge. GPU-accelerated, negligible performance cost for small bursts. Use CPUParticles2D only if targeting very old mobile hardware. | MEDIUM |
| **AudioStreamPlayer2D** | Sound effects | Positional audio for merge pops, drops, bounces. Use `AudioStreamPlayer` (non-positional) for UI sounds and music. | HIGH |
| **Camera2D** | Game viewport | Fixed camera, no scrolling. Set `anchor_mode = ANCHOR_MODE_FIXED_TOP_LEFT` for consistent positioning across resolutions. | HIGH |
| **CanvasLayer** | HUD/UI separation | Score display, next-fruit preview, card slots. Renders on top of game world regardless of camera. | HIGH |
| **Control nodes** | UI elements | `Label` for score, `TextureRect` for card art, `HBoxContainer`/`VBoxContainer` for card slot layout, `PanelContainer` for card shop modal. | HIGH |

### Physics Configuration (project.godot)

| Setting | Recommended Value | Default | Why |
|---------|-------------------|---------|-----|
| `physics/2d/default_gravity` | 980 | 980 | Standard: 100px = 1 meter in Godot 2D. 980 feels like real gravity. |
| `physics/2d/solver/solver_iterations` | 6 | 4 | Increase from default for better stacking stability. Suika games need reliable contact resolution with many overlapping circles. |
| `physics/common/physics_ticks_per_second` | 60 | 60 | Match display refresh. Lower values cause visible jitter with stacked RigidBodies. |
| `physics/2d/default_linear_damp` | 0.5 | 0.0 | Slight damping prevents fruits from sliding forever. Suika fruits should settle, not ice-skate. |
| `physics/2d/default_angular_damp` | 1.0 | 0.0 | Prevent perpetual spinning. Fruits should come to rest relatively quickly. |

### PhysicsMaterial for Fruits

| Property | Value | Why |
|----------|-------|-----|
| `friction` | 0.6 | Fruits should grip each other and walls. Too low (< 0.3) and stacks slide apart. |
| `bounce` | 0.15 | Slight bounce for game feel. Zero feels dead; above 0.3 fruits bounce out of the container. Reference games show minimal bounce. |
| `rough` | false | Default combine mode is fine for uniform fruit materials. |
| `absorbent` | false | Default combine mode. |

**Confidence:** MEDIUM -- these are starting values derived from analyzing reference games and community Suika clones. Expect to tune during prototyping.

### Data Architecture for Card System

| Technology | Purpose | Why |
|------------|---------|-----|
| **Custom Resource classes** (`.tres` files) | Card definitions | Godot's Resource system is purpose-built for this. Each card type is a `.tres` file with exported properties (name, description, icon, effect_type, parameters). Resources give static typing, editor integration, and serialize to version-control-friendly text format. Do NOT use JSON -- Resources handle Godot types natively and require less boilerplate. |
| **Enum-based effect system** | Card effect dispatch | Define `CardEffectType` enum. Each card Resource holds an effect type enum + parameters dictionary. Game logic uses `match` on effect type to apply modifiers. Simpler and more debuggable than polymorphic scripts for the initial ~10-20 card effects. |
| **Array of Resource references** | Active card slots | `var active_cards: Array[CardData] = []` with a max size (3-5). Clean, typed, inspectable in editor. |

**Example card Resource structure:**
```gdscript
# card_data.gd
class_name CardData
extends Resource

@export var card_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var effect_type: CardEffectType = CardEffectType.NONE
@export var effect_params: Dictionary = {}
@export var cost: int = 0
@export var rarity: int = 0  # 0=common, 1=uncommon, 2=rare

enum CardEffectType {
    NONE,
    MULTI_TYPE,      # fruit counts as multiple types for merging
    BOUNCY,          # increased bounce on all fruits
    HEAVY,           # increased gravity on fruits
    MAGNET,          # same-type fruits attract each other
    SCORE_MULTI,     # score multiplier on merges
    EXTRA_SLOT,      # +1 card slot
    REROLL,          # reroll shop offerings
}
```

**Confidence:** HIGH -- Custom Resources are the standard Godot 4 pattern for data-driven designs. Multiple official sources and community best practices confirm this approach.

### State Management

| Pattern | Purpose | Why |
|---------|---------|-----|
| **Enum + match state machine** | Game flow states (DROPPING, MERGING, GAME_OVER, SHOP_OPEN, PAUSED) | Simplest correct approach for a game with < 10 states. Node-based state machines add unnecessary complexity here. The entire game state fits in one enum variable. |
| **Signal bus autoload** | Cross-scene communication | Single autoload script (`Events.gd`) with signal definitions. Nodes emit/connect through `Events.fruit_merged.emit(tier)` rather than reaching up the tree. Keeps fruit scenes, HUD, and card system decoupled. |
| **Game manager autoload** | Run-level state persistence | Single autoload (`GameManager.gd`) holding score, currency, active cards, current run state. Persists across scene transitions (e.g., game-to-shop-to-game). |

**Confidence:** HIGH -- Autoload signal bus is the standard Godot 4 pattern documented officially and recommended by GDQuest.

### Input Handling

| Input Type | Approach | Details |
|------------|----------|---------|
| **Mouse (desktop)** | `_unhandled_input(event: InputEvent)` | Check for `InputEventMouseButton` (click to drop) and `InputEventMouseMotion` (position fruit). Use `_unhandled_input` not `_input` so UI elements get first crack at consuming clicks. |
| **Touch (mobile)** | Godot's built-in mouse-to-touch emulation | In Project Settings, enable `input_devices/pointing/emulate_mouse_from_touch = true` (default: true). This translates touch events into mouse events automatically. For a Suika game (single-finger tap-and-drop), this is sufficient -- no need for raw `InputEventScreenTouch` handling. |
| **Input actions** | `InputMap` for UI actions | Define `"drop"`, `"pause"` in Project Settings > Input Map. Use `Input.is_action_just_pressed("drop")` for consistency. Physical drop positioning uses mouse/touch position directly. |

**Confidence:** HIGH -- Mouse-to-touch emulation is well-documented and works for single-pointer games. Only go to raw touch events if you add multitouch gestures (which Suika does not need).

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Godot built-in Tween system | 4.5 | Juice animations (scale pops, color flashes, UI transitions) | Every merge, drop, card activation. `create_tween().tween_property()` is lightweight and chainable. No external animation library needed. |
| Godot built-in Timer node | 4.5 | Delayed actions (merge cooldown, overflow grace period, shop trigger) | Wherever you need a delay. Avoid `await get_tree().create_timer()` in tight loops -- use Timer nodes for persistent delays. |
| Godot built-in ResourceSaver/ResourceLoader | 4.5 | High score persistence, settings | Save to `user://` path. Use Resource-based saves, not JSON, for type safety. JSON does not handle Vector2, Color, etc. natively. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Godot 4.5 Editor | Development IDE | Built-in debugger, profiler, remote scene inspector. Use the Physics debugger (Debug > Visible Collision Shapes) heavily during development. |
| Git + `.gitignore` | Version control | Ignore `.godot/` (cache), `*.import` is version-controlled by Godot convention. Use text-based `.tres` and `.tscn` formats for mergeable diffs. |
| Aseprite or Krita | Sprite creation | Export as PNG spritesheet. Import into Godot with "2D Pixel" preset if pixel art, or default "2D" preset for smooth art. |
| Godot profiler | Performance monitoring | Monitor physics time specifically. If physics exceeds 4ms/frame with 11 fruits, something is wrong. |

## Project Setup

```
bucket/
  project.godot              # Engine config, input maps, autoloads
  scenes/
    game/
      game.tscn              # Main game scene
      game.gd
    fruit/
      fruit.tscn             # Generic fruit (RigidBody2D + Sprite2D + CircleShape2D)
      fruit.gd
    container/
      container.tscn         # Bucket (StaticBody2D walls)
    hud/
      hud.tscn               # Score, next preview, card slots
      hud.gd
    card_shop/
      card_shop.tscn         # Modal card shop UI
      card_shop.gd
    main_menu/
      main_menu.tscn
  scripts/
    autoload/
      events.gd              # Signal bus
      game_manager.gd        # Run state
    data/
      card_data.gd           # CardData Resource class
  resources/
    cards/
      bouncy_card.tres        # Individual card definitions
      multi_type_card.tres
      heavy_card.tres
    fruit_data/
      fruit_tier_1.tres       # Fruit tier definitions (radius, texture, score)
  assets/
    sprites/
      fruits/                 # Fruit PNGs or spritesheet
      cards/                  # Card art PNGs
      ui/                     # UI elements
    audio/
      sfx/                    # Merge pop, drop, bounce sounds
      music/                  # BGM
    fonts/
  addons/                     # Third-party if needed (e.g., Rapier)
```

## Collision Layer Plan

| Layer | Name | Used By |
|-------|------|---------|
| 1 | Fruits | All fruit RigidBody2D instances (layer + mask) |
| 2 | Container | StaticBody2D walls/floor (layer only, no mask needed) |
| 3 | Overflow | Area2D detection line (mask layer 1 only) |
| 4 | Drop Preview | Raycast or ghost fruit preview (no collision response) |

Fruit mask: layers 1 + 2 (collide with other fruits and container walls).
Container mask: none (static, does not need to detect anything).
Overflow mask: layer 1 (detect fruits entering overflow zone).

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| GodotPhysics2D (built-in) | Godot Rapier Physics 2D (GDExtension addon) | If stacking instability becomes a problem with 10+ fruits. Rapier is 2-3x faster and has better stacking stability. Swap is seamless (1:1 API compatibility -- just change Physics Engine in Project Settings). Trade-off: added dependency, newer/less battle-tested. |
| Compatibility renderer (OpenGL) | Mobile renderer (Vulkan) | If you need advanced 2D shader effects (e.g., stencil-based masking). For basic 2D sprites and particles, Compatibility is simpler and more broadly compatible. |
| Custom Resource `.tres` for cards | JSON files for cards | If you need runtime card modding or player-created cards. JSON is human-editable without Godot editor. For developer-authored cards, Resources are strictly better. |
| Enum-based card effects | Script-per-card-effect pattern (polymorphic) | When card count exceeds ~30 and effects become complex (multi-step, conditional, interactive). At that point, each effect as its own script with a shared `apply()` interface scales better. Start with enum, refactor later if needed. |
| Enum state machine | Node-based state machine | If game states become deeply nested or need independent sub-states (e.g., animation states within gameplay). Overkill for < 10 top-level game states. |
| Built-in mouse-to-touch emulation | Raw InputEventScreenTouch handling | If you add pinch-to-zoom, multi-finger gestures, or need to distinguish multiple simultaneous touches. Suika needs exactly one pointer, so emulation is sufficient. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| CharacterBody2D for fruits | CharacterBody2D is for player-controlled entities with move_and_slide(). Fruits are physics-driven objects that respond to gravity and forces -- that is RigidBody2D's job. CharacterBody2D would require manually reimplementing gravity, collision response, and stacking. | RigidBody2D |
| AnimatedSprite2D for fruit visuals | Fruits are static images per tier, not frame-by-frame animations. AnimatedSprite2D adds overhead for unused animation state tracking. Use Tween for scale/color effects. | Sprite2D + Tween for juice effects |
| JSON for card data | JSON does not support Godot types (Vector2, Color, Texture2D references). Requires manual serialization/deserialization boilerplate. Resources handle this natively with zero extra code and integrate with the editor inspector. | Custom Resource `.tres` files |
| Forward+ renderer | Requires Vulkan/Metal. Excludes older Android devices, does not support web export. A 2D Suika game gains nothing from Forward+'s clustered lighting and volumetric fog. | Compatibility renderer (OpenGL) |
| C# / GDExtension | Adds compilation step, increases build complexity, complicates mobile export. GDScript is 2-3x faster in Godot 4 vs 3.x, and a Suika game with < 20 active physics bodies has zero performance concerns with GDScript. Only consider C# if porting an existing C# codebase. | GDScript with static typing |
| Godot's built-in multiplayer / networking nodes | Out of scope per PROJECT.md. Including networking nodes or high-level multiplayer API adds unused complexity and potential security surface. | Nothing -- single player only |
| `call_deferred("queue_free")` chains for merge logic | Easy to create race conditions where two fruits both try to merge with the same partner in the same physics frame. | Use a merge queue: collect merge pairs in `_physics_process`, process them at end of frame, deduplicate. |
| Global `_process()` polling for game state changes | Wastes cycles checking conditions every frame. Godot's signal system exists precisely for event-driven state changes. | Signals for state transitions, `_physics_process()` only for physics-dependent logic |

## Stack Patterns by Variant

**If targeting web export (HTML5):**
- Renderer MUST be Compatibility (OpenGL). Forward+ and Mobile do not support web.
- Test with `OS.has_feature("web")` for web-specific input quirks.
- Expect slightly slower physics -- Godot 4.5 added WebAssembly SIMD support which helps.

**If physics instability becomes a problem:**
- Install Godot Rapier Physics 2D from Asset Library.
- Change one setting: Project Settings > Physics > 2D > Physics Engine = "Rapier2D".
- All existing RigidBody2D/StaticBody2D/Area2D code works unchanged (1:1 API).
- Rapier has better SIMD-optimized solver, but adds ~2MB to export size.

**If card effects become complex (30+ cards):**
- Migrate from enum dispatch to script-per-effect:
  ```gdscript
  # base_card_effect.gd
  class_name BaseCardEffect
  extends Resource
  func apply(game_state: GameState) -> void:
      pass
  func revert(game_state: GameState) -> void:
      pass
  ```
- Each card Resource references a `BaseCardEffect` subclass Resource.
- Keeps card data (.tres) separate from card logic (.gd).

**If art style is pixel art (not smooth/cute):**
- Project Settings > Rendering > Textures > Default Texture Filter = "Nearest"
- Or use the "2D Pixel" import preset per-texture.
- Enable Rendering > 2D > Snap 2D Transforms to Pixel = true.
- This prevents sub-pixel blurriness on scaled pixel sprites.

## Version Compatibility

| Component | Compatible With | Notes |
|-----------|-----------------|-------|
| Godot 4.5 | GDScript 2.0 (static typing) | Use `@export`, `class_name`, typed arrays. `@onready` for node references. |
| Godot 4.5 | Rapier Physics 2D addon | Check Asset Library for 4.5-compatible version. The addon tracks Godot releases closely. |
| Godot 4.5 Compatibility renderer | Android 5.0+, iOS 12+, all desktop, web (WASM) | Broadest device support of any renderer option. |
| Godot 4.5 Mobile renderer | Android 7.0+ (Vulkan), iOS 15+ (Metal), desktop | Better visual quality but narrower device support. |
| `.tres` / `.tscn` text format | Git | Always use text format (default). Binary `.res` / `.scn` are for export only. |

## Sources

- [Godot 4.5 Release](https://godotengine.org/article/dev-snapshot-godot-4-6-beta-2/) -- Confirmed 4.5 release date Sept 2025, features include chunked TileMap physics, stencil buffer, GDScript improvements. **HIGH confidence.**
- [Drygast.NET Suika Clone Tutorial](https://drygast.net/blog/post/godot_ahballs) -- Confirmed RigidBody2D + StaticBody2D + contact_monitor pattern for Suika games. **HIGH confidence.**
- [Yokai-Suika (Godot 4.3)](https://github.com/Checkroth/yokai-suika) -- Confirmed Custom Resource pattern for fruit data with scene-resource binding. **HIGH confidence.**
- [Godot Official Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html) -- Scene organization, autoloads, composition patterns. **HIGH confidence.**
- [Godot PhysicsMaterial Docs](https://docs.godotengine.org/en/stable/classes/class_physicsmaterial.html) -- Bounce/friction properties and combine behavior. **HIGH confidence.**
- [Godot Collision Shapes 2D Docs](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_2d.html) -- CircleShape2D is fastest primitive. **HIGH confidence.**
- [GDQuest Event Bus Pattern](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/) -- Signal bus autoload pattern. **HIGH confidence.**
- [GDQuest Design Patterns](https://www.gdquest.com/tutorial/godot/design-patterns/intro-to-design-patterns/) -- When to use/avoid patterns in Godot. **HIGH confidence.**
- [Godot Autoload/Singleton Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) -- Autoload lifecycle and usage. **HIGH confidence.**
- [Godot Renderers Overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) -- Compatibility vs Forward+ vs Mobile renderer comparison. **HIGH confidence.**
- [Godot Physics vs Box2D vs Rapier Benchmark](https://appsinacup.com/godot-physics-vs-box2d-vs-rapier2d/) -- Rapier 2-3x faster, better stacking. **MEDIUM confidence** (third-party benchmark, version 0.17.2).
- [Godot Rapier Physics](https://godot.rapier.rs/) -- 1:1 API compatibility with GodotPhysics, SIMD support. **MEDIUM confidence** (addon, not official).
- [Custom Resources for Data-Driven Design](https://ezcha.net/news/3-1-23-custom-resources-are-op-in-godot-4) -- Community validation of Resource pattern. **MEDIUM confidence.**
- [Godot Saving Games Docs](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) -- ResourceSaver/ResourceLoader and user:// path. **HIGH confidence.**
- [Collision Layers Best Practices](https://www.gotut.net/collision-layers-and-masks-in-godot-4/) -- Layer naming and mask optimization. **MEDIUM confidence.**

---
*Stack research for: Suika-style physics puzzle game with roguelike card system in Godot 4.5*
*Researched: 2026-02-07*
