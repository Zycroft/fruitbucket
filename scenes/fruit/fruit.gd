class_name Fruit
extends RigidBody2D
## A single fruit in the bucket. Configured at runtime via FruitData resource.
## Handles collision detection and requests merges through MergeManager.

## The data resource describing this fruit's tier, size, sprite, etc.
var fruit_data: FruitData

## True while MergeManager is processing this fruit's merge. Prevents double-merge.
var merging: bool = false

## True while the player is positioning this fruit above the bucket (frozen).
var is_dropping: bool = false

## True briefly after this fruit spawns from a merge, preventing immediate re-merge.
var merge_grace: bool = false


func initialize(data: FruitData) -> void:
	## Configure this fruit from a FruitData resource.
	## Must be called immediately after instantiation, before adding to scene tree.
	fruit_data = data

	# Set sprite texture and tint
	$Sprite2D.texture = data.sprite
	$Sprite2D.modulate = data.color

	# Create a NEW CircleShape2D instance -- NEVER share shapes between fruits.
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	$CollisionShape2D.shape = shape

	# Scale sprite to match the collision radius.
	# The placeholder texture is 64x64, so half-width = 32.
	var texture_half_width: float = data.sprite.get_width() / 2.0
	var scale_factor: float = data.radius / texture_half_width
	$Sprite2D.scale = Vector2(scale_factor, scale_factor)

	# Set physics mass from FruitData.
	mass = data.mass_override


func _on_body_entered(body: Node) -> void:
	## Called when another physics body touches this fruit.
	## Only the fruit with the LOWER instance ID requests the merge (tiebreaker).
	if not (body is Fruit):
		return
	if merging or body.merging:
		return
	if is_dropping or body.is_dropping:
		return
	if merge_grace or body.merge_grace:
		return
	if body.fruit_data.tier != fruit_data.tier:
		return

	# Deterministic tiebreaker: only the lower instance ID initiates the merge.
	# This guarantees exactly one merge request per colliding pair.
	if get_instance_id() < body.get_instance_id():
		var mm = get_tree().get_first_node_in_group("merge_manager")
		if mm:
			mm.request_merge(self, body)
