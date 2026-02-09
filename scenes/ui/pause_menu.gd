extends CanvasLayer
## Pause menu overlay with Resume, Restart, and Quit buttons.
## Uses process_mode ALWAYS so it functions while the tree is paused.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	# Connect button signals.
	$Overlay/MenuContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$Overlay/MenuContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$Overlay/MenuContainer/QuitButton.pressed.connect(_on_quit_pressed)

	# Connect EventBus signals.
	EventBus.pause_requested.connect(_on_pause_requested)
	EventBus.game_state_changed.connect(_on_game_state_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.current_state == GameManager.GameState.PAUSED:
			_on_resume_pressed()
		elif GameManager.current_state != GameManager.GameState.GAME_OVER \
				and GameManager.current_state != GameManager.GameState.PAUSED \
				and GameManager.current_state != GameManager.GameState.SHOPPING \
				and GameManager.current_state != GameManager.GameState.PICKING:
			_on_pause_requested()
		get_viewport().set_input_as_handled()


func _on_pause_requested() -> void:
	if GameManager.current_state == GameManager.GameState.GAME_OVER:
		return
	visible = true
	GameManager.change_state(GameManager.GameState.PAUSED)


func _on_resume_pressed() -> void:
	visible = false
	GameManager.change_state(GameManager._previous_state)


func _on_restart_pressed() -> void:
	visible = false
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	# TODO: Navigate to title screen when one exists.
	_on_restart_pressed()


func _on_game_state_changed(new_state: int) -> void:
	# Hide pause menu if game over fires while paused.
	if new_state == GameManager.GameState.GAME_OVER:
		visible = false
