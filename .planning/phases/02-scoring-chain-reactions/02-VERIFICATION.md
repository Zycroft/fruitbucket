---
phase: 02-scoring-chain-reactions
verified: 2026-02-08T22:38:13Z
status: human_needed
score: 5/5 must-haves verified
re_verification: false
human_verification:
  - test: "Basic merge scoring"
    expected: "Drop and merge two blueberries. A floating '+2' popup appears at merge point, rises, and fades. HUD score animates to 2."
    why_human: "Visual animation behavior - popup appearance, rise/fade timing, score roll-up effect"
  - test: "Tier-scaled scoring"
    expected: "Merge grapes (+4), cherries (+8), oranges (+16). Each tier awards roughly double the previous tier."
    why_human: "Verify exponential scaling is perceivable during gameplay"
  - test: "Chain reaction multipliers"
    expected: "Set up cascade. Second merge shows '+N x2!', third shows '+N x3!', etc. Chain counter 'CHAIN xN!' appears prominently in gold. Chain popups are gold-tinted and larger."
    why_human: "Visual feedback - gold tint, popup size, chain counter appearance, multiplier text formatting"
  - test: "Chain counter behavior"
    expected: "During chain: counter visible. After chain ends (~1s no merge): counter fades out. Next single merge: no 'CHAIN x1!' spam."
    why_human: "Timing-dependent behavior - chain expiration window, fade-out animation, spam prevention"
  - test: "Coin economy"
    expected: "After 100 total score: 'Coins: 1'. After 200: 'Coins: 2'. Coin label punches/scales on update."
    why_human: "Threshold-based behavior and scale punch animation"
  - test: "Score animation"
    expected: "On big score gain: score counter counts up smoothly (roll-up) and punches/scales briefly from center."
    why_human: "Animation quality - roll-up smoothness, centered scale punch, no label jumping"
  - test: "Popup cleanup"
    expected: "After 10+ merges, no popup accumulation in scene tree. Check debugger Remote Scene tab."
    why_human: "Memory leak prevention - requires scene tree inspection during gameplay"
---

# Phase 2: Scoring & Chain Reactions Verification Report

**Phase Goal:** Every merge awards points scaled by fruit tier, and rapid consecutive merges trigger chain reaction multipliers that reward skillful play.
**Verified:** 2026-02-08T22:38:13Z
**Status:** human_needed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Every merge shows a floating score popup at the merge point that rises and fades | VERIFIED | FloatingScore scene exists with show_score() implementing rise+fade tween, queue_free cleanup. HUD spawns popup via popup_container on score_awarded signal. |
| 2 | Chain merges show multiplier in popup (e.g., '+64 x3!') and a prominent chain counter | VERIFIED | HUD formats popup text as "+%d x%d!" for multiplier > 1. ChainLabel shows "CHAIN x%d!" with gold styling, scale punch animation, visible only when chain_count >= 2. |
| 3 | Score counter animates with roll-up counting and scale punch on big gains | VERIFIED | HUD.animate_score_to() uses tween_method for roll-up counting, parallel scale punch (1.2x over 0.1s), pivot_offset set for centered scaling. |
| 4 | Coin counter is visible in the HUD and updates when coins are awarded | VERIFIED | CoinLabel exists in hud.tscn. HUD connects to coins_awarded signal, updates "Coins: %d" text with scale punch animation. |
| 5 | Chain counter only appears for chain_count >= 2 (no 'CHAIN x1!' spam) | VERIFIED | _show_chain() hides ChainLabel and returns early if chain_count < 2. Explicit spam prevention per plan requirement. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scenes/ui/floating_score.tscn` | Floating score popup scene | VERIFIED | Exists. Label root with font_size 36, outline, mouse_filter=2 (IGNORE), horizontal_alignment center. Script attached. |
| `scenes/ui/floating_score.gd` | Popup animation script | VERIFIED | Exists. Contains show_score(text, pos, is_chain) with rise+fade parallel tween, gold tint for chains, scale punch, queue_free cleanup. 40 lines, substantive. |
| `scenes/ui/hud.gd` | Animated score, chain counter, coin display | VERIFIED | Exists. Contains animate_score_to() with roll-up tween and scale punch. Connects to score_awarded, chain_ended, coins_awarded signals. Spawns floating popups. 176 lines, substantive. |
| `scenes/ui/hud.tscn` | ChainLabel and CoinLabel nodes | VERIFIED | Exists. Contains ChainLabel (gold, font_size 36, visible=false) and CoinLabel (dark grey, font_size 28). Both have mouse_filter=2. |
| `scenes/game/game.tscn` | PopupContainer Node2D for world-space popups | VERIFIED | Exists. PopupContainer Node2D at line 24, in group "popup_container". Positioned between FruitContainer and MergeManager. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `scenes/ui/hud.gd` | `scripts/autoloads/event_bus.gd` | EventBus.score_awarded.connect and EventBus.coins_awarded.connect | WIRED | hud.gd line 24-26: connects to score_awarded, chain_ended, coins_awarded. EventBus defines all 3 signals (lines 22, 25, 28). |
| `scenes/ui/floating_score.gd` | `scenes/ui/hud.gd` | Spawned at merge position by score_awarded listener | WIRED | hud.gd line 17: preloads floating_score scene. Lines 96-100: instantiates, adds to popup_container, calls show_score(). |
| `scenes/game/game.tscn` | `scenes/ui/floating_score.tscn` | PopupContainer Node2D for world-space popups | WIRED | game.tscn line 24: PopupContainer in "popup_container" group. hud.gd line 96: gets popup_container via get_first_node_in_group(), adds popup as child. |

**Additional wiring verification:**

- **ScoreManager -> EventBus signals:** score_manager.gd line 46 connects to fruit_merged, lines 92/99/103 emit score_awarded/coins_awarded/score_threshold_reached
- **HUD -> GameManager:** hud.gd line 85 reads GameManager.score, line 32 reads GameManager.coins
- **Chain tracking:** ScoreManager tracks chain_count, emits with multiplier via score_awarded signal (line 92), HUD receives and displays (line 83-103)

### Requirements Coverage

From ROADMAP.md success criteria and REQUIREMENTS.md:

| Requirement | Status | Evidence |
|-------------|--------|----------|
| **SCOR-01**: Points awarded on each merge, scaling with fruit tier | SATISFIED | FruitData resources have power-of-2 score_value (1,2,4,8,16,32,64,128). ScoreManager calculates score from FruitData, multiplies by chain multiplier. Orange=16, Pear=64 confirmed in resources. |
| **SCOR-02**: Chain reaction multiplier for consecutive merges (x2, x3, etc.) | SATISFIED | ScoreManager uses Fibonacci-like CHAIN_MULTIPLIERS array [1,2,3,5,8,13,21,34,55,89]. Chain count increments per merge, resets after 1s timer (line 74-75, 107-112). Multiplier applied per-merge (line 90). |
| **Success Criterion 1**: Each merge awards points that increase with fruit tier | SATISFIED | Power-of-2 scoring verified in FruitData resources. ScoreManager reads score_value and applies to GameManager.score. |
| **Success Criterion 2**: Merges within time window trigger chain multipliers | SATISFIED | ChainTimer (1s window) restarts on each merge. Multiplier calculated from chain_count using CHAIN_MULTIPLIERS array. Chain resets on timer expiration. |
| **Success Criterion 3**: Score displayed in HUD, updates in real-time | SATISFIED | HUD connects to score_awarded signal, calls animate_score_to() on every merge. Score display uses roll-up tween for smooth real-time updates. |

### Anti-Patterns Found

**Scan performed on:**
- scenes/ui/floating_score.gd
- scenes/ui/floating_score.tscn
- scenes/ui/hud.gd
- scenes/ui/hud.tscn
- scenes/game/game.tscn

**Result:** No anti-patterns detected.

- No TODO/FIXME/PLACEHOLDER comments
- No empty return statements (return null, return {}, return [])
- No console.log-only implementations
- All functions have substantive implementations
- queue_free() explicitly called in popup tween cleanup (preventing memory leak)
- Tween kill pattern used before creating new tweens (preventing overlap issues)

### Human Verification Required

All automated checks passed. The following items require human verification due to visual/timing behavior:

#### 1. Basic merge scoring

**Test:** Drop and merge two blueberries. Observe the floating popup and score counter.
**Expected:** A floating "+2" popup appears at the merge point, rises upward, and fades out over ~1.2 seconds. The HUD score counter animates smoothly from 0 to 2 with a brief scale punch.
**Why human:** Visual animation behavior - popup rise/fade timing, score roll-up smoothness, scale punch quality cannot be verified programmatically.

#### 2. Tier-scaled scoring

**Test:** Create merges at different tiers: grapes (+4), cherries (+8), oranges (+16), pears (+64).
**Expected:** Each tier awards roughly double the previous tier. Score increases feel exponential, not linear.
**Why human:** Exponential scaling is a gameplay feel verification - numbers are correct in code, but player perception during gameplay needs human testing.

#### 3. Chain reaction multipliers

**Test:** Set up a cascade where one merge triggers another (e.g., drop fruit that merges into another pair). Observe the second and third merge popups.
**Expected:** 
- First merge: "+N" (normal popup)
- Second merge: "+N x2!" (gold-tinted, larger popup)
- Third merge: "+N x3!" or "+N x5!" (depending on Fibonacci progression)
- "CHAIN xN!" label appears prominently in center-top of screen, gold color, scale punches on each update
**Why human:** Visual feedback quality - gold tint intensity, popup size difference, chain counter prominence, multiplier text formatting all require visual inspection during gameplay.

#### 4. Chain counter behavior

**Test:** Execute a 3+ merge chain, then wait ~1 second without merging. Then perform a single merge.
**Expected:** 
- During chain: "CHAIN x2!", "CHAIN x3!", etc. visible
- After ~1s no merge: chain counter fades out and disappears
- Next single merge: No "CHAIN x1!" spam - counter stays hidden
**Why human:** Timing-dependent behavior - chain expiration window (1s), fade-out animation quality, spam prevention logic all involve timing that must be tested in real gameplay.

#### 5. Coin economy

**Test:** Play until score reaches 100, 200, 300, etc. Watch the coin counter.
**Expected:** 
- Score 0-99: "Coins: 0"
- Score 100-199: "Coins: 1" (label punches/scales briefly)
- Score 200-299: "Coins: 2" (label punches/scales again)
- Every 100 points awards 1 coin
**Why human:** Threshold-based behavior and animation quality. Scale punch animation must be visually verified. Coin award timing relative to score updates requires real gameplay observation.

#### 6. Score animation quality

**Test:** Create a large merge (e.g., orange or apple) or chain reaction with 50+ points in one update.
**Expected:** 
- Score counter counts up smoothly (roll-up effect, not instant jump)
- Score label briefly scales to 1.2x from its center (not from corner), then back to 1.0
- No label position jumping or offset issues during scale animation
**Why human:** Animation quality verification - roll-up smoothness, centered scaling (pivot_offset correct), visual polish. Code sets pivot_offset, but visual result must be tested.

#### 7. Popup cleanup

**Test:** Perform 10-15 merges (including chains). Open Godot debugger Remote Scene tab and check the PopupContainer node.
**Expected:** PopupContainer should have 0 children after all popups finish animating. No accumulated FloatingScore nodes left in the tree.
**Why human:** Memory leak prevention requires scene tree inspection during gameplay. queue_free() is called in code, but verification requires debugger observation to confirm nodes are actually freed.

---

## Summary

**All automated checks passed.** Phase 2 goal is achievable based on codebase analysis:

- Scoring system wired end-to-end: FruitData -> ScoreManager -> EventBus -> HUD
- Chain reaction tracking implemented with Fibonacci multipliers and 1s time window
- Visual feedback layer complete: floating popups, animated score counter, chain counter, coin display
- All must-have artifacts exist, are substantive (not stubs), and are properly wired
- No anti-patterns or incomplete implementations detected
- Requirements SCOR-01 and SCOR-02 satisfied by codebase structure

**Human verification required for 7 gameplay/visual items** to confirm animations, timing, and visual polish meet quality standards. All infrastructure is in place for the phase goal to be achieved.

**Recommended next step:** User playtest per Task 2 checklist in 02-02-PLAN.md. If playtest passes, Phase 2 is complete.

---

_Verified: 2026-02-08T22:38:13Z_
_Verifier: Claude (gsd-verifier)_
