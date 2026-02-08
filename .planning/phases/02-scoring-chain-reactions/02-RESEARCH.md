# Phase 2: Scoring & Chain Reactions - Research

**Researched:** 2026-02-08
**Domain:** Godot 4.5 scoring systems, chain reaction tracking, UI animation (Tweens), floating popups
**Confidence:** HIGH

## Summary

Phase 2 adds the scoring brain to a working physics-merge game. The codebase already has all the hooks needed: `EventBus.fruit_merged(old_tier, new_tier, position)` fires on every merge, `GameManager.score` exists as a centralized variable, `FruitData.score_value` is exported on every tier resource, and the HUD already calls `update_score(GameManager.score)` on each merge event. The work is connecting these pieces with actual scoring logic, adding cascade-based chain tracking, implementing animated score display, floating score popups, and a coin economy.

The architecture pattern is clear: a new `ScoreManager` component listens to `EventBus.fruit_merged`, calculates points (base value from `FruitData.score_value` times chain multiplier), updates `GameManager.score` and `GameManager.coins`, and emits signals that the HUD and floating popup system consume. Chain tracking is cascade-based (not time-windowed), so the `MergeManager` must tag newly spawned fruits as "chain children" and increment a chain counter that resets when no merge happens within a physics-settling window. Floating score popups are standard Godot 4 pattern: a Label scene spawned at the merge world position, tweened upward and faded out, then `queue_free()`.

**Primary recommendation:** Create a `ScoreManager` singleton/component that owns all scoring logic, a `ChainTracker` (or integrated into ScoreManager) that tracks cascade depth via merge-spawned fruit tagging, and a `FloatingScore` scene for world-space popups. Update the existing `FruitData.score_value` fields to use exponential scaling. Keep the HUD modifications minimal -- add coin display and animate the existing score label with tweens.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

- Exponential scaling (Suika-style): each tier worth roughly double the previous (e.g., 1, 2, 4, 8, 16... up to 512)
- Watermelon merge (top-tier, two watermelons vanishing) gets a large flat bonus on top of exponential value (e.g., +1000)
- Point values stored as a data resource (not hardcoded) for easy tuning during balancing
- Chains are cascade-based: a merge result must physically trigger the next merge -- no time window, purely physics-driven
- Chain multiplier escalates at an accelerating rate (x2, x3, x5, x8...) -- rare long chains feel explosive
- No cap on chain multiplier -- legendary chains feel legendary
- Every merge shows a floating score popup at the merge point (e.g., "+16" or "+64 x3!") that rises and fades
- Prominent chain counter appears during chains (e.g., "CHAIN x3!") -- hype moment, visible near the action
- Score counter animates when updating -- numbers roll/count up to new value with scale punch on big gains
- Coins are score-derived: awarded when cumulative score crosses thresholds (e.g., every 100 score = 1 coin), not per-merge
- Coin counter displayed in the HUD

### Claude's Discretion

- Score threshold awareness for Phase 5 shop triggers (whether to emit signals now or defer)
- Exact exponential point values per tier
- Per-merge vs end-of-chain multiplier application timing
- Coin conversion ratio and whether it's fixed or escalating
- Whether chain multipliers affect coin income
- Main score placement in HUD (fits with existing layout)
- Coin display style (floating popups or HUD-only)

### Deferred Ideas (OUT OF SCOPE)

None -- discussion stayed within phase scope

</user_constraints>

## Discretion Recommendations

These are my recommendations for the areas left to Claude's discretion:

### Exact Exponential Point Values Per Tier

Use powers of 2 for clean doubling. The existing `FruitData.score_value` fields will be updated:

| Tier | Fruit | Current Value | New Value | Reasoning |
|------|-------|---------------|-----------|-----------|
| 0 | Blueberry | 1 | 1 | Base unit |
| 1 | Grape | 3 | 2 | 2^1 |
| 2 | Cherry | 6 | 4 | 2^2 |
| 3 | Strawberry | 10 | 8 | 2^3 |
| 4 | Orange | 15 | 16 | 2^4 |
| 5 | Apple | 21 | 32 | 2^5 |
| 6 | Pear | 28 | 64 | 2^6 |
| 7 | Watermelon | 36 | 128 | 2^7 |
| 8 | Watermelon vanish | N/A | 1000 | Flat bonus (locked decision) |

This matches the user's "1, 2, 4, 8, 16... up to 512" intent while keeping 8 tiers (0-indexed). The watermelon score_value of 128 is the merge-creation reward; the 1000 bonus is for vanishing two watermelons. Note: original user example showed "up to 512" but we have 8 tiers (indices 0-7), so 2^7 = 128 for tier 7. If the user literally wants 512 at tier 7, the base would need to be higher (e.g., tier 0 = 1, then multiply by ~3.7x each tier). Recommend sticking with clean powers of 2 and tuning later via the data resources.

**Confidence:** HIGH -- powers of 2 are the standard Suika approach, and values live in `.tres` files for easy tuning.

### Per-Merge vs End-of-Chain Multiplier Application

**Recommendation: Apply multiplier per-merge, not at end of chain.**

Rationale:
- Per-merge application gives instant feedback -- the player sees "+64 x3!" immediately
- End-of-chain requires tracking all merges in a chain and retroactively awarding a lump sum, which is confusing
- Per-merge matches the floating popup design (each merge shows its own popup with multiplier)
- Chain counter still displays prominently during the chain
- This is how most cascade-scoring games work (Puzzle & Dragons, Puyo Puyo)

**Confidence:** HIGH -- matches locked decision for floating popups showing multiplier per merge.

### Coin Conversion Ratio

**Recommendation: Fixed ratio of 1 coin per 100 cumulative score.**

Rationale:
- Fixed ratio is simpler to understand and balance
- Score-derived means coins = floor(total_score / 100) - coins_already_awarded
- With exponential scoring, higher tiers naturally yield more coins (a single watermelon merge at 128 pts is worth more than a blueberry at 1 pt)
- Escalating conversion would add complexity without clear player-facing benefit
- The coin threshold (100) can be tuned in a single constant

**Confidence:** MEDIUM -- reasonable starting point, but the exact ratio needs playtesting. Store as a constant for easy tuning.

### Whether Chain Multipliers Affect Coin Income

**Recommendation: Yes, chain multipliers DO affect coin income (indirectly).**

Rationale:
- Coins are derived from cumulative score, and chain multipliers increase score
- So chains naturally increase coin income without any special logic
- This rewards skillful play with both higher scores AND more coins
- No additional code needed -- it's an emergent consequence of the score-derived design

**Confidence:** HIGH -- this is a direct consequence of the locked "score-derived coins" decision.

### Score Placement in HUD

**Recommendation: Keep score in existing position (top center, `ScoreLabel` at x=390-690, y=20-80).**

The current layout has:
- ScoreLabel: top center (390, 20) to (690, 80)
- NextFruitPreview: top right (780, 40) to (880, 140)
- GameOverLabel: centered

Add coin display to the left of NextFruitPreview or below the score, keeping the layout balanced. The viewport is 1080x1920 (portrait), so there is ample horizontal space.

**Confidence:** HIGH -- existing layout works well, just adding coin counter.

### Coin Display Style

**Recommendation: HUD-only (no floating coin popups).**

Rationale:
- Coins are score-derived (threshold-based), not per-merge, so there's no natural "moment" to show a floating coin popup
- Floating score popups already handle per-merge feedback
- A HUD coin counter that animates when coins are awarded (similar to score counter punch) provides sufficient feedback
- Keeps the game view uncluttered -- floating popups for score, HUD for coins

**Confidence:** HIGH -- matches the locked decision that coins are threshold-based, not per-merge.

### Score Threshold Awareness for Phase 5 Shop

**Recommendation: Emit a signal now, implement the shop listener in Phase 5.**

Add `signal score_threshold_reached(threshold: int)` to EventBus now. The ScoreManager checks cumulative score against a threshold list after each score update and emits when crossed. Phase 5 connects the shop opening to this signal. This is low-cost and prevents future refactoring.

**Confidence:** HIGH -- forward-compatible signal is trivial to add.

## Standard Stack

### Core (Godot 4.5 built-in)
| Component | Type | Purpose | Why Standard |
|-----------|------|---------|--------------|
| Tween (create_tween()) | Built-in | All UI animations (score roll-up, scale punch, floating popup fade) | Godot 4 standard for procedural animation, no nodes required |
| Resource (.tres) | Built-in | FruitData score_value storage | Already used for fruit tier data, score values live alongside radius/mass |
| Signal (EventBus) | Built-in | Cross-system communication for merge events, score changes | Already established pattern in codebase |
| Label | Built-in | Score display, chain counter, floating popups | Standard Godot UI node |
| Node2D | Built-in | Floating popup container (world-space) | Popups appear at merge position in game world |
| CanvasLayer | Built-in | HUD elements (score, coins, chain counter overlay) | Already used for HUD |

### Supporting
| Component | Type | Purpose | When to Use |
|-----------|------|---------|-------------|
| Timer | Built-in | Chain expiry detection (cascade settling timeout) | Detecting when a chain has ended |
| PackedScene | Built-in | FloatingScore.tscn preloading | Spawning score popups efficiently |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Label for floating popups | RichTextLabel | Heavier, supports BBCode formatting -- overkill for "+16 x3!" |
| Node2D for popup container | CanvasLayer | CanvasLayer requires world-to-screen coordinate conversion; Node2D popups naturally exist in world space |
| Timer for chain expiry | _process delta accumulation | Timer is cleaner, auto-resets, no manual delta tracking |

## Architecture Patterns

### Recommended New Files
```
scripts/
├── components/
│   └── score_manager.gd        # ScoreManager: scoring logic, chain tracking, coin economy
scenes/
├── ui/
│   ├── floating_score.tscn     # FloatingScore: Label scene for world-space popups
│   ├── floating_score.gd       # Animation script for floating popup
│   └── hud.gd                  # Updated: animated score, coin display, chain counter
```

### Pattern 1: ScoreManager as Event-Driven Component
**What:** A single ScoreManager node that listens to EventBus.fruit_merged, calculates score (base * chain multiplier), updates GameManager state, and emits scoring events for UI consumption.
**When to use:** Always -- centralizes all scoring logic in one place.

```gdscript
# scripts/components/score_manager.gd
class_name ScoreManager
extends Node

## Chain tracking
var _chain_count: int = 0
var _chain_active: bool = false

## Accelerating multiplier table (index = chain_count - 1)
const CHAIN_MULTIPLIERS: Array[int] = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89]

## Coin economy
const COIN_THRESHOLD: int = 100
var _coins_awarded: int = 0

## All FruitData resources for score_value lookup
var _fruit_types: Array[FruitData] = []

## Chain expiry timer -- resets on each merge, expires when chain settles
@onready var _chain_timer: Timer = $ChainTimer


func _ready() -> void:
    add_to_group("score_manager")
    _load_fruit_types()
    EventBus.fruit_merged.connect(_on_fruit_merged)
    _chain_timer.one_shot = true
    _chain_timer.wait_time = 1.0  # Tunable: how long after last merge before chain resets
    _chain_timer.timeout.connect(_on_chain_expired)


func _on_fruit_merged(old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
    # Calculate base score from the NEW fruit's tier
    var base_score: int = _get_score_for_tier(new_tier)

    # Track chain
    _chain_count += 1
    _chain_active = true
    _chain_timer.start()  # Reset the expiry timer

    # Calculate multiplier
    var multiplier: int = _get_chain_multiplier(_chain_count)
    var total_score: int = base_score * multiplier

    # Update GameManager
    GameManager.score += total_score

    # Award coins from threshold crossings
    var new_coins: int = GameManager.score / COIN_THRESHOLD - _coins_awarded
    if new_coins > 0:
        _coins_awarded += new_coins
        GameManager.coins += new_coins
        EventBus.coins_awarded.emit(new_coins, GameManager.coins)

    # Emit scoring event for UI
    EventBus.score_awarded.emit(total_score, merge_pos, _chain_count, multiplier)

    # Check score thresholds for future shop triggers
    _check_score_thresholds()


func _on_chain_expired() -> void:
    if _chain_count > 1:
        EventBus.chain_ended.emit(_chain_count)
    _chain_count = 0
    _chain_active = false


func _get_chain_multiplier(chain: int) -> int:
    if chain <= 1:
        return 1
    var idx: int = mini(chain - 1, CHAIN_MULTIPLIERS.size() - 1)
    return CHAIN_MULTIPLIERS[idx]


func _get_score_for_tier(tier: int) -> int:
    if tier >= _fruit_types.size():
        # Watermelon vanish bonus
        return 1000
    return _fruit_types[tier].score_value
```

### Pattern 2: Floating Score Popup (World-Space Label)
**What:** A lightweight Label scene spawned at the merge position in the game world (as a child of a Node2D container, NOT the CanvasLayer HUD). Uses create_tween() to rise and fade.
**When to use:** Every merge event.

```gdscript
# scenes/ui/floating_score.gd
extends Label

func show_score(text_value: String, start_pos: Vector2, is_chain: bool) -> void:
    text = text_value
    global_position = start_pos
    # Offset slightly so it doesn't overlap the merge exactly
    position.x += randf_range(-20.0, 20.0)

    # Set up the tween
    var tween: Tween = create_tween()
    tween.set_parallel(true)

    # Rise upward
    tween.tween_property(self, "position:y", position.y - 80.0, 0.8) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    # Fade out
    tween.tween_property(self, "modulate:a", 0.0, 0.8) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

    # Scale punch for chain merges
    if is_chain:
        tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15) \
            .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.chain().tween_property(self, "scale", Vector2.ONE, 0.3)

    # Clean up when done
    tween.chain().tween_callback(queue_free)
```

### Pattern 3: Animated Score Counter (Tween Roll-Up with Punch)
**What:** When the HUD score updates, use `tween_method` to animate the displayed number from old value to new value, and a brief scale punch on the label.
**When to use:** Every score update in the HUD.

```gdscript
# In hud.gd
var _displayed_score: int = 0

func animate_score_to(new_score: int) -> void:
    var old_score: int = _displayed_score
    _displayed_score = new_score

    var tween: Tween = create_tween()
    # Roll up the number
    tween.tween_method(_set_score_text, old_score, new_score, 0.4) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    # Scale punch on the label
    var score_label: Label = $ScoreLabel
    score_label.pivot_offset = score_label.size / 2.0
    var punch_tween: Tween = create_tween()
    punch_tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    punch_tween.tween_property(score_label, "scale", Vector2.ONE, 0.2)


func _set_score_text(value: int) -> void:
    $ScoreLabel.text = str(value)
```

### Pattern 4: Cascade-Based Chain Detection
**What:** Chains are detected by tagging merge-spawned fruits. When a fruit spawned by a merge triggers another merge before the chain timer expires, the chain count increments. The chain timer resets on each merge and expires when physics settles.
**When to use:** The chain timer approach works because cascade merges are physics-driven -- a merge spawns a new fruit, that fruit contacts another same-tier fruit, triggering a new merge. The time between these events is governed by physics (typically 0.1-0.5s), so a 1.0s timer provides generous settling time.

**Key insight:** The user's locked decision says "no time window, purely physics-driven." This means we should NOT use a time window to determine IF a merge is part of a chain. Instead, we track whether the merge-spawned fruit itself causes the next merge. The timer is only used to detect when the chain has ENDED (no more cascading merges), not to decide chain membership. Every merge that occurs while `_chain_active` is true increments the chain counter. The timer resets on each merge and only fires when physics has settled.

### Anti-Patterns to Avoid
- **Storing score logic in MergeManager:** MergeManager handles merge safety (locking, deactivation, spawning). Score calculation is a separate concern -- keep it in ScoreManager.
- **Floating popups on CanvasLayer:** Popups need to appear at world positions. Adding them to CanvasLayer requires coordinate conversion. Instead, add them as children of a Node2D in the game world.
- **Hardcoding score values in GDScript:** Values must live in `FruitData.score_value` (`.tres` files) for balancing. The only hardcoded values should be the watermelon vanish bonus and the chain multiplier table (which are game rules, not per-fruit data).
- **Using `_process()` for chain tracking:** A Timer node is cleaner and more Godot-idiomatic than manually accumulating delta in `_process()`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tween animations | Custom animation system with _process() | create_tween() | Built-in, handles cleanup, supports chaining/parallel |
| Score data storage | Dictionary or hardcoded values | FruitData Resource (.tres) | Already exists, editor-editable, type-safe |
| Event communication | Direct function calls between systems | EventBus signals | Already established in codebase, decouples systems |
| Timer/timeout | Manual delta accumulation | Timer node | Built-in, one_shot support, signal-based |
| Number formatting | Custom string formatting | str() for integers | Score values are integers, no formatting needed |

**Key insight:** This phase is almost entirely "connect existing pieces with new logic." The codebase already has EventBus, FruitData resources, GameManager, and a HUD. The new code is mostly a ScoreManager that listens and calculates, plus a small floating popup scene.

## Common Pitfalls

### Pitfall 1: Chain Counter Never Resets
**What goes wrong:** Chain count increments forever because the reset condition never triggers.
**Why it happens:** If using a time-based chain window, the timer may be too long (never expires during active play) or the reset logic has a bug.
**How to avoid:** Use a one_shot Timer that restarts on every merge. When it expires, reset the chain counter. Test by dropping a single fruit and verifying the chain resets to 0 after the timer expires (no second merge occurs).
**Warning signs:** Chain multiplier shows "x99" during normal play.

### Pitfall 2: Floating Popups Accumulate and Never Freed
**What goes wrong:** Hundreds of Label nodes pile up because `queue_free()` is never called.
**Why it happens:** The tween callback for cleanup isn't connected, or the tween is killed before it completes.
**How to avoid:** Always use `tween.chain().tween_callback(queue_free)` as the final step. Verify with the Godot debugger's scene tree -- popup nodes should appear and disappear within ~1 second.
**Warning signs:** FPS drops after many merges, scene tree shows growing list of FloatingScore nodes.

### Pitfall 3: Score Label Pivot Not Set for Scale Punch
**What goes wrong:** The score label scales from its top-left corner instead of center, causing it to jump around.
**Why it happens:** Label nodes have `pivot_offset` at (0,0) by default. Scaling without setting pivot makes the label expand rightward and downward.
**How to avoid:** Set `pivot_offset = size / 2.0` before any scale tween. Do this in `_ready()` or before each tween.
**Warning signs:** Score label visually jumps position when scaling.

### Pitfall 4: Double Score on Watermelon Vanish
**What goes wrong:** The watermelon vanish awards both the tier-7 merge score AND the vanish bonus, or awards nothing because `new_tier >= _fruit_types.size()` is not handled.
**Why it happens:** The current MergeManager emits `fruit_merged(old_tier=7, new_tier=8, merge_pos)` for watermelon vanish (line 81). Since there's no tier 8 FruitData, the ScoreManager must handle this case explicitly.
**How to avoid:** In ScoreManager, check `if new_tier >= _fruit_types.size()` and award the flat watermelon bonus (1000). Do NOT also add the tier-7 score_value -- the bonus replaces it.
**Warning signs:** Watermelon merge awards 1128 instead of 1000 (or 0).

### Pitfall 5: Tween on Freed Node
**What goes wrong:** "Cannot call method on previously freed instance" error when a tween tries to update a node that was already freed.
**Why it happens:** If multiple tweens target the same node (e.g., two rapid score updates creating overlapping roll-up tweens), the first tween's `queue_free` kills the node while the second tween is still running.
**How to avoid:** For the score label (which persists), kill previous tweens before starting new ones. For floating popups (which are fire-and-forget), each popup has its own tween and frees itself -- no conflict.
**Warning signs:** Intermittent errors during rapid chain merges.

### Pitfall 6: Chain Timer Starts Before First Merge
**What goes wrong:** Chain count is 1 even for the first merge, making the first merge look like a chain.
**Why it happens:** If `_chain_count` starts at 0 and increments to 1 on first merge, the multiplier lookup returns `CHAIN_MULTIPLIERS[0] = 1` (no multiplier), which is correct. But if the chain counter UI shows "CHAIN x1!" on every single merge, it's visually noisy.
**How to avoid:** Only show chain UI when `_chain_count >= 2`. The multiplier is always 1 for a single merge (no chain), so the math is correct either way -- it's purely a display concern.
**Warning signs:** "CHAIN x1!" appearing on every merge.

## Code Examples

### Example 1: EventBus Signal Additions
```gdscript
# scripts/autoloads/event_bus.gd -- new signals to add
## Emitted when score is awarded from a merge.
signal score_awarded(points: int, position: Vector2, chain_count: int, multiplier: int)

## Emitted when a chain ends (no more cascading merges).
signal chain_ended(chain_length: int)

## Emitted when coins are awarded from score threshold crossing.
signal coins_awarded(new_coins: int, total_coins: int)

## Emitted when cumulative score crosses a threshold (for Phase 5 shop).
signal score_threshold_reached(threshold: int)
```

### Example 2: GameManager Additions
```gdscript
# scripts/autoloads/game_manager.gd -- add coins variable
var coins: int = 0

func reset_game() -> void:
    score = 0
    coins = 0
    change_state(GameState.READY)
```

### Example 3: Floating Popup Spawning
```gdscript
# In ScoreManager or a dedicated popup spawner
var _floating_score_scene: PackedScene = preload("res://scenes/ui/floating_score.tscn")

func _spawn_score_popup(points: int, pos: Vector2, chain: int, multiplier: int) -> void:
    var popup: Label = _floating_score_scene.instantiate()

    # Format text: "+16" for normal, "+64 x3!" for chain
    var text: String = "+%d" % points
    if multiplier > 1:
        text = "+%d x%d!" % [points, multiplier]

    # Add to popup container in world space
    var container: Node = get_tree().get_first_node_in_group("popup_container")
    if container:
        container.add_child(popup)
    else:
        get_parent().add_child(popup)

    popup.show_score(text, pos, multiplier > 1)
```

### Example 4: Chain Counter HUD Display
```gdscript
# In hud.gd -- chain counter that appears during chains
func show_chain(chain_count: int, multiplier: int) -> void:
    if chain_count < 2:
        $ChainLabel.visible = false
        return

    $ChainLabel.visible = true
    $ChainLabel.text = "CHAIN x%d!" % multiplier

    # Punch scale for hype
    $ChainLabel.pivot_offset = $ChainLabel.size / 2.0
    var tween: Tween = create_tween()
    tween.tween_property($ChainLabel, "scale", Vector2(1.3, 1.3), 0.1) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property($ChainLabel, "scale", Vector2.ONE, 0.2)

func hide_chain() -> void:
    $ChainLabel.visible = false
```

### Example 5: Coin Display in HUD
```gdscript
# In hud.gd -- coin counter
func update_coins(total: int) -> void:
    $CoinLabel.text = str(total)

    # Small punch on coin gain
    $CoinLabel.pivot_offset = $CoinLabel.size / 2.0
    var tween: Tween = create_tween()
    tween.tween_property($CoinLabel, "scale", Vector2(1.15, 1.15), 0.1)
    tween.tween_property($CoinLabel, "scale", Vector2.ONE, 0.15)
```

### Example 6: Score Threshold Checking
```gdscript
# In ScoreManager
const SCORE_THRESHOLDS: Array[int] = [500, 1500, 3500, 7000]
var _thresholds_reached: int = 0

func _check_score_thresholds() -> void:
    while _thresholds_reached < SCORE_THRESHOLDS.size() \
            and GameManager.score >= SCORE_THRESHOLDS[_thresholds_reached]:
        EventBus.score_threshold_reached.emit(SCORE_THRESHOLDS[_thresholds_reached])
        _thresholds_reached += 1
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Tween node (Godot 3) | create_tween() procedural (Godot 4) | Godot 4.0 | No Tween child node needed, cleaner chaining API |
| interpolate_property() | tween_property() | Godot 4.0 | Method name change, chained modifiers (.set_trans, .set_ease) |
| yield(tween, "tween_completed") | tween.finished signal or tween_callback() | Godot 4.0 | Use tween_callback(queue_free) instead of yield |
| export var (Godot 3) | @export var (Godot 4) | Godot 4.0 | Annotation-based exports |
| rect_position / rect_size | position / size | Godot 4.0 | Control nodes use position/size directly |
| instance() | instantiate() | Godot 4.0 | Method rename on PackedScene |

**Note:** Many web tutorials still show Godot 3 syntax. The codebase is Godot 4.5 -- always use the current API.

## Open Questions

1. **Chain multiplier table values beyond 10 chains**
   - What we know: The locked decision says accelerating rate (x2, x3, x5, x8...) with no cap
   - What's unclear: Whether the table should follow Fibonacci (2, 3, 5, 8, 13, 21...) or a custom progression, and what happens beyond the table
   - Recommendation: Use Fibonacci-like progression for the first 10 entries, then continue with `previous * 1.618` (golden ratio) for any chain beyond 10. In practice, chains beyond 5-6 are extremely rare in Suika-style games, so the exact values for 10+ barely matter. The table can be tuned later.

2. **Popup container node placement**
   - What we know: Floating popups need to be in world space (Node2D), not CanvasLayer
   - What's unclear: Whether to add a dedicated "PopupContainer" Node2D to game.tscn or reuse FruitContainer
   - Recommendation: Add a new `PopupContainer` (Node2D) to game.tscn with group "popup_container". Keep it separate from FruitContainer to maintain clear separation of concerns.

3. **Chain timer duration tuning**
   - What we know: Cascade merges are physics-driven and happen within ~0.1-0.5s of the previous merge
   - What's unclear: Exact timeout value that correctly detects "chain over" without premature cutoff
   - Recommendation: Start with 1.0 seconds. This is generous enough to handle slow-rolling physics cascades but short enough that a new player drop won't accidentally extend a previous chain. Tune during playtesting.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `merge_manager.gd`, `event_bus.gd`, `game_manager.gd`, `hud.gd`, `fruit.gd`, `fruit_data.gd` -- direct code review of existing architecture
- FruitData `.tres` files -- current score_value fields confirmed (1, 3, 6, 10, 15, 21, 28, 36)
- Godot 4 Tween API -- verified via [official docs](https://docs.godotengine.org/en/stable/classes/class_tween.html) and [gotut.net tutorial](https://www.gotut.net/tweens-in-godot-4/)

### Secondary (MEDIUM confidence)
- [KidsCanCode Floating Combat Text Recipe](https://kidscancode.org/godot_recipes/4.x/ui/floating_text/index.html) -- Godot 3 syntax but pattern is the same
- [Wayline Floating Damage Numbers](https://www.wayline.io/blog/godot-floating-damage-numbers) -- confirmed world-position spawning pattern
- [Godot Forum: Hit-style Tweens](https://forum.godotengine.org/t/hit-style-tweens/92906) -- scale punch pattern verified
- [Suika Game Guide](https://suikagame.fun/en/blog/suika-game-complete-guide-2025) -- confirmed cascade-based chain mechanics in reference game

### Tertiary (LOW confidence)
- Chain multiplier Fibonacci progression -- based on game design intuition, not a specific verified source. The exact values need playtesting.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all Godot 4.5 built-in features, verified via docs and codebase
- Architecture: HIGH -- extends existing patterns (EventBus, GameManager, component nodes), well-understood codebase
- Pitfalls: HIGH -- derived from direct code analysis (watermelon vanish edge case, tween lifecycle)
- Chain tracking: MEDIUM -- the cascade-based approach is sound but the timer duration and multiplier table need playtesting
- Coin economy: MEDIUM -- fixed ratio is a good starting point but the threshold value (100) needs balancing

**Research date:** 2026-02-08
**Valid until:** 2026-03-08 (30 days -- Godot 4.5 is stable, patterns are well-established)
