extends PanelContainer
## Reusable card display component. Renders a single CardData with
## rarity-colored border, name, description, and optional price tag.
## Used by HUD card slots, shop offers, and starter pick screen.

## Rarity-to-color mapping for card borders.
const RARITY_COLORS: Dictionary = {
	CardData.Rarity.COMMON: Color(0.7, 0.7, 0.7),
	CardData.Rarity.UNCOMMON: Color(0.2, 0.7, 0.3),
	CardData.Rarity.RARE: Color(0.85, 0.65, 0.1),
}

## Rarity display names.
const RARITY_NAMES: Dictionary = {
	CardData.Rarity.COMMON: "Common",
	CardData.Rarity.UNCOMMON: "Uncommon",
	CardData.Rarity.RARE: "Rare",
}


func display_card(card: CardData, price: int = -1) -> void:
	## Render a card with name, description, rarity border, and optional price.
	$MarginContainer/Content/CardName.text = card.card_name
	$MarginContainer/Content/Description.text = card.description
	if price >= 0:
		$MarginContainer/Content/PriceLabel.visible = true
		$MarginContainer/Content/PriceLabel.text = "%d coins" % price
	else:
		$MarginContainer/Content/PriceLabel.visible = false
	# Set border color based on rarity.
	var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	style.border_color = RARITY_COLORS[card.rarity]
	add_theme_stylebox_override("panel", style)


func display_empty() -> void:
	## Render an empty card slot with default grey border.
	$MarginContainer/Content/CardName.text = "Empty"
	$MarginContainer/Content/Description.text = ""
	$MarginContainer/Content/PriceLabel.visible = false
	var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	add_theme_stylebox_override("panel", style)


func set_sell_mode(sell_price: int) -> void:
	## Show sell price on the card (used by shop for owned cards).
	$MarginContainer/Content/PriceLabel.visible = true
	$MarginContainer/Content/PriceLabel.text = "Sell: %d coins" % sell_price
