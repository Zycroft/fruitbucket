extends Node2D
## Draws a dashed overflow reference line inside the bucket.
## Uses Godot 4's native draw_dashed_line() API.

## The overflow Y position (set from parent bucket geometry).
@export var overflow_y: float = 760.0

## Interior width endpoints at the overflow line height.
## Calculated from bucket trapezoid geometry.
@export var left_x: float = 345.0
@export var right_x: float = 735.0

## Visual settings.
const LINE_COLOR: Color = Color(1.0, 0.3, 0.3, 0.4)
const LINE_WIDTH: float = 2.0
const DASH_LENGTH: float = 10.0


func _draw() -> void:
	draw_dashed_line(
		Vector2(left_x, overflow_y),
		Vector2(right_x, overflow_y),
		LINE_COLOR,
		LINE_WIDTH,
		DASH_LENGTH
	)
