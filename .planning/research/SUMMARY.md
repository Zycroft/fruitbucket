# Project Research Summary

**Project:** Bucket - Suika-style physics puzzle with roguelike card system
**Domain:** Physics-based puzzle game + roguelike modifier system (Godot 4.5 / GDScript)
**Researched:** 2026-02-07
**Confidence:** MEDIUM-HIGH

## Executive Summary

Bucket is a Suika-style fruit-merging physics puzzle game enhanced with a roguelike card modifier system. Research confirms this is a viable hybrid: the Suika core mechanics are well-documented and proven across multiple Godot implementations, while the card modifier layer directly adapts Balatro's successful joker system to physics gameplay. The recommended approach uses Godot 4.5's built-in physics engine with RigidBody2D circles, a Resource-based data architecture for both fruits and cards, and an event-driven signal bus to decouple systems.

The critical success factors are: (1) get the physics feel right before adding any card effects—Suika's appeal is its satisfying physics, and broken stacking kills the game, (2) implement a merge gatekeeper pattern from day one to prevent double-merge race conditions that plague every naive implementation, and (3) design card effects to modify orthogonal properties (physics, merge rules, scoring, economy) to avoid combinatorial explosion when cards stack. The physics tuning is the highest-risk work (stacking stability with 20+ fruits is where Godot's default solver struggles), but switching to the Rapier physics plugin is a validated fallback if needed.

The competitive landscape shows this is the right timing: Fruitbearer (direct competitor, roguelike Suika deckbuilder) ships March 2026, creating market validation for the concept but also time pressure. Bucket's differentiation is keeping the zen Suika feel intact while Fruitbearer leans into darker deckbuilder aesthetics. The card system must ship functional with 8-12 cards at minimum to validate the concept; expanding to 20-30 cards with synergies is post-validation work.

## Key Findings

### Recommended Stack

**Core engine decision:** Godot 4.5 (stable, Sept 2025) with GDScript 4.5 static typing, using the Compatibility renderer (OpenGL) for broadest device support including web and older Android. The built-in GodotPhysics2D engine is the starting point—sufficient for 11-20 simultaneous RigidBody2D fruits with proper tuning—but Godot Rapier Physics 2D is the 1:1 API-compatible fallback if stacking instability becomes unacceptable.

**Core technologies:**
- **Godot 4.5 Engine**: Built-in 2D physics (RigidBody2D), scene system, one-click mobile/web export. Godot 4.5 adds chunked physics improvements and GDScript strictness gains.
- **RigidBody2D + CircleShape2D**: Each fruit is a physics-driven rigid body with circular collision. Circles are fastest primitive shape and match Suika aesthetics. StaticBody2D for container walls.
- **Custom Resource system (.tres files)**: All fruit types defined as FruitData resources (tier, radius, sprite, score). All card effects defined as CardEffect resources with hook methods. Data-driven design with zero boilerplate and editor integration.
- **Event Bus autoload pattern**: Signal-only autoload (EventBus.gd) for cross-system communication. Keeps fruit system, score tracking, UI, and card system decoupled.
- **Enum-based state machine**: GameManager autoload holds game state (MENU, PLAYING, PAUSED, SHOP, GAME_OVER) using simple enum + match pattern. Scales to 5-10 states without node-based complexity.

**Critical configuration:**
- Physics solver iterations: 6 (up from default 4) for stacking stability
- PhysicsMaterial: friction 0.6, bounce 0.15 for Suika feel
- Compatibility renderer for web export and broad mobile support
- Contact monitor on fruits but max_contacts_reported capped at 4-8 to prevent performance overhead

### Expected Features

Research identified clear feature tiers based on genre expectations and competitive analysis.

**Must have (table stakes):**
- 11-tier fruit progression (blueberry through watermelon) — defining Suika mechanic
- Physics-based dropping with satisfying gravity and stacking
- Auto-merge on contact with chain reaction support
- Container with overflow game-over (with 2s dwell timer to prevent false positives)
- Next fruit preview (show upcoming drop, only tiers 1-5 appear as drops)
- Score system with chain bonuses
- Merge feedback ("juice"): particles, screen shake, sound, visual pop on merge
- 3 card slots with per-run economy (no persistence between runs)
- Card shop at score thresholds (500, 1500, 3500, etc.)
- In-game currency (coins from merges) to fuel card purchases
- Starter card pick (1 free card from 3 options at run start)
- Card rarity system (Common/Uncommon/Rare)

**Should have (differentiators):**
- Physics modifier cards (Bouncy, Heavy, Sticky) — unique to this game, changes gameplay feel mid-run
- Merge rule modifier cards (Wild Fruit, Chain Multiplier) — deepest strategic layer
- Score/economy modifier cards (Golden Touch, Fruit Frenzy) — number-go-up dopamine
- Card synergy system — emergent builds from card combinations (not scripted synergies)
- Card activation animations — visual feedback when cards trigger (Balatro pattern)
- Escalating chain reaction effects — intensity scales with chain length for spectacle
- Run summary stats screen — encourages "one more run"

**Defer (v2+):**
- Meta-progression (unlock new cards for pool) — adds long-term engagement but requires stable balance first
- Multiple starter card sets — needs 20+ card pool to create distinct archetypes
- Fruit expressions/personality — polish, not gameplay
- Daily challenge mode — seeded runs for community competition
- Achievements tied to card unlocks

**Anti-features (avoid):**
- Persistent card collection between runs — destroys roguelike identity
- Real-time multiplayer — project killer for v1 scope
- Unlimited card slots — removes strategic tension (Balatro caps at 5 for this reason)
- Time pressure mode — conflicts with Suika's zen flow
- Complex card crafting — disproportionate complexity for 5-15 minute runs

### Architecture Approach

Research identified proven patterns from Godot Suika clones and roguelike deckbuilders. The architecture uses three autoloads (EventBus for signals, GameManager for state/score, CardManager for active card inventory) coordinating scene-based components (Fruit, Container, DropController, MergeManager, UILayer).

**Major components:**
1. **Fruit (RigidBody2D scene)** — Configured from FruitData resource at spawn time. Detects collisions with same-tier fruits and requests merges. Never handles merge logic directly (prevents double-merge bugs).
2. **MergeManager (singleton orchestrator)** — Receives all merge requests, validates via CardManager hooks, prevents double-merges using instance ID locks, spawns next-tier fruit with card-modified properties, emits merge events.
3. **CardManager (autoload)** — Holds active card array (3-5 slots). Defines hook points (on_fruit_spawn, on_merge, modify_physics_material, etc.). Systems call CardManager at specific lifecycle points to apply active card modifiers.
4. **EventBus (signal-only autoload)** — Declares all cross-system signals (fruit_merged, score_changed, game_over_triggered, card_activated). No logic, no state. One-directional data flow from game logic to UI.
5. **DropController** — Translates input (mouse/touch) to clamped drop position, applies card spawn hooks, instantiates fruits into FruitContainer. Handles next-fruit preview display.
6. **OverflowLine (Area2D)** — Dwell-time based game-over detection. Tracks fruits above overflow line for 2 seconds before triggering game over (prevents false positives during chain reactions).

**Key patterns:**
- Resource-based data model: FruitData and CardEffect are custom Resources (.tres files), not scripts. Allows data-driven design with editor integration and zero serialization boilerplate.
- Merge gatekeeper: MergeManager is the single authority on merge validity. Instance ID comparison ensures deterministic merge ordering when 3+ same-tier fruits collide simultaneously.
- Card effect pipeline: Cards modify data in transit (FruitData before spawn, score during merge) via defined hook methods. Cards never directly control game objects.
- Enum state machine: Simple enum + match for 5 game states. Node-based FSMs are overkill for this game's linear state graph.

**Data flow:**
```
Player Input → DropController → CardManager.apply_spawn_hooks() → Fruit instantiated
Fruit collision → MergeManager.request_merge() → CardManager.validate_merge() → Spawn next-tier
Merge complete → EventBus.fruit_merged → GameManager.add_score() → EventBus.score_changed → UI update
Score threshold → EventBus.card_shop_opened → GameManager.change_state(SHOP) → CardShop UI
```

### Critical Pitfalls

Research identified six critical pitfalls verified against Godot issue tracker and community implementations:

1. **Double-merge race condition** — Both fruits in a collision detect simultaneously and spawn two merged fruits instead of one. Prevention: Use instance ID comparison tiebreaker + `merging` flag. Only the fruit with lower instance ID executes merge. Must be designed in Phase 1 (Core Physics).

2. **queue_free() crash during physics callbacks** — Calling `queue_free()` on RigidBody2D inside `body_entered` or physics callbacks crashes physics server (Godot issue #15904, #77793). Prevention: Use `call_deferred("queue_free")` after disabling contact_monitor and collision shape, OR use object pooling (better for mobile). Address in Phase 1.

3. **RigidBody2D cannot be scaled at runtime** — Physics engine resets scale to (1,1) every frame. Any card effect that tries to scale a RigidBody2D will fail silently. Prevention: Modify CollisionShape2D.shape.radius directly, scale sprite child node independently. NEVER scale the RigidBody2D node. Design fruit sizing architecture in Phase 1 before implementing any card effects.

4. **Stacking instability with 10+ fruits** — Default Godot physics solver produces jitter, overlapping bodies, and vibrating piles with many stacked circles (issues #2092, #80603). Prevention: Use CircleShape2D only (fastest/most stable), increase solver iterations to 6-8, set appropriate damping (0.5-1.0), ensure can_sleep=true. Fallback: Godot Rapier Physics 2D (2-3x faster, better stacking, 1:1 API compatible). Tune in Phase 1 with 30+ fruit stress test.

5. **Overflow detection false positives** — Naive Area2D.body_entered game-over triggers unfair deaths during bouncing chain reactions. Prevention: Dwell-time system (fruit must stay above line for 2+ seconds continuously). Ignore currently-dropping fruit and just-merged fruits (0.5s grace). Phase 1 design requirement.

6. **Card effect combinatorial explosion** — With 20 cards and 5 slots, there are 15,000+ possible loadouts. Untested combinations create degenerate gameplay (infinite score loops, broken physics, trivial wins). Prevention: Design cards to modify orthogonal properties (one physics card, one merge card, etc.). Cap effect values (set to 0.8, not add 0.5). Build autoplay test harness early. Start with 8-10 simple cards. Phase 3 concern but architecture must support modifier ordering from Phase 1.

**Additional technical debt patterns to avoid:**
- Hardcoded fruit properties in scene files (use FruitData resources from day one)
- Testing only with mouse input (add touch testing by Phase 2)
- Skipping merge animations (acceptable for MVP, add in Phase 2)
- contact_monitor with high max_contacts_reported (cap at 4-8, not 16+)

## Implications for Roadmap

Based on dependency analysis from architecture research and pitfall timing requirements, the roadmap should follow this phase structure:

### Phase 1: Core Physics & Merge Mechanics
**Rationale:** The physics feel IS the game. Every other system depends on having droppable, stackable, merge-capable fruits. All six critical pitfalls must be addressed in this phase because they are foundational—fixing them later requires architectural changes. The merge gatekeeper pattern, safe deletion, sizing architecture, and overflow detection logic must be correct before layering cards on top.

**Delivers:**
- Container (StaticBody2D walls) with overflow detection (Area2D with dwell timer)
- Fruit scene (RigidBody2D + CircleShape2D) configured from FruitData resources
- 11 FruitData resources (blueberry through watermelon) with correct radii and sprites
- MergeManager with instance ID gatekeeper and merge validation
- Basic DropController (mouse input, clamped positioning)
- Next fruit preview display
- EventBus autoload with core signals (fruit_dropped, fruit_merged, game_over_triggered)
- GameManager autoload with state machine (MENU, PLAYING, GAME_OVER) and score tracking

**Addresses features:**
- 11-tier fruit progression (table stakes)
- Physics-based dropping (table stakes)
- Auto-merge on contact (table stakes)
- Container with overflow game-over (table stakes)
- Next fruit preview (table stakes)
- Score system (table stakes)

**Avoids pitfalls:**
- Double-merge race condition (instance ID tiebreaker + merging flag)
- queue_free() crash (call_deferred pattern OR object pooling)
- RigidBody2D scaling limitation (FruitData.radius drives shape.radius, sprites scale independently)
- Stacking instability (tuned solver iterations, damping, CircleShape2D only; stress test with 30+ fruits)
- Overflow false positives (2-second dwell timer)

**Research flags:** LOW — Godot physics for Suika is well-documented. Phase can proceed without additional research. If stacking instability persists, evaluate Rapier physics plugin (documented alternative).

---

### Phase 2: Game Feel & Polish
**Rationale:** The core loop must feel satisfying before adding complexity. Chain reactions and merge feedback are what make Suika addictive. This phase depends on Phase 1 physics being stable because visual effects (screen shake, particles) are triggered by merge events. Touch input must be validated before card system because mobile is a primary target and input feel affects drop precision.

**Delivers:**
- Merge juice: particle bursts (GPUParticles2D), screen shake (Camera2D tween), pop sounds (AudioStreamPlayer2D)
- Chain reaction detection and escalating feedback (intensity scales with chain length)
- Mobile touch input with offset drop preview (finger doesn't obscure fruit)
- Pause menu and restart flow
- HUD with score display and next-fruit preview
- Game-over screen with final score and "Play Again"

**Addresses features:**
- Merge feedback / juice (table stakes)
- Chain reaction bonuses (table stakes)
- Escalating chain effects (differentiator)
- Pause and restart (table stakes)

**Uses stack elements:**
- Godot Tween system for scale pops and screen shake
- GPUParticles2D for merge bursts
- AudioStreamPlayer2D for positional merge sounds
- CanvasLayer for HUD/UI separation
- Input event mouse-to-touch emulation

**Research flags:** LOW — Standard Godot patterns. GDQuest Tween tutorials and official particle docs cover this. Touch input testing on physical devices required but no research needed.

---

### Phase 3: Roguelike Card System (MVP)
**Rationale:** This phase implements the game's unique value proposition. It depends on Phases 1 and 2 being complete because card effects modify physics properties (Phase 1) and must have visible feedback (Phase 2). The architecture for card hooks must be designed carefully to avoid combinatorial explosion (Pitfall 6). Start with 8-12 simple parameter-driven cards to validate the concept before expanding.

**Delivers:**
- CardEffect base Resource class with hook methods (on_fruit_spawn, on_merge, modify_physics_material, can_merge)
- CardManager autoload with active card array (3 slots initial)
- 8-12 initial cards across 5 categories:
  - Physics modifiers: Bouncy Berry, Heavy Hitter
  - Merge modifiers: Wild Fruit, Quick Fuse
  - Score modifiers: Fruit Frenzy, Big Game Hunter
  - Economy modifiers: Golden Touch, Lucky Break
  - Conditional: Cherry Bomb, Pineapple Express
- Coin economy (coins awarded on merge, displayed in HUD)
- Card shop UI at score thresholds (500, 1500, 3500)
- Starter card pick (choose 1 from 3 at run start)
- Card rarity system (Common/Uncommon/Rare)
- Card selling/recycling in shop

**Addresses features:**
- 3 card slots with per-run economy (table stakes for roguelike layer)
- Card shop at score thresholds (table stakes)
- In-game currency (table stakes)
- Starter card pick (table stakes)
- Card rarity system (table stakes)
- Physics modifier cards (differentiator — unique to Bucket)
- Merge rule modifier cards (differentiator)
- Score/economy modifiers (differentiator)

**Implements architecture:**
- CardEffect resource hierarchy with strategy pattern
- CardManager hook pipeline with explicit ordering
- Card shop UI flow (pause game → show shop → purchase → resume)
- Card activation via EventBus signals

**Avoids pitfalls:**
- Card combinatorial explosion: Cards modify orthogonal properties (limit 1 physics card active, etc.). Capped effect values. Start with 8-12 simple cards, test thoroughly before expanding.
- Signal ordering issues: CardManager applies effects in documented order, not signal callback order.

**Research flags:** MEDIUM — Core patterns adapted from Balatro (well-documented) but specific physics integration is novel. May need research-phase for complex card effect implementations if simple parameter-driven cards prove insufficient. Playtest-heavy phase.

---

### Phase 4: Content Expansion & Synergies
**Rationale:** Only expand card pool after Phase 3 validates that the base card system is fun and balanced. Synergies emerge from card combinations, so this phase requires 20+ cards minimum. Multiple starter sets need distinct card archetypes to be meaningful. This is post-MVP validation work.

**Delivers:**
- Expanded card pool to 20-30 cards
- Card synergy pass (discover natural synergies, add 2-3 synergy-enabling cards)
- Multiple starter card sets (Physics Kit, Score Kit, Economy Kit)
- Score threshold difficulty curve (shop spacing increases, rare cards appear later)
- Card activation animations (visual feedback when card triggers)
- Run summary/stats screen (biggest chain, highest tier, total merges)

**Addresses features:**
- Expanded card pool (should-have)
- Card synergy system (differentiator)
- Multiple starter sets (should-have)
- Card activation animations (differentiator)
- Run summary screen (differentiator)

**Research flags:** LOW — Content creation and balancing, not new patterns. Playtesting drives this phase.

---

### Phase 5: Mobile Optimization & Deployment
**Rationale:** Mobile is a primary platform (Suika's mass appeal comes from mobile). This phase optimizes for low-end Android devices and prepares for export to web and mobile stores. Depends on complete feature set from Phases 1-4.

**Delivers:**
- Object pooling for fruits (30-40 pre-instantiated, reused)
- Collision layer optimization (separate ActiveFruits and SettledFruits layers)
- Texture atlases for fruit sprites
- Mobile viewport scaling and safe area handling
- Android APK export with signing
- Web export (WASM) with loading screen
- Performance profiling (target 60fps on low-end Android with 25+ fruits)

**Uses stack elements:**
- Godot Compatibility renderer for web export
- Godot built-in export templates
- Object pooling pattern to avoid instantiation overhead

**Research flags:** LOW — Standard Godot mobile optimization. Official docs and community guides cover this.

---

### Phase Ordering Rationale

**Dependency-driven sequencing:**
- Phase 1 before all others: Physics is the foundation. Cannot test merging without physics. Cannot add card effects without fruits to modify.
- Phase 2 before Phase 3: Card activation feedback requires merge juice systems. Touch input must be validated before card shop UI.
- Phase 3 before Phase 4: Must validate base card system (8-12 cards) before expanding to 20-30. Synergies require variety to be meaningful.
- Phase 5 after feature-complete: Optimization requires knowing final scope. Premature optimization wastes effort.

**Pitfall-driven timing:**
- All 6 critical pitfalls addressed in Phase 1 because they are architectural. Fixing double-merge bugs or RigidBody scaling issues after building 30 cards on top requires rework.
- Combinatorial explosion (Pitfall 6) prevented by starting small (8-12 cards) and testing thoroughly before expanding in Phase 4.

**Risk mitigation:**
- Phase 1 stress test with 30+ fruits validates physics stability early. If Rapier plugin is needed, switching happens before card system exists.
- Phase 3 keeps card count low (8-12) to validate concept before content investment. If card system doesn't create fun variety, pivot is cheap.
- Phases 4-5 are post-validation. If Phases 1-3 don't prove product-market fit, these are deferred.

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 3 (Card System):** If complex behavioral cards are needed beyond simple parameter modifiers, may need research-phase for specific effect implementations (e.g., magnet forces between fruits, temporary physics freezes, spatial area effects). Start with simple cards first; research only if playtest demands complexity.

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Core Physics):** Well-documented. Godot Suika clones, official RigidBody2D docs, and GDQuest patterns cover all needed information.
- **Phase 2 (Polish):** Standard Godot juice patterns. Tweens, particles, camera shake are extensively documented.
- **Phase 4 (Content Expansion):** Balancing and playtesting, not technical research.
- **Phase 5 (Mobile Optimization):** Standard Godot export and optimization patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Godot 4.5 for Suika is proven (yokai-suika reference, Drygast tutorial, multiple clones). RigidBody2D + Resource pattern is official best practice. Rapier plugin is documented fallback for physics. Only uncertainty: exact tuning values for this specific game require iteration. |
| Features | MEDIUM-HIGH | Suika table stakes are well-defined (11 tiers, physics, merge, overflow). Balatro card taxonomy is proven successful and directly applicable. Competitive analysis (Fruitbearer, Suika Planet) validates roguelike-Suika hybrid concept. Uncertainty: optimal card count for MVP (8-12 is estimate, may need 12-15). |
| Architecture | MEDIUM-HIGH | Resource-based data model + EventBus + CardManager hook pattern are established Godot 4 patterns (GDQuest, official docs, community consensus). MergeManager gatekeeper is proven solution to double-merge problem. Only uncertainty: card effect hook granularity may need refinement during implementation. |
| Pitfalls | HIGH | All six pitfalls verified against Godot issue tracker (godotengine/godot #15904, #98353, #89898, #2092, etc.) and community implementations. Prevention strategies are documented with code examples. Confidence is high because these are known, reproducible issues with proven solutions. |

**Overall confidence:** MEDIUM-HIGH

The core Suika mechanics and Godot implementation patterns are well-established (HIGH confidence). The roguelike card layer is a novel application but adapts proven Balatro patterns to a new domain (MEDIUM confidence). The combination is viable but requires validation through prototyping—Phases 1-3 function as progressive risk reduction.

### Gaps to Address

**Physics tuning values:** Research provides starting points (solver iterations=6, friction=0.6, bounce=0.15, damping=0.5-1.0) but exact values for satisfying feel require playtesting iteration. Plan to allocate Phase 1 time for tuning and stress testing with 30+ fruits. Decision point: if tuning doesn't achieve stable stacking, switch to Rapier plugin (1:1 API swap, minimal rework).

**Card effect complexity boundary:** Research recommends starting with 8-12 simple parameter-driven cards (modify existing properties like bounce, score multiplier, merge timing). If playtesting reveals that behavioral cards (custom merge logic, spatial effects, multi-step conditionals) are needed for depth, this requires deeper implementation research. Mitigation: Phase 3 designs hook architecture to support both parameter and behavioral cards, but only implements parameter cards initially. Behavioral cards deferred to Phase 4 if needed.

**Mobile performance threshold:** Research states default Godot physics handles ~2,900 circle RigidBodies at 30fps. For this game, 20-40 fruits are expected. But card effects (especially per-frame physics modifiers) add overhead. Gap: exact performance profile unknown until Phase 3. Mitigation: Phase 5 includes profiling on target low-end Android device. Fallback: cap max fruit count at 30-35 if performance demands it.

**Card balance and synergies:** Research provides initial card pool taxonomy and warns about combinatorial explosion. Gap: what is the minimum card pool size to create interesting synergy space? Estimate is 15-20 cards across 5 categories. Mitigation: Phase 3 implements 8-12, Phase 4 expands based on playtesting. Use automated random-loadout stress testing to detect degenerate combinations early.

**Web export compatibility:** Stack recommends Compatibility renderer (OpenGL) for web export. Godot 4.5 added WebAssembly SIMD support for physics. Gap: performance on web with 20+ fruits is unknown. Mitigation: Phase 5 includes web export testing. Acceptable fallback: if web performance is poor, cap web version at 15 fruits or defer web export to post-launch.

## Sources

### Primary (HIGH confidence)
- [Godot 4.5 Official Docs — RigidBody2D, PhysicsMaterial, Resources](https://docs.godotengine.org/en/stable/)
- [GDQuest Design Patterns — Event Bus, Strategy, FSM](https://www.gdquest.com/tutorial/godot/design-patterns/)
- [yokai-suika Godot 4.3 implementation](https://github.com/Checkroth/yokai-suika) — Resource-based architecture reference
- [Godot Issue Tracker](https://github.com/godotengine/godot/issues) — Pitfalls verified (#15904, #98353, #89898, #2092, #80603, #72674)
- [Balatro Jokers Wiki](https://balatrogame.fandom.com/wiki/Jokers) — Card taxonomy, modifier patterns

### Secondary (MEDIUM confidence)
- [Drygast Suika Clone Tutorial](https://drygast.net/blog/post/godot_ahballs) — Merge detection, scene structure
- [Godot Rapier Physics Benchmarks](https://godot.rapier.rs/docs/documentation/performance/) — 1.7x performance, stacking stability
- [Balatro Design Analysis — Oreate AI](https://www.oreateai.com/blog/indepth-analysis-of-the-game-design-philosophy-and-roguelike-mechanisms-in-balatro/) — Shop pacing, modifier philosophy
- [Fruitbearer Steam Page](https://store.steampowered.com/app/4300180/Fruitbearer/) — Competitive analysis
- [Suika Game Planet — Saiga NAK](https://saiganak.com/release/suikagame-planet/) — Genre evolution, co-op mechanics
- [Slay the Spire Relics Wiki](https://slay-the-spire.fandom.com/wiki/Relics) — Passive modifier patterns

### Tertiary (LOW confidence)
- Community forum discussions on Godot physics tuning, merge mechanics, card effect systems — Multiple sources, varying quality; verified against official docs where possible

---
*Research completed: 2026-02-07*
*Ready for roadmap: yes*
