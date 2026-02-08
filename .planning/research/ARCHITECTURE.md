# Architecture Research

**Domain:** Suika-style physics puzzle game with roguelike card modifier system
**Researched:** 2026-02-07
**Confidence:** MEDIUM-HIGH

## Standard Architecture

### System Overview

```
Autoloads (persistent across scenes)
+---------------------------------------------------------+
|  EventBus         GameManager        CardManager         |
|  (signals)        (state, score)     (active cards,      |
|                                       card effects)      |
+---------------------------------------------------------+
         |                |                   |
         v                v                   v
Game Scene Tree
+---------------------------------------------------------+
|  Main (Node2D)                                           |
|  +-----------------------------------------------------+ |
|  | Container (StaticBody2D)                             | |
|  |   CollisionShape2D (left wall)                       | |
|  |   CollisionShape2D (right wall)                      | |
|  |   CollisionShape2D (floor)                           | |
|  +-----------------------------------------------------+ |
|  | OverflowLine (Area2D)                                | |
|  |   CollisionShape2D (horizontal line)                 | |
|  |   Timer (grace period)                               | |
|  +-----------------------------------------------------+ |
|  | DropController (Node2D)                              | |
|  |   PreviewFruit (Sprite2D, no physics)                | |
|  |   DropPosition (Marker2D)                            | |
|  +-----------------------------------------------------+ |
|  | FruitContainer (Node2D)                              | |
|  |   [Fruit instances spawned at runtime]               | |
|  +-----------------------------------------------------+ |
|  | MergeManager (Node)                                  | |
|  +-----------------------------------------------------+ |
|  | UILayer (CanvasLayer)                                | |
|  |   ScoreLabel     NextFruitPreview    CardSlots       | |
|  |   PauseMenu      GameOverScreen      CardShop        | |
|  +-----------------------------------------------------+ |
+---------------------------------------------------------+

Fruit Scene (instanced per fruit)
+---------------------------------------------------------+
|  Fruit (RigidBody2D)                                     |
|    Sprite2D (visual)                                     |
|    CollisionShape2D (CircleShape2D)                      |
|    [script: fruit.gd with type, tier, merge logic]       |
+---------------------------------------------------------+
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **EventBus** | Global signal routing between decoupled systems | Autoload script with signal declarations only. No logic, no state. Signals: `fruit_merged`, `score_changed`, `game_over`, `card_activated`, `card_deactivated`, `shop_opened` |
| **GameManager** | Game state machine (menu, playing, paused, game_over, shop), score tracking, run lifecycle, difficulty progression | Autoload script with enum-based state machine. Owns the score integer and high score persistence. Transitions between states via EventBus signals |
| **CardManager** | Active card inventory (3-5 slots), card effect application/removal, card shop logic, currency tracking | Autoload script holding an Array of active CardEffect Resources. Iterates active cards to apply modifiers when fruits are spawned, merged, or physics-ticked |
| **Container** | Physical bowl boundaries that fruits bounce off | StaticBody2D with three CollisionShape2D children (floor + two walls). Never changes at runtime |
| **DropController** | Input handling (mouse/touch), drop position clamping, fruit preview display, drop cooldown timer | Node2D that translates input position into a clamped x-coordinate within container bounds. Spawns fruit into FruitContainer on click/tap |
| **FruitContainer** | Parent node for all active fruit instances | Node2D that holds instanced fruit scenes. Allows easy iteration (get_children) for card effects that modify all fruits |
| **MergeManager** | Orchestrates merge events: validates merge, removes old fruits, spawns upgraded fruit, triggers score/effects | Node script that receives merge requests from fruits, prevents double-merges, handles spawn positioning, and emits `fruit_merged` on EventBus |
| **OverflowLine** | Game-over detection when fruits stay above the line | Area2D positioned at container top. Uses `body_entered`/`body_exited` with a Timer (1.5-2s grace period) to avoid false triggers from bouncing fruits |
| **Fruit** | Individual physics fruit with type identity and collision-based merge detection | RigidBody2D with `contact_monitor = true`, `contacts_reported = 4`. On `body_entered`, checks if colliding body is same tier fruit, then requests merge from MergeManager |
| **UILayer** | All HUD and menu rendering | CanvasLayer with Control children. Listens to EventBus signals to update score display, show/hide menus, render card shop |

## Recommended Project Structure

```
res://
+-- project.godot
+-- scenes/
|   +-- main/
|   |   +-- main.tscn              # Root game scene
|   |   +-- main.gd
|   +-- fruit/
|   |   +-- fruit.tscn             # Single reusable fruit scene
|   |   +-- fruit.gd               # Fruit behavior script
|   +-- container/
|   |   +-- container.tscn         # Bowl with collision walls
|   +-- ui/
|   |   +-- hud.tscn               # In-game HUD
|   |   +-- hud.gd
|   |   +-- game_over_screen.tscn
|   |   +-- pause_menu.tscn
|   |   +-- card_shop.tscn
|   |   +-- card_shop.gd
|   |   +-- card_slot.tscn         # Individual card slot UI
|   |   +-- card_slot.gd
+-- scripts/
|   +-- autoloads/
|   |   +-- event_bus.gd           # Global signal bus
|   |   +-- game_manager.gd        # State machine + score
|   |   +-- card_manager.gd        # Card inventory + effects
|   +-- components/
|   |   +-- drop_controller.gd     # Input + drop logic
|   |   +-- merge_manager.gd       # Merge orchestration
|   |   +-- overflow_detector.gd   # Game-over line logic
+-- resources/
|   +-- fruit_types/
|   |   +-- fruit_data.gd          # FruitData Resource class
|   |   +-- blueberry.tres         # Tier 0
|   |   +-- grape.tres             # Tier 1
|   |   +-- cherry.tres            # Tier 2
|   |   +-- strawberry.tres        # Tier 3
|   |   +-- persimmon.tres         # Tier 4
|   |   +-- apple.tres             # Tier 5
|   |   +-- pear.tres              # Tier 6
|   |   +-- peach.tres             # Tier 7
|   |   +-- pineapple.tres         # Tier 8
|   |   +-- melon.tres             # Tier 9
|   |   +-- watermelon.tres        # Tier 10
|   +-- card_effects/
|   |   +-- card_effect.gd         # Base CardEffect Resource class
|   |   +-- bouncy_fruits.tres
|   |   +-- multi_type_merge.tres
|   |   +-- gravity_shift.tres
|   |   +-- score_multiplier.tres
|   |   +-- [additional cards].tres
+-- assets/
|   +-- sprites/
|   |   +-- fruits/                # Per-fruit sprite images
|   |   +-- ui/                    # UI elements
|   |   +-- cards/                 # Card artwork
|   +-- audio/
|   |   +-- sfx/                   # Sound effects
|   |   +-- music/                 # Background music
|   +-- fonts/
```

### Structure Rationale

- **scenes/:** Grouped by game entity, not by node type. Each subfolder contains a .tscn and its companion .gd script together. This follows Godot's official recommendation to keep assets close to the scenes that use them.
- **scripts/autoloads/:** Separated from scene scripts because autoloads are registered in project settings and persist globally. Keeping them in one folder makes it obvious which scripts are singletons.
- **resources/fruit_types/:** All 11 fruit definitions as .tres files referencing a single FruitData class_name. Data-driven design means adding or tweaking a fruit type requires no code changes.
- **resources/card_effects/:** Each card is a .tres resource file. New cards are added by creating a new .tres file with different parameter values, not by writing new scripts (for parameter-driven cards) or by extending the base class (for behavior-driven cards).
- **assets/:** Raw art, audio, and font assets separated from game logic. Sprites organized by purpose.

## Architectural Patterns

### Pattern 1: Resource-Based Data Model (FruitData)

**What:** Define each fruit tier as a custom Resource class. The single fruit.tscn scene reads its FruitData resource at spawn time to configure sprite, collision radius, score value, and physics properties.
**When to use:** Always. This is the foundation of the fruit system.
**Trade-offs:** Extremely easy to add/modify fruit types without touching code. Slight indirection (fruit reads resource) vs. hardcoded values, but the flexibility is worth it for 11 types.

**Example:**
```gdscript
# resources/fruit_types/fruit_data.gd
class_name FruitData
extends Resource

@export var tier: int                    # 0-10
@export var fruit_name: String
@export var radius: float                # Collision circle radius
@export var sprite: Texture2D            # Fruit image
@export var score_value: int             # Points awarded on merge
@export var color: Color = Color.WHITE   # Tint for particles/effects
@export var mass_override: float = 1.0   # Physics mass
```

```gdscript
# scenes/fruit/fruit.gd
class_name Fruit
extends RigidBody2D

var fruit_data: FruitData
var merge_id: int = -1  # Unique ID to prevent double-merges

func initialize(data: FruitData) -> void:
    fruit_data = data
    $Sprite2D.texture = data.sprite
    $CollisionShape2D.shape = CircleShape2D.new()
    $CollisionShape2D.shape.radius = data.radius
    mass = data.mass_override

func _on_body_entered(body: Node) -> void:
    if body is Fruit and body.fruit_data.tier == fruit_data.tier:
        if fruit_data.tier < 10:  # Watermelon can't merge further
            MergeManager.request_merge(self, body)
```

### Pattern 2: Event Bus (Decoupled Communication)

**What:** A single autoload script that declares all cross-system signals. No logic, no state -- just signal declarations. Systems emit signals through EventBus, and listeners connect to EventBus signals.
**When to use:** For communication between systems that should not know about each other (e.g., MergeManager telling UI to update score, CardManager reacting to merges).
**Trade-offs:** Centralizes signal discovery (one file to check). Risk of becoming a dumping ground -- keep signals focused on game events, not internal component communication. Components within the same scene should use direct signals instead.

**Example:**
```gdscript
# scripts/autoloads/event_bus.gd
class_name EventBus
extends Node

# Fruit events
signal fruit_dropped(fruit: Fruit, position: Vector2)
signal fruit_merged(old_tier: int, new_tier: int, position: Vector2, score: int)
signal fruit_landed(fruit: Fruit)

# Game state events
signal game_state_changed(old_state: int, new_state: int)
signal score_changed(new_score: int)
signal game_over_triggered

# Card events
signal card_activated(card: CardEffect)
signal card_deactivated(card: CardEffect)
signal card_shop_opened
signal card_purchased(card: CardEffect)

# Currency events
signal currency_changed(new_amount: int)
```

### Pattern 3: Card Effect Modifier System (Strategy + Resource)

**What:** Card effects are Resource subclasses that implement hook methods. The CardManager holds active cards and calls their hooks at specific game events. Each card defines which hooks it cares about and what modifications it applies. This combines the Strategy pattern (swappable behavior) with Godot's Resource system (data-driven, editor-friendly).
**When to use:** For all card effects. This is the core of the roguelike layer.
**Trade-offs:** Requires defining a clear set of hook points upfront. Adding a new hook point means updating the base class and all call sites. But the alternative (ad-hoc signals per card) becomes unmaintainable past 10 cards.

**Example:**
```gdscript
# resources/card_effects/card_effect.gd
class_name CardEffect
extends Resource

@export var card_name: String
@export var description: String
@export var icon: Texture2D
@export var rarity: int = 0  # 0=common, 1=uncommon, 2=rare

# --- Hook methods (override in subclasses) ---

## Called when a fruit is about to be spawned. Return modified FruitData.
func on_fruit_spawn(data: FruitData) -> FruitData:
    return data

## Called when a merge is about to happen. Return modified score.
func on_merge(old_tier: int, new_tier: int, base_score: int) -> int:
    return base_score

## Called every physics frame on each active fruit.
func on_fruit_physics_process(fruit: Fruit, delta: float) -> void:
    pass

## Called when fruit physics material is being configured.
func modify_physics_material(mat: PhysicsMaterial) -> PhysicsMaterial:
    return mat

## Called to check if a non-standard merge is valid.
func can_merge(fruit_a: Fruit, fruit_b: Fruit) -> bool:
    return fruit_a.fruit_data.tier == fruit_b.fruit_data.tier
```

```gdscript
# Example concrete card: Bouncy Fruits
# resources/card_effects/bouncy_fruits.gd
class_name BouncyFruitsEffect
extends CardEffect

@export var bounce_value: float = 0.8

func modify_physics_material(mat: PhysicsMaterial) -> PhysicsMaterial:
    mat.bounce = bounce_value
    return mat
```

### Pattern 4: Merge Gatekeeper (Singleton Orchestrator)

**What:** A single MergeManager node receives all merge requests and guarantees exactly one merge per collision pair. Without this, both fruits in a collision detect each other simultaneously and trigger two merges (spawning two upgraded fruits instead of one).
**When to use:** Always. This is a critical correctness pattern for Suika-style games.
**Trade-offs:** Adds a layer of indirection between collision detection and merge execution. But the alternative (double-merge bugs) is a game-breaking defect that every Suika implementation encounters.

**Example:**
```gdscript
# scripts/components/merge_manager.gd
class_name MergeManager
extends Node

var _pending_merges: Dictionary = {}  # fruit_id -> true
var _fruit_scene: PackedScene = preload("res://scenes/fruit/fruit.tscn")
var _fruit_types: Array[FruitData] = []  # Loaded in _ready, indexed by tier

func request_merge(fruit_a: Fruit, fruit_b: Fruit) -> void:
    # Prevent double-merge: if either fruit is already merging, skip
    var id_a = fruit_a.get_instance_id()
    var id_b = fruit_b.get_instance_id()
    if _pending_merges.has(id_a) or _pending_merges.has(id_b):
        return

    # Check card effects for custom merge rules
    var can_merge = true
    for card in CardManager.active_cards:
        can_merge = card.can_merge(fruit_a, fruit_b)
        if not can_merge:
            break
    if not can_merge:
        return

    # Lock both fruits
    _pending_merges[id_a] = true
    _pending_merges[id_b] = true

    # Calculate merge position (midpoint)
    var merge_pos = (fruit_a.global_position + fruit_b.global_position) / 2.0
    var old_tier = fruit_a.fruit_data.tier
    var new_tier = old_tier + 1

    # Calculate score with card modifiers
    var base_score = _fruit_types[new_tier].score_value
    for card in CardManager.active_cards:
        base_score = card.on_merge(old_tier, new_tier, base_score)

    # Remove old fruits
    fruit_a.queue_free()
    fruit_b.queue_free()

    # Spawn new fruit (if not max tier)
    if new_tier <= 10:
        _spawn_merged_fruit(new_tier, merge_pos)

    # Notify systems
    EventBus.fruit_merged.emit(old_tier, new_tier, merge_pos, base_score)

    # Cleanup pending state (deferred so queue_free processes first)
    call_deferred("_cleanup_pending", id_a, id_b)
```

### Pattern 5: Enum-Based Game State Machine

**What:** Simple enum + match-based state machine in GameManager for top-level game states. Not node-based -- node-based FSMs are overkill for 4-5 game states with linear transitions.
**When to use:** For the overall game flow (menu -> playing -> shop -> playing -> game_over).
**Trade-offs:** Doesn't scale to 20+ states or complex hierarchical states. Perfect for this game's simple state graph.

**Example:**
```gdscript
# scripts/autoloads/game_manager.gd
extends Node

enum GameState { MENU, PLAYING, PAUSED, SHOP, GAME_OVER }

var current_state: GameState = GameState.MENU
var score: int = 0
var currency: int = 0

func change_state(new_state: GameState) -> void:
    var old_state = current_state
    current_state = new_state
    EventBus.game_state_changed.emit(old_state, new_state)

    match new_state:
        GameState.PLAYING:
            get_tree().paused = false
        GameState.PAUSED:
            get_tree().paused = true
        GameState.SHOP:
            get_tree().paused = true
        GameState.GAME_OVER:
            get_tree().paused = true
```

## Data Flow

### Fruit Drop Flow

```
Player Input (click/tap)
    |
    v
DropController
    | clamp x-position to container bounds
    | check drop cooldown timer
    | determine fruit type (random from pool, weighted by progression)
    v
CardManager.apply_spawn_hooks(fruit_data)
    | each active card's on_fruit_spawn() modifies FruitData
    v
Instantiate fruit.tscn
    | initialize(modified_fruit_data)
    | add to FruitContainer
    v
Fruit enters physics simulation
    | RigidBody2D gravity + collisions
    v
EventBus.fruit_dropped.emit()
    | UI updates next-fruit preview
```

### Merge Flow

```
Fruit._on_body_entered(other_body)
    | is other_body a Fruit?
    | is other_body.tier == self.tier?
    | is tier < 10?
    v
MergeManager.request_merge(self, other)
    | check _pending_merges (prevent doubles)
    | iterate CardManager.active_cards -> can_merge()
    | calculate merge position
    | calculate score with card modifiers
    v
queue_free() both fruits
    |
    v
Spawn new fruit at merge position (tier + 1)
    | apply card spawn hooks to new fruit
    v
EventBus.fruit_merged.emit(old_tier, new_tier, position, score)
    |
    +---> GameManager.add_score(score)
    |         |
    |         v
    |     EventBus.score_changed.emit()
    |         |
    |         v
    |     UILayer updates score display
    |     Check score thresholds -> open card shop
    |
    +---> SFX/VFX triggered by merge event
```

### Card Effect Application Points

```
CardManager.active_cards: Array[CardEffect]

Hook Points (where cards modify behavior):
    |
    +-- on_fruit_spawn()      --> DropController calls before instantiation
    +-- modify_physics_material() --> fruit.gd calls during initialize()
    +-- on_fruit_physics_process() --> fruit.gd calls in _physics_process()
    +-- on_merge()            --> MergeManager calls during merge
    +-- can_merge()           --> MergeManager calls to validate merge
```

### Game Over Flow

```
Fruit enters OverflowLine (Area2D)
    |
    v
OverflowDetector._on_body_entered()
    | start grace Timer (1.5-2 seconds)
    | track which fruits are above the line
    v
Timer timeout AND fruits still above line?
    | YES --> EventBus.game_over_triggered.emit()
    | NO  --> reset timer (fruits fell back down)
    v
GameManager receives game_over_triggered
    | change_state(GameState.GAME_OVER)
    | pause tree
    v
UILayer shows GameOverScreen
    | display final score, high score
    | "Play Again" button -> reset and change_state(PLAYING)
```

### Card Shop Flow

```
GameManager detects score threshold crossed
    |
    v
EventBus.card_shop_opened.emit()
    |
    v
GameManager.change_state(GameState.SHOP)
    | pauses game tree
    v
UILayer shows CardShop
    | generate 3 random card offers (weighted by rarity)
    | display card names, descriptions, costs
    v
Player selects card
    |
    v
CardManager.add_card(card_effect)
    | if slots full: prompt to replace existing card
    | deduct currency
    v
EventBus.card_activated.emit(card)
    | card hooks now active in all future game events
    v
GameManager.change_state(GameState.PLAYING)
    | unpauses game tree
```

### Key Data Flows

1. **Input -> Physics:** DropController translates screen position to game coordinates. Fruit is spawned as RigidBody2D and handed off to the physics engine entirely. No manual position updates.
2. **Physics -> Logic:** Fruit collision signals (body_entered) bubble up to MergeManager. The physics engine owns fruit movement; game logic only reacts to collision events.
3. **Logic -> UI:** All UI updates flow through EventBus signals. UI nodes never poll game state; they subscribe to signals and react. One-directional data flow.
4. **Cards -> Everything:** CardManager sits between systems, intercepting events at defined hook points. Cards modify data in transit (FruitData before spawn, score during merge, PhysicsMaterial during setup) rather than directly controlling game objects.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| MVP (core loop) | Single scene, 3 autoloads, no cards. Focus on physics feel and merge correctness. |
| Card system (10-20 cards) | Add CardManager autoload + CardEffect resource hierarchy. Simple parameter-driven cards only (bounce, score multiplier). |
| Full card system (50+ cards) | Extend CardEffect with subclasses for complex behaviors. Consider a CardEffectRegistry for weighted random selection. May need additional hook points. |
| Mobile optimization | Object pooling for fruits (avoid instantiate/queue_free churn). Reduce contacts_reported. Cap active fruit count at ~30-40. |

### Scaling Priorities

1. **First bottleneck: Physics performance with many fruits.** When 20+ RigidBody2D fruits are stacking and colliding, physics becomes expensive. Mitigation: cap fruit count, use simpler collision shapes (circles only, never polygons), keep contacts_reported low (4 is sufficient).
2. **Second bottleneck: Card effect complexity.** Cards that run logic every physics frame (on_fruit_physics_process) on every fruit create O(cards * fruits) per-frame cost. Mitigation: most cards should be parameter-modifying (set-and-forget), not per-frame. Reserve per-frame hooks for rare cards and document the performance cost.

## Anti-Patterns

### Anti-Pattern 1: Fruit-to-Fruit Direct Merge (No Gatekeeper)

**What people do:** Each fruit detects collision with matching fruit and immediately spawns a new fruit + deletes itself.
**Why it's wrong:** Both fruits in a pair detect the collision simultaneously. Without a gatekeeper, two new fruits spawn instead of one. This is the single most common bug in Suika game implementations.
**Do this instead:** Route all merge requests through MergeManager with a pending-merge lock dictionary. Only the first request for a given pair proceeds.

### Anti-Pattern 2: Hardcoded Fruit Types

**What people do:** Create 11 separate scenes (blueberry.tscn, grape.tscn, etc.) with hardcoded values in each script.
**Why it's wrong:** 11x the maintenance burden. Changing collision radius formula means editing 11 files. Adding a fruit type means creating a new scene + script. Card effects that modify fruits must know about all 11 types.
**Do this instead:** One fruit.tscn + one fruit.gd. All variation comes from FruitData resources. The scene configures itself from the resource at spawn time.

### Anti-Pattern 3: Cards as Autoloads or Singletons

**What people do:** Each card effect is its own autoload or global script that hooks into systems independently.
**Why it's wrong:** Card count grows to 30-50+. Each new autoload adds global state and ordering dependencies. No centralized way to activate/deactivate cards or limit active slots.
**Do this instead:** Cards are Resources, not nodes. CardManager is the single autoload that manages the active card array and routes game events through card hooks.

### Anti-Pattern 4: Polling Game State from UI

**What people do:** UI scripts check GameManager.score or GameManager.state in _process() every frame.
**Why it's wrong:** Wasteful (checking unchanged values 60 times/second) and couples UI tightly to GameManager's data structure.
**Do this instead:** EventBus signals (score_changed, game_state_changed). UI connects once and reacts only when values actually change.

### Anti-Pattern 5: Using Area2D for Fruit Collision Instead of RigidBody2D

**What people do:** Make fruits as Area2D for simpler collision detection, then manually simulate physics.
**Why it's wrong:** Reinventing physics. Stacking, bouncing, friction, mass -- all need manual implementation. Bugs and performance issues compound rapidly.
**Do this instead:** Use RigidBody2D with contact_monitor = true. Let Godot's physics engine handle stacking. Only react to body_entered signals for merge detection.

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| DropController -> FruitContainer | Direct: instantiate scene, add_child | Same scene tree; direct reference is fine |
| Fruit -> MergeManager | Direct call: MergeManager.request_merge() | MergeManager is a known singleton node in the scene. Fruit calls it directly because merge requests are high-frequency and need synchronous gating |
| MergeManager -> GameManager | Via EventBus: fruit_merged signal | Decoupled. MergeManager does not know about scoring |
| GameManager -> UILayer | Via EventBus: score_changed, game_state_changed | Decoupled. UI subscribes to events |
| CardManager -> Fruit/MergeManager | Caller-driven: systems call CardManager.apply_hooks() | Systems pull card modifications at hook points. Cards do not push effects. This keeps card effects predictable and debuggable |
| OverflowDetector -> GameManager | Via EventBus: game_over_triggered | Decoupled. Overflow logic is self-contained |
| UILayer (CardShop) -> CardManager | Direct call: CardManager.add_card() | UI initiates card purchase. Direct call is appropriate because it is a user-initiated action with immediate feedback |

### Communication Decision Rules

- **Same parent/scene, tight coupling expected:** Direct references (DropController -> FruitContainer)
- **Cross-system, fire-and-forget events:** EventBus signals (merge -> score update)
- **Cross-system, need return value or synchronous gating:** Direct singleton call (Fruit -> MergeManager)
- **Data modification in transit:** CardManager hook pattern (caller passes data through card pipeline)

## Build Order (Dependency-Driven)

The architecture implies this build sequence based on component dependencies:

| Phase | Components | Why This Order |
|-------|-----------|----------------|
| 1 | Container (StaticBody2D), single Fruit scene (RigidBody2D), FruitData resource for 2-3 types, basic DropController | You cannot test merging without droppable physics fruits in a container. This is the irreducible core. |
| 2 | MergeManager, full FruitData set (11 types), EventBus (initial signals) | Merging is the core mechanic. MergeManager prevents double-merge bugs from day one. EventBus enables score tracking. |
| 3 | GameManager (state machine + scoring), OverflowLine game-over detection | Game needs win/loss conditions and state transitions to be playable. Depends on EventBus existing. |
| 4 | UILayer (HUD, game over screen, pause menu) | UI visualizes game state. Depends on GameManager + EventBus for data. |
| 5 | CardEffect base class, CardManager, 3-5 starter cards, CardShop UI | Roguelike layer. Depends on all core systems existing to hook into. Starter cards should be parameter-driven (bouncy, score multiplier) not behavioral. |
| 6 | Input abstraction (mouse + touch), mobile viewport scaling | Cross-platform support. Depends on DropController existing to refactor input handling. |
| 7 | Audio, VFX (merge particles, screen shake), juice/polish | Polish layer. Connects to EventBus signals. No other system depends on it. |
| 8 | Advanced cards (behavioral subclasses), card balancing, meta-progression | Expansion. Depends on card system being proven stable with simple cards first. |

## Sources

- [yokai-suika - Godot 4.3 Suika implementation (resource-based architecture)](https://github.com/Checkroth/yokai-suika) - MEDIUM confidence
- [Drygast Suika clone blog (scene structure, signal-based merge)](https://drygast.net/blog/post/godot_ahballs) - MEDIUM confidence
- [GDQuest Event Bus pattern](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/) - HIGH confidence
- [GDQuest Strategy pattern](https://www.gdquest.com/tutorial/godot/design-patterns/strategy/) - HIGH confidence
- [Service Architecture pattern for Godot](https://www.manuelsanchezdev.com/blog/godot-singletons-to-service-architecture-the-runic-edda) - MEDIUM confidence
- [Godot design patterns overview](https://www.manuelsanchezdev.com/blog/game-development-patterns) - MEDIUM confidence
- [RigidBody2D official docs](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html) - HIGH confidence
- [PhysicsMaterial official docs](https://docs.godotengine.org/en/stable/classes/class_physicsmaterial.html) - HIGH confidence
- [Godot project organization best practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html) - HIGH confidence
- [Godot autoloads vs regular nodes](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html) - HIGH confidence
- [Complex buffs modifier system forum discussion](https://godotforums.org/d/27921-complex-buffs-modifier-system-for-game) - LOW confidence
- [Expandable upgrade system forum discussion](https://forum.godotengine.org/t/best-way-to-create-an-upgrade-system-that-is-easy-to-expand/70699) - LOW confidence
- [Suika merge mechanic blog (age-variable approach)](https://arnaught.neocities.org/blog/2023/11/16/godot-day-1) - MEDIUM confidence
- [GDQuest Finite State Machine](https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/) - HIGH confidence

---
*Architecture research for: Suika-style physics puzzle with roguelike card modifiers in Godot 4.5*
*Researched: 2026-02-07*
