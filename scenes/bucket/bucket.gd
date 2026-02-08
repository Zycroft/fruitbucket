extends StaticBody2D
## Trapezoid bucket container with visual art, collision walls, and overflow line.
## Exposes geometry query functions for other systems (DropController, OverflowDetector).

## Bucket geometry constants (outer edges of the opening and floor).
## Designed for 1080x1920 viewport, bucket centered horizontally at x=540.
@export var top_left: Vector2 = Vector2(340, 700)
@export var top_right: Vector2 = Vector2(740, 700)
@export var bottom_left: Vector2 = Vector2(410, 1250)
@export var bottom_right: Vector2 = Vector2(670, 1250)
@export var overflow_y: float = 760.0

## Wall thickness for collision polygons.
const WALL_THICKNESS: float = 12.0

## Wood plank line color (subtle, semi-transparent).
const PLANK_LINE_COLOR: Color = Color(0.42, 0.35, 0.25, 0.3)


func get_drop_bounds() -> Vector2:
	## Returns Vector2(left_x, right_x) for clamping the drop position
	## to the bucket opening width with a small inset.
	return Vector2(top_left.x + 20.0, top_right.x - 20.0)


func get_overflow_y() -> float:
	## Returns the Y position of the overflow line.
	return overflow_y


func set_warning_level(level: float) -> void:
	## Modulates the rim highlight from default dark brown to red.
	## level: 0.0 = normal, 1.0 = full warning (red).
	## Called by OverflowDetector in Plan 03.
	var rim: Line2D = $RimHighlight
	var normal_color: Color = Color(0.42, 0.26, 0.15, 1.0)
	var warning_color: Color = Color(1.0, 0.15, 0.1, 1.0)
	rim.default_color = normal_color.lerp(warning_color, clampf(level, 0.0, 1.0))


func _draw() -> void:
	## Draw subtle wood plank lines across the bucket body.
	## These are faint horizontal lines suggesting a wooden container.
	var plank_count: int = 3
	var bucket_height: float = bottom_left.y - top_left.y
	var spacing: float = bucket_height / float(plank_count + 1)

	for i in range(1, plank_count + 1):
		var y_pos: float = top_left.y + spacing * i
		# Lerp the x positions based on how far down we are (trapezoid narrows).
		var t: float = (y_pos - top_left.y) / bucket_height
		var left_x: float = lerpf(top_left.x, bottom_left.x, t) + WALL_THICKNESS
		var right_x: float = lerpf(top_right.x, bottom_right.x, t) - WALL_THICKNESS
		# Convert to local coordinates (this node is at origin).
		draw_line(Vector2(left_x, y_pos), Vector2(right_x, y_pos), PLANK_LINE_COLOR, 1.5)
