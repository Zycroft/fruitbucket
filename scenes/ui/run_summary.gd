extends CanvasLayer
## Run summary overlay with celebratory stat reveal animation.
## Shows 7 stats animating in one by one after game over.
## Play Again restarts the run, Quit reloads the page.

## Hardcoded tier names matching the kawaii fruit lineup.
const TIER_NAMES: Array[String] = [
	"Cherry", "Grape", "Strawberry", "Orange",
	"Apple", "Peach", "Pineapple", "Watermelon",
]

## Stat label references (populated in _ready).
var _stat_labels: Array[Label] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	# Connect buttons.
	$Overlay/SummaryContainer/ButtonRow/PlayAgainButton.pressed.connect(_on_play_again)
	$Overlay/SummaryContainer/ButtonRow/QuitButton.pressed.connect(_on_quit)


func show_summary(stats: Dictionary) -> void:
	## Populate stats and begin the celebratory reveal animation.
	var container: VBoxContainer = $Overlay/SummaryContainer

	# Populate stat text.
	container.get_node("MergesLabel").text = "Total Merges: %d" % stats.total_merges
	container.get_node("ChainLabel").text = "Biggest Chain: %d" % stats.biggest_chain
	container.get_node("TierLabel").text = "Highest Tier: %s" % _get_tier_name(stats.highest_tier)
	container.get_node("CardsLabel").text = "Cards Used: %d" % stats.cards_used.size()
	container.get_node("CoinsLabel").text = "Total Coins: %d" % stats.total_coins_earned
	container.get_node("TimeLabel").text = "Time Played: %s" % _format_time(stats.time_played)
	container.get_node("ScoreLabel").text = "Final Score: %d" % stats.final_score

	# Gather stat labels in reveal order.
	_stat_labels.clear()
	_stat_labels.append(container.get_node("MergesLabel") as Label)
	_stat_labels.append(container.get_node("ChainLabel") as Label)
	_stat_labels.append(container.get_node("TierLabel") as Label)
	_stat_labels.append(container.get_node("CardsLabel") as Label)
	_stat_labels.append(container.get_node("CoinsLabel") as Label)
	_stat_labels.append(container.get_node("TimeLabel") as Label)
	_stat_labels.append(container.get_node("ScoreLabel") as Label)

	# Hide all stat labels and button row initially.
	for label in _stat_labels:
		label.modulate.a = 0.0
	container.get_node("ButtonRow").modulate.a = 0.0

	visible = true
	get_tree().paused = true
	_reveal_stats()


func _reveal_stats() -> void:
	## Animate stats appearing one by one with scale punch.
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	for i in _stat_labels.size():
		var label: Label = _stat_labels[i]
		var is_score: bool = (i == _stat_labels.size() - 1)

		# Set initial scale (pivot must be set after text is assigned).
		label.pivot_offset = label.size / 2.0
		if is_score:
			label.scale = Vector2(0.3, 0.3)
		else:
			label.scale = Vector2(0.5, 0.5)

		# Fade in.
		var duration: float = 0.4 if is_score else 0.3
		tween.tween_property(label, "modulate:a", 1.0, duration)

		# Scale punch (parallel with fade).
		var ease_type: Tween.TransitionType = Tween.TRANS_BACK
		tween.parallel().tween_property(label, "scale", Vector2.ONE, duration) \
			.set_trans(ease_type).set_ease(Tween.EASE_OUT)

		# Interval between stats.
		if is_score:
			tween.tween_interval(0.2)
		else:
			tween.tween_interval(0.15)

	# Show button row after all stats.
	var button_row: HBoxContainer = $Overlay/SummaryContainer/ButtonRow
	tween.tween_property(button_row, "modulate:a", 1.0, 0.3)


func _format_time(seconds: int) -> String:
	## Format seconds as "Xm Ys" or "Xh Ym Zs" for longer runs.
	if seconds >= 3600:
		var hours: int = seconds / 3600
		var minutes: int = (seconds % 3600) / 60
		var secs: int = seconds % 60
		return "%dh %dm %ds" % [hours, minutes, secs]
	var minutes: int = seconds / 60
	var secs: int = seconds % 60
	return "%dm %ds" % [minutes, secs]


func _get_tier_name(tier: int) -> String:
	## Return the display name for a fruit tier.
	if tier >= 0 and tier < TIER_NAMES.size():
		return TIER_NAMES[tier]
	# Watermelon vanish case (tier 8) or any out-of-bounds.
	return "Watermelon"


func _on_play_again() -> void:
	## Restart the game cleanly.
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().reload_current_scene()


func _on_quit() -> void:
	## Reload the page (web) or quit (native).
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.reload()")
	else:
		get_tree().quit()
