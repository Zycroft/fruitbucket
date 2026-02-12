# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Bucket (Fruitbucket) — a roguelike Suika Game built with Godot 4.5 (GL Compatibility renderer). Fruits drop into a bucket, same-tier fruits merge into the next tier, with a card system adding roguelike modifiers each run. Portrait viewport (1080x1920, window override 540x960).

**Live at:** https://zycroft.github.io/fruitbucket/ and https://zycroft.duckdns.org/bucket/

## Running

Open in Godot 4.5-stable, run `scenes/game/game.tscn` (the main scene). No external dependencies — pure GDScript + Godot. Web export preset "Web" exports to `build/web/`.

## Deployment

Push to `main` triggers `.github/workflows/deploy-web.yml`: exports web build, then deploys in parallel to GitHub Pages and duckdns via SSH/rsync. Secrets needed: `SSH_PRIVATE_KEY`, `SSH_HOST`, `SSH_USER`.

## Architecture

### Autoloads (registered in project.godot, this order matters)

1. **EventBus** — Pure signal bus with ~24 signals, no logic or state. All cross-system communication goes through here. Signal naming: past tense for events (`fruit_merged`, `score_awarded`), present tense for requests (`pause_requested`).
2. **GameManager** — State machine (READY → DROPPING → WAITING → PAUSED/SHOPPING/PICKING → GAME_OVER). Owns `score` and `coins`. Controls tree pause/unpause.
3. **SfxManager** — 8-node AudioStreamPlayer pool. Tier-scaled pitch/volume for merge sounds.
4. **CardManager** — Manages 3 active card slots, shop offer generation with rarity-weighted selection (Common/Uncommon/Rare), shop level progression. Per-run economy.

### Component Pattern

Components live in `scripts/components/` and are attached to the game scene. They find each other via groups (e.g., `get_tree().get_first_node_in_group("merge_manager")`), not autoloads.

- **MergeManager** — Gatekeeper for merges. Prevents double-merge via instance ID dictionary locking + deterministic tiebreaker (lower ID initiates). Deactivates fruits safely before deferred queue_free.
- **DropController** — Input handling (mouse/touch) via `_unhandled_input`. Fruit preview, drop cooldown, horizontal clamping, drop guide.
- **ScoreManager** — Fibonacci-like chain multipliers `[1,2,3,5,8,13,21,34,55,89]`, 1.0s chain timer, coin threshold detection.
- **OverflowDetector** — Per-fruit dwell timer (2.0s continuous threshold). Game-over detection with grace period.
- **CardEffectSystem** — Hook-based modifier system. Reads `CardManager.active_cards`, applies effects on EventBus signals. Linear stacking (multiple copies add, don't multiply).
- **MergeFeedback** — Orchestrates particles, screen shake, SFX with tier-intensity scaling.

### Data-Driven Resources

- `resources/fruit_data/` — 8 `FruitData` .tres files (tier_1 through tier_8). Properties: tier, radius, score_value, color, mass_override, is_droppable (tiers 0-4 only).
- `resources/card_data/` — 10 `CardData` .tres files. Properties: card_id, rarity, base_price, icon, description.
- Single `fruit.tscn` scene used for all tiers — configured at runtime from FruitData resource.

### Signal Flow (merge example)

```
Fruit collision (body_entered, same tier)
  → fruit.gd calls MergeManager.request_merge() [lower instance ID initiates]
  → MergeManager locks both, emits EventBus.fruit_merged
  → ScoreManager calculates score + chains → EventBus.score_awarded
  → MergeFeedback spawns particles, shake, SFX
  → CardEffectSystem applies card bonuses
```

## Critical Godot Pitfalls (already solved — preserve these patterns)

1. **Never `queue_free()` in physics callbacks** — Use `call_deferred("queue_free")` after disabling `contact_monitor`, setting `freeze = true`, and disabling collision shape.
2. **Never scale RigidBody2D nodes** — Modify `CollisionShape2D.shape.radius` and `Sprite2D.scale` separately.
3. **Double-merge prevention** — Instance ID tiebreaker + MergeManager gatekeeper. Don't bypass this.
4. **Overflow false positives** — Per-fruit dwell timer, not simple area overlap. Ignores dropping/merging/grace-period fruits.
5. **Physics stability** — `solver_iterations=6`, `CircleShape2D` only, `linear_damp=0.5`, `can_sleep=true`, friction=0.6, bounce=0.15.

## Planning

Phase-based development docs live in `.planning/`. Key files:
- `PROJECT.md` — Core value prop, requirements, constraints
- `ROADMAP.md` — 8-phase roadmap (7 complete, Phase 8 remaining: card activation feedback & starter kits)
- `STATE.md` — Current position, velocity metrics, accumulated architectural decisions
- `research/PITFALLS.md` — Detailed pitfall analysis with solutions

## Conventions

- `class_name` on all scripts that need external reference
- `@export var` for inspector-editable properties, `@onready var` for node refs
- `##` doc comments on classes and public functions
- Private functions prefixed with underscore
- Constants in SCREAMING_SNAKE_CASE
- Event-driven UI — connect to EventBus signals, never poll state
- Physics layers: 1=Fruits, 2=Container, 3=Overflow
