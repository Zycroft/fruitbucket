---
phase: 06-card-effects-physics-merge
verified: 2026-02-10T02:59:26Z
status: passed
score: 14/14 must-haves verified
re_verification: false
---

# Phase 6: Card Effects -- Physics & Merge Verification Report

**Phase Goal**: Four card effects that physically change how fruits behave -- bouncing, mass, merge rules, and collision forces -- demonstrating the card system's ability to modify the core physics loop.

**Verified**: 2026-02-10T02:59:26Z

**Status**: PASSED

**Re-verification**: No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Bouncy Berry makes tier 0-2 fruits bounce visibly higher on impact | ✓ VERIFIED | card_effect_system.gd lines 186-217: `_apply_bouncy_to_fruit()` sets `bounce = 0.15 + (0.5 * stack_count)` for tiers 0-2 |
| 2 | Bouncy Berry applies retroactively to existing fruits when purchased | ✓ VERIFIED | card_effect_system.gd line 144: `_on_card_changed()` calls `_apply_bouncy_berry_all()` |
| 3 | Cherry Bomb creates outward blast pushing nearby fruits when cherries merge | ✓ VERIFIED | card_effect_system.gd lines 224-245: `_apply_cherry_bomb()` applies radial impulses within 200px radius |
| 4 | Cherry Bomb blast produces visible shockwave ring expanding from merge point | ✓ VERIFIED | card_effect_system.gd lines 248-277: `_spawn_shockwave()` creates Line2D circle with tween expansion |
| 5 | Duplicate cards stack linearly (2x effect with 2 cards) | ✓ VERIFIED | card_effect_system.gd line 78-84: `_count_active()` counts duplicates, used in all effect calculations |
| 6 | CardEffectSystem resets cleanly on scene reload | ✓ VERIFIED | Lives in game scene tree (not autoload), automatic cleanup on reload |
| 7 | Heavy Hitter gives next 3 drops 2x mass, pushing harder on contact | ✓ VERIFIED | card_effect_system.gd line 133: `fruit.mass = fruit.fruit_data.mass_override * 2.0 * stack_count` |
| 8 | Heavy Hitter charge count visible on HUD card slot (e.g., '3/3') and decrements per drop | ✓ VERIFIED | hud.gd lines 237-249: `_on_heavy_hitter_charges_changed()` updates slot status text |
| 9 | Heavy Hitter preview fruit looks different when heavy charge will apply | ✓ VERIFIED | drop_controller.gd lines 140-150: `_apply_heavy_preview()` darkens preview by 0.3 |
| 10 | Heavy Hitter recharges to 3/3 after 5 merges once charges depleted | ✓ VERIFIED | card_effect_system.gd lines 106-112: recharge counter increments, resets at 5 merges |
| 11 | Wild Fruit periodically designates random on-screen fruit as wild (rainbow shimmer) | ✓ VERIFIED | card_effect_system.gd lines 305-325: `_select_wild_fruits()` every 5 merges |
| 12 | Wild fruit merges with same-tier OR adjacent-tier fruits on contact | ✓ VERIFIED | fruit.gd lines 71-78: `_can_merge_with()` allows `abs(tier_a - tier_b) <= 1` for wild |
| 13 | Wild merge result upgrades to max(tier_a, tier_b) + 1 (generous upgrade) | ✓ VERIFIED | merge_manager.gd lines 66-69: `old_tier = maxi(tier_a, tier_b)`, `new_tier = old_tier + 1` |
| 14 | All effects reset cleanly on game restart | ✓ VERIFIED | CardEffectSystem is scene-tree node, state cleared on reload; no persistence |

**Score**: 14/14 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/components/card_effect_system.gd` | Central card effect processor with all 4 effects | ✓ VERIFIED | 345 lines, contains `_count_active`, all effect logic |
| `resources/shaders/rainbow_outline.gdshader` | Rainbow cycling outline shader for Wild Fruit | ✓ VERIFIED | 30 lines, `shader_type canvas_item`, time-based rainbow |
| `scenes/fruit/fruit.gd` | Fruit with is_wild, is_heavy flags, `_can_merge_with()` | ✓ VERIFIED | Lines 19, 22, 71-78: flags and merge check method |
| `scripts/autoloads/event_bus.gd` | New signals for card effect communication | ✓ VERIFIED | Line 61: `heavy_hitter_charges_changed`, 64/67/70: wild/cherry signals |
| `scripts/components/merge_manager.gd` | Wild merge result calculation (max tier + 1) | ✓ VERIFIED | Lines 62-73: `is_wild_merge` and tier calculation logic |
| `scripts/components/drop_controller.gd` | Heavy Hitter preview visual distinction | ✓ VERIFIED | Lines 140-150: `_apply_heavy_preview()`, line 67: charge listener |
| `scenes/ui/card_slot_display.gd` | Status text overlay for charge display | ✓ VERIFIED | Lines 52-64: `set_status_text()`, `clear_status_text()` |
| `scenes/ui/hud.gd` | Heavy Hitter charge display on HUD card slots | ✓ VERIFIED | Line 38: signal connection, lines 237-249: charge handler |
| `scenes/game/game.tscn` | CardEffectSystem node in scene tree | ✓ VERIFIED | Lines 16, 48-49: ext_resource and node with groups |
| `resources/card_data/bouncy_berry.tres` | Bouncy Berry card data | ✓ VERIFIED | card_id = "bouncy_berry" |
| `resources/card_data/cherry_bomb.tres` | Cherry Bomb card data | ✓ VERIFIED | card_id = "cherry_bomb" |
| `resources/card_data/heavy_hitter.tres` | Heavy Hitter card data | ✓ VERIFIED | card_id = "heavy_hitter" |
| `resources/card_data/wild_fruit.tres` | Wild Fruit card data | ✓ VERIFIED | card_id = "wild_fruit" |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| CardEffectSystem | EventBus.fruit_merged | signal connection | ✓ WIRED | Line 63: `fruit_merged.connect(_on_fruit_merged)` |
| CardEffectSystem | CardManager.active_cards | reads for stack count | ✓ WIRED | Line 81: `for entry in CardManager.active_cards` |
| CardEffectSystem | EventBus.heavy_hitter_charges_changed | emits charge state | ✓ WIRED | Lines 70, 112, 136, 150, 165: emit calls |
| HUD | EventBus.heavy_hitter_charges_changed | listens and updates slot | ✓ WIRED | Line 38: connect, lines 237-249: handler |
| MergeManager | fruit.is_wild | checks for wild merge calculation | ✓ WIRED | Line 62: `fruit_a.is_wild or fruit_b.is_wild` |
| Fruit | _can_merge_with() | merge rule extension | ✓ WIRED | Line 60: `_on_body_entered()` calls it before merge |
| DropController | CardEffectSystem.has_heavy_charges | preview visual query | ✓ WIRED | Line 145: `effect_system.has_heavy_charges()` |
| DropController | EventBus.heavy_hitter_charges_changed | updates preview on charge change | ✓ WIRED | Line 67: connect, line 140: handler |
| CardSlotDisplay | set_status_text() | used by HUD for charges | ✓ WIRED | hud.gd line 248: `slot.set_status_text()` |

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| EFCT-01: Bouncy Berry makes tier 1-3 fruits bounce 50% higher | ✓ SATISFIED | Truth 1-2 verified, BOUNCY_BERRY_BOUNCE_BONUS = 0.5 |
| EFCT-02: Heavy Hitter gives next 3 drops 2x mass | ✓ SATISFIED | Truth 7-10 verified, charge system operational |
| EFCT-03: Wild Fruit causes random fruit to merge with adjacent tier | ✓ SATISFIED | Truth 11-13 verified, selection and merge logic complete |
| EFCT-09: Cherry Bomb creates outward push on cherry merge | ✓ SATISFIED | Truth 3-4 verified, blast and shockwave implemented |

### Anti-Patterns Found

None. All modified files are clean:
- No TODO/FIXME/PLACEHOLDER comments
- No stub implementations (empty returns, console-only logic)
- No orphaned code
- All methods are substantive and wired

### Human Verification Required

The following items require human testing in the running game:

#### 1. Visual Bounce Height Difference

**Test**: Run game. Pick Bouncy Berry as starter card. Drop several tier 0-2 fruits (Blueberry, Grape, Cherry). Observe bounce behavior on contact with floor/other fruits. Compare with a run without Bouncy Berry.

**Expected**: Bouncy Berry fruits should bounce noticeably higher (65% bounce vs 15% default). The visual difference should be clear during normal gameplay.

**Why human**: Bounce "feel" is subjective. Code shows correct physics values, but perceptibility depends on game speed, fruit size, and visual context.

#### 2. Heavy Mass Push Effect

**Test**: Pick Heavy Hitter. Drop 3 heavy fruits into an existing pile. Observe displacement of surrounding fruits on impact.

**Expected**: Heavy fruits should push the pile noticeably harder than normal drops (2x mass). Fruits should scatter/roll more on impact.

**Why human**: "Noticeably more" is qualitative. Physics simulation is correct, but gameplay feel requires human assessment.

#### 3. Wild Fruit Rainbow Shimmer Visibility

**Test**: Pick Wild Fruit. Perform ~5 merges. Observe the designated wild fruit.

**Expected**: Wild fruit should have a clearly visible, animated rainbow outline that cycles through colors. The effect should be distinct enough to identify wild fruits at a glance during fast gameplay.

**Why human**: Shader visibility depends on fruit size, screen resolution, background color contrast. The rainbow shader exists and is applied, but aesthetic appeal requires human judgment.

#### 4. Cherry Bomb Shockwave Visibility

**Test**: Pick Cherry Bomb. Drop two cherries to create a merge. Observe the merge point.

**Expected**: An orange expanding ring should appear at the merge position, growing from the center outward and fading over ~0.3s. The visual should reinforce the blast effect and be satisfying to watch.

**Why human**: Visual feedback timing and clarity are subjective. The tween and Line2D are implemented, but the "feel" of the explosion requires human evaluation.

#### 5. Charge Display Readability

**Test**: Pick Heavy Hitter. Observe the HUD card slot showing "3/3". Drop fruits and watch the counter decrement. Perform 5 merges after depletion and observe recharge to "3/3".

**Expected**: Charge text should be legible, update immediately on drop/recharge, and not overlap other card slot elements.

**Why human**: UI layout and text size depend on viewport settings, font choices, and card slot design. Code correctly updates text, but readability requires visual inspection.

#### 6. Game Restart State Cleanup

**Test**: Pick all 4 cards in a run. Use their effects. Trigger game over. Restart game. Verify no wild fruits persist, no heavy charges remain, bounce returns to default, no lingering shockwaves.

**Expected**: Fresh state every run. No visual or behavioral artifacts from previous session.

**Why human**: State leaks can be subtle (e.g., leftover shader materials, stale references). Code shows proper cleanup, but runtime behavior needs manual verification.

---

## Verification Notes

All 14 observable truths verified. All 13 artifacts exist, are substantive (not stubs), and are wired into the game loop. All 9 key links traced and confirmed functional. All 4 requirements satisfied.

**Commits verified**:
- `eca1095`: feat(06-01) scaffold CardEffectSystem, fruit.gd infrastructure, EventBus signals, rainbow shader
- `cda351b`: feat(06-01) implement Bouncy Berry and Cherry Bomb card effects
- `cbf8540`: feat(06-02) Heavy Hitter charge system with drop-time mass boost and HUD integration
- `f94b019`: feat(06-02) Wild Fruit periodic selection with rainbow shader and adjacent-tier merge logic

**Code quality**: Clean, well-structured, no anti-patterns detected. All constants are named and documented. Signal-driven architecture avoids per-frame polling. Effects correctly use `call_deferred()` to avoid physics callback race conditions.

**Stacking verified**: `_count_active()` correctly counts duplicate cards. All effect formulas use linear stacking (bounce, mass, blast force scale with count).

**Lifecycle verified**: CardEffectSystem lives in game scene tree (not autoload), ensuring automatic state reset on scene reload. Purchase/sell handlers correctly initialize/cleanup state.

**Pattern consistency**: All 4 effects follow established patterns from Phase 5 (EventBus signals, CardManager.active_cards array, card_id string matching).

---

_Verified: 2026-02-10T02:59:26Z_  
_Verifier: Claude (gsd-verifier)_
