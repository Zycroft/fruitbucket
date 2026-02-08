# Phase 2: Scoring & Chain Reactions - Context

**Gathered:** 2026-02-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Every merge awards points scaled by fruit tier, and rapid consecutive merges trigger chain reaction multipliers that reward skillful play. Coins are also implemented as a score-derived currency. Visual merge feedback (particles, screen shake, sound) belongs to Phase 3.

</domain>

<decisions>
## Implementation Decisions

### Score values & scaling
- Exponential scaling (Suika-style): each tier worth roughly double the previous (e.g., 1, 2, 4, 8, 16... up to 512)
- Watermelon merge (top-tier, two watermelons vanishing) gets a large flat bonus on top of exponential value (e.g., +1000)
- Point values stored as a data resource (not hardcoded) for easy tuning during balancing

### Chain mechanics
- Chains are cascade-based: a merge result must physically trigger the next merge — no time window, purely physics-driven
- Chain multiplier escalates at an accelerating rate (x2, x3, x5, x8...) — rare long chains feel explosive
- No cap on chain multiplier — legendary chains feel legendary

### Score display
- Every merge shows a floating score popup at the merge point (e.g., "+16" or "+64 x3!") that rises and fades
- Prominent chain counter appears during chains (e.g., "CHAIN x3!") — hype moment, visible near the action
- Score counter animates when updating — numbers roll/count up to new value with scale punch on big gains

### Coin economy
- Coins are score-derived: awarded when cumulative score crosses thresholds (e.g., every 100 score = 1 coin), not per-merge
- Coin counter displayed in the HUD

### Claude's Discretion
- Score threshold awareness for Phase 5 shop triggers (whether to emit signals now or defer)
- Exact exponential point values per tier
- Per-merge vs end-of-chain multiplier application timing
- Coin conversion ratio and whether it's fixed or escalating
- Whether chain multipliers affect coin income
- Main score placement in HUD (fits with existing layout)
- Coin display style (floating popups or HUD-only)

</decisions>

<specifics>
## Specific Ideas

- Suika Game as the reference for exponential scoring feel — higher tier merges should feel dramatically more valuable
- Chain counter should feel like a "hype moment" — prominent, exciting, scales with chain length
- Coins as score-derived currency is a deliberate design choice to keep economy predictable and prevent per-merge coin flooding

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-scoring-chain-reactions*
*Context gathered: 2026-02-08*
