# Bucket — Roguelike Suika Game

## What This Is

A Suika-style fruit-dropping puzzle game built in Godot 4.5 with a roguelike card system layered on top. Players drop fruits into a container where matching fruits merge into larger ones, while collecting and activating modifier cards that alter gameplay mechanics. Targets desktop and mobile (touch controls) with polished 2D fruit art.

## Core Value

The drop-merge-physics loop must feel satisfying and correct — fruits fall naturally, collide realistically, and merge reliably. Without solid core mechanics, the card system has nothing to build on.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Core Suika drop/merge/physics gameplay (11 fruit tiers, blueberry → watermelon)
- [ ] Gravity-based physics container with game-over on overflow
- [ ] Score system based on merge values with chain reaction bonuses
- [ ] Next fruit preview
- [ ] Roguelike card system with 3-5 active card slots per run
- [ ] Card effects that modify fruit behavior (multi-type, bouncy physics, etc.)
- [ ] In-run card shop triggered at score thresholds
- [ ] Free starter card pack at the beginning of each run
- [ ] In-game currency earned from merges/score, spent on card offers
- [ ] Per-run card economy (no persistence between runs)
- [ ] Desktop + mobile support with touch controls
- [ ] Cute fruit sprite art style

### Out of Scope

- Real-money microtransactions — in-game currency only for v1
- Persistent card collections between runs — classic roguelike per-run design
- Multiplayer — single-player focus
- Leaderboards / online features — local play only for v1
- Advanced roguelike elements (meta-progression, unlockables) — planned for later milestones

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

---
*Last updated: 2026-02-07 after initialization*
