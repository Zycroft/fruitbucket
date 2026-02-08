extends Node
## Global signal bus for cross-system communication.
## Contains only signal declarations -- no logic.

## Emitted when two fruits merge. old_tier is the tier that was consumed,
## new_tier is the tier that was created (or 8 if watermelon pair vanished).
signal fruit_merged(old_tier: int, new_tier: int, position: Vector2)

## Emitted when a fruit is released by the player and enters physics simulation.
signal fruit_dropped(tier: int, position: Vector2)

## Emitted when a fruit stays above the overflow line for the required duration.
signal game_over_triggered()

## Emitted when GameManager transitions to a new state.
signal game_state_changed(new_state: int)

## Emitted when the DropController rolls the next fruit tier (for HUD preview).
signal next_fruit_changed(tier: int)
