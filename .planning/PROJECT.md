# Bucket — Roguelike Suika Game

## What This Is

A Suika-style fruit-dropping puzzle game built in Godot 4.5 with a roguelike card system layered on top. Players drop fruits into a container where matching fruits merge into larger ones, while collecting and activating modifier cards that alter gameplay mechanics. Targets desktop and mobile (touch controls) with polished 2D fruit art.

## Core Value

The drop-merge-physics loop must feel satisfying and correct — fruits fall naturally, collide realistically, and merge reliably. Without solid core mechanics, the card system has nothing to build on.

## Current Milestone: v1.1 Kawaii Art Overhaul

**Goal:** Replace all procedural/vector visuals with AI-generated kawaii/chibi art — cute expressive fruits, a charming basket container, warm background scene, and cohesive UI styling — using Runware image generation.

**Target features:**
- 8 kawaii/chibi fruit sprites with unique expressive faces per tier
- Cute basket/bucket container art replacing procedural Polygon2D
- Warm, inviting background scene replacing solid ColorRects
- UI element styling to match the cohesive kawaii art direction
- All art generated via Runware AI, processed for game integration (transparency, sizing)

## Requirements

### Validated (v1.0)

- Core Suika drop/merge/physics gameplay (8 fruit tiers) — v1.0
- Gravity-based physics container with game-over on overflow — v1.0
- Score system with chain reaction multipliers — v1.0
- Next fruit preview — v1.0
- Roguelike card system with 3 active card slots — v1.0
- 10 card effects (physics/merge/scoring/economy) — v1.0
- Card shop at score thresholds — v1.0
- Starter card pick at run start — v1.0
- Per-run card economy — v1.0
- Desktop + mobile support with touch controls — v1.0
- Run summary screen at game over — v1.0

### Active

- [ ] Kawaii/chibi fruit sprites for all 8 tiers
- [ ] Cute basket container art
- [ ] Background scene art
- [ ] Cohesive UI styling matching art direction

### Out of Scope

- Real-money microtransactions — in-game currency only
- Persistent card collections between runs — classic roguelike per-run design
- Multiplayer — single-player focus
- Leaderboards / online features — local play only
- Advanced roguelike elements (meta-progression, unlockables) — planned for later milestones
- Card art / card icons — defer to future milestone
- Animated fruit sprites (idle, squash/stretch) — static sprites for v1.1

## Context

**Reference games studied:**
- suikagame.co.uk — Standard Suika with 11 fruits, push mechanic (5 left, 5 right nudges)
- suika.world — Clean minimal Suika implementation with fruit chart
- Arkadium Fruit Merge — Polished Suika with blueberry(1pt) → watermelon(66pt) progression, bouncy physics where fruits can bounce out of container

**Key mechanics from references:**
- 11 fruit progression: blueberry, cherry, strawberry, lemon, banana, orange, apple, pear, grape, pineapple, watermelon
- Click/tap to position, release to drop
- Identical touching fruits auto-merge into next tier
- Container overflow = game over
- Next fruit preview shown to player
- Physics: gravity, collision, stacking, potential bounce

**Roguelike card system design:**
- Each run is self-contained — start fresh every time
- Begin with free starter card(s)
- 3-5 active card slots (limited slots force strategic choices)
- Game pauses at score thresholds to open card shop
- Spend in-game coins (earned from merges) on offered cards
- Example card effects: multi-type fruit (counts as multiple types for merging), bouncy physics modifier, and more to be designed

**Engine:** Godot 4.5 (GDScript)
**Target platforms:** Desktop (Windows) + Mobile (touch controls)

## Constraints

- **Engine**: Godot 4.5 — using built-in 2D physics (RigidBody2D) for fruit simulation
- **Language**: GDScript — Godot's native scripting language
- **Platform**: Must support both mouse/keyboard and touch input
- **Art**: 2D sprites — cute fruit art style matching reference games
- **Card system**: Must be extensible — more card effects will be added in future milestones

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Godot 4.5 with GDScript | User-specified engine choice, good 2D physics support | — Pending |
| Per-run roguelike (no persistence) | Classic roguelike design, simpler v1, persistence in later milestones | — Pending |
| Score thresholds trigger card shop | Natural pacing mechanism, rewards good play with more card choices | — Pending |
| 3-5 active card slots | Forces strategic choices, prevents card stacking from trivializing gameplay | — Pending |
| In-game currency only | No real-money complexity for v1 | — Pending |

| Runware AI for game art generation | Fast iteration, consistent kawaii style, no manual art pipeline needed | — Pending |
| Full visual overhaul in v1.1 | Cohesive art direction improves game feel more than piecemeal updates | — Pending |

---
*Last updated: 2026-02-13 after milestone v1.1 start*
