extends Node
## Manages global game state and score.
## Score logic (awarding points) is Phase 2; the variable lives here for
## centralized access.

enum GameState {
	READY,      ## Waiting for player to position/drop a fruit
	DROPPING,   ## A fruit is in mid-air after release
	WAITING,    ## Cooldown between drops or processing merges
	GAME_OVER,  ## Overflow detected, run is finished
}

var current_state: GameState = GameState.READY
var score: int = 0


func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	EventBus.game_state_changed.emit(new_state)


func reset_game() -> void:
	score = 0
	change_state(GameState.READY)
