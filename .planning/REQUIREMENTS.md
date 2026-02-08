# Requirements: Bucket

**Defined:** 2026-02-07
**Core Value:** The drop-merge-physics loop must feel satisfying and correct -- fruits fall naturally, collide realistically, and merge reliably.

## v1 Requirements

### Core Physics

- [ ] **PHYS-01**: User can drop fruits into a bounded container by clicking/tapping to position horizontally and releasing to drop
- [ ] **PHYS-02**: Fruits obey gravity, collide with each other and container walls, stack and settle naturally using RigidBody2D physics
- [ ] **PHYS-03**: 11 fruit tiers exist (blueberry, cherry, strawberry, lemon, banana, orange, apple, pear, grape, pineapple, watermelon) with increasing sizes
- [ ] **PHYS-04**: Only the 5 smallest fruit tiers appear as drops; tiers 6-11 only appear via merging
- [ ] **PHYS-05**: Two identical fruits auto-merge on contact into the next tier at the contact midpoint
- [ ] **PHYS-06**: Two watermelons merging vanish (clearing space, awarding bonus score)
- [ ] **PHYS-07**: Game ends when any fruit remains above the overflow line for 2+ seconds (grace period prevents false game-overs from bounce)
- [ ] **PHYS-08**: Next fruit to drop is previewed in the UI

### Scoring & Feedback

- [ ] **SCOR-01**: Points awarded on each merge, scaling with fruit tier
- [ ] **SCOR-02**: Chain reaction multiplier for consecutive merges within a short time window (x2, x3, etc.)
- [ ] **SCOR-03**: Merge feedback includes particle burst, screen shake (scaling with tier), and sound effect
- [ ] **SCOR-04**: Chain reactions trigger escalating visual/audio intensity (shake increases, particles shift color, effects build)
- [ ] **SCOR-05**: Run summary screen shows end-of-run stats (biggest chain, highest tier reached, total merges, cards used, final score)

### Card System

- [ ] **CARD-01**: 3 active card slots displayed in the HUD during gameplay
- [ ] **CARD-02**: Game pauses at score thresholds (e.g., 500, 1500, 3500, 7000) to open card shop
- [ ] **CARD-03**: Card shop offers 3-4 cards to choose from; player can buy, skip, or sell existing cards
- [ ] **CARD-04**: In-game coins earned from merges (scaling with tier), displayed in HUD
- [ ] **CARD-05**: At run start, player picks 1 free card from 3 random options (introduces the system immediately)
- [ ] **CARD-06**: Cards have Common, Uncommon, and Rare rarity tiers affecting shop price and appearance frequency
- [ ] **CARD-07**: Player can sell owned cards at the shop for 50% of purchase price
- [ ] **CARD-08**: Cards display clear, unambiguous effect descriptions
- [ ] **CARD-09**: Cards visually glow/pulse when their effect triggers during gameplay
- [ ] **CARD-10**: Per-run economy resets completely between runs (no persistence)
- [ ] **CARD-11**: Score thresholds space out as score increases; card prices increase; rare cards appear in later shops

### Card Effects

- [ ] **EFCT-01**: Bouncy Berry (Common) -- small fruits (tier 1-3) bounce 50% higher on impact
- [ ] **EFCT-02**: Heavy Hitter (Uncommon) -- next 3 drops have 2x mass, push existing fruits harder
- [ ] **EFCT-03**: Wild Fruit (Rare) -- one random fruit on screen becomes wild (merges with same OR adjacent tier)
- [ ] **EFCT-04**: Quick Fuse (Common) -- merges within 1 second of previous merge grant +25% score
- [ ] **EFCT-05**: Fruit Frenzy (Common) -- +2x score multiplier for chains of 3+
- [ ] **EFCT-06**: Big Game Hunter (Uncommon) -- +50% score for tier 7+ merges
- [ ] **EFCT-07**: Golden Touch (Common) -- +2 coins per merge
- [ ] **EFCT-08**: Lucky Break (Uncommon) -- 15% chance any merge drops bonus 5 coins
- [ ] **EFCT-09**: Cherry Bomb (Common) -- when cherries merge, push all fruits in a small radius outward
- [ ] **EFCT-10**: Pineapple Express (Uncommon) -- when a pineapple is created, earn +20 coins and +100 score

### Game Management

- [ ] **GAME-01**: Pause menu with resume, restart, and quit options
- [ ] **GAME-02**: 2-3 starter card sets offering different play styles (Physics Kit, Score Kit, Economy Kit)
- [ ] **GAME-03**: Desktop (mouse/keyboard) and mobile (touch) input support

## v2 Requirements

### Content Expansion

- **POOL-01**: Expand card pool to 20-30 cards
- **SYNC-01**: Card synergy pass -- cards that reference/amplify other cards

### Meta-Progression

- **META-01**: Meta-progression -- unlock new cards to appear in pool
- **SLOT-01**: Unlock 4th and 5th card slots

### Polish

- **EXPR-01**: Fruit expressions/personality (faces that react to gameplay)
- **MOBL-01**: Mobile-specific polish (haptics, swipe gestures)
- **ACCS-01**: Accessibility options (colorblind palettes, UI scaling)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Real-money microtransactions | In-game currency only for v1 |
| Persistent card collections | Per-run roguelike design; persistence kills replayability |
| Multiplayer | Massive scope increase; single-player focus |
| Unlimited card slots | Removes strategic tension; constraint IS the gameplay |
| Time pressure / speed mode | Fights Suika's zen feel; tension from space pressure, not time |
| Complex card crafting | Disproportionate overhead for 5-15 min runs |
| Undo / rewind mechanic | Physics non-determinism makes this technically unreliable |
| Detailed tutorials | Suika is self-evident; tooltips on first run sufficient |
| Fruit skins / cosmetics | Distracts from core polish; readability matters for physics puzzle |
| Achievements / trophies | Metadata not mechanics; defer to v1.x tied to card unlocks |
| Leaderboards / online features | Local play only for v1 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PHYS-01 | Phase 1 | Pending |
| PHYS-02 | Phase 1 | Pending |
| PHYS-03 | Phase 1 | Pending |
| PHYS-04 | Phase 1 | Pending |
| PHYS-05 | Phase 1 | Pending |
| PHYS-06 | Phase 1 | Pending |
| PHYS-07 | Phase 1 | Pending |
| PHYS-08 | Phase 1 | Pending |
| SCOR-01 | Phase 2 | Pending |
| SCOR-02 | Phase 2 | Pending |
| SCOR-03 | Phase 3 | Pending |
| SCOR-04 | Phase 3 | Pending |
| SCOR-05 | Phase 8 | Pending |
| CARD-01 | Phase 5 | Pending |
| CARD-02 | Phase 5 | Pending |
| CARD-03 | Phase 5 | Pending |
| CARD-04 | Phase 5 | Pending |
| CARD-05 | Phase 5 | Pending |
| CARD-06 | Phase 5 | Pending |
| CARD-07 | Phase 5 | Pending |
| CARD-08 | Phase 5 | Pending |
| CARD-09 | Phase 8 | Pending |
| CARD-10 | Phase 5 | Pending |
| CARD-11 | Phase 5 | Pending |
| EFCT-01 | Phase 6 | Pending |
| EFCT-02 | Phase 6 | Pending |
| EFCT-03 | Phase 6 | Pending |
| EFCT-04 | Phase 7 | Pending |
| EFCT-05 | Phase 7 | Pending |
| EFCT-06 | Phase 7 | Pending |
| EFCT-07 | Phase 7 | Pending |
| EFCT-08 | Phase 7 | Pending |
| EFCT-09 | Phase 6 | Pending |
| EFCT-10 | Phase 7 | Pending |
| GAME-01 | Phase 4 | Pending |
| GAME-02 | Phase 8 | Pending |
| GAME-03 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 37 total
- Mapped to phases: 37
- Unmapped: 0

---
*Requirements defined: 2026-02-07*
*Last updated: 2026-02-07 after roadmap creation*
