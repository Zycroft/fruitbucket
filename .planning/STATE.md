# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-07)

**Core value:** The drop-merge-physics loop must feel satisfying and correct -- fruits fall naturally, collide realistically, and merge reliably.
**Current focus:** Phase 7 complete. All 6 scoring/economy card effects operational. Ready for Phase 8 (polish and balance).

## Current Position

Phase: 7 of 8 (Card Effects -- Scoring & Economy) -- COMPLETE
Plan: 2 of 2 in current phase (Phase 7 complete)
Status: Phase 7 complete -- all 6 scoring/economy card effects operational
Last activity: 2026-02-12 - Completed quick task 2: Add unique cartoon faces to all 8 fruit types

Progress: [██████████] 95% (Phase 7 complete, Phase 8 next)

## Performance Metrics

**Velocity:**
- Total plans completed: 15
- Average duration: 5min
- Total execution time: 1.15 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-core-physics-merging | 3/3 | 12min | 4min |
| 02-scoring-chain-reactions | 2/2 | 7min | 3.5min |
| 03-merge-feedback-juice | 2/2 | 23min | 11.5min |
| 04-game-flow-input | 1/1 | 5min | 5min |
| 05-card-system-infrastructure | 3/3 | 12min | 4min |
| 06-card-effects-physics-merge | 2/2 | 6min | 3min |
| 07-card-effects-scoring-economy | 2/2 | 3min | 1.5min |

**Recent Trend:**
- Last 5 plans: 05-03 (5min), 06-01 (3min), 06-02 (3min), 07-01 (2min), 07-02 (1min)
- Trend: Consistent 1-5min for non-playtest plans

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: 8 phases derived from 37 requirements at comprehensive depth
- [Roadmap]: All 6 critical pitfalls (double-merge, queue_free, RigidBody scaling, stacking, overflow, card combinatorial) addressed in Phase 1 architecture
- [Roadmap]: Card effects split into two phases (Physics/Merge vs Scoring/Economy) for parallel execution potential
- [01-01]: Bucket wall collision extends 12px outside visible art for tunneling prevention
- [01-01]: Bucket floor has higher friction/lower bounce PhysicsMaterial than fruit-to-fruit physics
- [01-01]: OverflowLine drawing in separate Node2D script for separation of concerns
- [01-02]: MergeManager found via group lookup (not autoload) for scene-component composition
- [01-02]: Instance ID tiebreaker ensures exactly one merge request per colliding pair
- [01-02]: 0.5s merge grace period prevents immediate re-merge of freshly spawned fruits
- [01-02]: DropController uses _unhandled_input so future UI can consume events first
- [01-03]: OverflowDetector per-fruit dwell timer (instance ID dictionary) prevents one fruit's bounce from affecting another's accumulated time
- [01-03]: Next-fruit preview via EventBus.next_fruit_changed for DropController-HUD decoupling
- [01-03]: Bucket rim warning enhanced with width increase (5px to 8px) above 80% danger
- [02-01]: Watermelon vanish awards flat 1000 bonus replacing tier score (not additive per research pitfall #4)
- [02-01]: Chain multipliers use Fibonacci-like sequence [1,2,3,5,8,13,21,34,55,89] clamped at bounds
- [02-01]: ChainTimer created programmatically in _ready() for script-only component pattern
- [02-01]: Per-merge multiplier application -- each cascade merge gets its own chain-position multiplier
- [02-02]: PopupContainer uses group-based discovery (popup_container group) matching MergeManager pattern
- [02-02]: Chain label hidden for chain_count < 2 to prevent "CHAIN x1!" spam
- [02-02]: Tween-based UI animation with pivot_offset set after text assignment for correct centered scaling
- [02-02]: Coin label styled dark grey for secondary emphasis, score remains primary focus
- [03-01]: SFX bus graceful fallback -- push_warning and use Master if SFX bus missing
- [03-01]: All three play functions reuse same merge_pop.wav with pitch/volume variation per context
- [03-01]: No finished->queue_free in particle scene (editor crash bug #107743); connect at spawn time
- [03-02]: Screen shake uses position offset instead of Camera2D offset property for reliable shake in 1080x1920 viewport
- [03-02]: Feedback orchestrator pattern: single MergeFeedback component connects EventBus and dispatches to particles, shake, SFX
- [03-02]: Tier intensity scaling: clampf(float(new_tier) / 7.0, 0.1, 1.0) normalizes all feedback proportionally
- [04-01]: Tree pause for PAUSED state; GAME_OVER does NOT pause tree (fruits settle naturally)
- [04-01]: PauseMenu on CanvasLayer layer 10 with PROCESS_MODE_ALWAYS for input during pause
- [04-01]: Overlay ColorRect mouse_filter=STOP blocks click-through; VBoxContainer mouse_filter=IGNORE
- [04-01]: Restart unpauses tree BEFORE reload_current_scene (avoids loading into paused state)
- [04-01]: TOUCH_PREVIEW_OFFSET=0.0 constant added but not applied (natural 80px gap sufficient)
- [05-01]: active_cards stores {card, purchase_price} dictionaries for transparent sell-price refunds (50% of actual paid price)
- [05-01]: SHOPPING and PICKING states extend PAUSED pattern (save _previous_state, pause tree, emit before pause)
- [05-01]: Shop offers avoid duplicate card_ids via re-roll with max_attempts safety (count * 5)
- [05-01]: CardManager autoload placed after SfxManager in project.godot (no cross-autoload _ready dependency)
- [05-02]: Card shop on layer 11 (above PauseMenu layer 10) with process_mode ALWAYS for input during tree pause
- [05-02]: Offer rows built dynamically as HBoxContainer with CardSlotDisplay + Buy button, cleaned up on close
- [05-02]: Player slots use gui_input with bind(slot_index) for sell-on-tap in shop; HUD slots are display-only
- [05-02]: PauseMenu Escape key guard extended for SHOPPING and PICKING states
- [05-03]: Starter pick overlay follows CardShop CanvasLayer pattern (layer 11, ALWAYS, visible=false)
- [05-03]: PICKING state blocks all gameplay before card selection (tree paused)
- [05-03]: Sell price uses maxi(purchase_price/2, base_price/2) so free cards always have sell value
- [06-01]: CardEffectSystem as scene-local Node (not autoload) for automatic cleanup on scene reload
- [06-01]: Per-fruit PhysicsMaterial.new() to avoid shared resource mutation -- matches CircleShape2D pattern from Phase 1
- [06-01]: Bounce always calculated from base (0.15) + bonus*N, never from current value, preventing exponential stacking
- [06-01]: Cherry Bomb triggers on old_tier == 2 (0-indexed, matching tier_3_cherry.tres)
- [06-01]: Shockwave ring via Line2D circle + tween, no separate .tscn needed
- [06-02]: Heavy Hitter targets last FruitContainer child as just-dropped fruit for reliable mass boost
- [06-02]: Wild merge old_tier uses maxi(tier_a, tier_b) so ScoreManager rewards the higher tier
- [06-02]: Wild Fruit selection triggered by merge counter (every 5 merges) for predictable timing
- [06-02]: CardSlotDisplay PriceLabel reused for charge status text in HUD mode (no new UI nodes)
- [07-01]: Scoring bonuses apply to base_score only (FruitData.score_value), not chain-multiplied total, preventing runaway inflation
- [07-01]: Quick Fuse requires chain_count >= 2 (first merge in chain does NOT qualify)
- [07-01]: Fruit Frenzy "+2x" is additive bonus (base_score * 2 * count), not multiplicative on chain multiplier
- [07-01]: Big Game Hunter triggers on new_tier >= 6 (created tier is Pear or Watermelon)
- [07-01]: Bonus popups use separate show_bonus() method with purple/green colors, offset 30px below normal popups
- [07-02]: Golden Touch is unconditional (every merge awards coins regardless of tier/chain)
- [07-02]: Lucky Break uses independent rolls per card (2 cards can both trigger for 10 coins)
- [07-02]: Pineapple Express maps to Pear (code tier 6) since no pineapple tier exists
- [07-02]: Coin bonuses emit both coins_awarded and bonus_awarded for dual HUD+popup feedback
- [07-02]: Direct card coin additions bypass ScoreManager's _coins_awarded counter (independent economy)
- [quick-2]: Vector _draw() faces instead of texture sprites -- scales perfectly at any size, no asset files needed
- [quick-2]: Fixed 25.0 radius for HUD preview face -- consistent preview size regardless of actual fruit radius

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 1 resolved]: Physics stacking stable with solver_iterations=6, playtest confirmed 20+ fruit stacking without jitter
- [Phase 1 lesson]: ColorRect/Control nodes default to mouse_filter=STOP — always set IGNORE on non-interactive UI elements
- [Phase 5 lesson]: theme_override_constants is a .tscn serialization key, NOT a settable GDScript property — use add_theme_constant_override() in code

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 1 | Deploy game to zycroft.duckdns.org/bucket via GitHub Actions | 2026-02-12 | d0698fc | [1-deploy-game-to-zycroft-duckdns-org-bucke](./quick/1-deploy-game-to-zycroft-duckdns-org-bucke/) |
| 2 | Add unique cartoon faces to all 8 fruit types | 2026-02-12 | bad8203 | [2-add-faces-to-each-of-the-fruit-types](./quick/2-add-faces-to-each-of-the-fruit-types/) |

## Session Continuity

Last session: 2026-02-12
Stopped at: Completed quick-2 (add faces to fruits). FaceRenderer with 8 unique _draw() expressions on all fruit tiers + HUD preview.
Resume file: None
