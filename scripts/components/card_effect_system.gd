class_name CardEffectSystem
extends Node
## Central card effect processor. Connects to EventBus signals and reads
## CardManager.active_cards to apply physics/merge card effects at runtime.
## Lives in the game scene tree (not an autoload) for automatic cleanup on reset.

# --- Bouncy Berry constants ---
## Additional bounce per Bouncy Berry card owned (50% increase per card).
const BOUNCY_BERRY_BOUNCE_BONUS: float = 0.5
## Base bounce value matching fruit_physics.tres.
const BOUNCY_BASE_BOUNCE: float = 0.15
## Base friction value matching fruit_physics.tres.
const BOUNCY_BASE_FRICTION: float = 0.6
## Maximum tier affected by Bouncy Berry (0=Blueberry, 1=Grape, 2=Cherry).
const BOUNCY_MAX_TIER: int = 2

# --- Cherry Bomb constants ---
## Cherry is tier index 2 in code (tier_3_cherry.tres has tier=2).
const CHERRY_TIER: int = 2
## Blast radius in pixels.
const CHERRY_BOMB_RADIUS: float = 200.0
## Base blast force per stack. Scales linearly with card count.
const CHERRY_BOMB_FORCE: float = 800.0
## Number of points on the shockwave ring circle.
const SHOCKWAVE_POINTS: int = 32

## Shared default physics material to restore non-bouncy fruits.
var _default_physics_material: PhysicsMaterial = preload("res://resources/fruit_physics.tres")


func _ready() -> void:
	add_to_group("card_effect_system")
	EventBus.fruit_merged.connect(_on_fruit_merged)
	EventBus.fruit_dropped.connect(_on_fruit_dropped)
	EventBus.card_purchased.connect(_on_card_changed)
	EventBus.card_sold.connect(_on_card_removed)


func _count_active(card_id: String) -> int:
	## Count how many copies of a card_id are in active slots (for linear stacking).
	var count: int = 0
	for entry in CardManager.active_cards:
		if entry != null and (entry["card"] as CardData).card_id == card_id:
			count += 1
	return count


func _get_fruit_container() -> Node:
	## Return the FruitContainer node where all fruits live.
	return get_tree().get_first_node_in_group("fruit_container")


# =============================================================================
# Signal handlers
# =============================================================================

func _on_fruit_merged(old_tier: int, _new_tier: int, merge_pos: Vector2) -> void:
	## Dispatch merge-triggered effects.
	# Cherry Bomb: explode on cherry merge
	var cherry_count: int = _count_active("cherry_bomb")
	if cherry_count > 0 and old_tier == CHERRY_TIER:
		_apply_cherry_bomb(merge_pos, cherry_count)
	# Bouncy Berry: apply to newly spawned merge result (deferred to let MergeManager spawn first)
	if _count_active("bouncy_berry") > 0:
		call_deferred("_apply_bouncy_berry_all")


func _on_fruit_dropped(_tier: int, _pos: Vector2) -> void:
	## Apply bouncy berry to the just-dropped fruit (transitions from frozen to physics).
	if _count_active("bouncy_berry") > 0:
		call_deferred("_apply_bouncy_berry_all")


func _on_card_changed(_card: CardData, _slot_index: int) -> void:
	## Retroactively apply effects when a card is purchased.
	_apply_bouncy_berry_all()


func _on_card_removed(_card: CardData, _slot_index: int, _refund: int) -> void:
	## Recalculate/revert effects when a card is sold.
	_apply_bouncy_berry_all()


# =============================================================================
# Bouncy Berry effect
# =============================================================================

func _apply_bouncy_berry_all() -> void:
	## Apply or revert Bouncy Berry on all existing fruits in the bucket.
	## Always calculates from base values to prevent exponential stacking.
	var stack_count: int = _count_active("bouncy_berry")
	var container: Node = _get_fruit_container()
	if not container:
		return
	for child in container.get_children():
		if child is Fruit and is_instance_valid(child) and not child.merging:
			_apply_bouncy_to_fruit(child, stack_count)


func _apply_bouncy_to_fruit(fruit: Fruit, stack_count: int) -> void:
	## Apply Bouncy Berry bounce modification to a single fruit.
	## Only affects tiers 0-2 (Blueberry, Grape, Cherry).
	if fruit.fruit_data.tier > BOUNCY_MAX_TIER:
		# Restore default material for non-affected tiers
		fruit.physics_material_override = _default_physics_material
		return
	if stack_count <= 0:
		# No Bouncy Berry active -- restore default material
		fruit.physics_material_override = _default_physics_material
		# Restore original sprite color
		fruit.get_node("Sprite2D").modulate = fruit.fruit_data.color
		return
	# Create a NEW PhysicsMaterial (never modify the shared resource)
	var mat: PhysicsMaterial = PhysicsMaterial.new()
	mat.friction = BOUNCY_BASE_FRICTION
	mat.bounce = BOUNCY_BASE_BOUNCE + (BOUNCY_BERRY_BOUNCE_BONUS * stack_count)
	fruit.physics_material_override = mat
	# Subtle persistent glow: lighten the sprite color based on stack count
	fruit.get_node("Sprite2D").modulate = fruit.fruit_data.color.lightened(0.15 * stack_count)


# =============================================================================
# Cherry Bomb effect
# =============================================================================

func _apply_cherry_bomb(merge_pos: Vector2, stack_count: int) -> void:
	## Apply radial impulse to all nearby fruits when cherries merge.
	var blast_force: float = CHERRY_BOMB_FORCE * stack_count
	var container: Node = _get_fruit_container()
	if not container:
		return

	for child in container.get_children():
		if not (child is Fruit) or not is_instance_valid(child):
			continue
		if child.merging or child.is_dropping or child.freeze:
			continue
		var direction: Vector2 = child.global_position - merge_pos
		var distance: float = direction.length()
		if distance > CHERRY_BOMB_RADIUS or distance < 1.0:
			continue
		# Linear falloff: full force at center, zero at radius edge
		var strength: float = blast_force * (1.0 - distance / CHERRY_BOMB_RADIUS)
		child.apply_central_impulse(direction.normalized() * strength)

	_spawn_shockwave(merge_pos)
	EventBus.cherry_bomb_triggered.emit(merge_pos)


func _spawn_shockwave(pos: Vector2) -> void:
	## Create an expanding, fading ring visual at the blast center.
	## Uses a Node2D + Line2D drawn as a circle, tweened for expansion and fade.
	var effects: Node = get_tree().get_first_node_in_group("effects_container")
	if not effects:
		effects = self

	# Create the ring container
	var ring: Node2D = Node2D.new()
	effects.add_child(ring)
	ring.global_position = pos

	# Create the circle Line2D
	var line: Line2D = Line2D.new()
	line.width = 3.0
	line.default_color = Color(1.0, 0.6, 0.2, 0.9)
	ring.add_child(line)

	# Draw circle points at radius 1.0 (will be scaled up by tween)
	for i in SHOCKWAVE_POINTS + 1:
		var angle: float = (float(i) / float(SHOCKWAVE_POINTS)) * TAU
		line.add_point(Vector2(cos(angle), sin(angle)))

	# Tween: expand ring from scale 1 to CHERRY_BOMB_RADIUS, fade out
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(CHERRY_BOMB_RADIUS, CHERRY_BOMB_RADIUS), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(line, "modulate:a", 0.0, 0.3).from(0.9)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)
