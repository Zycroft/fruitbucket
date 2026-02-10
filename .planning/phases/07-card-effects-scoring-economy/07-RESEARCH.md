# Phase 7: Card Effects -- Scoring & Economy - Research

**Researched:** 2026-02-09
**Domain:** Score calculation hooks, coin economy modification, chain reaction bonuses, per-merge event processing (Godot 4.5 / GDScript / GL Compatibility)
**Confidence:** HIGH

## Summary

Phase 7 implements six card effects that modify score calculations and coin income. Unlike Phase 6's physics/merge effects, these effects all operate on the **scoring pipeline** -- they intercept the merge event, compute bonus score or coins, and apply them through the existing GameManager and EventBus infrastructure. The core challenge is deciding WHERE in the scoring pipeline to apply these bonuses: inside ScoreManager (which currently owns all score/coin logic), inside CardEffectSystem (which owns all card effect logic), or through a new hook between them.

The current ScoreManager calculates score as `base_score * chain_multiplier`, then derives coins from cumulative score thresholds (1 coin per 100 cumulative score). The six Phase 7 effects modify this pipeline in three ways: (1) Quick Fuse and Fruit Frenzy add **bonus score multipliers** on top of the existing chain multiplier, (2) Big Game Hunter and Pineapple Express add **flat bonus score** for specific conditions, and (3) Golden Touch and Lucky Break add **direct coin awards** independent of the score-to-coin threshold system.

The architectural question is whether to extend ScoreManager with card-awareness or keep all card logic in CardEffectSystem. Based on the Phase 6 precedent (all card logic lives in CardEffectSystem, ScoreManager remains card-unaware), the recommended approach is: **CardEffectSystem listens to the same `fruit_merged` signal as ScoreManager, computes bonus score/coins independently, and applies them directly to GameManager.score/coins.** This keeps ScoreManager unchanged and maintains the clean separation established in Phase 6. The HUD already reacts to GameManager.score changes via the `score_awarded` signal, but bonus score from cards needs its own signal for visual feedback (floating popups with different styling).

**Critical finding:** The Pineapple Express card references "pineapple" but no pineapple fruit tier exists in the game. The current implementation has 8 tiers (Blueberry through Watermelon). The original PROJECT.md mentions an 11-fruit progression including pineapple, but Phase 1 implemented only 8. The card must be mapped to an existing tier. **Recommendation: Map "pineapple" to Pear (tier index 6, display name "tier_7_pear"), as Pear is the second-highest tier and thematically fits the "rare high-tier creation" intent of the card. Alternatively, it could trigger on Watermelon creation (tier index 7), but watermelons already have a 1000-point vanish bonus, making an additional +100 score trivial.** This is an open question requiring user decision.

**Primary recommendation:** Add all six scoring/economy effects to CardEffectSystem as methods triggered by `_on_fruit_merged()`. Add a new EventBus signal `bonus_awarded(text, position, type)` for card-sourced bonus feedback (floating popups). Do NOT modify ScoreManager -- let CardEffectSystem apply bonuses directly to GameManager.score and GameManager.coins.

## Standard Stack

### Core

| System | Version | Purpose | Why Standard |
|--------|---------|---------|--------------|
| CardEffectSystem._on_fruit_merged() | Phase 6 | Hook point for all 6 effects (they all trigger on merge) | Already connected to EventBus.fruit_merged. All Phase 7 effects are merge-triggered. |
| GameManager.score (int) | Phase 2 | Direct score modification for bonus points | Global autoload. CardEffectSystem already accesses it (via CardManager). Direct += is safe. |
| GameManager.coins (int) | Phase 2 | Direct coin modification for bonus coins | Same as score. Direct += is the simplest coin-awarding mechanism. |
| ScoreManager._chain_count | Phase 2 | Read chain state for Quick Fuse and Fruit Frenzy conditions | ScoreManager tracks chain count and timer. CardEffectSystem needs to read (not write) this state. |
| EventBus signals | Phase 1 | Cross-system communication for bonus feedback | Existing pattern. Add new signal for bonus popups. |

### Supporting

| System | Version | Purpose | When to Use |
|--------|---------|---------|-------------|
| FloatingScore popup | Phase 2 | Display bonus score/coin popups at merge position | Reuse existing floating_score.tscn for card bonus popups with different color styling |
| CardSlotDisplay.set_status_text() | Phase 6 | Show effect state on HUD card slots | Could show Golden Touch coin count or Pineapple Express trigger count |
| HUD._on_coins_awarded() | Phase 2 | Update coin display when bonus coins are added | Already reacts to EventBus.coins_awarded signal |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CardEffectSystem applying score directly | Modifying ScoreManager to accept card bonuses | Would couple ScoreManager to card system. Phase 6 established cards as separate. Keep ScoreManager clean. |
| New bonus_awarded signal | Reusing score_awarded signal | score_awarded carries chain_count/multiplier context specific to ScoreManager. Card bonuses need their own signal with different popup styling (e.g., green for coins, purple for card bonuses). |
| Reading ScoreManager._chain_count directly | Adding a public getter | ScoreManager exposes chain_count as private (_chain_count). Add a public accessor or use the group pattern to query it. |

## Architecture Patterns

### Recommended Project Structure

```
scripts/
  components/
    card_effect_system.gd    # MODIFIED: Add 6 scoring/economy effect methods
    score_manager.gd         # MODIFIED: Add public chain_count accessor (read-only)
scenes/
  ui/
    hud.gd                   # MODIFIED: Handle bonus_awarded signal for card bonus popups
    floating_score.gd        # POSSIBLY MODIFIED: Support different popup colors/styles
scripts/
  autoloads/
    event_bus.gd             # MODIFIED: Add bonus_awarded signal
```

### Pattern 1: Merge-Triggered Bonus Calculation (All 6 Effects)

**What:** All Phase 7 effects activate on the `fruit_merged` signal. CardEffectSystem._on_fruit_merged() already dispatches to Cherry Bomb and Bouncy Berry. Add Phase 7 dispatch to the same method.

**When to use:** Every merge event.

**Key insight:** The order of signal handlers matters. ScoreManager connects to `fruit_merged` first (added in Phase 2, connected in _ready). CardEffectSystem connects second (added in Phase 6). Both receive the same signal arguments. ScoreManager computes base score and updates GameManager.score. CardEffectSystem then reads GameManager.score (already updated) and the ScoreManager chain state to compute bonuses.

**However:** Godot signal connection order is determined by connection order, not node order. Since both connect in _ready(), and ScoreManager appears before CardEffectSystem in the scene tree, ScoreManager's handler will fire first. This is correct -- CardEffectSystem can read the already-computed base score.

**Example:**
```gdscript
# In CardEffectSystem._on_fruit_merged() -- add to existing method
func _on_fruit_merged(old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
    # --- Phase 6 effects (existing) ---
    # Cherry Bomb, Bouncy Berry, Heavy Hitter recharge, Wild Fruit selection
    # ... (existing code) ...

    # --- Phase 7 scoring effects ---
    _apply_scoring_effects(old_tier, new_tier, merge_pos)


func _apply_scoring_effects(old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
    var bonus_score: int = 0
    var bonus_coins: int = 0

    # Quick Fuse: +25% score per card if merge within 1s of previous
    # Fruit Frenzy: +2x multiplier per card for chains of 3+
    # Big Game Hunter: +50% score per card for tier 6+ merges (display "tier 7+")
    # Pineapple Express: +100 score, +20 coins when pineapple tier created
    # Golden Touch: +2 coins per card per merge
    # Lucky Break: 15% chance per card for +5 bonus coins

    if bonus_score > 0:
        GameManager.score += bonus_score
        EventBus.bonus_awarded.emit(bonus_score, merge_pos, "score")
    if bonus_coins > 0:
        GameManager.coins += bonus_coins
        EventBus.bonus_awarded.emit(bonus_coins, merge_pos, "coins")
```

### Pattern 2: Reading Chain State from ScoreManager

**What:** Quick Fuse needs to know if the current merge happened within 1 second of the previous merge. Fruit Frenzy needs to know the current chain count. ScoreManager already tracks both via `_chain_count` and `_chain_timer`.

**How to access:** ScoreManager is found via group "score_manager". Access its chain state through a public method.

**Option A (recommended): Add public accessor to ScoreManager:**
```gdscript
# In score_manager.gd
func get_chain_count() -> int:
    return _chain_count

func is_chain_active() -> bool:
    ## Returns true if a merge happened within the chain timer window.
    return not _chain_timer.is_stopped()
```

**Option B: Use signal arguments directly:**
The `score_awarded` signal already emits `chain_count` and `multiplier`. But CardEffectSystem listens to `fruit_merged`, not `score_awarded`. Switching to `score_awarded` would change the effect trigger point.

**Option C: Track chain state independently in CardEffectSystem:**
CardEffectSystem already tracks merge counts for Heavy Hitter recharge and Wild Fruit selection. It could track its own chain timer. This duplicates ScoreManager logic but avoids coupling.

**Recommendation:** Option A -- a simple public accessor is clean, minimal, and avoids state duplication. ScoreManager already has the data; expose it read-only.

### Pattern 3: Bonus Score vs. Base Score Separation

**What:** The base score is calculated by ScoreManager (`base_score * chain_multiplier`). Card bonuses are additive on top. The question is what "base" the percentage bonuses (Quick Fuse +25%, Big Game Hunter +50%) apply to.

**Critical design decision:** Do percentage bonuses apply to:
- (A) The raw `base_score` before chain multiplier?
- (B) The `total_score` after chain multiplier (`base_score * chain_multiplier`)?

**Analysis:**
- Quick Fuse grants "+25% score" for fast merges. If this applies to `total_score` (after chain multiplier), it becomes extremely powerful during chains (a chain x8 merge with Quick Fuse would get +25% of the already-8x-multiplied score).
- If it applies to `base_score` only, the bonus is modest and predictable.

**Recommendation:** Apply percentage bonuses to `base_score` only (before chain multiplier). This keeps bonuses predictable and prevents runaway score inflation when multiple multiplier cards stack with chain multipliers. The bonus is still meaningful -- Quick Fuse adds 25% of the fruit's base score per merge in a chain, which is a steady drip of extra points.

**To get base_score in CardEffectSystem:** Either look up `FruitData.score_value` directly (CardEffectSystem can load fruit types, or compute from tier), or add a public accessor on ScoreManager that returns the last computed base_score.

**Simpler approach:** CardEffectSystem loads the same FruitData array (like ScoreManager does) and reads `score_value` directly from the tier. This avoids depending on ScoreManager's internal calculation.

### Pattern 4: Direct Coin Awards (Golden Touch, Lucky Break)

**What:** Golden Touch adds +2 coins per merge (flat, not threshold-based). Lucky Break has a 15% chance to add +5 coins per merge. These bypass the normal score-to-coin threshold system.

**How coins currently work:** ScoreManager awards coins based on cumulative score: `new_coins = GameManager.score / COIN_THRESHOLD - _coins_awarded`. Every 100 cumulative score = 1 coin. Golden Touch and Lucky Break add coins DIRECTLY, not by adding score.

**Implementation:** Simply `GameManager.coins += bonus_coins` and emit `EventBus.coins_awarded.emit(bonus_coins, GameManager.coins)`. The coins_awarded signal updates the HUD coin display.

**Important:** ScoreManager's `_coins_awarded` counter tracks score-derived coins only. Direct coin additions from cards do NOT need to update this counter (they are independent of the score threshold system). The counter exists only to prevent double-awarding of threshold-based coins.

### Pattern 5: Bonus Popup Visual Feedback

**What:** When a card awards bonus score or coins, display a floating popup at the merge position. These should be visually distinct from normal score popups (different color, possibly different text format).

**Reuse existing FloatingScore:** The floating_score.tscn/gd already supports `show_score(text, position, is_chain)` with gold tinting for chains. Extend it to support a third popup type for card bonuses.

**Example:**
```gdscript
# Option: Add a color parameter to show_score, or a separate method
func show_bonus(text_value: String, start_pos: Vector2, bonus_type: String) -> void:
    text = text_value
    global_position = start_pos + Vector2(randf_range(-20.0, 20.0), -30.0)
    pivot_offset = size / 2.0
    if bonus_type == "coins":
        modulate = Color(0.2, 0.9, 0.3, 1.0)  # Green for coins
    else:
        modulate = Color(0.6, 0.4, 1.0, 1.0)  # Purple for card score bonuses
    # Same rise+fade animation as regular popups
```

### Anti-Patterns to Avoid

- **Modifying ScoreManager to be card-aware:** ScoreManager should remain a pure scoring engine. Card bonuses are applied by CardEffectSystem independently. This maintains the Phase 6 pattern where card logic is isolated.

- **Using score_awarded signal as the trigger for card effects:** This creates a dependency on ScoreManager processing order. Use `fruit_merged` directly -- CardEffectSystem already connects to it.

- **Applying percentage bonuses to post-chain-multiplier totals:** This creates exponential score inflation. Apply percentages to the base score (FruitData.score_value) to keep bonuses linear and predictable.

- **Tracking chain state independently in CardEffectSystem when ScoreManager already has it:** Duplicating the chain timer and counter creates drift risk. Read from ScoreManager via a public accessor instead.

- **Forgetting to emit coins_awarded after direct coin additions:** The HUD only updates the coin display on the coins_awarded signal. If Golden Touch adds coins without emitting this signal, the display will be stale until the next score-threshold coin award.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Chain state tracking | Duplicate timer + counter in CardEffectSystem | ScoreManager.get_chain_count() accessor | ScoreManager already tracks chains. Duplication creates drift risk. |
| Coin display update | Custom HUD update call from CardEffectSystem | EventBus.coins_awarded.emit() | HUD already listens to coins_awarded. Emit the signal and the HUD updates automatically. |
| Floating bonus popup | New scene for card bonus text | Extend existing floating_score.tscn with color parameter | The animation logic (rise, fade, scale punch) is identical. Just add a color option. |
| Base score lookup | Parse score from GameManager.score delta | Load FruitData array and read score_value[tier] | Direct lookup is deterministic. Score delta depends on signal processing order. |
| Random chance for Lucky Break | Custom RNG system | `randf() < probability` | Godot's built-in randf() is sufficient for a 15% check. |

**Key insight:** All six effects are "compute bonus, add to total, emit signal" patterns. None require ongoing state (unlike Heavy Hitter's charges or Wild Fruit's persistent references). Quick Fuse and Fruit Frenzy need to read chain state, but they don't modify it. Golden Touch and Lucky Break are stateless per-merge calculations. Big Game Hunter and Pineapple Express are simple conditional checks. The implementation is fundamentally simpler than Phase 6.

## Common Pitfalls

### Pitfall 1: Quick Fuse Timing vs. Chain Timer Semantics

**What goes wrong:** Quick Fuse is supposed to trigger for "merges within 1 second of previous merge." The chain timer in ScoreManager has a 1.0-second window. But the chain timer restarts on every merge, so ANY merge during an active chain qualifies for Quick Fuse.

**Why it happens:** Quick Fuse's condition ("within 1s of previous merge") is semantically identical to "is part of a chain" (chain_count >= 2). This makes Quick Fuse overlap with Fruit Frenzy (which triggers on chains of 3+).

**How to handle:** Accept the overlap. Quick Fuse triggers for any merge that is part of a chain (chain_count >= 2). Fruit Frenzy triggers for deeper chains (chain_count >= 3). They stack -- a chain of 3 gets BOTH Quick Fuse (+25% per merge in the chain) AND Fruit Frenzy (+2x multiplier). This is intentional: players who own both cards get rewarded for chains. The 1-second timing is already tracked by ScoreManager's chain timer; if the chain is active, the merge qualifies.

**Warning signs:** Quick Fuse never triggers, or triggers on every single merge (including the first merge of a chain, which should NOT qualify since there was no "previous merge within 1s").

### Pitfall 2: Fruit Frenzy Multiplier Stacking with Chain Multiplier

**What goes wrong:** Fruit Frenzy gives "+2x score multiplier for chains of 3+." If this multiplies the already-chain-multiplied score, a chain of 5 with Fruit Frenzy would be `base * 8 (chain) * 2 (frenzy) = 16x`, which may be intentionally strong or accidentally overpowered.

**Why it happens:** Ambiguity in whether "+2x score multiplier" means "double the total" or "add 2 to the chain multiplier."

**How to handle:** Interpret "+2x score multiplier" as a **bonus score equal to 2x the base_score** per card. For a chain of 3+ merge, add `base_score * 2 * frenzy_card_count` as bonus score. This is additive, not multiplicative with the chain multiplier. The chain multiplier already provides exponential scaling; Fruit Frenzy adds a flat bonus proportional to the base score.

Alternatively, if the intent is truly multiplicative (double the total score for that merge), then compute it as `total_score_from_this_merge * frenzy_card_count` added as bonus. This is more dramatic and probably the player's expectation when they read "2x score multiplier." Flag for user decision.

**Warning signs:** Score numbers feel either trivially small (additive interpretation) or wildly large (multiplicative interpretation) during chains.

### Pitfall 3: Pineapple Express Has No Pineapple Tier

**What goes wrong:** The card references "when a pineapple is created" but no pineapple fruit exists in the game. The 8-tier system goes Blueberry -> Grape -> Cherry -> Strawberry -> Orange -> Apple -> Pear -> Watermelon.

**Why it happens:** The original PROJECT.md references an 11-fruit progression including pineapple. Phase 1 implemented only 8 tiers without pineapple.

**How to handle:** Map "pineapple" to an existing high-tier fruit. Options:
1. **Pear (tier index 6, display "tier 7"):** Second-highest tier. Rare enough to be rewarding when triggered. Thematically fits "exotic fruit bonus."
2. **Watermelon (tier index 7, display "tier 8"):** Highest tier, extremely rare. But watermelon merges already award a 1000-point vanish bonus, making +100 score trivial.
3. **Any tier 5+ creation:** Broadens the trigger to make the card more useful but dilutes the "special moment" feel.

**Recommendation:** Pear (tier index 6). This is the highest tier that produces a new fruit (watermelon merges vanish), making the trigger feel like a real achievement. The +20 coins and +100 score are meaningful additions to a merge that already awards 64 base points.

**This requires user decision.** Flag as open question.

### Pitfall 4: Lucky Break Coin Popup Spam

**What goes wrong:** Lucky Break triggers on 15% of merges. During a fast chain of 10 merges, 1-2 Lucky Break popups overlap with the regular score popups, creating visual noise.

**Why it happens:** Each merge spawns a score popup (from ScoreManager via HUD) AND potentially a coin popup (from Lucky Break via CardEffectSystem). Both appear at the merge position.

**How to avoid:** Offset bonus popups slightly (e.g., +30px Y offset from merge position) and use a distinct color (green for coins). The floating_score.gd already adds random X offset (-20 to +20px). Adding a vertical offset for bonus popups creates visual separation.

**Warning signs:** Popups stack on top of each other and become unreadable during chains.

### Pitfall 5: Signal Processing Order for Score Bonuses

**What goes wrong:** CardEffectSystem computes Quick Fuse bonus as "+25% of base_score." But if CardEffectSystem's handler fires BEFORE ScoreManager, the base score has not been awarded yet and reading GameManager.score to derive the base would give stale data.

**Why it happens:** Signal handler execution order depends on connection order. Both systems connect in _ready(). Node initialization order in the scene tree is top-to-bottom.

**How to avoid:** Do NOT rely on reading GameManager.score to compute base_score. Instead, load the FruitData array in CardEffectSystem and look up `score_value` directly from the tier index. This is deterministic regardless of signal processing order.

**Warning signs:** Bonus calculations produce wrong values, or zero values when they should be positive.

### Pitfall 6: Big Game Hunter "Tier 7+" Indexing Confusion

**What goes wrong:** The card says "tier 7+" but tier_7_pear.tres has `tier = 6` in code (0-indexed). Developer implements `old_tier >= 7` which only catches Watermelon (tier=7), missing Pear entirely.

**Why it happens:** Same indexing confusion as Cherry Bomb in Phase 6. Display names use 1-indexed tiers ("tier 7" = Pear), code uses 0-indexed.

**How to avoid:** Use a named constant. "Tier 7+" in display terms means tier index >= 6 in code (Pear=6, Watermelon=7). Specifically, Big Game Hunter should trigger when `new_tier >= 6` (the created tier is Pear or Watermelon) OR when `old_tier >= 6` (the tier being consumed is Pear or Watermelon). The natural trigger is `new_tier >= 6` since the bonus rewards creating high-tier fruits.

Wait -- actually, the bonus should apply to the SCORE of the merge. The merge creates `new_tier`. Big Game Hunter gives "+50% score for tier 7+ merges" -- "tier 7+" means the result of the merge is tier 7 or higher in display terms, i.e., `new_tier >= 6` in code. Constant: `const BIG_GAME_MIN_TIER: int = 6`.

**Warning signs:** Big Game Hunter never triggers, or triggers on mid-tier merges.

## Code Examples

### Quick Fuse: Chain-Timing Score Bonus

```gdscript
# In CardEffectSystem
const QUICK_FUSE_BONUS: float = 0.25  # +25% per card

func _apply_quick_fuse(new_tier: int, merge_pos: Vector2) -> int:
    var count: int = _count_active("quick_fuse")
    if count <= 0:
        return 0
    var sm: ScoreManager = get_tree().get_first_node_in_group("score_manager")
    if not sm or sm.get_chain_count() < 2:
        return 0  # Not in a chain -- first merge doesn't qualify
    var base_score: int = _get_base_score(new_tier)
    var bonus: int = int(base_score * QUICK_FUSE_BONUS * count)
    return bonus
```

### Fruit Frenzy: Deep Chain Multiplier

```gdscript
const FRUIT_FRENZY_MULTIPLIER: float = 2.0  # +2x base score per card for chains of 3+
const FRUIT_FRENZY_MIN_CHAIN: int = 3

func _apply_fruit_frenzy(new_tier: int, merge_pos: Vector2) -> int:
    var count: int = _count_active("fruit_frenzy")
    if count <= 0:
        return 0
    var sm: ScoreManager = get_tree().get_first_node_in_group("score_manager")
    if not sm or sm.get_chain_count() < FRUIT_FRENZY_MIN_CHAIN:
        return 0
    var base_score: int = _get_base_score(new_tier)
    var bonus: int = int(base_score * FRUIT_FRENZY_MULTIPLIER * count)
    return bonus
```

### Big Game Hunter: High-Tier Score Bonus

```gdscript
const BIG_GAME_BONUS: float = 0.5  # +50% score per card
const BIG_GAME_MIN_TIER: int = 6   # Code tier index 6 = display "tier 7" (Pear)

func _apply_big_game_hunter(new_tier: int, merge_pos: Vector2) -> int:
    var count: int = _count_active("big_game_hunter")
    if count <= 0:
        return 0
    if new_tier < BIG_GAME_MIN_TIER:
        return 0
    var base_score: int = _get_base_score(new_tier)
    var bonus: int = int(base_score * BIG_GAME_BONUS * count)
    return bonus
```

### Golden Touch: Flat Coin Bonus Per Merge

```gdscript
const GOLDEN_TOUCH_COINS: int = 2  # +2 coins per card per merge

func _apply_golden_touch() -> int:
    var count: int = _count_active("golden_touch")
    if count <= 0:
        return 0
    return GOLDEN_TOUCH_COINS * count
```

### Lucky Break: Probabilistic Coin Drop

```gdscript
const LUCKY_BREAK_CHANCE: float = 0.15  # 15% per card
const LUCKY_BREAK_COINS: int = 5

func _apply_lucky_break() -> int:
    var count: int = _count_active("lucky_break")
    if count <= 0:
        return 0
    # Each card gives an independent 15% chance.
    # With 2 cards: 1 - (1 - 0.15)^2 = 27.75% total chance.
    var total_coins: int = 0
    for i in count:
        if randf() < LUCKY_BREAK_CHANCE:
            total_coins += LUCKY_BREAK_COINS
    return total_coins
```

### Pineapple Express: Conditional Tier Bonus

```gdscript
const PINEAPPLE_TIER: int = 6       # Pear = code tier 6 (mapped from "pineapple")
const PINEAPPLE_BONUS_SCORE: int = 100
const PINEAPPLE_BONUS_COINS: int = 20

func _apply_pineapple_express(new_tier: int) -> Dictionary:
    var count: int = _count_active("pineapple_express")
    if count <= 0:
        return {"score": 0, "coins": 0}
    if new_tier != PINEAPPLE_TIER:
        return {"score": 0, "coins": 0}
    return {
        "score": PINEAPPLE_BONUS_SCORE * count,
        "coins": PINEAPPLE_BONUS_COINS * count,
    }
```

### Dispatch Pattern: Apply All Scoring Effects

```gdscript
func _apply_scoring_effects(old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
    var bonus_score: int = 0
    var bonus_coins: int = 0

    bonus_score += _apply_quick_fuse(new_tier, merge_pos)
    bonus_score += _apply_fruit_frenzy(new_tier, merge_pos)
    bonus_score += _apply_big_game_hunter(new_tier, merge_pos)

    bonus_coins += _apply_golden_touch()
    bonus_coins += _apply_lucky_break()

    var pineapple: Dictionary = _apply_pineapple_express(new_tier)
    bonus_score += pineapple["score"]
    bonus_coins += pineapple["coins"]

    if bonus_score > 0:
        GameManager.score += bonus_score
        EventBus.bonus_awarded.emit(bonus_score, merge_pos, "score")

    if bonus_coins > 0:
        GameManager.coins += bonus_coins
        EventBus.coins_awarded.emit(bonus_coins, GameManager.coins)
```

### FruitData Lookup Helper

```gdscript
# In CardEffectSystem -- load fruit types for base score lookup
var _fruit_types: Array[FruitData] = []

func _load_fruit_types() -> void:
    var paths: Array[String] = [
        "res://resources/fruit_data/tier_1_blueberry.tres",
        "res://resources/fruit_data/tier_2_grape.tres",
        "res://resources/fruit_data/tier_3_cherry.tres",
        "res://resources/fruit_data/tier_4_strawberry.tres",
        "res://resources/fruit_data/tier_5_orange.tres",
        "res://resources/fruit_data/tier_6_apple.tres",
        "res://resources/fruit_data/tier_7_pear.tres",
        "res://resources/fruit_data/tier_8_watermelon.tres",
    ]
    for path in paths:
        var data: FruitData = load(path) as FruitData
        if data:
            _fruit_types.append(data)

func _get_base_score(new_tier: int) -> int:
    if new_tier >= _fruit_types.size():
        return 1000  # Watermelon vanish bonus (ScoreManager.WATERMELON_VANISH_BONUS)
    return _fruit_types[new_tier].score_value
```

### ScoreManager Public Accessor

```gdscript
# Add to score_manager.gd
func get_chain_count() -> int:
    ## Public read-only accessor for current chain count.
    ## Used by CardEffectSystem for Quick Fuse and Fruit Frenzy.
    return _chain_count
```

## Tier Reference

For clarity in implementation, the complete tier mapping:

| Display Name | File Name | Code Tier Index | Score Value | Droppable |
|-------------|-----------|-----------------|-------------|-----------|
| Blueberry | tier_1_blueberry.tres | 0 | 1 | Yes |
| Grape | tier_2_grape.tres | 1 | 2 | Yes |
| Cherry | tier_3_cherry.tres | 2 | 4 | Yes |
| Strawberry | tier_4_strawberry.tres | 3 | 8 | Yes |
| Orange | tier_5_orange.tres | 4 | 16 | Yes |
| Apple | tier_6_apple.tres | 5 | 32 | No |
| Pear | tier_7_pear.tres | 6 | 64 | No |
| Watermelon | tier_8_watermelon.tres | 7 | 128 | No |
| (Vanish) | N/A | 8 (new_tier = size) | 1000 (flat) | N/A |

**Key mappings for Phase 7 cards:**
- Big Game Hunter "tier 7+" = code tier index >= 6 (Pear + Watermelon creation)
- Pineapple Express "pineapple" = NEEDS DECISION (recommended: Pear, code tier 6)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| All score logic in ScoreManager | ScoreManager for base score, CardEffectSystem for bonuses | Phase 7 (new) | Card bonuses are additive and independent. ScoreManager remains unchanged. |
| Coins only from score thresholds | Score thresholds + direct card awards | Phase 7 (new) | Golden Touch and Lucky Break bypass the 100-score-per-coin threshold system. |
| Single popup color (white/gold) | Multiple popup colors (white=normal, gold=chain, green=coins, purple=card bonus) | Phase 7 (new) | Players can distinguish the source of score/coin awards at a glance. |

**Deprecated/outdated:**
- Nothing deprecated. All systems being extended are stable from Phase 2 (ScoreManager, EventBus, HUD, FloatingScore) and Phase 6 (CardEffectSystem).

## Open Questions

1. **What tier should "pineapple" map to for Pineapple Express?**
   - What we know: No pineapple tier exists. 8-tier system ends at Watermelon. Card says "when a pineapple is created."
   - What's unclear: Which existing tier the card should trigger on.
   - Options: (A) Pear (tier index 6) -- second-highest, rare, produces a new fruit. (B) Watermelon (tier index 7) -- rarest, but already has 1000-point vanish bonus making +100 trivial. (C) Reword the card to trigger on a different condition.
   - Recommendation: Pear (tier index 6). The card description could be updated to "When a pear is created" or kept as "pineapple" if flavor text is preferred over accuracy.

2. **Should Fruit Frenzy "+2x score multiplier" be additive or multiplicative?**
   - What we know: The requirement says "+2x score multiplier for chains of 3+".
   - What's unclear: Is this 2x the base_score (additive bonus) or 2x the total_score (multiplicative on top of chain multiplier)?
   - Option A (additive): `bonus = base_score * 2 * card_count`. Moderate, predictable bonus.
   - Option B (multiplicative): `bonus = total_score_for_this_merge * card_count`. Very powerful during long chains.
   - Recommendation: Multiplicative -- the card is called "Frenzy" and "+2x multiplier" reads as "double your score for this merge." The chain multiplier already makes chains rewarding; Fruit Frenzy should make them *exciting*. With 1 card and a chain of 5 (chain multiplier x8): `base * 8 + base * 8 * 2 = base * 24`. With 2 cards: `base * 8 + base * 8 * 4 = base * 40`. This feels dramatic but bounded by chain length (which is skill-dependent).

   **Actually, re-reading:** The existing ScoreManager calculates `total_score = base_score * chain_multiplier` and emits it via `score_awarded`. CardEffectSystem does NOT have access to `total_score` from the current merge unless it recomputes it or reads from the signal. To make Fruit Frenzy truly multiplicative, CardEffectSystem would need to know the chain multiplier. ScoreManager could expose this via the public accessor, or CardEffectSystem could replicate the lookup from `CHAIN_MULTIPLIERS[chain_count - 1]`.

   Simplest approach: Add `get_chain_multiplier() -> int` to ScoreManager. Then Fruit Frenzy bonus = `total_score * FRENZY_MULTIPLIER * card_count` where `total_score = base_score * chain_multiplier`.

3. **Should Lucky Break's 15% stack independently per card or increase the probability?**
   - What we know: Requirement says "15% chance any merge drops bonus 5 coins."
   - Options: (A) Each card rolls independently: 2 cards = 1 - (0.85)^2 = 27.75% chance of at least one trigger, small chance of double trigger (10 coins). (B) Additive: 2 cards = 30% chance of one trigger (5 coins).
   - Recommendation: Independent rolls (Option A). This matches the Phase 6 pattern of "duplicate cards stack linearly" and creates fun moments where double Lucky Break triggers. The expected value scales linearly: 1 card = 0.75 coins/merge, 2 cards = 1.5 coins/merge.

## Sources

### Primary (HIGH confidence)
- Existing codebase analysis:
  - `scripts/components/score_manager.gd` -- chain tracking, base score calculation, coin threshold system, CHAIN_MULTIPLIERS array, WATERMELON_VANISH_BONUS
  - `scripts/components/card_effect_system.gd` -- existing effect dispatch pattern, _count_active() helper, signal connections, _on_fruit_merged() structure
  - `scripts/autoloads/event_bus.gd` -- signal signatures (fruit_merged, score_awarded, coins_awarded)
  - `scripts/autoloads/game_manager.gd` -- score/coins as direct integer properties
  - `resources/fruit_data/*.tres` -- tier indices and score_value for all 8 tiers
  - `resources/card_data/*.tres` -- all 6 Phase 7 card definitions (card_id, description, rarity, base_price)
  - `scenes/ui/hud.gd` -- score_awarded and coins_awarded handlers, floating popup spawning
  - `scenes/ui/floating_score.gd` -- popup animation pattern, show_score() API
  - `.planning/phases/06-card-effects-physics-merge/06-RESEARCH.md` -- established CardEffectSystem architecture patterns

### Secondary (MEDIUM confidence)
- Phase 6 implementation analysis -- the CardEffectSystem pattern is proven and working. Phase 7 follows the same architecture (all effects in CardEffectSystem, triggered by fruit_merged signal).
- Phase 2 implementation analysis -- ScoreManager's chain tracking and coin threshold system are stable and well-documented.

### Tertiary (LOW confidence)
- Tuning values for Lucky Break probability (15%), Quick Fuse bonus (25%), Fruit Frenzy multiplier (2x), Big Game Hunter bonus (50%) are from the requirements. Whether these create balanced gameplay needs playtesting.
- The "pineapple = pear" mapping is a recommendation, not confirmed by the user.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All systems are existing Godot 4.5 components already used in the codebase (GameManager, EventBus, ScoreManager, CardEffectSystem). No new libraries or tools needed.
- Architecture: HIGH -- Follows the established CardEffectSystem pattern from Phase 6. All effects are merge-triggered, stateless (no persistent state like Heavy Hitter charges), and compute bonuses from existing data.
- Effect implementation: HIGH -- Each effect is a simple conditional check + arithmetic. Quick Fuse and Fruit Frenzy read chain state; Big Game Hunter and Pineapple Express check tier; Golden Touch is flat per-merge; Lucky Break is a random roll. All are trivially implementable.
- Visual feedback: MEDIUM -- Extending floating_score.gd for colored bonus popups is straightforward, but the exact visual design (colors, text format, positioning offsets) needs iteration.
- Tuning/balance: LOW -- Score multiplier values and coin amounts are from requirements but untested. Fruit Frenzy in particular could be wildly overpowered or underwhelming depending on additive vs. multiplicative interpretation.

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (stable Godot features and established project patterns)
