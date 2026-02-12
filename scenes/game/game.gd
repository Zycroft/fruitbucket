extends Node2D
## Root game scene script. Orchestrates the game loop by managing state
## transitions and connecting to EventBus signals.

## Reference to the HUD for score/preview updates.
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	# Start in READY state, then show starter card pick.
	GameManager.change_state(GameManager.GameState.READY)

	# Connect game over signal.
	EventBus.game_over_triggered.connect(_on_game_over)

	# Connect card shop signals.
	EventBus.score_threshold_reached.connect(_on_score_threshold)
	EventBus.shop_closed.connect(_on_shop_closed)

	# Connect starter pick signal.
	EventBus.starter_pick_completed.connect(_on_starter_pick_done)

	# Brief delay to let physics settle, then show starter card pick.
	await get_tree().create_timer(0.3).timeout
	_show_starter_pick()


func _show_starter_pick() -> void:
	## Show the starter kit pick overlay. Kits are defined in CardManager.
	GameManager.change_state(GameManager.GameState.PICKING)
	EventBus.starter_pick_requested.emit([])


func _on_starter_pick_done(_card: CardData) -> void:
	## Resume gameplay after the player picks a starter card.
	GameManager.change_state(GameManager.GameState.DROPPING)


func _on_game_over() -> void:
	GameManager.change_state(GameManager.GameState.GAME_OVER)
	# Delay showing summary so fruits settle visually (GAME_OVER doesn't pause tree).
	await get_tree().create_timer(2.5).timeout
	_show_run_summary()


func _show_run_summary() -> void:
	## Gather run stats and display the celebratory summary overlay.
	var tracker: RunStatsTracker = get_tree().get_first_node_in_group("run_stats_tracker") as RunStatsTracker
	if tracker:
		var stats: Dictionary = tracker.get_stats()
		$RunSummary.show_summary(stats)


func _on_score_threshold(_threshold: int) -> void:
	## Open card shop when a score threshold is crossed.
	# Only open if actively playing (not already in shop, paused, picking, or game over).
	if GameManager.current_state != GameManager.GameState.DROPPING \
			and GameManager.current_state != GameManager.GameState.WAITING:
		return

	# Generate offers and advance shop level.
	var offers: Array = CardManager.generate_shop_offers()
	CardManager.advance_shop_level()

	# Transition to SHOPPING state (pauses tree).
	GameManager.change_state(GameManager.GameState.SHOPPING)

	# Open the shop overlay.
	EventBus.shop_opened.emit(offers, CardManager._shop_level)


func _on_shop_closed() -> void:
	## Resume gameplay after the shop is closed.
	GameManager.change_state(GameManager.GameState.DROPPING)
