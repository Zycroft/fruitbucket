# Phase 9: Fruit Sprites - Context

**Gathered:** 2026-02-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Generate and integrate 8 kawaii/chibi fruit sprites replacing the procedural white-circle-plus-tint visuals and FaceRenderer draw-based faces. Fruits must remain physically correct (collisions, stacking, merging unchanged). Two fruit names change: blueberry → cherry (tier 1), pear → peach (tier 6).

</domain>

<decisions>
## Implementation Decisions

### Art style & expression
- Full chibi face style — huge sparkly eyes, big blush marks, tiny mouth (Molang/Sumikko Gurashi level cute)
- Natural fruit colors with a soft kawaii glow/polish — not pastel, not hyper-saturated
- Full kawaii decorative extras — blush, sparkles, sweat drops as appropriate per fruit expression
- No hard outlines/borders — soft edges, painterly/illustration look
- Transparent background only — no glow/aura behind the sprite

### Per-tier personality
- Expressions escalate with tier — small fruits are timid/cute, bigger fruits are confident/bold (progression mood)
- Same level of visual detail across all tiers — differentiation through shape, color, and expression, not complexity
- Two fruit swaps from current lineup:
  - Tier 1: blueberry → **cherry**
  - Tier 6: pear → **peach**
- Final lineup: cherry, grape, strawberry, orange, apple, peach, pineapple, watermelon

### Sprite composition
- Transparent background, clean cutout
- Selection priority: cute AND recognizable — reject any that sacrifice one for the other

### Claude's Discretion
- Whether fruits have tiny stub limbs or are face-only (whatever works best for circular collision shapes)
- Sprite generation resolution (based on largest in-game render size needed — watermelon ~160px diameter)
- Shape fit: how strictly sprites fill the collision circle vs allowing small overhangs for stems/leaves
- Prompting strategy: same template vs individual prompts per fruit — pick what produces the most cohesive set
- Number of variations generated per fruit before selecting the best
- All integration technical details (scaling, Godot scene changes, FruitData resource updates)

</decisions>

<specifics>
## Specific Ideas

- Progression mood reference: tier 1 cherry might have shy/bashful big eyes, tier 8 watermelon might have a proud/confident grin
- Kawaii extras should feel natural to the expression — a nervous grape might have a sweat drop, a happy strawberry might have sparkles
- The set should feel like a cohesive character family — same art style, same level of polish

</specifics>

<deferred>
## Deferred Ideas

- Expand to 10 tiers with full classic Suika lineup (cherry → strawberry → grape → dekopon → orange → apple → pear → peach → pineapple → watermelon) — requires new FruitData resources, radii, masses, score values, and merge chain changes. Gameplay/mechanics scope, not art scope.

</deferred>

---

*Phase: 09-fruit-sprites*
*Context gathered: 2026-02-13*
