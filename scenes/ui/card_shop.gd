extends CanvasLayer
## Card shop overlay. Displays 3 card offers with buy buttons, 3 player card
## slots with sell-on-tap, and a skip button. Opens on EventBus.shop_opened,
## closes on skip or EventBus.shop_closed.

## Preloaded card slot display scene for offer and slot instances.
var _card_slot_scene: PackedScene = preload("res://scenes/ui/card_slot_display.tscn")

## Current shop offers (CardData references).
var _current_offers: Array[CardData] = []

## Dynamic offer HBoxContainer nodes (one per offer row).
var _offer_nodes: Array = []

## Player card slot display instances (3 total).
var _slot_nodes: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	# Connect to shop_opened signal from EventBus.
	EventBus.shop_opened.connect(_on_shop_opened)

	# Connect skip button.
	$Overlay/ShopContainer/SkipButton.pressed.connect(_on_skip_pressed)

	# Create 3 player card slot displays in SlotsContainer.
	for i in 3:
		var slot_display: PanelContainer = _card_slot_scene.instantiate()
		slot_display.custom_minimum_size = Vector2(160, 120)
		$Overlay/ShopContainer/SlotsContainer.add_child(slot_display)
		slot_display.display_empty()
		slot_display.gui_input.connect(_on_slot_clicked.bind(i))
		# Make slots interactive for sell (mouse_filter = STOP).
		slot_display.mouse_filter = Control.MOUSE_FILTER_STOP
		_slot_nodes.append(slot_display)


func _on_shop_opened(offers: Array, _shop_level: int) -> void:
	## Open the shop overlay with the given card offers.
	_current_offers.clear()
	for offer in offers:
		_current_offers.append(offer as CardData)

	# Update coin display.
	$Overlay/ShopContainer/CoinLabel.text = "Coins: %d" % GameManager.coins

	# Clear previous offer nodes.
	_clear_offers()

	# Build offer rows.
	for i in _current_offers.size():
		var card: CardData = _current_offers[i]
		var price: int = CardManager.get_buy_price(card)

		# Each offer is an HBoxContainer with a CardSlotDisplay and a Buy button.
		var row: HBoxContainer = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.theme_override_constants = {}
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		var card_display: PanelContainer = _card_slot_scene.instantiate()
		card_display.custom_minimum_size = Vector2(380, 100)
		row.add_child(card_display)
		card_display.display_card(card, price)

		var buy_btn: Button = Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(80, 50)
		buy_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		buy_btn.pressed.connect(_on_buy_pressed.bind(i))
		row.add_child(buy_btn)

		$Overlay/ShopContainer/OffersContainer.add_child(row)
		_offer_nodes.append(row)

	# Refresh player slots.
	_refresh_slots()

	visible = true


func _refresh_slots() -> void:
	## Refresh all 3 player card slot displays and coin label.
	for i in 3:
		var card: CardData = CardManager.get_card(i)
		if card != null:
			_slot_nodes[i].display_card(card)
			_slot_nodes[i].set_sell_mode(CardManager.get_sell_price(i))
		else:
			_slot_nodes[i].display_empty()
	$Overlay/ShopContainer/CoinLabel.text = "Coins: %d" % GameManager.coins


func _on_buy_pressed(offer_index: int) -> void:
	## Attempt to buy a card from the shop offers.
	if offer_index < 0 or offer_index >= _current_offers.size():
		return

	var card: CardData = _current_offers[offer_index]
	var price: int = CardManager.get_buy_price(card)

	# Guard: insufficient coins.
	if GameManager.coins < price:
		_flash_label($Overlay/ShopContainer/CoinLabel, Color.RED)
		return

	# Guard: no empty slots.
	if not CardManager.has_empty_slot():
		_flash_label($Overlay/ShopContainer/YourCardsLabel, Color.RED)
		return

	# Deduct coins and add card.
	GameManager.coins -= price
	var slot: int = CardManager.add_card(card, price)

	# Emit signals.
	EventBus.card_purchased.emit(card, slot)
	EventBus.active_cards_changed.emit(CardManager.active_cards)

	# Disable the buy button for this offer so it cannot be bought again.
	if offer_index < _offer_nodes.size():
		var row: HBoxContainer = _offer_nodes[offer_index]
		for child in row.get_children():
			if child is Button:
				child.disabled = true

	_refresh_slots()


func _on_slot_clicked(event: InputEvent, slot_index: int) -> void:
	## Handle tap/click on a player card slot to sell.
	if not (event is InputEventMouseButton and event.pressed):
		return

	# Guard: slot is empty.
	if CardManager.get_card(slot_index) == null:
		return

	# Calculate refund before removal.
	var refund: int = CardManager.get_sell_price(slot_index)

	# Remove card and refund coins.
	var card: CardData = CardManager.remove_card(slot_index)
	GameManager.coins += refund

	# Emit signals.
	EventBus.card_sold.emit(card, slot_index, refund)
	EventBus.active_cards_changed.emit(CardManager.active_cards)

	_refresh_slots()


func _on_skip_pressed() -> void:
	## Close the shop and resume gameplay.
	visible = false
	_clear_offers()
	EventBus.shop_closed.emit()


func _clear_offers() -> void:
	## Remove all dynamic offer nodes from OffersContainer.
	for node in _offer_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_offer_nodes.clear()


func _flash_label(label: Label, flash_color: Color) -> void:
	## Briefly flash a label to a color and back to indicate an error.
	var original_color: Color = label.modulate
	var tween: Tween = create_tween()
	tween.tween_property(label, "modulate", flash_color, 0.1)
	tween.tween_property(label, "modulate", original_color, 0.2)
