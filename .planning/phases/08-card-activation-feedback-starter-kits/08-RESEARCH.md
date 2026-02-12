# Phase 8: Card Activation Feedback & Starter Kits - Research

**Researched:** 2026-02-12
**Domain:** Godot 4.5 UI animation, tween-based feedback, run statistics tracking, full-screen overlay UI
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Card trigger animation:** Glow + scale bounce combo on the HUD card slot when its effect fires. Glow color matches card rarity: Common=white, Uncommon=green, Rare=purple. No additional text near the card slot -- existing on-screen bonus popups are sufficient. All 10 existing card effects (Phases 6-7) get trigger feedback wired up.
- **Trigger frequency handling:** Claude's discretion on dampening rapid re-triggers (e.g. Golden Touch fires every merge).
- **Simultaneous triggers:** Staggered animation with ~0.15s delay between cards when multiple trigger on the same merge. Player can visually track which cards fired in sequence.
- **Charge vs passive cards:** Charge-based cards (e.g. Heavy Hitter) get a more prominent animation than passive/always-on cards. Claude's discretion on the exact differentiation.
- **Starter kit selection:** 2 themed kits + 1 "Surprise" random option (not 3 themed kits). Each kit gives 1 card (same as current starter pick slot count). Replaces current starter pick overlay -- same full-screen layout, but options labeled as kits. Kit name visible, specific card hidden -- player discovers what's inside after choosing. Themed kits are Physics Kit and Score Kit; Surprise gives a random card from any category.
- **Run summary screen:** Celebratory reveal style -- stats animate in one by one with small fanfare. 7 stats displayed: biggest chain, highest tier reached (with visual fruit circle + name), total merges, cards used during run, total coins earned, time played, final score. Two actions: "Play Again" (restart) and "Quit" (reload/close).

### Claude's Discretion
- Frequency dampening approach for rapid card triggers
- Whether to add a subtle visual link (matching rarity color) between HUD glow and on-screen effect
- Exact charge-card animation differentiation
- Stats reveal order and animation timing
- What "Quit" does (no main menu exists -- likely page reload for web)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

## Summary

Phase 8 is pure polish and presentation with no new game mechanics. It divides into three independent feature areas: (1) card activation feedback -- making all 10 existing card effects visually announce themselves in the HUD when they trigger, (2) starter kit selection -- replacing the current random-3-card-pick with 2 themed kits + 1 surprise option, and (3) a celebratory run summary screen at game over.

The codebase is well-structured for all three features. Card trigger feedback requires a new signal (`card_effect_triggered`) on EventBus that CardEffectSystem emits at each trigger point, and a new animation method on CardSlotDisplay that the HUD orchestrates with staggered timing. Starter kits require modifying `CardManager.generate_starter_offers()` and the `starter_pick.gd` UI to present kit choices instead of individual cards. The run summary requires a new CanvasLayer overlay scene (following the CardShop/StarterPick/PauseMenu pattern) plus a new `RunStatsTracker` component to accumulate stats that aren't currently tracked (biggest chain, highest tier reached, total merges, time played).

**Primary recommendation:** Implement in two plans -- Plan 1 covers card trigger feedback (the most code-touching feature, modifying CardEffectSystem + CardSlotDisplay + HUD), Plan 2 covers starter kits and run summary screen (both are self-contained UI features).

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Godot 4.5 | 4.5-stable | Game engine | Already in use |
| GDScript | 4.5 | All scripting | Project convention |
| Tween API | Built-in | All UI animations | Already used extensively in HUD, floating_score, card_shop |
| CanvasLayer | Built-in | Overlay screens | Established pattern for HUD (no layer), PauseMenu (10), CardShop/StarterPick (11) |
| StyleBoxFlat | Built-in | Card glow borders | Already used in CardSlotDisplay for rarity-colored borders |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| Timer | Built-in | Run timer tracking | For time_played stat (ScoreManager already uses Timer for chain timing) |
| Node2D _draw() | Built-in | Fruit circle in run summary | FaceRenderer already uses this pattern for fruit faces |
| ColorRect | Built-in | Full-screen overlays | Already used in StarterPick and CardShop overlays |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Tween glow on StyleBoxFlat | Shader-based glow | Shaders are overkill for a border color+alpha animation; Tween is simpler and matches existing patterns |
| New RunStatsTracker node | Extending ScoreManager | ScoreManager already tracks chains but not all stats; separate node is cleaner and matches component pattern |

## Architecture Patterns

### Recommended New File Structure
```
scripts/components/
    run_stats_tracker.gd       # NEW: Tracks biggest_chain, highest_tier, total_merges, time_played
scenes/ui/
    run_summary.tscn           # NEW: Full-screen overlay (CanvasLayer layer 11)
    run_summary.gd             # NEW: Animates stats reveal, handles Play Again / Quit
scripts/autoloads/
    event_bus.gd               # MODIFIED: Add card_effect_triggered signal
scripts/components/
    card_effect_system.gd      # MODIFIED: Emit trigger signals at each effect point
scenes/ui/
    card_slot_display.gd       # MODIFIED: Add play_trigger_animation() method
    hud.gd                     # MODIFIED: Listen for triggers, orchestrate staggered animations
    starter_pick.gd            # MODIFIED: Show kits instead of individual cards
scripts/autoloads/
    card_manager.gd            # MODIFIED: Add generate_kit_offers() or modify generate_starter_offers()
```

### Pattern 1: Card Trigger Signal Architecture

**What:** A new EventBus signal carries the card_id that just triggered, allowing HUD to find the correct slot and animate it.

**When to use:** Every time a card effect fires in CardEffectSystem.

**Design:**
```gdscript
# event_bus.gd - new signal
signal card_effect_triggered(card_id: String)

# card_effect_system.gd - emit at each trigger point
# Example: Cherry Bomb triggers
if cherry_count > 0 and old_tier == CHERRY_TIER:
    _apply_cherry_bomb(merge_pos, cherry_count)
    EventBus.card_effect_triggered.emit("cherry_bomb")

# Example: Golden Touch triggers (every merge)
func _apply_golden_touch() -> int:
    var count: int = _count_active("golden_touch")
    if count <= 0:
        return 0
    EventBus.card_effect_triggered.emit("golden_touch")
    return GOLDEN_TOUCH_COINS * count
```

**Key insight:** The signal must be emitted AFTER confirming the effect actually triggers (count > 0, conditions met), not just when the check runs.

### Pattern 2: Staggered Animation Queue

**What:** HUD collects trigger signals within a merge frame and plays animations with 0.15s stagger.

**When to use:** When multiple cards trigger on the same merge event (e.g., Golden Touch + Quick Fuse both fire).

**Design:**
```gdscript
# hud.gd - staggered animation
var _trigger_queue: Array[String] = []
var _trigger_timer: float = 0.0
const TRIGGER_STAGGER: float = 0.15

func _on_card_effect_triggered(card_id: String) -> void:
    _trigger_queue.append(card_id)
    if _trigger_queue.size() == 1:
        _play_next_trigger()

func _play_next_trigger() -> void:
    if _trigger_queue.is_empty():
        return
    var card_id: String = _trigger_queue.pop_front()
    _animate_card_slot(card_id)
    if not _trigger_queue.is_empty():
        get_tree().create_timer(TRIGGER_STAGGER).timeout.connect(_play_next_trigger)
```

### Pattern 3: Card Glow + Bounce Animation on CardSlotDisplay

**What:** Temporary border color intensification + scale bounce on the PanelContainer.

**When to use:** When the HUD dispatches a trigger animation to a specific card slot.

**Design:**
```gdscript
# card_slot_display.gd - new method
const TRIGGER_GLOW_COLORS: Dictionary = {
    CardData.Rarity.COMMON: Color(1.0, 1.0, 1.0, 1.0),      # White
    CardData.Rarity.UNCOMMON: Color(0.2, 0.9, 0.3, 1.0),     # Green
    CardData.Rarity.RARE: Color(0.7, 0.4, 1.0, 1.0),         # Purple
}

var _current_card: CardData = null  # Needs to store reference for rarity lookup

func play_trigger_animation(is_charge: bool = false) -> void:
    if _current_card == null:
        return
    var glow_color: Color = TRIGGER_GLOW_COLORS.get(_current_card.rarity, Color.WHITE)
    var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()

    # Animate border color: rarity base -> bright glow -> back to rarity base
    var bounce_scale: float = 1.15 if not is_charge else 1.25
    var glow_duration: float = 0.3 if not is_charge else 0.5

    pivot_offset = size / 2.0
    var tween: Tween = create_tween()
    tween.set_parallel(true)

    # Scale bounce
    tween.tween_property(self, "scale", Vector2(bounce_scale, bounce_scale), 0.1)\
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    # Border glow (brighten + widen)
    style.border_color = glow_color
    style.border_width_left = 5
    # ... etc
    add_theme_stylebox_override("panel", style)

    tween.set_parallel(false)
    tween.tween_property(self, "scale", Vector2.ONE, 0.2)
    tween.tween_callback(_restore_normal_border)
```

### Pattern 4: Overlay Screen (established project pattern)

**What:** Full-screen CanvasLayer with ColorRect backdrop, VBoxContainer content, process_mode ALWAYS.

**When to use:** Run summary screen (same pattern as PauseMenu, CardShop, StarterPick).

**Key properties:**
- CanvasLayer layer = 11 (same as CardShop/StarterPick)
- process_mode = PROCESS_MODE_ALWAYS (functions during tree pause)
- ColorRect background with Color(0, 0, 0, 0.7) and mouse_filter = STOP
- VBoxContainer for content, mouse_filter = IGNORE
- visible = false by default, shown via EventBus signal

### Pattern 5: Kit-Based Starter Selection

**What:** Replace 3 random card picks with 2 themed kits + 1 surprise option.

**Kit card pools (from codebase analysis):**
```
Physics Kit cards: bouncy_berry, cherry_bomb, heavy_hitter, wild_fruit
Score Kit cards: quick_fuse, fruit_frenzy, big_game_hunter, pineapple_express

Common (rarity 0): bouncy_berry, cherry_bomb, fruit_frenzy, golden_touch, quick_fuse
Uncommon (rarity 1): big_game_hunter, heavy_hitter, lucky_break, pineapple_express
Rare (rarity 2): wild_fruit
```

**Design:** Each kit picks 1 random card from its pool. Physics Kit picks from [bouncy_berry, cherry_bomb, heavy_hitter, wild_fruit]. Score Kit picks from [quick_fuse, fruit_frenzy, big_game_hunter, pineapple_express]. Surprise picks from the full pool.

### Anti-Patterns to Avoid
- **Polling for card triggers in _process():** Never poll; use signal-driven architecture matching existing EventBus pattern.
- **Animating shared StyleBoxFlat resources:** Always `.duplicate()` before modifying, matching existing `display_card()` pattern in CardSlotDisplay.
- **Storing stats in GameManager:** GameManager only owns score and coins. Keep run stats in a dedicated component (matches component pattern).
- **Blocking game over with summary screen:** GAME_OVER state does NOT pause the tree (fruits settle naturally, per decision [04-01]). Show summary screen after a brief delay to let fruits settle, then pause.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Timer for run duration | Manual delta accumulation | Godot Timer node or OS.get_ticks_msec() delta | Cleaner, pause-aware with appropriate process_mode |
| Card trigger cooldown/dampening | Custom frame-counting | Tween.is_running() check on the slot's current tween | If tween is still playing, skip re-trigger or queue -- already built into Tween API |
| Staggered animation timing | Manual timer management | create_timer().timeout.connect() chain | Matches existing cooldown pattern in DropController |
| Fruit circle rendering in summary | Sprite texture loading + scaling | FaceRenderer pattern (Node2D _draw()) | Already proven for HUD preview; scales perfectly at any size |

**Key insight:** Every animation pattern needed already exists in the codebase (scale punch in HUD, border color in CardSlotDisplay, overlay screens in CardShop/StarterPick). No novel animation techniques required.

## Common Pitfalls

### Pitfall 1: Trigger Feedback on Tree-Paused Signals
**What goes wrong:** CardEffectSystem is a game scene node (PROCESS_MODE_PAUSABLE). If a card effect triggers right before tree pause (e.g., merge at shop threshold), the HUD animation might not play.
**Why it happens:** HUD is a CanvasLayer with no explicit process_mode set (defaults to INHERIT = PAUSABLE). Tweens on paused nodes don't advance.
**How to avoid:** Card trigger animations should be on a CanvasLayer node (HUD already is one). Tweens on CanvasLayer children should work fine as long as HUD process_mode is not explicitly set to ALWAYS. Since game pauses AFTER signal emission (GameManager emits state change, THEN pauses tree), the signal handlers fire before pause. The tween will be created while unpaused. During pause, the tween freezes -- this is actually fine since the animation will complete when unpaused. Non-issue unless rapid shop openings interrupt animations.
**Warning signs:** Card glow animation freezing mid-way when shop opens. Solution: kill active trigger tweens on shop open.

### Pitfall 2: Multiple Identical Cards Triggering Stagger
**What goes wrong:** Player has 2x Golden Touch cards. Each merge emits `card_effect_triggered("golden_touch")` once (both cards are counted in a single `_count_active()` call), but the player sees only one glow.
**Why it happens:** The effect system applies stacked cards as a single calculation, not per-card-slot.
**How to avoid:** For trigger feedback purposes, emit one signal per effect trigger (not per card copy). The animation should play on ALL slots that hold the same card_id. HUD should find all matching slots and stagger-animate them together.
**Warning signs:** Only one of two duplicate card slots glowing.

### Pitfall 3: ScoreManager Chain vs RunStatsTracker Chain
**What goes wrong:** ScoreManager._chain_count resets to 0 when chain_timer expires. If RunStatsTracker reads it at the wrong time, biggest_chain is always 0 or 1.
**Why it happens:** chain_ended signal carries the completed chain length, but by the time it fires, _chain_count is about to reset.
**How to avoid:** RunStatsTracker should listen to `EventBus.chain_ended(chain_length)` which carries the chain length at emission time, and track `biggest_chain = maxi(biggest_chain, chain_length)`.
**Warning signs:** Run summary always showing "Biggest Chain: 1" or 0.

### Pitfall 4: Game Over -> Run Summary Timing
**What goes wrong:** Showing the run summary immediately on game_over_triggered causes it to appear while fruits are still settling.
**Why it happens:** GAME_OVER state intentionally does NOT pause the tree so fruits settle naturally.
**How to avoid:** Add a 2-3 second delay after game_over_triggered before showing the run summary overlay. Use create_timer() with process_mode ALWAYS so it fires even if we later decide to pause.
**Warning signs:** Summary screen appearing over still-moving fruits.

### Pitfall 5: Rapid Trigger Dampening for Golden Touch
**What goes wrong:** Golden Touch fires on every merge. During a 5-merge chain happening in quick succession, the card slot rapidly flashes 5 times, becoming a visual strobe.
**Why it happens:** No dampening -- signal fires, animation plays immediately.
**How to avoid:** **Recommended dampening approach:** If a trigger tween is already running on a slot, skip queueing another animation for the same card_id. The existing glow persists for 0.3-0.5s, which naturally dampens triggers faster than ~2 per second. This means during rapid chains, the card stays glowing continuously rather than strobing.
**Warning signs:** Card slot flickering/strobing during chain reactions.

### Pitfall 6: CardSlotDisplay Needs Card Reference for Rarity Lookup
**What goes wrong:** `play_trigger_animation()` needs to know the card's rarity for glow color, but CardSlotDisplay currently doesn't store a reference to the displayed CardData.
**Why it happens:** `display_card()` reads card properties but doesn't save the CardData reference.
**How to avoid:** Add `var _current_card: CardData = null` to CardSlotDisplay, set it in `display_card()`, clear it in `display_empty()`.
**Warning signs:** Glow color always defaulting to white because rarity is unknown.

### Pitfall 7: Starter Pick Kit Offers vs Signal Compatibility
**What goes wrong:** Current `starter_pick_requested` signal passes `offers: Array` of CardData. Kits don't map 1:1 to individual cards.
**Why it happens:** The existing signal/UI was built for "pick a visible card."
**How to avoid:** Two approaches: (a) Change the signal to pass kit data (kit name, description) instead of cards, or (b) pass a different data structure. Recommend approach (a): create a simple Dictionary or Resource for kit definitions, change the starter_pick UI to display kits with names/descriptions instead of card details, and resolve the actual card only after selection.
**Warning signs:** StarterPick UI showing card details instead of kit names.

## Code Examples

### Trigger Signal Emission Points (all 10 cards)

Based on codebase analysis, here are the exact locations where each card effect activates in `card_effect_system.gd`. Each needs a `card_effect_triggered` signal emission:

```gdscript
# 1. Cherry Bomb -- _on_fruit_merged, line ~126-127
# Triggers: When old_tier == CHERRY_TIER (tier 2 merge)
# Type: Conditional (not every merge)
if cherry_count > 0 and old_tier == CHERRY_TIER:
    _apply_cherry_bomb(merge_pos, cherry_count)
    EventBus.card_effect_triggered.emit("cherry_bomb")

# 2. Bouncy Berry -- _on_fruit_merged, line ~129
# Triggers: On every merge (applies retroactively to all fruits)
# Type: Passive/always-on -- consider NOT triggering feedback since it's ambient
# Alternative: Only trigger on fruit_dropped (more visible single-event moment)
if _count_active("bouncy_berry") > 0:
    call_deferred("_apply_bouncy_berry_all")
    EventBus.card_effect_triggered.emit("bouncy_berry")

# 3. Heavy Hitter (recharge) -- _on_fruit_merged, line ~132-138
# Triggers: When recharge counter reaches threshold
# Type: Charge-based -- trigger on RECHARGE (prominent animation)
if _heavy_merge_counter >= HEAVY_RECHARGE_MERGES:
    _heavy_charges = HEAVY_CHARGES_MAX
    EventBus.card_effect_triggered.emit("heavy_hitter")

# 4. Heavy Hitter (consume) -- _on_fruit_dropped, line ~155-156
# Triggers: When a charged drop occurs
# Type: Charge-based -- trigger on USE (prominent animation)
if _count_active("heavy_hitter") > 0 and _heavy_charges > 0:
    _heavy_charges -= 1
    EventBus.card_effect_triggered.emit("heavy_hitter")

# 5. Wild Fruit -- _on_fruit_merged, line ~143-145
# Triggers: Every WILD_SELECT_INTERVAL (5) merges
# Type: Conditional periodic
if _wild_merge_counter >= WILD_SELECT_INTERVAL:
    _wild_merge_counter = 0
    _select_wild_fruits()
    EventBus.card_effect_triggered.emit("wild_fruit")

# 6. Quick Fuse -- _apply_quick_fuse(), line ~342-348
# Triggers: When merge happens during active chain (chain_count >= 2)
# Type: Conditional per-merge
# Emit only when bonus > 0

# 7. Fruit Frenzy -- _apply_fruit_frenzy(), line ~353-359
# Triggers: When chain_count >= 3
# Type: Conditional per-merge
# Emit only when bonus > 0

# 8. Big Game Hunter -- _apply_big_game_hunter(), line ~364-369
# Triggers: When new_tier >= 6 (Pear or Watermelon)
# Type: Conditional (rare, high-value trigger)
# Emit only when bonus > 0

# 9. Golden Touch -- _apply_golden_touch(), line ~374-377
# Triggers: EVERY merge (unconditional)
# Type: Passive/always-on -- HIGH FREQUENCY, needs dampening
# Emit only when bonus > 0

# 10. Lucky Break -- _apply_lucky_break(), line ~383-390
# Triggers: 15% chance per card per merge
# Type: Probabilistic
# Emit only when total_coins > 0

# 11. Pineapple Express -- _apply_pineapple_express(), line ~396-403
# Triggers: When new_tier == PINEAPPLE_TIER (Pear created)
# Type: Conditional (rare, high-value trigger)
# Emit only when score > 0 or coins > 0
```

### Run Stats Currently Available vs Needs Tracking

```
Stat                | Currently Tracked?          | Source
--------------------|-----------------------------|---------
Final score         | YES - GameManager.score     | Direct read
Total coins earned  | PARTIAL - GameManager.coins | This is CURRENT coins, not total earned
Biggest chain       | NO - ScoreManager resets    | Needs RunStatsTracker on chain_ended signal
Highest tier        | NO                          | Needs RunStatsTracker on fruit_merged signal
Total merges        | NO                          | Needs RunStatsTracker on fruit_merged signal
Cards used          | PARTIAL - CardManager       | active_cards at game over; need to track ALL cards used (including sold ones)
Time played         | NO                          | Needs RunStatsTracker with Timer or OS.get_ticks_msec()
```

### Starter Kit Data Structure

```gdscript
# In CardManager or a new kit_data.gd
const STARTER_KITS: Array[Dictionary] = [
    {
        "name": "Physics Kit",
        "description": "Modify how fruits move and collide",
        "card_pool": ["bouncy_berry", "cherry_bomb", "heavy_hitter", "wild_fruit"],
    },
    {
        "name": "Score Kit",
        "description": "Boost your score and chain bonuses",
        "card_pool": ["quick_fuse", "fruit_frenzy", "big_game_hunter", "pineapple_express"],
    },
    {
        "name": "Surprise!",
        "description": "A random card from any category",
        "card_pool": [],  # Empty = pick from full pool
    },
]
```

### Run Summary Stat Reveal Animation Pattern

```gdscript
# Sequential tween chain for celebratory reveal
var reveal_order: Array[String] = [
    "total_merges", "biggest_chain", "highest_tier",
    "cards_used", "total_coins", "time_played", "final_score"
]

func _reveal_stats() -> void:
    var tween: Tween = create_tween()
    for i in reveal_order.size():
        var label: Control = _stat_nodes[reveal_order[i]]
        label.modulate.a = 0.0
        label.scale = Vector2(0.5, 0.5)
        tween.tween_property(label, "modulate:a", 1.0, 0.3)
        tween.parallel().tween_property(label, "scale", Vector2(1.0, 1.0), 0.3)\
            .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.tween_interval(0.15)  # Pause between stats
    # Final score gets special treatment (bigger, slower)
    tween.tween_callback(_show_buttons)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No card trigger feedback | Phase 8 adds visual triggers | N/A (new feature) | Players understand what their cards are doing |
| Random starter card pick | Kit-based themed selection | N/A (new feature) | Players can shape early strategy |
| "GAME OVER" label only | Full run summary with stats | N/A (new feature) | Every run feels like progress |

**Nothing deprecated** -- all existing patterns remain valid. Phase 8 builds on them.

## Open Questions

1. **Total Coins Earned Tracking**
   - What we know: `GameManager.coins` tracks current balance (decremented by purchases). Card bonus coins bypass ScoreManager's `_coins_awarded` counter.
   - What's unclear: Need to track total coins ever awarded (including spent ones) for the "total coins earned" stat.
   - Recommendation: RunStatsTracker listens to `coins_awarded` signal AND `bonus_awarded` with `bonus_type == "coins"` and sums them. This captures both ScoreManager-awarded coins and card bonus coins.

2. **"Cards Used During Run" Definition**
   - What we know: User wants "cards used during run" as a stat.
   - What's unclear: Does this mean (a) cards currently held at game over, (b) all cards ever purchased (including sold ones), or (c) unique card_ids activated?
   - Recommendation: Track all unique card_ids that were ever in `active_cards` during the run (listen to `card_purchased` and `starter_pick_completed`). Display count with names.

3. **Bouncy Berry Trigger Feedback**
   - What we know: Bouncy Berry applies to all small fruits on every merge and every drop. It's ambient/passive.
   - What's unclear: Should an ambient effect that fires constantly get trigger feedback?
   - Recommendation: Show trigger feedback only on `fruit_dropped` (when the bouncy effect is most noticeable to the player -- the just-dropped small fruit bounces higher). Skip the merge trigger (too frequent, less visible to player).

4. **Heavy Hitter Double Trigger**
   - What we know: Heavy Hitter triggers both on charge consumption (fruit_dropped) and charge refill (after 5 merges).
   - What's unclear: Should both events trigger the prominent charge animation?
   - Recommendation: Yes -- both are meaningful moments. Charge consumption = "power used!", charge refill = "power ready!". The recharge trigger naturally has low frequency (every 5 merges after depletion).

## Discretion Recommendations

### Frequency Dampening (Claude's Discretion)
**Recommendation:** Use a "tween-is-running" guard. If a CardSlotDisplay already has an active trigger tween, skip additional triggers for that slot. The glow+bounce animation duration (0.3-0.5s) naturally dampens to max 2-3 triggers per second. For Golden Touch specifically (fires every merge), this means during rapid chains the card stays in a continuous glow state rather than strobing. This is the simplest approach and produces a natural "the card is active right now" visual.

### Charge vs Passive Animation Differentiation (Claude's Discretion)
**Recommendation:**
- **Passive/common triggers:** Scale to 1.15x, border glow for 0.3s, subtle
- **Charge-based triggers (Heavy Hitter, Wild Fruit):** Scale to 1.25x, border glow for 0.5s, border width increases from 3px to 6px, adds a brief white flash on the panel background
- The larger bounce + wider border + longer duration makes charge triggers feel "meatier" without requiring new VFX

### Rarity Color Link to On-Screen Effects (Claude's Discretion)
**Recommendation:** Skip this. The bonus popups already use distinct colors (purple for score, green for coins), and adding rarity-colored particles would create visual confusion between "this is a score bonus" (purple) and "this is a rare card" (also purple). Keep the HUD glow and on-screen effects as separate visual channels.

### Stats Reveal Order (Claude's Discretion)
**Recommendation:** Build anticipation by ordering from "common" to "impressive":
1. Total Merges (everyone gets many)
2. Biggest Chain (mid-engagement)
3. Highest Tier Reached (visual fruit circle -- satisfying reveal)
4. Cards Used (reminds player of their build)
5. Total Coins Earned (economic summary)
6. Time Played (context)
7. **Final Score** (the big reveal, biggest font, slight delay before)

### "Quit" Button Behavior (Claude's Discretion)
**Recommendation:** `JavaScriptBridge.eval("window.location.reload()")` for web builds. This cleanly reloads the page. For native builds, fall back to `get_tree().quit()`. The PauseMenu's current `_on_quit_pressed()` already just calls restart -- the run summary version should do the same for "Play Again" and use JS reload for "Quit".

## Sources

### Primary (HIGH confidence)
- **Codebase analysis** - Direct reading of all 23 GDScript files and 11 .tscn scenes in the project
- **Godot 4.5 Tween API** - Verified from existing usage patterns across 7+ files in the project (HUD, floating_score, card_shop, card_slot_display, card_effect_system shockwave, merge_feedback)
- **CardSlotDisplay architecture** - Direct analysis of card_slot_display.gd and card_slot_display.tscn
- **EventBus signal patterns** - Direct analysis of event_bus.gd (24 existing signals) and all connection points

### Secondary (MEDIUM confidence)
- **Godot CanvasLayer layer ordering** - Inferred from existing usage (HUD=default, PauseMenu=10, CardShop/StarterPick=11); run summary should use layer 12 or 11 with careful z-ordering
- **JavaScriptBridge.eval** - Known Godot web export API for JS interop; not currently used in project but standard for web builds

### Tertiary (LOW confidence)
- None -- all findings verified from direct codebase analysis

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools already used in the project, no new dependencies
- Architecture: HIGH - Every pattern directly observed in existing code (overlays, tweens, signals, components)
- Pitfalls: HIGH - Derived from actual code paths and known Godot behaviors already handled in project
- Discretion recommendations: MEDIUM - Based on game design judgment and existing project patterns, but untested until implementation

**Research date:** 2026-02-12
**Valid until:** Indefinite (no external dependencies, pure project-internal research)
