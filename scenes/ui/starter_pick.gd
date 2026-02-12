extends CanvasLayer
## Starter kit pick overlay. Displays 3 themed kit options at run start.
## Player picks a kit to receive a mystery card from its pool.
## Listens for EventBus.starter_pick_requested, emits starter_pick_completed.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	# Connect to starter pick signal from EventBus.
	EventBus.starter_pick_requested.connect(_on_starter_pick_requested)


func _on_starter_pick_requested(_offers: Array) -> void:
	## Show the starter kit overlay. The offers parameter is ignored (kept for
	## signal compatibility); kits are read from CardManager.STARTER_KITS.
	# Clear any existing children in OffersContainer (safety for restart).
	var offers_container: VBoxContainer = $Overlay/PickContainer/OffersContainer
	for child in offers_container.get_children():
		child.queue_free()

	# Build kit rows.
	for kit_index in CardManager.STARTER_KITS.size():
		var kit: Dictionary = CardManager.STARTER_KITS[kit_index]

		# Each kit is an HBoxContainer with a styled panel and a Pick button.
		var row: HBoxContainer = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		# Kit display panel.
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(380, 100)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.5, 0.5, 0.6, 0.8)
		style.content_margin_left = 12.0
		style.content_margin_top = 10.0
		style.content_margin_right = 12.0
		style.content_margin_bottom = 10.0
		panel.add_theme_stylebox_override("panel", style)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)

		var name_label: Label = Label.new()
		name_label.text = kit["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 24)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var desc_label: Label = Label.new()
		desc_label.text = kit["description"]
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.add_theme_font_size_override("font_size", 16)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		vbox.add_child(name_label)
		vbox.add_child(desc_label)
		panel.add_child(vbox)
		row.add_child(panel)

		var pick_btn: Button = Button.new()
		pick_btn.text = "Pick"
		pick_btn.custom_minimum_size = Vector2(100, 50)
		pick_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		pick_btn.add_theme_font_size_override("font_size", 20)
		pick_btn.pressed.connect(_on_kit_picked.bind(kit_index))
		row.add_child(pick_btn)

		offers_container.add_child(row)

	visible = true


func _on_kit_picked(kit_index: int) -> void:
	## Handle picking a starter kit: resolve to a card, add to inventory, emit signal, close.
	var card: CardData = CardManager.get_kit_card(kit_index)

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
