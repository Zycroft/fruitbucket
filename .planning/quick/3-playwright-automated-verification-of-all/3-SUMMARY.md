# Quick Task 3: Playwright Automated Verification — Summary

## Overview

Automated browser verification of all 8 phases on `zycroft.duckdns.org/bucket/` using Playwright CLI. Tested via canvas input simulation, screenshot capture, and console log analysis (Godot 4.5 renders everything to a single `<canvas>` element — no inspectable HTML DOM elements).

## Critical Finding: Stale Deployment

**Phase 8 code is NOT deployed** despite `deploy-duckdns` job reporting success.

| Deploy Job | Status | Notes |
|------------|--------|-------|
| `deploy-pages` (GitHub Pages) | FAILED | "Get Pages site failed" — Pages configuration broken |
| `deploy-duckdns` (SSH/rsync) | SUCCESS | But serves stale code (Phase 5 starter pick, not Phase 8 kits) |

**Evidence:**
- Deployed starter selection shows individual card names ("Golden Touch", "Quick Fuse") with Phase 5 behavior
- Source code shows Phase 8 kit selection (`CardManager.STARTER_KITS` with kit names/descriptions)
- Run summary screen does not appear after game over (Phase 8 feature)
- GameOverLabel text visible (removed in Phase 8, replaced by run summary)

**Root cause:** Either the rsync deploy didn't update the `.pck` file (Godot's compiled resource pack) or server-side caching is serving the old version.

## Bugs Found (Phases 1-7, confirmed on deployed build)

### BUG-1: Physics Callback Errors (MAJOR)
- **482 errors per session** of `Can't disable contact monitoring during in/out callback` and `Can't change this state while flushing queries`
- Triggers on every merge operation via 4 distinct error paths:
  - `set_contact_monitor` (rigid_body_2d.cpp:599)
  - `body_set_mode` (godot_physics_server_2d.cpp:570)
  - `body_set_shape_disabled` (godot_physics_server_2d.cpp:654)
  - `body_set_shape_as_one_way_collision` (godot_physics_server_2d.cpp:663)
- **Root cause:** MergeManager's `_deactivate_fruit()` modifies physics state during physics callbacks instead of using `call_deferred()` for all operations
- **Impact:** Doesn't crash but fills console with errors, may cause state corruption over time

### BUG-2: Game Freeze at ~1484 Score (BLOCKER)
- Game becomes completely unresponsive during active chain reactions near the 1500 score threshold
- Score popups freeze in place, background dims, no input works (clicks, Escape)
- **Suspected root cause:** Shop threshold (1500) triggers `SHOPPING` state which pauses the tree DURING an active chain reaction, leaving the game in a permanently paused state with no visible shop overlay
- **Reproduction:** Play normally, score approaches 1500 during a chain reaction
- Screenshot evidence: `09-check-gameover.png` through `12-after-continue-click.png`

### BUG-3: GitHub Pages Deploy Broken (MAJOR)
- Latest deploy at 2026-02-12T16:20:11Z failed
- Error: `Get Pages site failed. Please verify that the repository has Pages enabled and configured to build using GitHub Actions`
- All code since Phase 5 not deployed to GitHub Pages (last success: Feb 9)

## Verified Working (Phases 1-7)

### Phase 1: Core Physics & Merging
| Test | Result | Evidence |
|------|--------|----------|
| Fruit drop via mouse click | PASS | `02-after-starter-pick.png` |
| Physics stacking (multiple fruits) | PASS | `04-after-many-drops.png` |
| Fruit merging (same tier → next tier) | PASS | Score increased 0→334 in `04-after-many-drops.png` |
| Multiple tiers visible (1-5+) | PASS | Blue, purple, red, green, orange fruits visible |
| Overflow detection (red line) | PASS | `15-overflow-check.png` — red overflow line |
| Game over trigger | PASS | `15-overflow-check.png` — "GAME OVER" text |
| Next fruit preview | PASS | Orange fruit in top-right corner |
| Fruit faces (Quick Task 2) | PASS | Cartoon faces visible on all fruit tiers |

### Phase 2: Scoring & Chain Reactions
| Test | Result | Evidence |
|------|--------|----------|
| Score updates on merge | PASS | Score: 0 → 2 → 334 → 1392 → 1484 |
| Chain multipliers (x2, x3) | PASS | "CHAIN x2!" and "CHAIN x3!" visible in HUD |
| Floating score popups | PASS | "+32", "+192 x3!" popups in `09-check-gameover.png` |
| Coin accumulation | PASS | Coins: 0 → 2 → 23 → 73 → 86 |

### Phase 3: Merge Feedback & Juice
| Test | Result | Evidence |
|------|--------|----------|
| Floating popups with chain text | PASS | "+32 x2!" visible with chain multipliers |
| Bonus popups (card effects) | PASS | "+2 coins" from Golden Touch visible |
| Visual distinction (single vs chain) | PASS | Chain popups show colored multiplier text |

### Phase 4: Game Flow & Input
| Test | Result | Evidence |
|------|--------|----------|
| Pause menu opens | PASS | `05-pause-menu.png` — "PAUSED" with Resume/Restart/Quit |
| Resume from pause | PASS | Game continued after clicking Resume |
| Pause button hides on game over | PASS | No pause button in game over screenshots |

### Phase 5: Card System Infrastructure
| Test | Result | Evidence |
|------|--------|----------|
| Starter card selection at run start | PASS | `01-game-load.png` — 3 card options with Pick buttons |
| Card appears in HUD slot after pick | PASS | `02-after-starter-pick.png` — Golden Touch in slot 1 |
| Card shop opens at threshold | PASS | `06-after-more-drops.png` — "CARD SHOP" overlay |
| Buy card (coins deducted, slot filled) | PASS | `07-after-buy.png` — Bouncy Berry purchased, coins 29→21 |
| Sell price shown (50% of purchase) | PASS | "Sell: 5 coins" for 10-coin Bouncy Berry |
| Card descriptions visible | PASS | Full descriptions in shop and HUD slots |
| 3 HUD card slots | PASS | Visible in all gameplay screenshots |
| Rarity affects pricing | PASS | Wild Fruit (Rare) = 37 coins vs Bouncy Berry = 10 coins |
| State resets on reload | PASS | `13-fresh-load.png` — Score: 0, Coins: 0, new random cards |

### Phases 6-7: Card Effects
| Test | Result | Evidence |
|------|--------|----------|
| Golden Touch (+2 coins per merge) | PASS | "+2 coins" popups visible during gameplay |
| Chain counter with card bonuses | PASS | CHAIN x3! with bonus popups simultaneously |

### Phase 8: Card Activation Feedback & Starter Kits
| Test | Result | Notes |
|------|--------|-------|
| Starter kit selection (themed kits) | UNTESTABLE | Phase 8 not deployed — shows Phase 5 individual card pick |
| Card glow on trigger | UNTESTABLE | Phase 8 not deployed |
| Run summary after game over | UNTESTABLE | Phase 8 not deployed — shows GameOverLabel instead |

## Console Error Summary

| Category | Count | Severity |
|----------|-------|----------|
| Physics `call_deferred` errors | 482 | Major (non-crash, but wrong behavior) |
| SFX bus missing warning | 1 | Minor (graceful fallback to Master) |
| WebGL ReadPixels GPU stall | 4 | Cosmetic (suppressed after first) |

## Action Items

1. **Fix deploy** — Debug why duckdns rsync isn't updating the .pck file, fix GitHub Pages configuration
2. **Fix physics callback errors** — Wrap ALL fruit deactivation operations in `call_deferred()` in MergeManager
3. **Fix game freeze** — Add guard in `_on_score_threshold` to prevent shop opening during active chain reactions, or defer the shop opening until chain completes
4. **Re-verify Phase 8** — After fixing deploy, re-run Playwright verification for starter kits, card glow, and run summary

## Test Session Details

- **URL:** https://zycroft.duckdns.org/bucket/
- **Date:** 2026-02-12
- **Browser:** Chromium (headless via Playwright CLI)
- **Viewport:** 540x960 (matching game window override)
- **Screenshots:** 18 captured in this directory
- **Console logs:** Captured in `.playwright-cli/` directory
