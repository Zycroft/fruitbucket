extends CanvasLayer
## Starter card pick overlay. Displays 3 random card offers at run start.
## Player picks one for free before gameplay begins.
## Listens for EventBus.starter_pick_requested, emits starter_pick_completed.

## Preloaded card slot display scene for offer instances.
var _card_slot_scene: PackedScene = preload("res://scenes/ui/card_slot_display.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	# Connect to starter pick signal from EventBus.
	EventBus.starter_pick_requested.connect(_on_starter_pick_requested)


func _on_starter_pick_requested(offers: Array) -> void:
	## Show the starter pick overlay with the given card offers.
	# Clear any existing children in OffersContainer (safety for restart).
	var offers_container: VBoxContainer = $Overlay/PickContainer/OffersContainer
	for child in offers_container.get_children():
		child.queue_free()

	# Build offer rows.
	for card in offers:
		var card_data: CardData = card as CardData
		if card_data == null:
			continue

		# Each offer is an HBoxContainer with a CardSlotDisplay and a Pick button.
		var row: HBoxContainer = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		var card_display: PanelContainer = _card_slot_scene.instantiate()
		card_display.custom_minimum_size = Vector2(380, 100)
		row.add_child(card_display)
		card_display.display_card(card_data)

		var pick_btn: Button = Button.new()
		pick_btn.text = "Pick"
		pick_btn.custom_minimum_size = Vector2(100, 50)
		pick_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		pick_btn.add_theme_font_size_override("font_size", 20)
		pick_btn.pressed.connect(_on_card_picked.bind(card_data))
		row.add_child(pick_btn)

		offers_container.add_child(row)

	visible = true


func _on_card_picked(card: CardData) -> void:
	## Handle picking a starter card: add to inventory, emit signal, close.
	# Add to inventory (purchase_price = 0, it's free).
	CardManager.add_card(card, 0)

	# Emit signals.
	EventBus.starter_pick_completed.emit(card)
	EventBus.active_cards_changed.emit(CardManager.active_cards)

	# Clean up OffersContainer children.
	var offers_container: VBoxContainer = $Overlay/PickContainer/OffersContainer
	for child in offers_container.get_children():
		child.queue_free()

	visible = false
