class_name CardData
extends Resource
## Data resource describing a single card.
## Each card has a corresponding .tres file in resources/card_data/.
## Card effects are implemented in Phase 6/7 -- this class defines data only.

enum Rarity { COMMON, UNCOMMON, RARE }

## Unique identifier used by the effect system (Phase 6/7).
@export var card_id: String = ""

## Display name shown in HUD and shop.
@export var card_name: String = ""

## Effect description shown on the card face.
@export var description: String = ""

## Rarity tier affecting shop price and appearance frequency.
@export var rarity: Rarity = Rarity.COMMON

## Base price in coins (before shop-level inflation).
@export var base_price: int = 10

## Card icon/art (placeholder until art phase).
@export var icon: Texture2D
