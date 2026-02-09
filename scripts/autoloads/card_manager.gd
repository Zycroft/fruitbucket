extends Node
## Manages card inventory, shop offer generation, and card economy.
## Registered as an autoload -- persists across scene reloads.
## Card effects are Phase 6/7; this handles data and inventory only.

## Maximum number of active card slots.
const MAX_CARD_SLOTS: int = 3

## Rarity weights per shop level: [Common, Uncommon, Rare].
## Later shops offer more rare cards.
const RARITY_WEIGHTS: Array = [
	[0.70, 0.25, 0.05],  # Shop level 0 (first shop)
	[0.55, 0.35, 0.10],  # Shop level 1
	[0.40, 0.40, 0.20],  # Shop level 2
	[0.25, 0.40, 0.35],  # Shop level 3
]

## Price multiplier per shop level (prices increase as run progresses).
const PRICE_MULTIPLIERS: Array[float] = [1.0, 1.25, 1.5, 2.0]

## Cards currently in the player's slots.
## Each element is either null (empty) or a Dictionary { card: CardData, purchase_price: int }.
var active_cards: Array = []

## All available card definitions loaded from .tres resources.
var _card_pool: Array[CardData] = []

## Number of shops opened this run (affects pricing and rarity).
var _shop_level: int = 0


func _ready() -> void:
	_load_card_pool()
	reset()


func _load_card_pool() -> void:
	## Load all card .tres files from the card_data directory.
	var card_paths: Array[String] = [
		"res://resources/card_data/bouncy_berry.tres",
		"res://resources/card_data/quick_fuse.tres",
		"res://resources/card_data/fruit_frenzy.tres",
		"res://resources/card_data/golden_touch.tres",
		"res://resources/card_data/cherry_bomb.tres",
		"res://resources/card_data/heavy_hitter.tres",
		"res://resources/card_data/big_game_hunter.tres",
		"res://resources/card_data/lucky_break.tres",
		"res://resources/card_data/pineapple_express.tres",
		"res://resources/card_data/wild_fruit.tres",
	]
	_card_pool.clear()
	for path in card_paths:
		var card: CardData = load(path) as CardData
		if card:
			_card_pool.append(card)
		else:
			push_warning("CardManager: Failed to load card at %s" % path)


func reset() -> void:
	## Clear all card slots and reset shop level. Called by GameManager.reset_game().
	active_cards.clear()
	for i in MAX_CARD_SLOTS:
		active_cards.append(null)
	_shop_level = 0


func has_empty_slot() -> bool:
	## Returns true if any card slot is empty.
	return active_cards.has(null)


func add_card(card: CardData, purchase_price: int = 0) -> int:
	## Add card to first empty slot. Returns slot index, or -1 if full.
	for i in active_cards.size():
		if active_cards[i] == null:
			active_cards[i] = { "card": card, "purchase_price": purchase_price }
			return i
	return -1


func remove_card(slot_index: int) -> CardData:
	## Remove and return the CardData from a slot. Returns null if slot was empty.
	if slot_index < 0 or slot_index >= active_cards.size():
		return null
	var entry = active_cards[slot_index]
	active_cards[slot_index] = null
	if entry == null:
		return null
	return entry["card"] as CardData


func get_card(slot_index: int) -> CardData:
	## Return the CardData at a slot index, or null if empty.
	if slot_index < 0 or slot_index >= active_cards.size():
		return null
	var entry = active_cards[slot_index]
	if entry == null:
		return null
	return entry["card"] as CardData


func get_buy_price(card: CardData) -> int:
	## Calculate buy price with shop-level inflation.
	return int(card.base_price * _get_price_multiplier())


func get_sell_price(slot_index: int) -> int:
	## Sell price is 50% of what the player paid, floored to 50% of base price.
	## Ensures free cards (e.g. starter pick) still have sell value.
	if slot_index < 0 or slot_index >= active_cards.size():
		return 0
	var entry = active_cards[slot_index]
	if entry == null:
		return 0
	var card: CardData = entry["card"] as CardData
	return maxi(entry["purchase_price"] / 2, card.base_price / 2)


func generate_shop_offers(count: int = 3) -> Array[CardData]:
	## Generate shop card offers based on current shop level.
	## Avoids duplicate card_ids within one offer set (re-rolls on duplicate).
	var offers: Array[CardData] = []
	var used_ids: Array[String] = []
	var weights: Array = RARITY_WEIGHTS[mini(_shop_level, RARITY_WEIGHTS.size() - 1)]
	var max_attempts: int = count * 5  # Prevent infinite loop
	var attempts: int = 0
	while offers.size() < count and attempts < max_attempts:
		attempts += 1
		var rarity: int = _pick_weighted_rarity(weights)
		var card: CardData = _pick_random_card_of_rarity(rarity)
		if card and card.card_id not in used_ids:
			offers.append(card)
			used_ids.append(card.card_id)
	return offers


func generate_starter_offers(count: int = 3) -> Array[CardData]:
	## Generate starter card offers using shop level 0 weights (more common cards).
	## Does NOT increment shop level.
	var offers: Array[CardData] = []
	var used_ids: Array[String] = []
	var weights: Array = RARITY_WEIGHTS[0]
	var max_attempts: int = count * 5
	var attempts: int = 0
	while offers.size() < count and attempts < max_attempts:
		attempts += 1
		var rarity: int = _pick_weighted_rarity(weights)
		var card: CardData = _pick_random_card_of_rarity(rarity)
		if card and card.card_id not in used_ids:
			offers.append(card)
			used_ids.append(card.card_id)
	return offers


func advance_shop_level() -> void:
	## Increment shop level (called when opening a shop).
	_shop_level += 1


func _get_price_multiplier() -> float:
	## Get the current price multiplier based on shop level.
	return PRICE_MULTIPLIERS[mini(_shop_level, PRICE_MULTIPLIERS.size() - 1)]


func _pick_weighted_rarity(weights: Array) -> int:
	## Weighted random selection. Returns 0 (COMMON), 1 (UNCOMMON), or 2 (RARE).
	var roll: float = randf()
	var cumulative: float = 0.0
	for i in weights.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return i
	return 0  # Fallback to common


func _pick_random_card_of_rarity(rarity: int) -> CardData:
	## Pick a random card from the pool matching the given rarity.
	## Falls back to COMMON if no cards match the target rarity.
	var matching: Array[CardData] = []
	for card in _card_pool:
		if card.rarity == rarity:
			matching.append(card)
	if matching.is_empty():
		if rarity != CardData.Rarity.COMMON:
			return _pick_random_card_of_rarity(CardData.Rarity.COMMON)
		return null
	return matching.pick_random()
