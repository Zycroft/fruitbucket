class_name FaceRenderer
extends Node2D
## Draws a cartoon face on a fruit using _draw(). Each of the 8 tiers has a
## unique expression. All features scale proportionally to face_radius so faces
## look correct at every fruit size.

## Tier index (0-7) determining which expression to draw.
var face_tier: int = 0

## Radius used to scale all face features proportionally.
var face_radius: float = 15.0

## Shared face color: black with slight transparency.
const FACE_COLOR := Color(0, 0, 0, 0.85)

## White color for eye highlights.
const HIGHLIGHT_COLOR := Color(1, 1, 1, 0.9)


func set_face(tier: int, radius: float) -> void:
	## Configure the face for a given fruit tier and radius, then redraw.
	face_tier = tier
	face_radius = radius
	queue_redraw()


func _draw() -> void:
	## Dispatch to the tier-specific drawing function.
	var r: float = face_radius
	match face_tier:
		0: _draw_blueberry(r)
		1: _draw_grape(r)
		2: _draw_cherry(r)
		3: _draw_strawberry(r)
		4: _draw_orange(r)
		5: _draw_apple(r)
		6: _draw_pear(r)
		7: _draw_watermelon(r)


func _line_width(r: float) -> float:
	## Standard line width scaled to fruit radius.
	return maxf(1.0, r * 0.04)


func _draw_blueberry(r: float) -> void:
	## Tier 0: Tiny dot eyes, small "o" mouth (surprised/cute).
	# Eyes
	draw_circle(Vector2(-0.25 * r, -0.1 * r), 0.08 * r, FACE_COLOR)
	draw_circle(Vector2(0.25 * r, -0.1 * r), 0.08 * r, FACE_COLOR)
	# Mouth: small circle "o"
	draw_circle(Vector2(0, 0.2 * r), 0.06 * r, FACE_COLOR)


func _draw_grape(r: float) -> void:
	## Tier 1: Happy closed-eye smile. Eyes are downward arcs.
	var lw: float = _line_width(r)
	var eye_r: float = 0.1 * r
	# Left eye: arc opening downward (happy closed eye)
	draw_arc(Vector2(-0.25 * r, -0.1 * r), eye_r, deg_to_rad(200), deg_to_rad(340), 12, FACE_COLOR, lw)
	# Right eye
	draw_arc(Vector2(0.25 * r, -0.1 * r), eye_r, deg_to_rad(200), deg_to_rad(340), 12, FACE_COLOR, lw)
	# Mouth: upward arc (smile)
	draw_arc(Vector2(0, 0.15 * r), 0.25 * r, deg_to_rad(10), deg_to_rad(170), 16, FACE_COLOR, lw)


func _draw_cherry(r: float) -> void:
	## Tier 2: Cheerful wide eyes with highlights, big grin.
	var lw: float = _line_width(r)
	var eye_r: float = 0.1 * r
	# Left eye
	draw_circle(Vector2(-0.25 * r, -0.1 * r), eye_r, FACE_COLOR)
	draw_circle(Vector2(-0.25 * r + 0.03 * r, -0.1 * r - 0.03 * r), 0.04 * r, HIGHLIGHT_COLOR)
	# Right eye
	draw_circle(Vector2(0.25 * r, -0.1 * r), eye_r, FACE_COLOR)
	draw_circle(Vector2(0.25 * r + 0.03 * r, -0.1 * r - 0.03 * r), 0.04 * r, HIGHLIGHT_COLOR)
	# Mouth: wide grin arc
	draw_arc(Vector2(0, 0.1 * r), 0.3 * r, deg_to_rad(10), deg_to_rad(170), 20, FACE_COLOR, lw * 1.2)


func _draw_strawberry(r: float) -> void:
	## Tier 3: Winking face. Left eye filled, right eye is a wink line.
	var lw: float = _line_width(r)
	# Left eye: filled circle
	draw_circle(Vector2(-0.25 * r, -0.1 * r), 0.09 * r, FACE_COLOR)
	# Right eye: horizontal wink line
	draw_line(
		Vector2(0.15 * r, -0.1 * r),
		Vector2(0.35 * r, -0.1 * r),
		FACE_COLOR, lw * 1.5
	)
	# Mouth: slight smirk arc, offset right
	draw_arc(Vector2(0.05 * r, 0.15 * r), 0.2 * r, deg_to_rad(10), deg_to_rad(150), 14, FACE_COLOR, lw)


func _draw_orange(r: float) -> void:
	## Tier 4: Confident grin. Anime-style half-circle eyes, broad smile.
	var lw: float = _line_width(r)
	var eye_r: float = 0.1 * r
	# Left eye: filled bottom half-circle (flat bottom anime eye)
	draw_arc(Vector2(-0.25 * r, -0.1 * r), eye_r, deg_to_rad(180), deg_to_rad(360), 16, FACE_COLOR, lw * 1.3)
	draw_line(
		Vector2(-0.25 * r - eye_r, -0.1 * r),
		Vector2(-0.25 * r + eye_r, -0.1 * r),
		FACE_COLOR, lw
	)
	# Right eye
	draw_arc(Vector2(0.25 * r, -0.1 * r), eye_r, deg_to_rad(180), deg_to_rad(360), 16, FACE_COLOR, lw * 1.3)
	draw_line(
		Vector2(0.25 * r - eye_r, -0.1 * r),
		Vector2(0.25 * r + eye_r, -0.1 * r),
		FACE_COLOR, lw
	)
	# Mouth: broad confident smile
	draw_arc(Vector2(0, 0.12 * r), 0.3 * r, deg_to_rad(10), deg_to_rad(170), 20, FACE_COLOR, lw * 1.5)


func _draw_apple(r: float) -> void:
	## Tier 5: Cool/smug. Narrow squinting eyes, small smirk.
	var lw: float = _line_width(r)
	# Left eye: narrow horizontal line (squinting)
	draw_line(
		Vector2(-0.35 * r, -0.1 * r),
		Vector2(-0.15 * r, -0.1 * r),
		FACE_COLOR, lw * 1.8
	)
	# Right eye
	draw_line(
		Vector2(0.15 * r, -0.1 * r),
		Vector2(0.35 * r, -0.1 * r),
		FACE_COLOR, lw * 1.8
	)
	# Mouth: small smirk, one side raised
	draw_arc(Vector2(0.05 * r, 0.18 * r), 0.15 * r, deg_to_rad(10), deg_to_rad(120), 12, FACE_COLOR, lw)


func _draw_pear(r: float) -> void:
	## Tier 6: Sleepy/content. Droopy curved-down eye lines, gentle wavy smile.
	var lw: float = _line_width(r)
	# Left eye: curved downward line (droopy/relaxed)
	draw_arc(Vector2(-0.25 * r, -0.08 * r), 0.1 * r, deg_to_rad(20), deg_to_rad(160), 12, FACE_COLOR, lw * 1.5)
	# Right eye
	draw_arc(Vector2(0.25 * r, -0.08 * r), 0.1 * r, deg_to_rad(20), deg_to_rad(160), 12, FACE_COLOR, lw * 1.5)
	# Mouth: gentle wavy smile (two connected small arcs)
	draw_arc(Vector2(-0.1 * r, 0.18 * r), 0.12 * r, deg_to_rad(10), deg_to_rad(170), 10, FACE_COLOR, lw)
	draw_arc(Vector2(0.1 * r, 0.18 * r), 0.12 * r, deg_to_rad(10), deg_to_rad(170), 10, FACE_COLOR, lw)


func _draw_watermelon(r: float) -> void:
	## Tier 7: Big happy face. Large round eyes with highlights, wide open smile.
	var lw: float = _line_width(r)
	var eye_r: float = 0.12 * r
	# Left eye: large filled circle with big highlight
	draw_circle(Vector2(-0.25 * r, -0.1 * r), eye_r, FACE_COLOR)
	draw_circle(Vector2(-0.25 * r + 0.04 * r, -0.1 * r - 0.04 * r), 0.05 * r, HIGHLIGHT_COLOR)
	# Right eye
	draw_circle(Vector2(0.25 * r, -0.1 * r), eye_r, FACE_COLOR)
	draw_circle(Vector2(0.25 * r + 0.04 * r, -0.1 * r - 0.04 * r), 0.05 * r, HIGHLIGHT_COLOR)
	# Mouth: wide open smile -- upper lip arc + lower lip arc forming an open mouth
	draw_arc(Vector2(0, 0.12 * r), 0.3 * r, deg_to_rad(10), deg_to_rad(170), 24, FACE_COLOR, lw * 2.0)
	draw_arc(Vector2(0, 0.18 * r), 0.25 * r, deg_to_rad(200), deg_to_rad(340), 20, FACE_COLOR, lw * 1.5)
