# Roadmap: Bucket

## Overview

Bucket delivers a Suika-style fruit-merging puzzle game with a roguelike card modifier system, built in Godot 4.5. The roadmap starts with rock-solid physics (the game lives or dies on satisfying drop-merge-stack feel), layers scoring and juice on top, then builds out the card system infrastructure before populating it with effects. Eight phases progress from a playable physics sandbox through a fully realized roguelike puzzle game with 10 card effects, dual-platform input, and polished game feel.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Core Physics & Merging** - Droppable, stackable, mergeable fruits in a physics container with overflow detection (completed 2026-02-08)
- [x] **Phase 2: Scoring & Chain Reactions** - Points on merge with chain reaction multipliers
- [x] **Phase 3: Merge Feedback & Juice** - Particles, screen shake, and escalating effects that make merging feel satisfying
- [x] **Phase 4: Game Flow & Input** - Pause menu, restart, and dual-platform input (mouse + touch)
- [x] **Phase 5: Card System Infrastructure** - Card slots, shop, economy, rarity, and per-run card lifecycle (completed 2026-02-09)
- [x] **Phase 6: Card Effects -- Physics & Merge** - Cards that modify physics properties and merge behavior (completed 2026-02-09)
- [ ] **Phase 7: Card Effects -- Scoring & Economy** - Cards that modify score multipliers and coin income
- [ ] **Phase 8: Card Activation Feedback & Starter Kits** - Visual card triggers, starter card sets, and run summary screen

## Phase Details

### Phase 1: Core Physics & Merging
**Goal**: Players can drop fruits into a container where they obey gravity, stack naturally, and auto-merge into larger fruits -- with all critical physics pitfalls (double-merge, queue_free crash, RigidBody scaling, stacking instability, overflow false positives) solved from day one.
**Depends on**: Nothing (first phase)
**Requirements**: PHYS-01, PHYS-02, PHYS-03, PHYS-04, PHYS-05, PHYS-06, PHYS-07, PHYS-08
**Success Criteria** (what must be TRUE):
  1. Player can position a fruit horizontally by moving the mouse/cursor and drop it by clicking, and the fruit falls into the container under gravity
  2. Dropped fruits collide with container walls and other fruits, stacking and settling naturally without jitter even with 20+ fruits on screen
  3. Two identical fruits touching each other merge into the next tier at the contact midpoint, and two watermelons merging vanish with no crash or duplicate spawn
  4. Only tiers 1-5 (blueberry through orange) appear as drops; the next fruit to drop is previewed in the UI
  5. Game ends when a fruit stays above the overflow line for 2+ seconds, but does not falsely trigger during bounces or chain reactions
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md -- Project setup, FruitData resources, bucket scene, background (Wave 1)
- [x] 01-02-PLAN.md -- Fruit scene, MergeManager gatekeeper, DropController, game scene (Wave 2)
- [x] 01-03-PLAN.md -- Overflow detector, HUD, game assembly, playtest checkpoint (Wave 3)

### Phase 2: Scoring & Chain Reactions
**Goal**: Every merge awards points scaled by fruit tier, and rapid consecutive merges trigger chain reaction multipliers that reward skillful play.
**Depends on**: Phase 1
**Requirements**: SCOR-01, SCOR-02
**Success Criteria** (what must be TRUE):
  1. Each merge awards points that increase with fruit tier (higher-tier merges are worth more)
  2. Merges that happen within a short time window of a previous merge trigger chain multipliers (x2, x3, etc.) that multiply the score award
  3. Score is displayed in the HUD and updates in real-time as merges occur
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md -- ScoreManager with chain tracking, coin economy, EventBus signals, FruitData score values (Wave 1)
- [x] 02-02-PLAN.md -- Floating score popups, animated HUD, chain counter, coin display, playtest (Wave 2)

### Phase 3: Merge Feedback & Juice
**Goal**: Merges produce satisfying visual and audio feedback that scales with fruit tier and chain length, making the core loop feel rewarding and spectacle-worthy.
**Depends on**: Phase 2
**Requirements**: SCOR-03, SCOR-04
**Success Criteria** (what must be TRUE):
  1. Every merge produces a particle burst, screen shake, and sound effect that scale in intensity with the tier of fruit created
  2. Chain reactions produce escalating feedback -- shake increases, particle colors shift, and effects build with each consecutive merge in the chain
  3. Feedback is visually distinct enough that a player can tell the difference between a single merge and a 3+ chain reaction without looking at the score
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md -- Screen shake Camera2D, SFX pool autoload, particle scene, placeholder audio (Wave 1)
- [x] 03-02-PLAN.md -- MergeFeedback orchestrator, game scene integration, chain escalation, playtest (Wave 2)

### Phase 4: Game Flow & Input
**Goal**: Players can pause, resume, restart, and quit mid-run, and the game works equally well with mouse/keyboard and touch input.
**Depends on**: Phase 1
**Requirements**: GAME-01, GAME-03
**Success Criteria** (what must be TRUE):
  1. Player can open a pause menu that freezes gameplay, and resume, restart, or quit from it
  2. Player can position and drop fruits using touch input on mobile with the same precision as mouse input on desktop (finger does not obscure the drop position)
  3. All gameplay interactions (drop, pause, shop navigation) work correctly on both desktop and mobile without requiring separate control schemes
**Plans**: 1 plan

Plans:
- [x] 04-01-PLAN.md -- Pause menu, restart flow, HUD pause button, touch input verification (Wave 1)

### Phase 5: Card System Infrastructure
**Goal**: The full card lifecycle works -- players pick a starter card, see active cards in the HUD, earn coins from merges, and spend them in a card shop that opens at score thresholds -- all resetting cleanly between runs.
**Depends on**: Phase 2
**Requirements**: CARD-01, CARD-02, CARD-03, CARD-04, CARD-05, CARD-06, CARD-07, CARD-08, CARD-10, CARD-11
**Success Criteria** (what must be TRUE):
  1. At run start, player picks 1 free card from 3 random options, and it appears in one of 3 HUD card slots with a clear effect description
  2. Merges award coins (scaling with fruit tier) displayed in the HUD, and the game pauses at score thresholds (500, 1500, 3500, 7000) to open a card shop with 3-4 card offers at varying rarities and prices
  3. Player can buy cards (if they have enough coins and an open slot), sell owned cards for 50% of purchase price, or skip the shop to resume play
  4. Card rarity (Common, Uncommon, Rare) affects shop prices and appearance frequency, with rare cards appearing more in later shops and prices increasing as the run progresses
  5. All cards, coins, and shop state reset completely when a new run starts -- nothing persists between runs
**Plans**: 3 plans

Plans:
- [x] 05-01-PLAN.md -- CardData resource, 10 card definitions, CardManager autoload, GameManager states, EventBus signals, CardSlotDisplay component (Wave 1)
- [x] 05-02-PLAN.md -- Card shop overlay with buy/sell/skip, HUD card slots, score threshold-to-shop wiring (Wave 2)
- [x] 05-03-PLAN.md -- Starter card pick overlay, game flow integration, full lifecycle playtest (Wave 3)

### Phase 6: Card Effects -- Physics & Merge
**Goal**: Four card effects that physically change how fruits behave -- bouncing, mass, merge rules, and collision forces -- demonstrating the card system's ability to modify the core physics loop.
**Depends on**: Phase 5, Phase 1
**Requirements**: EFCT-01, EFCT-02, EFCT-03, EFCT-09
**Success Criteria** (what must be TRUE):
  1. Bouncy Berry makes small fruits (tier 1-3) visibly bounce higher on impact compared to default behavior
  2. Heavy Hitter gives the next 3 dropped fruits noticeably more mass, pushing existing fruits harder on contact, and the charge count decrements visibly
  3. Wild Fruit causes one random on-screen fruit to become wild (visually marked), and that fruit merges with same-tier OR adjacent-tier fruits on contact
  4. Cherry Bomb creates a visible outward push on nearby fruits when cherries merge, displacing the surrounding pile
**Plans**: 2 plans

Plans:
- [x] 06-01-PLAN.md -- CardEffectSystem scaffold, Bouncy Berry bounce effect, Cherry Bomb blast with shockwave (Wave 1)
- [x] 06-02-PLAN.md -- Heavy Hitter charge-based mass boost with HUD display, Wild Fruit periodic selection with rainbow shader and adjacent-tier merging (Wave 2)

### Phase 7: Card Effects -- Scoring & Economy
**Goal**: Six card effects that modify score calculations and coin income, giving players strategic choices about optimizing points versus accumulating currency for better cards.
**Depends on**: Phase 5, Phase 2
**Requirements**: EFCT-04, EFCT-05, EFCT-06, EFCT-07, EFCT-08, EFCT-10
**Success Criteria** (what must be TRUE):
  1. Quick Fuse and Fruit Frenzy visibly increase score awards during chain reactions (Quick Fuse for fast consecutive merges, Fruit Frenzy for chains of 3+)
  2. Big Game Hunter awards noticeably more points for tier 7+ merges compared to the base score
  3. Golden Touch and Lucky Break visibly increase coin income (Golden Touch adds per-merge coins, Lucky Break occasionally drops bonus coin pickups)
  4. Pineapple Express awards a visible bonus of +20 coins and +100 score specifically when a pineapple is created from merging
**Plans**: 2 plans

Plans:
- [ ] 07-01-PLAN.md -- Score bonus effects infrastructure + Quick Fuse, Fruit Frenzy, Big Game Hunter with colored bonus popups (Wave 1)
- [ ] 07-02-PLAN.md -- Golden Touch, Lucky Break, Pineapple Express coin/mixed effects with complete dispatcher (Wave 2)

### Phase 8: Card Activation Feedback & Starter Kits
**Goal**: Players see when their cards trigger during gameplay, can choose from distinct starter card sets that shape early strategy, and see a comprehensive run summary at game over.
**Depends on**: Phase 6, Phase 7
**Requirements**: CARD-09, GAME-02, SCOR-05
**Success Criteria** (what must be TRUE):
  1. Active cards visually glow or pulse in the HUD at the moment their effect triggers during gameplay, making it clear which card did what
  2. At run start, player chooses from 2-3 starter card sets (Physics Kit, Score Kit, Economy Kit) that each offer cards biased toward a specific play style
  3. After game over, a run summary screen displays biggest chain, highest tier reached, total merges, cards used during the run, and final score
**Plans**: TBD

Plans:
- [ ] 08-01: TBD
- [ ] 08-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8

Note: Phase 4 depends only on Phase 1 (not Phase 2/3), so it could execute in parallel with Phases 2-3 if desired.
Phases 6 and 7 both depend on Phase 5 and could execute in parallel.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Physics & Merging | 3/3 | ✓ Complete | 2026-02-08 |
| 2. Scoring & Chain Reactions | 2/2 | ✓ Complete | 2026-02-08 |
| 3. Merge Feedback & Juice | 2/2 | ✓ Complete | 2026-02-08 |
| 4. Game Flow & Input | 1/1 | ✓ Complete | 2026-02-08 |
| 5. Card System Infrastructure | 3/3 | ✓ Complete | 2026-02-09 |
| 6. Card Effects -- Physics & Merge | 2/2 | ✓ Complete | 2026-02-09 |
| 7. Card Effects -- Scoring & Economy | 0/2 | Not started | - |
| 8. Card Activation Feedback & Starter Kits | 0/2 | Not started | - |
