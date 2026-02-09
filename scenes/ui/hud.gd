extends CanvasLayer
## HUD overlay displaying animated score counter, chain counter, coin display,
## next-fruit preview, and game-over text. Spawns floating score popups at merge
## positions via the world-space PopupContainer.

## All 8 FruitData resources loaded in tier order for sprite/color lookups.
var _fruit_types: Array[FruitData] = []

## Animated score counter state.
var _displayed_score: int = 0
var _score_tween: Tween = null

## Chain display tween (killed on overlap).
var _chain_tween: Tween = null

## Preloaded floating score popup scene.
var _floating_score_scene: PackedScene = preload("res://scenes/ui/floating_score.tscn")

## Preloaded card slot display scene for HUD card slots.
var _card_slot_scene: PackedScene = preload("res://scenes/ui/card_slot_display.tscn")

## Card slot display instances (3 total, display-only in HUD).
var _card_slot_nodes: Array = []


func _ready() -> void:
	_load_fruit_types()

	# Connect EventBus signals.
	EventBus.score_awarded.connect(_on_score_awarded)
	EventBus.chain_ended.connect(_on_chain_ended)
	EventBus.coins_awarded.connect(_on_coins_awarded)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.next_fruit_changed.connect(_on_next_fruit_changed)
	EventBus.card_purchased.connect(_on_card_purchased)
	EventBus.card_sold.connect(_on_card_sold)
	EventBus.active_cards_changed.connect(_on_active_cards_changed)

	# Connect pause button.
	$PauseButton.pressed.connect(_on_pause_button_pressed)

	# Initialize displays.
	$ScoreLabel.text = "0"
	$CoinLabel.text = "Coins: %d" % GameManager.coins
	$ChainLabel.visible = false
	$GameOverLabel.visible = false

	# Create 3 card slot displays in the CardSlots container.
	for i in 3:
		var slot_display: PanelContainer = _card_slot_scene.instantiate()
		slot_display.custom_minimum_size = Vector2(280, 100)
		$CardSlots.add_child(slot_display)
		slot_display.display_empty()
		_card_slot_nodes.append(slot_display)


func _load_fruit_types() -> void:
	## Load all 8 FruitData .tres files in tier order.
	var paths: Array[String] = [
		"res://resources/fruit_data/tier_1_blueberry.tres",
		"res://resources/fruit_data/tier_2_grape.tres",
		"res://resources/fruit_data/tier_3_cherry.tres",
		"res://resources/fruit_data/tier_4_strawberry.tres",
		"res://resources/fruit_data/tier_5_orange.tres",
		"res://resources/fruit_data/tier_6_apple.tres",
		"res://resources/fruit_data/tier_7_pear.tres",
		"res://resources/fruit_data/tier_8_watermelon.tres",
	]
	for path in paths:
		var data: FruitData = load(path) as FruitData
		if data:
			_fruit_types.append(data)
		else:
			push_error("HUD: Failed to load FruitData at %s" % path)


func animate_score_to(new_score: int) -> void:
	## Animate the score label from _displayed_score to new_score with roll-up
	## counting and a scale punch.
	if _score_tween and _score_tween.is_valid():
		_score_tween.kill()

	_score_tween = create_tween()

	# Roll-up counting animation.
	_score_tween.tween_method(_set_score_text, _displayed_score, new_score, 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Scale punch (centered via pivot_offset).
	$ScoreLabel.pivot_offset = $ScoreLabel.size / 2.0
	_score_tween.parallel().tween_property($ScoreLabel, "scale", Vector2(1.2, 1.2), 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_score_tween.tween_property($ScoreLabel, "scale", Vector2.ONE, 0.2)

	_displayed_score = new_score


func _set_score_text(value: int) -> void:
	## Callback for tween_method roll-up animation.
	$ScoreLabel.text = str(value)


func _on_score_awarded(points: int, merge_pos: Vector2, chain_count: int, multiplier: int) -> void:
	## Update score display and spawn floating popup at merge position.
	animate_score_to(GameManager.score)

	# Format popup text.
	var popup_text: String
	var is_chain: bool = multiplier > 1
	if is_chain:
		popup_text = "+%d x%d!" % [points, multiplier]
	else:
		popup_text = "+%d" % points

	# Spawn floating score popup in world space.
	var popup_container: Node2D = get_tree().get_first_node_in_group("popup_container") as Node2D
	if popup_container:
		var popup: Label = _floating_score_scene.instantiate()
		popup_container.add_child(popup)
		popup.show_score(popup_text, merge_pos, is_chain)

	# Update chain display.
	_show_chain(chain_count, multiplier)


func _show_chain(chain_count: int, multiplier: int) -> void:
	## Show chain counter for cascades (chain_count >= 2). Hide for single merges.
	if chain_count < 2:
		$ChainLabel.visible = false
		return

	$ChainLabel.visible = true
	$ChainLabel.text = "CHAIN x%d!" % multiplier

	# Kill previous chain tween to prevent overlap.
	if _chain_tween and _chain_tween.is_valid():
		_chain_tween.kill()

	# Scale punch on chain label.
	$ChainLabel.pivot_offset = $ChainLabel.size / 2.0
	_chain_tween = create_tween()
	_chain_tween.tween_property($ChainLabel, "scale", Vector2(1.3, 1.3), 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_chain_tween.tween_property($ChainLabel, "scale", Vector2.ONE, 0.2)


func _on_chain_ended(_chain_length: int) -> void:
	## Chain ended -- fade out the chain label.
	if _chain_tween and _chain_tween.is_valid():
		_chain_tween.kill()

	_chain_tween = create_tween()
	_chain_tween.tween_property($ChainLabel, "modulate:a", 0.0, 0.3)
	_chain_tween.tween_callback(func():
		$ChainLabel.visible = false
		$ChainLabel.modulate.a = 1.0
	)


func _on_coins_awarded(_new_coins: int, total_coins: int) -> void:
	## Update coin display with scale punch.
	$CoinLabel.text = "Coins: %d" % total_coins

	$CoinLabel.pivot_offset = $CoinLabel.size / 2.0
	var coin_tween: Tween = create_tween()
	coin_tween.tween_property($CoinLabel, "scale", Vector2(1.15, 1.15), 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	coin_tween.tween_property($CoinLabel, "scale", Vector2.ONE, 0.15)


func update_next_fruit(tier: int) -> void:
	## Update the next-fruit preview sprite to show the given tier.
	if tier < 0 or tier >= _fruit_types.size():
		return
	var data: FruitData = _fruit_types[tier]
	$NextFruitPreview/NextFruitSprite.texture = data.sprite
	$NextFruitPreview/NextFruitSprite.modulate = data.color
	# Scale the preview to a consistent display size (~50x50 pixels).
	if data.sprite:
		var tex_size: float = data.sprite.get_width()
		if tex_size > 0:
			var target_size: float = 50.0
			var s: float = target_size / tex_size
			$NextFruitPreview/NextFruitSprite.scale = Vector2(s, s)


func _on_pause_button_pressed() -> void:
	## Request pause via EventBus (PauseMenu listens and handles state change).
	if GameManager.current_state == GameManager.GameState.GAME_OVER:
		return
	EventBus.pause_requested.emit()


func _on_game_state_changed(new_state: int) -> void:
	## Update HUD elements based on game state changes.
	if new_state == GameManager.GameState.GAME_OVER:
		$GameOverLabel.visible = true
		$PauseButton.visible = false
	elif new_state == GameManager.GameState.PAUSED:
		$PauseButton.visible = false
	elif new_state == GameManager.GameState.SHOPPING \
			or new_state == GameManager.GameState.PICKING:
		$PauseButton.visible = false
	else:
		$PauseButton.visible = true


func _on_next_fruit_changed(tier: int) -> void:
	## Called when DropController rolls a new next fruit tier.
	update_next_fruit(tier)


func _on_card_purchased(card: CardData, slot_index: int) -> void:
	## Update HUD card slot when a card is purchased.
	if slot_index >= 0 and slot_index < _card_slot_nodes.size():
		_card_slot_nodes[slot_index].display_card(card)
	$CoinLabel.text = "Coins: %d" % GameManager.coins


func _on_card_sold(_card: CardData, slot_index: int, _refund: int) -> void:
	## Clear HUD card slot when a card is sold.
	if slot_index >= 0 and slot_index < _card_slot_nodes.size():
		_card_slot_nodes[slot_index].display_empty()
	$CoinLabel.text = "Coins: %d" % GameManager.coins


func _on_active_cards_changed(cards: Array) -> void:
	## Refresh all 3 HUD card slots from the active_cards array.
	for i in mini(cards.size(), _card_slot_nodes.size()):
		if cards[i] != null:
			_card_slot_nodes[i].display_card(cards[i]["card"] as CardData)
		else:
			_card_slot_nodes[i].display_empty()
