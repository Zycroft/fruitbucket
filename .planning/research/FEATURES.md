# Feature Research

**Domain:** Suika-style physics puzzle game with roguelike card modifier system
**Researched:** 2026-02-07
**Confidence:** MEDIUM-HIGH (core Suika mechanics well-documented; card modifier design draws from established roguelike patterns; hybrid combination is novel territory)

## Feature Landscape

### Table Stakes: Suika Core Mechanics (Users Expect These)

Features users assume exist from playing any Suika/fruit-merge game. Missing these means the game does not function as a Suika game.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| 11-tier fruit progression | Defining mechanic of the genre. Every Suika clone uses 11 tiers (cherry through watermelon). Players expect the full chain. | MEDIUM | The merge chain IS the game. Blueberry -> cherry -> strawberry -> lemon -> banana -> orange -> apple -> pear -> grape -> pineapple -> watermelon per PROJECT.md. Two watermelons merging should vanish (score bonus, clears space). |
| Physics-based fruit dropping | Fruits must obey gravity, collide, stack, and settle naturally. The unpredictability of physics is what makes Suika fun vs a static puzzle. | HIGH | This is the hardest table-stakes feature. Godot's RigidBody2D handles basics, but tuning mass, friction, bounciness, and collision shapes per fruit size is where the "feel" lives. Must feel weighty, not floaty. |
| Container with overflow game-over | Bounded play area where fruits pile up. Game ends when any fruit crosses the top line. Creates tension and stakes. | LOW | Simple boundary check. The emotional weight comes from the physics (will that stack hold?). Consider a grace period (1-2 seconds above line) so physics settling does not cause unfair deaths. |
| Click/tap to position, release to drop | Standard input pattern across all Suika games. Player sees a guide line, positions horizontally, drops. | LOW | Must support both mouse and touch. Show a dotted drop guide line. Horizontal positioning only (no angle control -- that is Suika Planet's differentiator, not table stakes). |
| Next fruit preview | Players need to plan ahead. Every Suika game shows the next fruit. Without it, the game feels random rather than strategic. | LOW | Show next fruit in a UI element. Only the 5 smallest fruits appear as drops (6-11 only appear via merging). This is standard across all references. |
| Auto-merge on contact | When two identical fruits touch, they merge instantly into the next tier. No player action required beyond positioning. This is the core loop. | MEDIUM | Collision detection between same-tier fruits. Merge produces next-tier fruit at contact midpoint. Must handle edge cases: three same-tier fruits touching simultaneously (merge the first pair, remaining fruit may then merge with result). |
| Score system | Points awarded on merge. Bigger merges = more points. Players need visible feedback on progress. | LOW | Point values should scale meaningfully. Standard pattern: tier N merge awards roughly N*(N+1)/2 points (cumulative value). Display prominently. |
| Chain reaction bonuses | When a merge creates a fruit that immediately touches and merges with another identical fruit, chain reactions occur. The most satisfying moment in Suika. | MEDIUM | Chains should be visually and audibly distinct from single merges. Consider a chain multiplier (x2, x3, etc.) for consecutive merges within a short time window. This is where "juice" matters most. |
| Satisfying merge feedback ("juice") | Screen shake, particle effects, sound effects, brief flash on merge. Players expect tactile feedback. Without it, merges feel flat and the game feels cheap. | MEDIUM | Particle burst on merge, slight screen shake scaling with fruit tier, satisfying pop/squelch sound, brief glow on newly created fruit. Chain reactions should escalate the feedback intensity. This is table stakes because every polished Suika clone has it. |
| Pause and restart | Players expect to pause mid-game and restart a run. Basic game state management. | LOW | Pause menu with resume/restart/quit. On mobile, pausing on app background is expected. |

### Table Stakes: Roguelike Card System (Users Expect These)

Features that define the roguelike card modifier layer. Since this IS the game's identity (not just "another Suika clone"), the card system must meet baseline roguelike expectations.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Per-run card economy (no persistence) | Core roguelike identity. Each run starts fresh. Players who know Slay the Spire, Balatro, etc. expect this. Persistence would make it a roguelite, which is a different game. | LOW | Clean state on run start. No save/load of card state between runs. Future milestones may add meta-progression (unlocking new cards to appear in the pool), but the economy resets each run. |
| Card slots (3-5 active) | Limited slots force meaningful choices. This is the Balatro joker slot pattern -- constraint creates strategy. Players must choose which modifiers to keep. | LOW | UI showing 3-5 slots. Start with 3, potentially expand to 5 via special cards or score milestones. Selling/replacing cards in occupied slots is the key decision point. |
| Card shop at score thresholds | Natural pacing mechanism. Reaching score milestones pauses gameplay and offers card choices. Players expect a shop/reward flow between gameplay segments. | MEDIUM | Define threshold curve (e.g., 500, 1500, 3500, 7000, 15000). Shop offers 3-4 cards to choose from. Player can buy, skip, or sell existing cards. Must feel like a meaningful break, not an interruption. |
| In-game currency (coins from merges) | Economy fuel. Players need a resource to spend in the shop. Earning it from merges ties the economy to core gameplay skill. | LOW | Award coins on merge, scaling with tier. Coins displayed in HUD. Spent in card shop. Consider bonus coins for chains. |
| Starter card(s) | Every roguelike run begins with something. Starting with zero cards means the card system is invisible for the early game. Free starter card(s) introduce the system immediately. | LOW | Offer 1 free card pick from 3 options at run start (before first drop). Or give a fixed starter card. The pick approach is better -- it introduces the shop mechanic early and gives the player agency. |
| Card effect descriptions | Cards must clearly explain what they do. Roguelike players expect readable, unambiguous effect text. Balatro and Slay the Spire set the standard here. | LOW | Tooltip or card face text. Use consistent terminology. "When fruits merge: +X coins" or "All [type] fruits: +Y% merge radius." Avoid vague language. |
| Card rarity system | Common, uncommon, rare cards. Rarity gates power level and creates excitement when rare cards appear. Every roguelike modifier system uses rarity. | LOW | 3 tiers: Common (frequent, small effects), Uncommon (moderate, conditional), Rare (powerful, build-defining). Rarity affects shop price and appearance frequency. |

### Differentiators: Card Effects That Modify Physics (Competitive Advantage)

These are the features that make Bucket unique. The specific card effects and how they interact with the physics system is where the game differentiates from both standard Suika AND standard roguelikes. Organized by modifier category (following Balatro's proven taxonomy).

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Physics Modifier Cards** | Alter how fruits physically behave -- bouncy, heavy, sticky, slippery. No other Suika game does this. Changes the "feel" of gameplay mid-run. | HIGH | Examples: "Bouncy Berries" (small fruits bounce 2x higher), "Lead Weight" (next 5 drops fall faster and push harder), "Sticky Jam" (fruits resist sliding after landing). Must be tuned carefully -- physics modifiers can break gameplay if too extreme. |
| **Merge Rule Modifier Cards** | Change WHAT can merge or HOW merges work. The deepest strategic layer. | HIGH | Examples: "Wild Fruit" (one fruit counts as any type for merging, a la Balatro's Wild Card), "Cascade" (merging triggers a small explosion pushing nearby fruits), "Evolution Skip" (merge jumps 2 tiers instead of 1, but only once per activation). These are build-defining cards. |
| **Score Multiplier Cards** | Additive or multiplicative bonuses to scoring. The Balatro "+Mult / xMult" pattern translated to Suika. Creates the number-go-up dopamine. | MEDIUM | Examples: "Fruit Frenzy" (+2x score for chains of 3+), "Big Game Hunter" (x1.5 score for tier 8+ merges), "Combo King" (+50 bonus per chain link). Additive bonuses for common cards, multiplicative for rare. |
| **Economy Modifier Cards** | Alter coin generation. Fund bigger shops, create economic engines. The Balatro "Economy Joker" pattern. | LOW | Examples: "Golden Touch" (+3 coins per merge), "High Roller" (double shop offerings but 50% price increase), "Penny Pincher" (10% chance any merge drops a bonus coin). |
| **Conditional/Triggered Cards** | Effects that activate only under specific conditions. Creates "build crafting" where the player shapes their strategy around card synergies. | MEDIUM | Examples: "Cherry Bomb" (when cherries merge, all adjacent fruits get pushed away), "Watermelon Dream" (if you create a watermelon, all cards activate twice this run), "Pineapple Express" (+5 coins every time a pineapple is created). Condition-based cards are where replayability lives. |
| **Card synergy system** | Cards that reference or amplify other cards. The "build" emerges from card combinations, not individual cards. This is what makes Balatro/StS endlessly replayable. | HIGH | Example: "Fruit Salad" (gain +1 Mult for each unique fruit type on screen) synergizes with cards that prevent merging or that spawn specific fruit types. Synergies should be discoverable, not prescribed -- emergent > scripted. |
| **Card selling/recycling** | Sell owned cards for coins. Creates a secondary economy and prevents "dead card" frustration. Standard in Balatro (sell jokers) and StS (remove cards). | LOW | Sell at shop for 50% of purchase price. Prevents slot lock-in. Encourages experimentation. |

### Differentiators: Juice and Polish (What Makes It Feel Premium)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Escalating chain reaction effects | Chains of 3+ merges trigger increasingly dramatic visual/audio feedback. Screen shake intensifies, particle colors shift, music swells. Makes skilled play feel spectacular. | MEDIUM | Most Suika clones have basic merge effects. Few escalate based on chain length. This is cheap differentiation -- high impact, moderate effort. |
| Card activation animations | When a card triggers, it visually activates (glow, pulse, flip). Players see WHICH card caused an effect. Borrowed from Balatro's joker activation feedback. | MEDIUM | Brief highlight animation on the card slot when its effect triggers. Essential for player understanding of card interactions. Without this, cards feel invisible. |
| Fruit personality/expressions | Fruits have faces that react to gameplay (happy when merging, worried when stacked high, scared near the top line). Adds charm beyond static sprites. | LOW | Simple sprite swaps based on position/state. Not animated -- just expression variants. Cheap personality. |
| Run summary/stats screen | End-of-run breakdown: biggest chain, highest-tier fruit created, total merges, cards used, final score. Roguelike players expect this. | LOW | Post-game-over screen with key stats. Encourages "one more run" and gives players something to screenshot/share. |

### Differentiators: Game Structure

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Score threshold difficulty curve | As score increases, card shop thresholds space out, card prices increase, and rare cards become available. Creates natural difficulty ramp within a single run. | MEDIUM | Early game: frequent shops, cheap common cards. Mid game: less frequent, uncommon cards appear. Late game: rare cards available but expensive. Mirrors Balatro's ante progression. |
| Multiple starter card sets | Choose from 2-3 "starter kits" at run start, each nudging toward a different play style (e.g., "Physics Kit" with bouncy/heavy cards, "Score Kit" with multiplier focus, "Economy Kit" with coin generation). | LOW | Low complexity to implement (just curated starting options), but high replay value. Each starter set teaches a different build archetype. Add more sets as content grows. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems for this specific game.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Persistent card collection between runs | "I want to keep my progress!" Players conditioned by gacha/collection games. | Destroys roguelike identity. Persistence means optimal builds are solved, killing replayability. Balatro resets each run for a reason. Also adds save system complexity. | Per-run card economy with meta-progression limited to UNLOCKING new cards that can appear in the pool (never guaranteed). Unlocks expand variety without creating power persistence. |
| Real-time multiplayer | "I want to compete against friends!" Competitive Suika exists (Suika Planet co-op). | Massively increases scope: networking, synchronization, latency compensation for physics, matchmaking. For v1, this is a project killer. | Local high score comparison. Consider async "ghost" replays as a future milestone. Multiplayer is a v3+ feature. |
| Unlimited card slots | "Why can't I hold more cards?" Players want to stack all the buffs. | Removes the core strategic tension. With unlimited slots, there is no reason to sell or skip cards. The game becomes "collect everything" instead of "choose wisely." Balatro limits joker slots to 5 for this exact reason. | Start with 3 slots. Rare cards or achievements can unlock slots 4 and 5. Never exceed 5. The constraint IS the gameplay. |
| Time pressure / speed mode | "Add a timer for excitement!" Some puzzle games use time limits. | Suika's appeal is its zen, no-time-pressure flow. Adding time pressure fights the core game feel. The tension comes from SPACE pressure (overflow), not TIME pressure. | The overflow mechanic already provides all the tension needed. If players want more urgency, that comes from physics modifier cards (faster drops, heavier fruits) that they opt into. |
| Complex card crafting/combining | "Let me combine two cards into a stronger one!" Crafting systems are popular. | Adds significant UI complexity, balance burden, and combinatorial explosion. For a game where runs are 5-15 minutes, the crafting overhead is disproportionate. | Card rarity tiers with clear power scaling. Rare cards ARE the "crafted" versions. Keep the card system as pick-and-play, not a meta-puzzle within the puzzle. |
| Fruit skins / cosmetic customization | "I want to customize my fruits!" Cosmetic systems are monetization-ready. | Distracts from core game polish. Custom fruit skins may conflict with the readability requirement (players must instantly identify fruit tiers by appearance). Art consistency matters for a physics puzzle. | Single polished art set. Consider palette swaps for accessibility (colorblind mode) rather than cosmetic skins. Cosmetics are a v2+ feature if demand exists. |
| Undo / rewind mechanic | "Let me take back my last drop!" Puzzle games sometimes offer undo. | Physics simulation is non-deterministic in practice (floating point, timing). Rewinding physics state reliably is technically hard and breaks the commitment-to-drop tension that defines Suika. | One "preview drop" card that shows where the fruit will land (physics simulation preview). This helps planning without removing commitment. Or a rare card that "freezes" all fruit briefly, letting you reposition. |
| Detailed tutorials / onboarding | "New players need a tutorial!" Seems responsible. | Suika's genius is that the mechanics are self-evident. A formal tutorial interrupts the discovery. Overexplaining cards kills the roguelike discovery moment. | First-run tooltip hints (3-4 max). "Drop fruits. Match to merge." and "Cards modify your game." Let the game teach itself. Card descriptions do the heavy lifting for the roguelike layer. |
| Achievements / trophy system | "Give me goals to chase!" Achievement systems drive engagement. | For v1, achievements add scope without adding gameplay. They are metadata, not mechanics. | Defer to v1.x. When added, tie achievements to card unlocks (meta-progression trigger) so they serve a gameplay purpose, not just trophy collection. |

## Feature Dependencies

```
[Physics Engine (RigidBody2D, collision)]
    |
    +--requires--> [Fruit Dropping Mechanic]
    |                   |
    |                   +--requires--> [Next Fruit Preview]
    |                   |
    |                   +--requires--> [Container + Overflow Detection]
    |
    +--requires--> [Auto-Merge System]
                       |
                       +--requires--> [Score System]
                       |                  |
                       |                  +--requires--> [Chain Reaction Bonus]
                       |                  |
                       |                  +--requires--> [Coin Economy]
                       |                                     |
                       |                                     +--requires--> [Card Shop]
                       |                                                       |
                       |                                                       +--requires--> [Card Slot System]
                       |                                                       |
                       |                                                       +--requires--> [Card Rarity]
                       |                                                       |
                       |                                                       +--requires--> [Starter Cards]
                       |
                       +--enhances--> [Merge Feedback / Juice]

[Card Slot System]
    |
    +--requires--> [Card Effect Descriptions]
    |
    +--requires--> [Card Selling/Recycling]
    |
    +--enables--> [Physics Modifier Cards]
    |
    +--enables--> [Merge Rule Modifier Cards]
    |
    +--enables--> [Score Multiplier Cards]
    |
    +--enables--> [Economy Modifier Cards]
    |
    +--enables--> [Conditional/Triggered Cards]

[Physics Modifier Cards] --conflicts--> [Undo/Rewind Mechanic]
    (physics modifiers make state rewinding even harder)

[Card Synergy System] --requires--> [Multiple card effect types exist]
    (synergies need at least 2-3 card categories to be meaningful)

[Multiple Starter Card Sets] --requires--> [Card pool of 15+ cards minimum]
    (need enough cards to create distinct starter archetypes)
```

### Dependency Notes

- **Physics Engine requires tuning before cards**: The base physics must feel right BEFORE adding modifier cards that alter it. A bouncy card on broken physics = compounded brokenness.
- **Score System requires before Coin Economy**: Coins derive from score events. Score system must be stable before layering economy on top.
- **Card Shop requires Coin Economy**: No shop without currency. Economy must feel fair before shop pricing is meaningful.
- **Card Synergy requires card variety**: Synergies only matter when there are 15+ cards across 3+ categories. Do not design synergies first; design individual cards, then discover/promote natural synergies.
- **Starter Card Sets require card pool depth**: Cannot offer meaningful starter archetypes with fewer than 15 cards. Defer starter sets until card pool is large enough.
- **Physics Modifier Cards conflict with Undo**: Physics modifiers create non-reversible state changes. Do not attempt undo if physics modifiers exist.

## MVP Definition

### Launch With (v1)

Minimum viable product -- what is needed to validate "Suika + roguelike cards" as a concept.

- [ ] **11-tier fruit merge with physics** -- the core loop. Without this, there is no game.
- [ ] **Container with overflow game-over** -- creates stakes and run structure.
- [ ] **Score system with chain bonuses** -- gives players a number to chase.
- [ ] **Next fruit preview** -- enables planning, lifts gameplay above random.
- [ ] **Basic merge juice** (particles, sound, screen shake) -- makes merges feel good.
- [ ] **3 card slots with 8-12 initial cards** -- enough to demonstrate the card system without needing massive content.
- [ ] **Card shop at 3-4 score thresholds** -- proves the pacing mechanic works.
- [ ] **Coin economy from merges** -- ties card acquisition to gameplay skill.
- [ ] **1 starter card pick** -- introduces card system at run start.
- [ ] **Card effect descriptions** -- players must understand their cards.
- [ ] **Pause and restart** -- basic game state management.

### Add After Validation (v1.x)

Features to add once core loop is proven fun.

- [ ] **Expand card pool to 20-30 cards** -- when playtesting reveals which card categories are most fun, double down on those.
- [ ] **Card rarity system (Common/Uncommon/Rare)** -- when card pool is large enough to stratify meaningfully (15+ cards minimum).
- [ ] **Card synergy pass** -- review card pool for emergent synergies, add 2-3 cards designed to enable specific combos.
- [ ] **Card selling/recycling** -- when playtesters report "dead card" frustration (they will).
- [ ] **Multiple starter card sets** -- when card pool reaches 20+ and distinct archetypes emerge naturally.
- [ ] **Score threshold difficulty curve** -- ramp shop spacing and pricing as run progresses.
- [ ] **Run summary/stats screen** -- post-game-over breakdown to encourage replays.
- [ ] **Card activation animations** -- when card system is stable, add visual feedback for card triggers.
- [ ] **Escalating chain reaction effects** -- polish pass on merge feedback.

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Meta-progression (unlock new cards for the pool)** -- adds long-term engagement loop but requires stable card balance first.
- [ ] **Additional card slots (4th, 5th)** -- earned through meta-progression or rare in-run events.
- [ ] **Fruit expressions/personality** -- polish feature, adds charm but not gameplay.
- [ ] **Daily challenge mode** -- seeded runs with fixed card offerings for community competition.
- [ ] **Mobile-specific polish** -- haptic feedback on merge, swipe gestures, etc.
- [ ] **Accessibility options** -- colorblind fruit palettes, larger UI scaling.
- [ ] **Async competitive features** -- ghost replays, score sharing.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| 11-tier fruit merge physics | HIGH | HIGH | P1 |
| Container + overflow game-over | HIGH | LOW | P1 |
| Score system + chain bonuses | HIGH | MEDIUM | P1 |
| Next fruit preview | HIGH | LOW | P1 |
| Merge juice (particles/sound/shake) | HIGH | MEDIUM | P1 |
| Card slot system (3 slots) | HIGH | MEDIUM | P1 |
| Initial card pool (8-12 cards) | HIGH | HIGH | P1 |
| Card shop at score thresholds | HIGH | MEDIUM | P1 |
| Coin economy | MEDIUM | LOW | P1 |
| Starter card pick | MEDIUM | LOW | P1 |
| Card descriptions | MEDIUM | LOW | P1 |
| Pause/restart | MEDIUM | LOW | P1 |
| Card rarity system | MEDIUM | LOW | P2 |
| Card selling/recycling | MEDIUM | LOW | P2 |
| Expanded card pool (20-30) | HIGH | HIGH | P2 |
| Card synergy pass | HIGH | MEDIUM | P2 |
| Multiple starter sets | MEDIUM | LOW | P2 |
| Score threshold curve | MEDIUM | MEDIUM | P2 |
| Run summary screen | MEDIUM | LOW | P2 |
| Card activation animations | MEDIUM | MEDIUM | P2 |
| Chain escalation effects | MEDIUM | MEDIUM | P2 |
| Meta-progression unlocks | HIGH | HIGH | P3 |
| Additional card slots | MEDIUM | LOW | P3 |
| Fruit expressions | LOW | LOW | P3 |
| Daily challenge mode | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for launch (validates the "Suika + roguelike cards" concept)
- P2: Should have, add when core loop is proven (polish + content expansion)
- P3: Nice to have, future milestones (growth features)

## Competitor Feature Analysis

| Feature | Standard Suika (suikagame.co.uk) | Arkadium Fruit Merge | Suika Game Planet (2026) | Fruitbearer (2026) | Balatro (reference) | **Bucket (Our Approach)** |
|---------|----------------------------------|---------------------|--------------------------|-------------------|--------------------|----|
| Fruit merge chain | 11 tiers, basic | 11 tiers, point values displayed | 11 tiers, circular stage | Fruit merging as deckbuilder combat | N/A | 11 tiers with chain multiplier scoring |
| Physics feel | Standard gravity | Bouncy, fruits can exit container | 360-degree gravity (planet) | Unknown (unreleased) | N/A | Tuned gravity + physics modifier cards change feel mid-run |
| Modifier system | None | None | Super Evolution Time (chain bonus mode) | Card-based fruit selection and deck building | 150 Jokers across 7 categories | 3-5 card slots with physics/merge/score/economy modifiers |
| Shop/economy | None | None | None | Between-level card shop | Shop between rounds with reroll | In-run shop at score thresholds, coins from merges |
| Replayability | Score chasing only | Score chasing only | Score chasing + co-op | Roguelike runs with deck variety | Infinite via joker combinations | Per-run card builds create unique gameplay each time |
| Input method | Click to drop | Click to drop | 360-degree drop angle | Card selection + merge | Card selection | Click/tap to drop (standard) |
| Unique hook | Push mechanic (nudge fruits) | Polished art, bouncy physics | Circular planet stage, multiplayer | Dark aesthetic, deckbuilder framing | Poker hand scoring with modifier stacking | Physics-altering cards on a Suika base |

### Key Competitive Insights

**vs. Standard Suika clones:** Every clone has the same 11-tier merge. The card system is the entire differentiator. Without it, Bucket is clone #10,000.

**vs. Suika Game Planet:** Planet differentiates through stage geometry (circular) and input (360-degree). Bucket differentiates through gameplay modifiers (cards). These are orthogonal -- not competing on the same axis.

**vs. Fruitbearer:** Most direct competitor. Fruitbearer frames fruit merging as deckbuilder combat (different genre feel). Bucket keeps the zen Suika gameplay loop intact and layers cards ON TOP rather than replacing the core loop. Bucket's advantage: familiar Suika feel + roguelike depth. Fruitbearer's advantage: darker aesthetic, more "gamer" framing. Key risk: if Fruitbearer ships first (March 2026), it may define the "roguelike Suika" concept.

**vs. Balatro (design reference, not competitor):** Balatro's modifier taxonomy (additive/multiplicative/economy/retrigger/conditional) is the blueprint for Bucket's card categories. The 5-joker-slot constraint, shop economy, and rarity system are proven patterns to adopt directly. Do NOT try to out-Balatro Balatro -- adopt the structural patterns, apply them to physics puzzles.

## Recommended Initial Card Pool (8-12 Cards for MVP)

Based on Balatro's proven joker category taxonomy, mapped to physics-puzzle context:

### Physics Modifiers (2-3 cards)
- **Bouncy Berry** (Common): Small fruits (tier 1-3) bounce 50% higher on impact. Creates chaos but opens merge opportunities.
- **Heavy Hitter** (Uncommon): Next 3 drops have 2x mass. Pushes existing fruits harder on landing. Risk/reward: can cause chain reactions or overflow.

### Merge Rule Modifiers (2-3 cards)
- **Wild Fruit** (Rare): One random fruit on screen becomes "wild" (merges with any adjacent same-OR-adjacent-tier fruit). Build-defining.
- **Quick Fuse** (Common): Merges within 1 second of a previous merge grant +25% score. Rewards chain setups.

### Score Modifiers (2 cards)
- **Fruit Frenzy** (Common): +2x score multiplier for chains of 3+.
- **Big Game Hunter** (Uncommon): +50% score for tier 7+ merges (pear and above).

### Economy Modifiers (1-2 cards)
- **Golden Touch** (Common): +2 coins per merge.
- **Lucky Break** (Uncommon): 15% chance any merge drops a bonus 5 coins.

### Conditional/Triggered (1-2 cards)
- **Cherry Bomb** (Common): When cherries merge, push all fruits within a small radius outward. Creates space.
- **Pineapple Express** (Uncommon): When a pineapple is created via merging, earn +20 coins and +100 score.

This gives 10 cards across 5 categories: enough variety for meaningful shop choices without overwhelming content creation needs.

## Sources

- [Suika Game - Wikipedia](https://en.wikipedia.org/wiki/Suika_Game) -- core mechanics, fruit progression, game history (MEDIUM confidence)
- [Suika Game Planet - Saiga NAK](https://saiganak.com/release/suikagame-planet/) -- sequel features, Super Evolution Time (MEDIUM confidence)
- [Suika Game Planet - GoNintendo](https://gonintendo.com/contents/56203-suika-game-planet-heads-to-switch-switch-2-on-jan-5th-2026) -- 360-degree mechanics, co-op (MEDIUM confidence)
- [Balatro Card Modifiers - Fandom Wiki](https://balatrogame.fandom.com/wiki/Card_Modifiers) -- enhancement/edition/seal/sticker taxonomy (HIGH confidence)
- [Balatro Jokers - Fandom Wiki](https://balatrogame.fandom.com/wiki/Jokers) -- 7 joker categories, slot system, synergy patterns (HIGH confidence)
- [Balatro Design Analysis - Oreate AI](https://www.oreateai.com/blog/indepth-analysis-of-the-game-design-philosophy-and-roguelike-mechanisms-in-balatro/4fdfc5f5314b10a83aa161f2aa243254) -- shop pacing, modifier system design philosophy (MEDIUM confidence)
- [Slay the Spire Relics - Fandom Wiki](https://slay-the-spire.fandom.com/wiki/Relics) -- passive modifier patterns, relic taxonomy (HIGH confidence)
- [Luck Be a Landlord - Wikipedia](https://en.wikipedia.org/wiki/Luck_Be_a_Landlord) -- symbol synergy patterns, rent escalation as difficulty curve (MEDIUM confidence)
- [Fruitbearer - Steam](https://store.steampowered.com/app/4300180/Fruitbearer/) -- direct competitor, roguelike deckbuilder Suika hybrid (MEDIUM confidence)
- [Suika Game Fruits Points List](https://suikagame.com/games/suika-game-fruits-points-list/) -- fruit progression reference (MEDIUM confidence)
- [Roguelike Deck-Building Game - Wikipedia](https://en.wikipedia.org/wiki/Roguelike_deck-building_game) -- genre patterns, design conventions (MEDIUM confidence)
- [Roguelite Progression Systems - Game Rant](https://gamerant.com/roguelite-games-with-best-progression-systems/) -- Hades currency structure, meta-progression patterns (MEDIUM confidence)

---
*Feature research for: Suika-style physics puzzle with roguelike card modifiers*
*Researched: 2026-02-07*
