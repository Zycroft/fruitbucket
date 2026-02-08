extends CanvasLayer
## HUD overlay displaying current score, next-fruit preview, and game-over text.
## Listens to EventBus signals for updates.

## All 8 FruitData resources loaded in tier order for sprite/color lookups.
var _fruit_types: Array[FruitData] = []


func _ready() -> void:
	_load_fruit_types()

	# Connect EventBus signals.
	EventBus.fruit_merged.connect(_on_fruit_merged)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.next_fruit_changed.connect(_on_next_fruit_changed)

	# Initialize score display.
	update_score(GameManager.score)

	# Hide game over label by default.
	$GameOverLabel.visible = false


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


func update_score(score: int) -> void:
	## Update the score label display.
	$ScoreLabel.text = str(score)


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


func _on_fruit_merged(_old_tier: int, _new_tier: int, _pos: Vector2) -> void:
	## When fruits merge, update the score display.
	## Phase 2 will populate actual score values; for now just display the current score.
	update_score(GameManager.score)


func _on_game_state_changed(new_state: int) -> void:
	## Show game over label when entering GAME_OVER state.
	if new_state == GameManager.GameState.GAME_OVER:
		$GameOverLabel.visible = true


func _on_next_fruit_changed(tier: int) -> void:
	## Called when DropController rolls a new next fruit tier.
	update_next_fruit(tier)
