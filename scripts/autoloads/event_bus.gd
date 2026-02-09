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

## Emitted on every merge with calculated score, chain info, and position for popups.
signal score_awarded(points: int, position: Vector2, chain_count: int, multiplier: int)

## Emitted when a cascade chain ends (no merge within the settling window).
signal chain_ended(chain_length: int)

## Emitted when cumulative score crosses a coin threshold (every 100 points).
signal coins_awarded(new_coins: int, total_coins: int)

## Emitted when cumulative score crosses a milestone threshold (for Phase 5 shop triggers).
signal score_threshold_reached(threshold: int)

## Emitted by the HUD pause button to request a pause.
signal pause_requested()

## Emitted by the PauseMenu when the player resumes (for symmetry).
signal resume_requested()

## Emitted when the starter card pick UI should appear.
signal starter_pick_requested(offers: Array)

## Emitted when the player picks a starter card.
signal starter_pick_completed(card: CardData)

## Emitted when the card shop should open.
signal shop_opened(offers: Array, shop_level: int)

## Emitted when the player closes the shop (buy, skip, or sell).
signal shop_closed()

## Emitted when a card is purchased and added to a slot.
signal card_purchased(card: CardData, slot_index: int)

## Emitted when a card is sold from a slot.
signal card_sold(card: CardData, slot_index: int, refund: int)

## Emitted when active cards change (purchase, sell, or reset).
signal active_cards_changed(cards: Array)
