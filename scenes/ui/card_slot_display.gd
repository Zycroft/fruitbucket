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

## Rarity-to-glow-color mapping for trigger animations.
const TRIGGER_GLOW_COLORS: Dictionary = {
	CardData.Rarity.COMMON: Color(1.0, 1.0, 1.0, 1.0),
	CardData.Rarity.UNCOMMON: Color(0.2, 0.9, 0.3, 1.0),
	CardData.Rarity.RARE: Color(0.7, 0.4, 1.0, 1.0),
}

## Reference to the currently displayed card (for rarity lookup in trigger animation).
var _current_card: CardData = null

## Active trigger animation tween (for dampening rapid re-triggers).
var _trigger_tween: Tween = null


func display_card(card: CardData, price: int = -1) -> void:
	## Render a card with name, description, rarity border, and optional price.
	_current_card = card
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
	_current_card = null
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


func set_status_text(text: String) -> void:
	## Show a status overlay on the card slot (e.g., charge count "3/3").
	## Reuses PriceLabel which is hidden in HUD display-only mode.
	if text.is_empty():
		$MarginContainer/Content/PriceLabel.visible = false
	else:
		$MarginContainer/Content/PriceLabel.visible = true
		$MarginContainer/Content/PriceLabel.text = text


func clear_status_text() -> void:
	## Hide the status overlay.
	$MarginContainer/Content/PriceLabel.visible = false


func get_card_id() -> String:
	## Return the card_id of the currently displayed card, or empty string if none.
	if _current_card != null:
		return _current_card.card_id
	return ""


func play_trigger_animation(is_charge: bool = false) -> void:
	## Play a glow + scale bounce animation on this card slot.
	## Rarity determines glow color. Charge cards get bigger/longer animation.
	## Dampened: if a trigger tween is already running, skip to prevent strobing.
	if _current_card == null:
		return
	# Dampening: skip re-trigger if animation is already playing.
	if _trigger_tween and _trigger_tween.is_valid() and _trigger_tween.is_running():
		return
	# Kill any leftover tween (edge case: tween valid but finished).
	if _trigger_tween and _trigger_tween.is_valid():
		_trigger_tween.kill()
	# Determine glow parameters based on rarity and charge type.
	var glow_color: Color = TRIGGER_GLOW_COLORS.get(_current_card.rarity, Color.WHITE)
	var bounce_scale: float
	var glow_duration: float
	var border_width: int
	if is_charge:
		bounce_scale = 1.25
		glow_duration = 0.5
		border_width = 6
	else:
		bounce_scale = 1.15
		glow_duration = 0.3
		border_width = 5
	# Center pivot for scale animation.
	pivot_offset = size / 2.0
	# Apply glow border style (duplicated to avoid shared resource mutation).
	var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	style.border_color = glow_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	add_theme_stylebox_override("panel", style)
	# Create tween: scale bounce + glow persistence + restore.
	_trigger_tween = create_tween()
	# Phase 1: Scale up (parallel with glow already applied).
	_trigger_tween.tween_property(self, "scale", Vector2(bounce_scale, bounce_scale), 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Phase 2: Scale back down.
	_trigger_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	# Phase 3: Hold glow for remaining duration.
	var hold_time: float = maxf(glow_duration - 0.3, 0.0)
	if hold_time > 0.0:
		_trigger_tween.tween_interval(hold_time)
	# Phase 4: Restore normal border.
	_trigger_tween.tween_callback(_restore_normal_border)


func _restore_normal_border() -> void:
	## Restore the card slot border to its normal rarity color after trigger glow.
	if _current_card != null:
		var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
		style.border_color = RARITY_COLORS[_current_card.rarity]
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		add_theme_stylebox_override("panel", style)
	else:
		display_empty()
