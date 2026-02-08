class_name MergeManager
extends Node
## Gatekeeper for fruit merges. Prevents double-merge race conditions by
## tracking pending merges via instance ID locking. Handles safe fruit removal
## (no queue_free in physics callbacks) and spawns the next-tier fruit.

## Instance IDs currently being merged -- prevents double-merge.
var _pending_merges: Dictionary = {}

## Preloaded fruit scene for spawning.
var _fruit_scene: PackedScene = preload("res://scenes/fruit/fruit.tscn")

## All 8 FruitData resources, indexed by tier (0 = Blueberry, 7 = Watermelon).
var _fruit_types: Array[FruitData] = []


func _ready() -> void:
	add_to_group("merge_manager")
	_load_fruit_types()


func _load_fruit_types() -> void:
	## Load all 8 FruitData .tres files in tier order.
	var paths: Array[String] = [
		"res://resources/fruit_data/tier_1_blueberry.tres",
		"res://resources/fruit_data/tier_2_grape.tres",
		"res://resources/fruit_data/tier_3_cherry.tres",
		"res://resources/fruit_data/tier_4_strawberry.tres",
		"res://resources/fruit_data/tier_5_orange.tres",
		"res://resources/fruit_data/tier_6_apple.tres",
		"res://resources/fruit_data/tier_7_pear.tres",
		"res://resources/fruit_data/tier_8_watermelon.tres",
	]
	for path in paths:
		var data: FruitData = load(path) as FruitData
		if data:
			_fruit_types.append(data)
		else:
			push_error("MergeManager: Failed to load FruitData at %s" % path)


func request_merge(fruit_a: Fruit, fruit_b: Fruit) -> void:
	## Called by the fruit with the lower instance ID when two same-tier fruits collide.
	## Locks both fruits, deactivates them safely, and spawns the next tier.
	var id_a: int = fruit_a.get_instance_id()
	var id_b: int = fruit_b.get_instance_id()

	# Guard: if either fruit is already in a pending merge, bail out.
	if _pending_merges.has(id_a) or _pending_merges.has(id_b):
		return

	# Lock both fruits to prevent any other merge involving them.
	_pending_merges[id_a] = true
	_pending_merges[id_b] = true
	fruit_a.merging = true
	fruit_b.merging = true

	# Calculate merge position (midpoint of both fruits).
	var merge_pos: Vector2 = (fruit_a.global_position + fruit_b.global_position) / 2.0
	var old_tier: int = fruit_a.fruit_data.tier
	var new_tier: int = old_tier + 1

	# Safely deactivate both fruits (no queue_free in physics callback).
	_deactivate_fruit(fruit_a)
	_deactivate_fruit(fruit_b)

	# Spawn the next-tier fruit, or vanish if watermelon pair.
	if new_tier < _fruit_types.size():
		var new_fruit: Fruit = spawn_fruit(new_tier, merge_pos)
		new_fruit.merge_grace = true
		# Clear merge_grace after 0.5s so the new fruit can participate in merges.
		get_tree().create_timer(0.5).timeout.connect(func():
			if is_instance_valid(new_fruit):
				new_fruit.merge_grace = false
		)
		# Signal with the actual new tier.
		EventBus.fruit_merged.emit(old_tier, new_tier, merge_pos)
	else:
		# Watermelon pair vanish -- no new fruit spawned.
		# Emit with new_tier = _fruit_types.size() to indicate vanish.
		EventBus.fruit_merged.emit(old_tier, _fruit_types.size(), merge_pos)

	# Clean up pending locks after the physics frame.
	call_deferred("_cleanup_pending", id_a, id_b)


func _deactivate_fruit(fruit: Fruit) -> void:
	## Safely removes a fruit from physics simulation and queues it for deletion.
	## CRITICAL: Never call queue_free() directly from a physics callback.
	## This pattern prevents the "flushing queries" crash.
	fruit.set_contact_monitor(false)
	fruit.freeze = true
	fruit.get_node("CollisionShape2D").set_deferred("disabled", true)
	fruit.visible = false
	fruit.call_deferred("queue_free")


func _cleanup_pending(id_a: int, id_b: int) -> void:
	## Remove instance IDs from the pending set after merge completes.
	_pending_merges.erase(id_a)
	_pending_merges.erase(id_b)


func spawn_fruit(tier: int, pos: Vector2, dropping: bool = false) -> Fruit:
	## Public function for spawning a fruit at a given position.
	## Used by both request_merge (for next-tier spawn) and DropController (for preview).
	## If dropping=true, the fruit is frozen in kinematic mode for player positioning.
	if tier < 0 or tier >= _fruit_types.size():
		push_error("MergeManager.spawn_fruit: Invalid tier %d" % tier)
		return null

	var fruit: Fruit = _fruit_scene.instantiate()
	fruit.initialize(_fruit_types[tier])

	# Add to the fruit container node.
	var container: Node = get_tree().get_first_node_in_group("fruit_container")
	if container:
		container.add_child(fruit)
	else:
		push_error("MergeManager: No node in group 'fruit_container' found")
		add_child(fruit)

	fruit.global_position = pos

	if dropping:
		fruit.freeze = true
		fruit.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		fruit.is_dropping = true

	return fruit
