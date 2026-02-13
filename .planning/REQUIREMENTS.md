# Requirements: Bucket

**Defined:** 2026-02-07 (v1.0), 2026-02-13 (v1.1)
**Core Value:** The drop-merge-physics loop must feel satisfying and correct -- fruits fall naturally, collide realistically, and merge reliably.

## v1.1 Requirements — Kawaii Art Overhaul

### Fruit Sprites

- [ ] **FRUIT-01**: Each of the 8 fruit tiers has a unique kawaii/chibi sprite with transparent background, expressive face, and distinct visual identity
- [ ] **FRUIT-02**: Fruit sprites render correctly at all tier sizes (15px blueberry to 80px watermelon radius) without distortion or blurriness
- [ ] **FRUIT-03**: Next-fruit preview in the HUD displays a matching smaller version of the fruit sprite
- [ ] **FRUIT-04**: A visual merge tier chart shows the full fruit progression (tier 1 → tier 8) that players can reference
- [ ] **FRUIT-05**: Wild Fruit visual effect (rainbow/shimmer) works correctly on new sprites

### Basket Container

- [ ] **BSKT-01**: The game container is a kawaii woven basket sprite replacing the procedural Polygon2D trapezoid
- [ ] **BSKT-02**: Basket has a decorative rim with cute details (flowers, leaves, or similar) along the top edge
- [ ] **BSKT-03**: Overflow warning visual integrates with the new basket art (rim glow or color change at danger threshold)

### Background Scene

- [ ] **BG-01**: A warm kitchen or picnic background scene replaces the solid ColorRect background
- [ ] **BG-02**: Background art frames the basket naturally (table/counter surface, ambient elements) without competing with gameplay visibility

### UI Styling

- [ ] **UI-01**: Score, coin, and chain HUD elements use fonts/colors that match the kawaii art direction
- [ ] **UI-02**: Card shop overlay (panels, buttons, card frames) is restyled with kawaii-themed visuals
- [ ] **UI-03**: Pause menu, starter pick, and run summary screens use consistent kawaii-themed styling
- [ ] **UI-04**: Button art (buy, sell, skip, pause, restart) matches the cohesive kawaii visual theme

## v1.0 Requirements (Validated)

All 37 v1.0 requirements shipped. See MILESTONES.md for archive.

<details>
<summary>v1.0 requirement IDs (all complete)</summary>

PHYS-01 through PHYS-08, SCOR-01 through SCOR-05, CARD-01 through CARD-11, EFCT-01 through EFCT-10, GAME-01 through GAME-03
</details>

## Future Requirements

### Animation
- **ANIM-01**: Fruits have idle animations (gentle bob, breathing)
- **ANIM-02**: Fruits squash/stretch on collision impact
- **ANIM-03**: Merge animation with fruit-specific effects

### Card Art
- **CART-01**: Each of the 10 cards has unique kawaii illustration art
- **CART-02**: Card rarity frames (Common/Uncommon/Rare) with distinct visual treatment

### Content Expansion
- **POOL-01**: Expand card pool to 20-30 cards
- **SYNC-01**: Card synergy pass -- cards that reference/amplify other cards

### Meta-Progression
- **META-01**: Meta-progression -- unlock new cards to appear in pool
- **SLOT-01**: Unlock 4th and 5th card slots

## Out of Scope

| Feature | Reason |
|---------|--------|
| Animated fruit sprites | Static sprites first; animation in future milestone |
| Card illustration art | Separate art milestone; cards use text/icon for now |
| Sound effect overhaul | Audio is separate from visual overhaul |
| Particle effect restyle | Existing particles work fine with new art |
| Custom font/typeface design | Use existing kawaii-compatible fonts |
| Real-money microtransactions | In-game currency only |
| Multiplayer | Single-player focus |
| Leaderboards / online features | Local play only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FRUIT-01 | — | Pending |
| FRUIT-02 | — | Pending |
| FRUIT-03 | — | Pending |
| FRUIT-04 | — | Pending |
| FRUIT-05 | — | Pending |
| BSKT-01 | — | Pending |
| BSKT-02 | — | Pending |
| BSKT-03 | — | Pending |
| BG-01 | — | Pending |
| BG-02 | — | Pending |
| UI-01 | — | Pending |
| UI-02 | — | Pending |
| UI-03 | — | Pending |
| UI-04 | — | Pending |

**Coverage:**
- v1.1 requirements: 14 total
- Mapped to phases: 0
- Unmapped: 14

---
*Requirements defined: 2026-02-13*
*Last updated: 2026-02-13 after v1.1 definition*
