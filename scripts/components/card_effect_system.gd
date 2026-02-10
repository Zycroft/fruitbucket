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

# --- Heavy Hitter constants ---
## Maximum charges per activation cycle.
const HEAVY_CHARGES_MAX: int = 3
## Number of merges required to recharge after depletion.
const HEAVY_RECHARGE_MERGES: int = 5
## Mass multiplier per Heavy Hitter card owned (stacks linearly).
const HEAVY_MASS_MULTIPLIER: float = 2.0

# --- Wild Fruit constants ---
## Select a new wild fruit every N merges.
const WILD_SELECT_INTERVAL: int = 5
## Maximum wild fruits per Wild Fruit card owned.
const WILD_MAX_PER_CARD: int = 1

## Shared default physics material to restore non-bouncy fruits.
var _default_physics_material: PhysicsMaterial = preload("res://resources/fruit_physics.tres")

# --- Heavy Hitter state ---
## Current number of heavy charges remaining.
var _heavy_charges: int = 0
## True when charges are depleted and counting merges toward recharge.
var _heavy_recharging: bool = false
## Merges counted toward recharge threshold.
var _heavy_merge_counter: int = 0

# --- Wild Fruit state ---
## References to currently wild Fruit instances.
var _wild_fruits: Array = []
## Merges counted toward next wild fruit selection.
var _wild_merge_counter: int = 0
## Rainbow outline shader for wild fruit visual.
var _rainbow_shader: Shader = preload("res://resources/shaders/rainbow_outline.gdshader")


func _ready() -> void:
	add_to_group("card_effect_system")
	EventBus.fruit_merged.connect(_on_fruit_merged)
	EventBus.fruit_dropped.connect(_on_fruit_dropped)
	EventBus.card_purchased.connect(_on_card_changed)
	EventBus.card_sold.connect(_on_card_removed)
	# Initialize Heavy Hitter state if card is already active (e.g., starter pick).
	if _count_active("heavy_hitter") > 0:
		_heavy_charges = HEAVY_CHARGES_MAX
		EventBus.heavy_hitter_charges_changed.emit(_heavy_charges, HEAVY_CHARGES_MAX)


func has_heavy_charges() -> bool:
	## Public query for DropController preview visual.
	return _count_active("heavy_hitter") > 0 and _heavy_charges > 0


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
	# Heavy Hitter: recharge logic
	if _count_active("heavy_hitter") > 0 and _heavy_recharging:
		_heavy_merge_counter += 1
		if _heavy_merge_counter >= HEAVY_RECHARGE_MERGES:
			_heavy_charges = HEAVY_CHARGES_MAX
			_heavy_recharging = false
			_heavy_merge_counter = 0
			EventBus.heavy_hitter_charges_changed.emit(_heavy_charges, HEAVY_CHARGES_MAX)
	# Wild Fruit: cleanup invalid references and select new wild fruits
	_cleanup_wild_refs()
	if _count_active("wild_fruit") > 0:
		_wild_merge_counter += 1
		if _wild_merge_counter >= WILD_SELECT_INTERVAL:
			_wild_merge_counter = 0
			_select_wild_fruits()


func _on_fruit_dropped(_tier: int, _pos: Vector2) -> void:
	## Apply bouncy berry to the just-dropped fruit (transitions from frozen to physics).
	if _count_active("bouncy_berry") > 0:
		call_deferred("_apply_bouncy_berry_all")
	# Heavy Hitter: consume a charge and apply mass boost to the just-dropped fruit.
	if _count_active("heavy_hitter") > 0 and _heavy_charges > 0:
		_heavy_charges -= 1
		var container: Node = _get_fruit_container()
		if container and container.get_child_count() > 0:
			var fruit: Fruit = container.get_child(container.get_child_count() - 1) as Fruit
			if fruit and is_instance_valid(fruit):
				fruit.mass = fruit.fruit_data.mass_override * HEAVY_MASS_MULTIPLIER * _count_active("heavy_hitter")
				fruit.is_heavy = true
				fruit.get_node("Sprite2D").modulate = fruit.fruit_data.color.darkened(0.3)
		EventBus.heavy_hitter_charges_changed.emit(_heavy_charges, HEAVY_CHARGES_MAX)
		if _heavy_charges <= 0:
			_heavy_recharging = true
			_heavy_merge_counter = 0


func _on_card_changed(card: CardData, _slot_index: int) -> void:
	## Retroactively apply effects when a card is purchased.
	_apply_bouncy_berry_all()
	# Heavy Hitter: reset charges on purchase.
	if card.card_id == "heavy_hitter":
		_heavy_charges = HEAVY_CHARGES_MAX
		_heavy_recharging = false
		_heavy_merge_counter = 0
		EventBus.heavy_hitter_charges_changed.emit(_heavy_charges, HEAVY_CHARGES_MAX)
	# Wild Fruit: immediately select from existing fruits.
	if card.card_id == "wild_fruit":
		_wild_merge_counter = 0
		_select_wild_fruits()


func _on_card_removed(card: CardData, _slot_index: int, _refund: int) -> void:
	## Recalculate/revert effects when a card is sold.
	_apply_bouncy_berry_all()
	# Heavy Hitter: reset state if no more heavy hitter cards.
	if card.card_id == "heavy_hitter" and _count_active("heavy_hitter") == 0:
		_heavy_charges = 0
		_heavy_recharging = false
		_heavy_merge_counter = 0
		EventBus.heavy_hitter_charges_changed.emit(0, 0)
	# Wild Fruit: cleanup or trim wild fruits.
	if card.card_id == "wild_fruit":
		if _count_active("wild_fruit") == 0:
			_cleanup_wild_fruits()
		else:
			# Trim excess wild fruits down to new max capacity.
			var max_wild: int = _count_active("wild_fruit") * WILD_MAX_PER_CARD
			_cleanup_wild_refs()
			while _wild_fruits.size() > max_wild:
				var fruit: Fruit = _wild_fruits.back()
				if is_instance_valid(fruit):
					_unmark_fruit_as_wild(fruit)
				else:
					_wild_fruits.pop_back()


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


# =============================================================================
# Wild Fruit effect
# =============================================================================

func _mark_fruit_as_wild(fruit: Fruit) -> void:
	## Apply wild status and rainbow shader to a fruit.
	fruit.is_wild = true
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _rainbow_shader
	mat.set_shader_parameter("line_scale", 4.0)
	mat.set_shader_parameter("frequency", 0.8)
	mat.set_shader_parameter("light_offset", 0.5)
	fruit.get_node("Sprite2D").material = mat
	_wild_fruits.append(fruit)
	EventBus.wild_fruit_marked.emit(fruit)


func _unmark_fruit_as_wild(fruit: Fruit) -> void:
	## Remove wild status and rainbow shader from a fruit.
	fruit.is_wild = false
	fruit.get_node("Sprite2D").material = null
	_wild_fruits.erase(fruit)
	EventBus.wild_fruit_unmarked.emit(fruit)


func _select_wild_fruits() -> void:
	## Pick random non-wild fruits to designate as wild, up to max capacity.
	var max_wild: int = _count_active("wild_fruit") * WILD_MAX_PER_CARD
	_cleanup_wild_refs()
	if _wild_fruits.size() >= max_wild:
		return
	var container: Node = _get_fruit_container()
	if not container:
		return
	# Gather valid candidates: non-wild, non-merging, non-dropping, non-frozen fruits.
	var candidates: Array = []
	for child in container.get_children():
		if child is Fruit and is_instance_valid(child):
			if not child.is_wild and not child.merging and not child.is_dropping and not child.freeze:
				candidates.append(child)
	if candidates.is_empty():
		return
	candidates.shuffle()
	var slots_to_fill: int = max_wild - _wild_fruits.size()
	for i in mini(slots_to_fill, candidates.size()):
		_mark_fruit_as_wild(candidates[i])


func _cleanup_wild_refs() -> void:
	## Remove invalid (freed/merged) references from the wild fruits array.
	var valid: Array = []
	for fruit in _wild_fruits:
		if is_instance_valid(fruit) and fruit.is_inside_tree():
			valid.append(fruit)
	_wild_fruits = valid


func _cleanup_wild_fruits() -> void:
	## Fully unmark all wild fruits and reset wild state.
	var copy: Array = _wild_fruits.duplicate()
	for fruit in copy:
		if is_instance_valid(fruit):
			_unmark_fruit_as_wild(fruit)
	_wild_fruits.clear()
	_wild_merge_counter = 0
