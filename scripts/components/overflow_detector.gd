class_name OverflowDetector
extends Area2D
## Detects when fruits stay above the overflow line for too long.
## Uses a dwell timer approach: each fruit in the zone accumulates time,
## and if any fruit exceeds OVERFLOW_DURATION continuous seconds, game over.
## Ignores dropping, merging, and grace-period fruits to prevent false positives.

## Seconds of continuous dwell above the overflow line before triggering game over.
const OVERFLOW_DURATION: float = 2.0

## Tracks instance_id -> accumulated_time for each fruit currently in the zone.
var _fruits_in_zone: Dictionary = {}

## Reference to the bucket node for warning level updates.
var _bucket: Node = null


func _ready() -> void:
	# Connect area signals.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Find the bucket for warning level.
	_bucket = get_tree().get_first_node_in_group("bucket")

	# Area2D monitoring config: detect Fruit bodies (layer 1).
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1


func _on_body_entered(body: Node) -> void:
	if not (body is Fruit):
		return
	# Ignore fruits that are still being positioned, merging, or in grace period.
	if body.is_dropping or body.merge_grace or body.merging:
		return
	_fruits_in_zone[body.get_instance_id()] = 0.0


func _on_body_exited(body: Node) -> void:
	if body is Fruit:
		_fruits_in_zone.erase(body.get_instance_id())


func _physics_process(delta: float) -> void:
	# Stop processing if game is already over.
	if GameManager.current_state == GameManager.GameState.GAME_OVER:
		return

	var max_dwell: float = 0.0
	var to_remove: Array[int] = []

	for id: int in _fruits_in_zone:
		# Validate the instance still exists.
		if not is_instance_valid(instance_from_id(id)):
			to_remove.append(id)
			continue

		var fruit: Fruit = instance_from_id(id) as Fruit
		if fruit == null or fruit.is_dropping or fruit.merge_grace or fruit.merging:
			to_remove.append(id)
			continue

		# Accumulate dwell time.
		_fruits_in_zone[id] += delta
		max_dwell = maxf(max_dwell, _fruits_in_zone[id])

		# Check if this fruit has exceeded the threshold.
		if _fruits_in_zone[id] >= OVERFLOW_DURATION:
			EventBus.game_over_triggered.emit()
			set_physics_process(false)
			return

	# Clean up invalid entries.
	for id: int in to_remove:
		_fruits_in_zone.erase(id)

	# Update bucket rim warning level (0.0 to 1.0).
	if _bucket:
		_bucket.set_warning_level(clampf(max_dwell / OVERFLOW_DURATION, 0.0, 1.0))
