extends Node
## Manages global game state and score.
## Score logic (awarding points) is Phase 2; the variable lives here for
## centralized access.

enum GameState {
	READY,      ## Waiting for player to position/drop a fruit
	DROPPING,   ## A fruit is in mid-air after release
	WAITING,    ## Cooldown between drops or processing merges
	PAUSED,     ## Pause menu is open, tree is paused
	GAME_OVER,  ## Overflow detected, run is finished
}

var current_state: GameState = GameState.READY
var score: int = 0
var coins: int = 0

## Stores the state before pausing so resume returns to the correct state.
var _previous_state: GameState = GameState.READY


func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	# When entering PAUSED, remember the state we came from.
	if new_state == GameState.PAUSED:
		_previous_state = current_state

	# When leaving PAUSED, unpause the tree.
	if current_state == GameState.PAUSED and new_state != GameState.PAUSED:
		get_tree().paused = false

	current_state = new_state
	EventBus.game_state_changed.emit(new_state)

	# When entering PAUSED, pause the tree (after emitting signal so listeners
	# with process_mode ALWAYS can react to the state change).
	if new_state == GameState.PAUSED:
		get_tree().paused = true


func reset_game() -> void:
	# Unpause the tree BEFORE any state change (critical: reload_current_scene
	# must not run while paused or the new scene starts frozen).
	get_tree().paused = false
	_previous_state = GameState.READY
	score = 0
	coins = 0
	change_state(GameState.READY)
