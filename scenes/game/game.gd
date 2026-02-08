extends Node2D
## Root game scene script. Orchestrates the game loop by managing state
## transitions and connecting to EventBus signals.

## Reference to the HUD for score/preview updates.
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	# Start in READY state, then transition to DROPPING after physics settles.
	GameManager.change_state(GameManager.GameState.READY)

	# Connect game over signal.
	EventBus.game_over_triggered.connect(_on_game_over)

	# Brief delay to let physics settle before enabling drops.
	await get_tree().create_timer(0.3).timeout
	GameManager.change_state(GameManager.GameState.DROPPING)


func _on_game_over() -> void:
	GameManager.change_state(GameManager.GameState.GAME_OVER)
