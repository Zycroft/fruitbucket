# Roadmap: Bucket

## Milestones

- v1.0 MVP - Phases 1-8 (shipped 2026-02-12)
- v1.1 Kawaii Art Overhaul - Phases 9-13 (in progress)

## Phases

<details>
<summary>v1.0 MVP (Phases 1-8) - SHIPPED 2026-02-12</summary>

### Phase 1: Core Physics & Merging
**Goal**: Players can drop fruits into a container where they obey gravity, stack naturally, and auto-merge into larger fruits -- with all critical physics pitfalls solved from day one.
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md -- Project setup, FruitData resources, bucket scene, background (Wave 1)
- [x] 01-02-PLAN.md -- Fruit scene, MergeManager gatekeeper, DropController, game scene (Wave 2)
- [x] 01-03-PLAN.md -- Overflow detector, HUD, game assembly, playtest checkpoint (Wave 3)

### Phase 2: Scoring & Chain Reactions
**Goal**: Every merge awards points scaled by fruit tier, and rapid consecutive merges trigger chain reaction multipliers that reward skillful play.
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md -- ScoreManager with chain tracking, coin economy, EventBus signals, FruitData score values (Wave 1)
- [x] 02-02-PLAN.md -- Floating score popups, animated HUD, chain counter, coin display, playtest (Wave 2)

### Phase 3: Merge Feedback & Juice
**Goal**: Merges produce satisfying visual and audio feedback that scales with fruit tier and chain length.
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md -- Screen shake Camera2D, SFX pool autoload, particle scene, placeholder audio (Wave 1)
- [x] 03-02-PLAN.md -- MergeFeedback orchestrator, game scene integration, chain escalation, playtest (Wave 2)

### Phase 4: Game Flow & Input
**Goal**: Players can pause, resume, restart, and quit mid-run, and the game works equally well with mouse/keyboard and touch input.
**Plans**: 1 plan

Plans:
- [x] 04-01-PLAN.md -- Pause menu, restart flow, HUD pause button, touch input verification (Wave 1)

### Phase 5: Card System Infrastructure
**Goal**: The full card lifecycle works -- players pick a starter card, see active cards in the HUD, earn coins from merges, and spend them in a card shop.
**Plans**: 3 plans

Plans:
- [x] 05-01-PLAN.md -- CardData resource, 10 card definitions, CardManager autoload, GameManager states, EventBus signals, CardSlotDisplay component (Wave 1)
- [x] 05-02-PLAN.md -- Card shop overlay with buy/sell/skip, HUD card slots, score threshold-to-shop wiring (Wave 2)
- [x] 05-03-PLAN.md -- Starter card pick overlay, game flow integration, full lifecycle playtest (Wave 3)

### Phase 6: Card Effects -- Physics & Merge
**Goal**: Four card effects that physically change how fruits behave.
**Plans**: 2 plans

Plans:
- [x] 06-01-PLAN.md -- CardEffectSystem scaffold, Bouncy Berry bounce effect, Cherry Bomb blast with shockwave (Wave 1)
- [x] 06-02-PLAN.md -- Heavy Hitter charge-based mass boost with HUD display, Wild Fruit periodic selection with rainbow shader and adjacent-tier merging (Wave 2)

### Phase 7: Card Effects -- Scoring & Economy
**Goal**: Six card effects that modify score calculations and coin income.
**Plans**: 2 plans

Plans:
- [x] 07-01-PLAN.md -- Score bonus effects infrastructure + Quick Fuse, Fruit Frenzy, Big Game Hunter with colored bonus popups (Wave 1)
- [x] 07-02-PLAN.md -- Golden Touch, Lucky Break, Pineapple Express coin/mixed effects with complete dispatcher (Wave 2)

### Phase 8: Card Activation Feedback & Starter Kits
**Goal**: Players see when their cards trigger during gameplay, can choose from distinct starter card sets, and see a run summary at game over.
**Plans**: 2 plans

Plans:
- [x] 08-01-PLAN.md -- Card trigger feedback: glow + bounce animation on HUD card slots for all 10 card effects (Wave 1)
- [x] 08-02-PLAN.md -- Starter kit selection (Physics/Score/Surprise) and celebratory run summary screen (Wave 1)

</details>

### v1.1 Kawaii Art Overhaul (In Progress)

**Milestone Goal:** Replace all procedural/vector visuals with AI-generated kawaii/chibi art -- cute expressive fruits, a charming basket, warm background, and cohesive UI -- using Runware image generation.

- [ ] **Phase 9: Fruit Sprites** - Generate and integrate 8 kawaii fruit sprites replacing white circle + FaceRenderer visuals
- [ ] **Phase 10: Fruit Features** - Preview display, tier chart, and Wild Fruit effect working with new sprites
- [ ] **Phase 11: Basket Art** - Kawaii basket container replacing Polygon2D trapezoid with integrated overflow warning
- [ ] **Phase 12: Background Scene** - Warm kitchen/picnic background replacing ColorRect layers
- [ ] **Phase 13: UI Styling** - HUD, card shop, overlays, and buttons restyled to match kawaii art direction

## Phase Details

### Phase 9: Fruit Sprites
**Goal**: All 8 fruit tiers display as unique kawaii/chibi characters with expressive faces, replacing the procedural white-circle-plus-tint visuals, while maintaining correct physics behavior at every tier size.
**Depends on**: Phase 8 (v1.0 complete)
**Requirements**: FRUIT-01, FRUIT-02
**Success Criteria** (what must be TRUE):
  1. Each of the 8 fruit tiers (blueberry through watermelon) displays a visually distinct kawaii sprite with an expressive face -- no two tiers look alike
  2. Fruit sprites render sharply at all tier sizes from 15px radius (blueberry) to 80px radius (watermelon) without visible distortion, blurriness, or clipping against the collision shape
  3. Fruits still collide, stack, and merge identically to v1.0 behavior -- the art change is purely visual with no physics side effects
  4. The old FaceRenderer draw-based faces and white circle tinting are fully removed -- all visuals come from the new sprite textures
**Plans**: TBD

### Phase 10: Fruit Features
**Goal**: All fruit-dependent UI and gameplay visuals work correctly with the new sprites -- the preview shows what you are about to drop, players can see the full progression, and the Wild Fruit effect remains readable.
**Depends on**: Phase 9
**Requirements**: FRUIT-03, FRUIT-04, FRUIT-05
**Success Criteria** (what must be TRUE):
  1. The next-fruit preview in the HUD displays a smaller version of the actual fruit sprite that matches what will drop next -- not a placeholder or wrong tier
  2. A tier chart is visible to the player showing all 8 fruits in progression order (tier 1 through tier 8) so they can learn what merges into what
  3. When Wild Fruit activates on a fruit, the rainbow/shimmer effect is clearly visible over the new sprite art without obscuring the fruit's identity
**Plans**: TBD

### Phase 11: Basket Art
**Goal**: The game container is a charming kawaii basket that replaces the procedural trapezoid, with decorative details and an overflow warning that integrates naturally with the basket art.
**Depends on**: Phase 9 (fruit style establishes art direction)
**Requirements**: BSKT-01, BSKT-02, BSKT-03
**Success Criteria** (what must be TRUE):
  1. The game container displays as a kawaii woven basket sprite with the Polygon2D trapezoid and Line2D outlines fully removed -- collision shape unchanged
  2. The basket has a decorative rim along the top edge with cute details (flowers, leaves, or similar) that matches the kawaii fruit style
  3. When fruits approach the overflow threshold, a visual warning integrates with the basket art (rim glow, color shift, or similar) that is clearly distinguishable from the normal basket state
**Plans**: TBD

### Phase 12: Background Scene
**Goal**: The game world has a warm, inviting background scene that frames the basket naturally and completes the kawaii atmosphere without competing with gameplay visibility.
**Depends on**: Phase 11 (basket art defines foreground framing)
**Requirements**: BG-01, BG-02
**Success Criteria** (what must be TRUE):
  1. A warm kitchen or picnic scene replaces the solid ColorRect background, with the beige/brown procedural layers fully removed
  2. The background art frames the basket on a natural surface (table, counter, blanket) with ambient elements that add atmosphere without distracting from fruit gameplay or obscuring the play area
**Plans**: TBD

### Phase 13: UI Styling
**Goal**: All UI elements -- HUD, card shop, overlays, and buttons -- are restyled with kawaii-themed visuals that create a cohesive art direction across the entire game.
**Depends on**: Phase 9 (art palette established), Phase 12 (background context)
**Requirements**: UI-01, UI-02, UI-03, UI-04
**Success Criteria** (what must be TRUE):
  1. Score, coin count, and chain multiplier HUD elements use fonts and colors that match the kawaii art direction rather than default Godot styling
  2. The card shop overlay (panels, card frames, price labels, buy/sell/skip buttons) is visually restyled with kawaii-themed backgrounds, borders, and accents
  3. Pause menu, starter card pick, and run summary screens use consistent kawaii-themed styling (backgrounds, borders, fonts) that matches the shop and HUD
  4. All interactive buttons (buy, sell, skip, pause, restart) have kawaii-styled button art that is visually consistent across every screen
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 9 -> 10 -> 11 -> 12 -> 13

Note: Phase 11 (Basket) depends on Phase 9 (Fruit Sprites) for art direction but not on Phase 10 (Fruit Features). Phases 10 and 11 could execute in parallel if desired.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Core Physics & Merging | v1.0 | 3/3 | Complete | 2026-02-08 |
| 2. Scoring & Chain Reactions | v1.0 | 2/2 | Complete | 2026-02-08 |
| 3. Merge Feedback & Juice | v1.0 | 2/2 | Complete | 2026-02-08 |
| 4. Game Flow & Input | v1.0 | 1/1 | Complete | 2026-02-08 |
| 5. Card System Infrastructure | v1.0 | 3/3 | Complete | 2026-02-09 |
| 6. Card Effects -- Physics & Merge | v1.0 | 2/2 | Complete | 2026-02-09 |
| 7. Card Effects -- Scoring & Economy | v1.0 | 2/2 | Complete | 2026-02-10 |
| 8. Card Activation Feedback & Starter Kits | v1.0 | 2/2 | Complete | 2026-02-12 |
| 9. Fruit Sprites | v1.1 | 0/TBD | Not started | - |
| 10. Fruit Features | v1.1 | 0/TBD | Not started | - |
| 11. Basket Art | v1.1 | 0/TBD | Not started | - |
| 12. Background Scene | v1.1 | 0/TBD | Not started | - |
| 13. UI Styling | v1.1 | 0/TBD | Not started | - |
