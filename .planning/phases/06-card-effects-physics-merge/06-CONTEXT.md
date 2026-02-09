# Phase 6: Card Effects -- Physics & Merge - Context

**Gathered:** 2026-02-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Four card effects that physically change how fruits behave -- bouncing, mass, merge rules, and collision forces. This phase demonstrates the card system's ability to modify the core physics loop. No new card infrastructure (Phase 5 handles that), no scoring/economy cards (Phase 7).

</domain>

<decisions>
## Implementation Decisions

### Effect Visibility (General)
- Effects should feel **dramatic and fun** -- 50-100% property changes, fruits fly around more
- Whether effects apply retroactively depends on the card:
  - Bouncy Berry: retroactive (all tier 1-3 fruits in bucket get the bounce boost immediately)
  - Heavy Hitter: new drops only (charge-based, applies to next N drops)
  - Wild Fruit: retroactive (selects from fruits already in bucket)
  - Cherry Bomb: trigger-based (activates on cherry merge events)
- Duplicate cards stack linearly (two Bouncy Berrys = double the bounce boost)

### Bouncy Berry
- Claude's discretion on visual treatment (glow on impact, persistent marker, etc.)
- Affects tier 1-3 fruits
- Retroactive -- existing fruits in bucket gain the bounce boost

### Heavy Hitter Charges
- 3 charges per activation cycle
- Charge display: **both** card HUD slot (shows remaining count) AND drop preview (fruit looks different when heavy)
- After all 3 charges used: card **recharges after N merges** (not time-based, not one-shot)
- All 3 charges refill at once after the merge threshold
- Claude's discretion on which fruit tiers are affected (all drops vs large only)
- Claude's discretion on whether heavy fruits look different after landing
- Overflow risk from heavy pushes is **intentional** -- risk/reward tradeoff, part of the fun
- Claude's discretion on whether recharge pattern is reusable for future cards or Heavy Hitter-specific

### Wild Fruit Behavior
- Wild fruits are selected **periodically** (every N merges), not on purchase or on drop
- Rainbow shimmer visual treatment -- cycling rainbow outline/shimmer so wild fruits are eye-catching
- When a wild fruit merges with an adjacent tier, result **always upgrades** to the higher tier's next tier (generous, rewarding)
- Claude's discretion on how many wild fruits can exist simultaneously

### Cherry Bomb Force
- Triggers only on **cherry (tier 1) merges** -- two cherries merging = explosion
- Blast force is **big and chaotic** -- nearby fruits get launched, can scatter the pile
- Visual: **shockwave ring** expanding from the merge point, clearly showing blast radius
- Chain reactions from the blast are **intentional** -- strategic cherry placement can trigger merge chains
- Part of the card's value is the chain reaction potential

</decisions>

<specifics>
## Specific Ideas

- "Dramatic and fun" intensity baseline -- effects should be game-changing, not subtle tweaks
- Heavy Hitter overflow risk is a feature, not a bug -- risk/reward is the fun
- Cherry Bomb should enable strategic play through chain reactions from blast displacement
- Wild Fruit rainbow shimmer should be the most visually distinctive marker in the game
- Linear stacking of duplicate cards rewards players who commit to a physics-focused strategy

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 06-card-effects-physics-merge*
*Context gathered: 2026-02-09*
