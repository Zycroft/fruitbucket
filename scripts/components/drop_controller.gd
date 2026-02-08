class_name DropController
extends Node2D
## Handles player input for positioning and dropping fruits.
## Manages preview fruit, drop guide line, cooldown, and random tier selection.

## The fruit currently being positioned by the player (frozen above bucket).
var _current_fruit: Fruit = null

## Tier of the NEXT fruit to drop (rolled after each drop).
var _next_tier: int = -1

## Whether the player can drop right now (false during cooldown).
var _can_drop: bool = true

## Seconds of cooldown between successive drops.
var _drop_cooldown: float = 0.15

## Horizontal bounds of the bucket opening (set from bucket geometry).
var _bucket_left: float = 0.0
var _bucket_right: float = 0.0

## Y position where the preview fruit hovers (above the bucket rim).
var _drop_y: float = 0.0

## Floor Y of the bucket (for the drop guide endpoint).
var _bucket_floor_y: float = 0.0

## Last known cursor X position (so the next preview appears at the same spot).
var _last_drop_x: float = 0.0

## Reference to the drop guide Line2D child node.
@onready var _drop_guide: Line2D = $DropGuide

## Reference to the MergeManager (found via group).
var _merge_manager: MergeManager


func _ready() -> void:
	# Find the bucket and query its geometry.
	var bucket = get_tree().get_first_node_in_group("bucket")
	if bucket:
		var bounds: Vector2 = bucket.get_drop_bounds()
		_bucket_left = bounds.x
		_bucket_right = bounds.y
		_drop_y = bucket.top_left.y - 80.0
		_bucket_floor_y = bucket.bottom_left.y
		_last_drop_x = (_bucket_left + _bucket_right) / 2.0
	else:
		push_error("DropController: No node in group 'bucket' found")

	# Find the MergeManager.
	_merge_manager = get_tree().get_first_node_in_group("merge_manager")
	if not _merge_manager:
		push_error("DropController: No node in group 'merge_manager' found")

	# Configure the drop guide line.
	_drop_guide.default_color = Color(1, 1, 1, 0.15)
	_drop_guide.width = 1.5
	_drop_guide.visible = false

	# Roll the first tier and spawn the preview fruit.
	_roll_next_tier()
	_spawn_preview()


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state == GameManager.GameState.GAME_OVER:
		return

	if event is InputEventMouseMotion and _current_fruit:
		var clamped_x: float = clampf(event.position.x, _bucket_left, _bucket_right)
		_current_fruit.global_position = Vector2(clamped_x, _drop_y)
		_last_drop_x = clamped_x

		# Update the drop guide line.
		_drop_guide.clear_points()
		_drop_guide.add_point(Vector2(clamped_x, _drop_y))
		_drop_guide.add_point(Vector2(clamped_x, _bucket_floor_y))

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed and _can_drop and _current_fruit:
		_drop_fruit()


func _drop_fruit() -> void:
	## Release the current preview fruit into physics simulation.
	_current_fruit.freeze = false
	_current_fruit.is_dropping = false

	EventBus.fruit_dropped.emit(_current_fruit.fruit_data.tier, _current_fruit.global_position)

	_current_fruit = null
	_can_drop = false
	_drop_guide.visible = false

	# Cooldown before spawning the next preview.
	await get_tree().create_timer(_drop_cooldown).timeout

	_can_drop = true
	_spawn_preview()


func _spawn_preview() -> void:
	## Spawn a new frozen preview fruit at the last cursor position.
	if not _merge_manager:
		return

	_current_fruit = _merge_manager.spawn_fruit(
		_next_tier,
		Vector2(_last_drop_x, _drop_y),
		true  # dropping = true (frozen for positioning)
	)

	# Show and position the drop guide.
	_drop_guide.visible = true
	_drop_guide.clear_points()
	_drop_guide.add_point(Vector2(_last_drop_x, _drop_y))
	_drop_guide.add_point(Vector2(_last_drop_x, _bucket_floor_y))

	# Roll the tier for the NEXT drop.
	_roll_next_tier()


func _roll_next_tier() -> void:
	## Pick a random droppable tier (0-4, equal probability).
	_next_tier = randi_range(0, 4)
	EventBus.next_fruit_changed.emit(_next_tier)
