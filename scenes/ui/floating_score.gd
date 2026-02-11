extends Label
## Floating score popup that spawns at merge positions, rises, and fades out.
## Supports chain-highlight styling with gold tint and scale punch.


func show_score(text_value: String, start_pos: Vector2, is_chain: bool) -> void:
	## Display the score text at the given position with rise+fade animation.
	## If is_chain, applies gold tint and scale punch for visual emphasis.
	text = text_value
	global_position = start_pos + Vector2(randf_range(-20.0, 20.0), 0.0)

	# Pivot must be set after text assignment so size is correct.
	pivot_offset = size / 2.0

	# Gold tint for chain popups.
	if is_chain:
		modulate = Color(1.0, 0.9, 0.3, 1.0)

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	var duration: float = 1.4 if is_chain else 1.2

	# Rise upward.
	tween.tween_property(self, "position:y", position.y - 100.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fade out (starts fading after a brief visible hold).
	tween.tween_property(self, "modulate:a", 0.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Scale punch for chain popups — bigger for emphasis.
	if is_chain:
		tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(self, "scale", Vector2(1.3, 1.3), 0.3)

	# Free after animation completes to prevent popup accumulation.
	tween.chain().tween_callback(queue_free)


func show_bonus(text_value: String, start_pos: Vector2, bonus_type: String) -> void:
	## Display a card bonus popup with distinct color styling.
	## bonus_type: "score" = purple, "coins" = green.
	text = text_value
	# Offset slightly below normal score popups to avoid overlap.
	global_position = start_pos + Vector2(randf_range(-20.0, 20.0), 30.0)

	pivot_offset = size / 2.0

	if bonus_type == "coins":
		modulate = Color(0.2, 0.9, 0.3, 1.0)  # Green for coin bonuses
	else:
		modulate = Color(0.7, 0.4, 1.0, 1.0)  # Purple for score bonuses

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	var duration: float = 1.2

	# Rise upward.
	tween.tween_property(self, "position:y", position.y - 80.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fade out.
	tween.tween_property(self, "modulate:a", 0.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Subtle scale punch for bonus popups.
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

	tween.chain().tween_callback(queue_free)
