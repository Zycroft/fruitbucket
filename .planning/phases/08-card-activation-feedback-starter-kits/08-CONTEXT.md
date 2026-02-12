# Phase 8: Card Activation Feedback & Starter Kits - Context

**Gathered:** 2026-02-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Players see when their cards trigger during gameplay (visual feedback on all 10 existing card effects), choose from themed starter kits instead of random card picks, and see a celebratory run summary screen at game over. No new card effects, no new game mechanics — this is polish and presentation for the existing card system.

</domain>

<decisions>
## Implementation Decisions

### Card trigger animation
- Glow + scale bounce combo on the HUD card slot when its effect fires
- Glow color matches card rarity: Common=white, Uncommon=green, Rare=purple
- No additional text near the card slot — existing on-screen bonus popups are sufficient
- All 10 existing card effects (Phases 6-7) get trigger feedback wired up

### Trigger frequency handling
- Claude's discretion on dampening rapid re-triggers (e.g. Golden Touch fires every merge)

### Simultaneous triggers
- Staggered animation with ~0.15s delay between cards when multiple trigger on the same merge
- Player can visually track which cards fired in sequence

### Charge vs passive cards
- Charge-based cards (e.g. Heavy Hitter) get a more prominent animation than passive/always-on cards
- Claude's discretion on the exact differentiation (bigger bounce, longer glow, etc.)

### Starter kit selection
- 2 themed kits + 1 "Surprise" random option (not 3 themed kits)
- Each kit gives 1 card (same as current starter pick slot count)
- Replaces current starter pick overlay — same full-screen layout, but options labeled as kits
- Kit name visible, specific card hidden — player discovers what's inside after choosing
- Themed kits are Physics Kit and Score Kit; Surprise gives a random card from any category

### Run summary screen
- Celebratory reveal style — stats animate in one by one with small fanfare
- 7 stats displayed: biggest chain, highest tier reached (with visual fruit circle + name), total merges, cards used during run, total coins earned, time played, final score
- Two actions: "Play Again" (restart) and "Quit" (reload/close)

### Claude's Discretion
- Frequency dampening approach for rapid card triggers
- Whether to add a subtle visual link (matching rarity color) between HUD glow and on-screen effect
- Exact charge-card animation differentiation
- Stats reveal order and animation timing
- What "Quit" does (no main menu exists — likely page reload for web)

</decisions>

<specifics>
## Specific Ideas

- Card trigger animation should be noticeable but not disruptive to gameplay flow
- Starter kit hidden cards add a discovery/learning element — players learn what each kit gives over multiple runs
- Run summary "celebratory reveal" should make even mediocre runs feel like progress, but great runs should feel special (bigger chains, higher tiers = more dramatic reveals)
- Highest tier stat shows the actual colored fruit circle, not just text — ties back to the visual language of the game

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-card-activation-feedback-starter-kits*
*Context gathered: 2026-02-12*
