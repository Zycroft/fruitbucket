# Phase 1: Core Physics & Merging - Context

**Gathered:** 2026-02-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Droppable, stackable, mergeable fruits in a physics container with overflow detection. Players position and drop fruits that obey gravity, collide with walls and each other, stack naturally, and auto-merge into larger fruits on contact. Includes next-fruit preview and 2-second overflow dwell timer. Scoring, chain multipliers, visual juice, and card systems are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Container & playfield
- Bucket/trapezoid shape — wider at top, narrower at bottom, funnels fruits together and matches the game name
- Visible bucket art with thickness and material — the container is a drawn object, not just invisible collision walls
- Overflow indicator: dashed line near the top of the bucket interior as a static reference, PLUS the bucket rim glows/changes color (e.g., turns red) as fruits approach the danger zone — escalating warning
- Themed background scene behind the bucket (kitchen counter, picnic table, or similar setting) — gives the game world and context

### Fruit visual identity
- Flat/vector art style — clean geometric shapes with bold colors, easy to read at any size
- 8 fruit tiers in the merge chain (e.g., blueberry → grape → cherry → strawberry → orange → apple → pear → watermelon)
- Only tiers 1-5 appear as drops (per ROADMAP requirements)

### Drop & aim feel
- Fruit follows cursor/finger position above the bucket (WYSIWYG aiming)
- Faint vertical drop line extends from the fruit down into the bucket, showing exactly where it will land
- Next-fruit preview displayed above the bucket near the drop zone — keeps the player's eyes in one place

### Merge presentation
- Two max-tier fruits (watermelon) merging triggers a dramatic vanish with special VFX celebration and bonus — this is the big payoff moment
- Chain reactions have linked visual effects (flash/line/ripple connecting merge points) so consecutive merges read as a connected chain, not isolated events

### Claude's Discretion
- Whether fruits have faces/expressions (kawaii-style or plain)
- Size progression curve across the 8 tiers (gradual vs dramatic scaling)
- Drop cooldown timing (if any) between consecutive drops
- Drop speed / initial velocity after release
- How merging fruits disappear (instant pop vs shrink-to-midpoint)
- How the new merged fruit appears (instant vs scale-up animation)
- Themed background specific scene choice
- Bucket material/texture (metal, wood, ceramic, etc.)

</decisions>

<specifics>
## Specific Ideas

- The bucket shape is thematic — it IS the game's identity, not just a container
- Overflow warning should feel escalating: static line for awareness, rim glow for urgency
- Drop line + hovering fruit together = maximum aim clarity for both mouse and touch
- Max-tier merge should feel like an achievement — the spectacle should match the difficulty of getting there
- Chain reaction visuals should make it obvious that merges are connected, even if the player isn't watching the score

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-core-physics-merging*
*Context gathered: 2026-02-08*
