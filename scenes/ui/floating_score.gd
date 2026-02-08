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

	# Rise upward.
	tween.tween_property(self, "position:y", position.y - 80.0, 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fade out.
	tween.tween_property(self, "modulate:a", 0.0, 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Scale punch for chain popups.
	if is_chain:
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(self, "scale", Vector2.ONE, 0.3)

	# Free after animation completes to prevent popup accumulation.
	tween.chain().tween_callback(queue_free)
