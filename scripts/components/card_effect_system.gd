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
## Maximum tier affected by Bouncy Berry (0=Cherry, 1=Grape, 2=Strawberry).
const BOUNCY_MAX_TIER: int = 2

# --- Cherry Bomb constants ---
## Strawberry is tier index 2 in code (tier_3_strawberry.tres has tier=2).
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

# --- Scoring effect constants ---
## Quick Fuse: +25% of base_score per card for merges during active chain.
const QUICK_FUSE_BONUS: float = 0.25
## Fruit Frenzy: bonus = base_score * 2.0 * card_count for chains of 3+.
const FRUIT_FRENZY_MULTIPLIER: float = 2.0
const FRUIT_FRENZY_MIN_CHAIN: int = 3
## Big Game Hunter: +50% of base_score per card for tier 7+ (code tier >= 6) merges.
const BIG_GAME_BONUS: float = 0.5
const BIG_GAME_MIN_TIER: int = 6

# --- Coin/Mixed effect constants ---
## Golden Touch: flat +2 coins per card per merge.
const GOLDEN_TOUCH_COINS: int = 2
## Lucky Break: 15% independent chance per card to award bonus coins.
const LUCKY_BREAK_CHANCE: float = 0.15
const LUCKY_BREAK_COINS: int = 5
## Pineapple Express: triggers when Pineapple (code tier 6) is created.
const PINEAPPLE_TIER: int = 6
const PINEAPPLE_BONUS_SCORE: int = 100
const PINEAPPLE_BONUS_COINS: int = 20

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

## FruitData resources for base score lookup (loaded in _ready).
var _fruit_types: Array[FruitData] = []


func _ready() -> void:
	add_to_group("card_effect_system")
	_load_fruit_types()
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

func _on_fruit_merged(old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
	## Dispatch merge-triggered effects.
	# Cherry Bomb: explode on strawberry merge (tier 2)
	var cherry_count: int = _count_active("cherry_bomb")
	if cherry_count > 0 and old_tier == CHERRY_TIER:
		_apply_cherry_bomb(merge_pos, cherry_count)
		EventBus.card_effect_triggered.emit("cherry_bomb")
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
			EventBus.card_effect_triggered.emit("heavy_hitter")
	# Wild Fruit: cleanup invalid references and select new wild fruits
	_cleanup_wild_refs()
	if _count_active("wild_fruit") > 0:
		_wild_merge_counter += 1
		if _wild_merge_counter >= WILD_SELECT_INTERVAL:
			_wild_merge_counter = 0
			_select_wild_fruits()
			EventBus.card_effect_triggered.emit("wild_fruit")
	# Scoring card effects: compute and apply bonus score from active scoring cards
	_apply_scoring_effects(old_tier, new_tier, merge_pos)


func _on_fruit_dropped(_tier: int, _pos: Vector2) -> void:
	## Apply bouncy berry to the just-dropped fruit (transitions from frozen to physics).
	if _count_active("bouncy_berry") > 0:
		call_deferred("_apply_bouncy_berry_all")
		EventBus.card_effect_triggered.emit("bouncy_berry")
	# Heavy Hitter: consume a charge and apply mass boost to the just-dropped fruit.
	if _count_active("heavy_hitter") > 0 and _heavy_charges > 0:
		_heavy_charges -= 1
		EventBus.card_effect_triggered.emit("heavy_hitter")
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
	## Only affects tiers 0-2 (Cherry, Grape, Strawberry).
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
# Scoring effect infrastructure
# =============================================================================

func _load_fruit_types() -> void:
	## Load all 8 FruitData .tres files in tier order for base score lookup.
	var paths: Array[String] = [
		"res://resources/fruit_data/tier_1_cherry.tres",
		"res://resources/fruit_data/tier_2_grape.tres",
		"res://resources/fruit_data/tier_3_strawberry.tres",
		"res://resources/fruit_data/tier_4_orange.tres",
		"res://resources/fruit_data/tier_5_apple.tres",
		"res://resources/fruit_data/tier_6_peach.tres",
		"res://resources/fruit_data/tier_7_pineapple.tres",
		"res://resources/fruit_data/tier_8_watermelon.tres",
	]
	for path in paths:
		var data: FruitData = load(path) as FruitData
		if data:
			_fruit_types.append(data)
		else:
			push_error("CardEffectSystem: Failed to load FruitData at %s" % path)


func _get_base_score(new_tier: int) -> int:
	## Look up the base score_value for a given tier from FruitData.
	## Returns WATERMELON_VANISH_BONUS for watermelon vanish (tier >= array size).
	if new_tier >= _fruit_types.size():
		return 1000  # Watermelon vanish bonus
	return _fruit_types[new_tier].score_value


func _apply_quick_fuse(new_tier: int) -> int:
	## Quick Fuse: +25% of base_score per card when merge happens during active chain.
	var count: int = _count_active("quick_fuse")
	if count == 0:
		return 0
	var sm: ScoreManager = get_tree().get_first_node_in_group("score_manager") as ScoreManager
	if sm == null or sm.get_chain_count() < 2:
		return 0
	var bonus: int = int(_get_base_score(new_tier) * QUICK_FUSE_BONUS * count)
	if bonus > 0:
		EventBus.card_effect_triggered.emit("quick_fuse")
	return bonus


func _apply_fruit_frenzy(new_tier: int) -> int:
	## Fruit Frenzy: +2x base_score per card when chain_count >= 3.
	var count: int = _count_active("fruit_frenzy")
	if count == 0:
		return 0
	var sm: ScoreManager = get_tree().get_first_node_in_group("score_manager") as ScoreManager
	if sm == null or sm.get_chain_count() < FRUIT_FRENZY_MIN_CHAIN:
		return 0
	var bonus: int = int(_get_base_score(new_tier) * FRUIT_FRENZY_MULTIPLIER * count)
	if bonus > 0:
		EventBus.card_effect_triggered.emit("fruit_frenzy")
	return bonus


func _apply_big_game_hunter(new_tier: int) -> int:
	## Big Game Hunter: +50% of base_score per card when created fruit is tier 7+ (code tier >= 6).
	var count: int = _count_active("big_game_hunter")
	if count == 0:
		return 0
	if new_tier < BIG_GAME_MIN_TIER:
		return 0
	var bonus: int = int(_get_base_score(new_tier) * BIG_GAME_BONUS * count)
	if bonus > 0:
		EventBus.card_effect_triggered.emit("big_game_hunter")
	return bonus


func _apply_golden_touch() -> int:
	## Golden Touch: +2 coins per card per merge (flat, unconditional).
	var count: int = _count_active("golden_touch")
	if count <= 0:
		return 0
	var bonus: int = GOLDEN_TOUCH_COINS * count
	if bonus > 0:
		EventBus.card_effect_triggered.emit("golden_touch")
	return bonus


func _apply_lucky_break() -> int:
	## Lucky Break: 15% independent chance per card for +5 bonus coins.
	## Each card rolls independently -- 2 cards can both trigger for 10 coins.
	var count: int = _count_active("lucky_break")
	if count <= 0:
		return 0
	var total_coins: int = 0
	for i in count:
		if randf() < LUCKY_BREAK_CHANCE:
			total_coins += LUCKY_BREAK_COINS
	if total_coins > 0:
		EventBus.card_effect_triggered.emit("lucky_break")
	return total_coins


func _apply_pineapple_express(new_tier: int) -> Dictionary:
	## Pineapple Express: +100 score and +20 coins when Pineapple is created.
	## Returns {"score": int, "coins": int}.
	var count: int = _count_active("pineapple_express")
	if count <= 0:
		return {"score": 0, "coins": 0}
	if new_tier != PINEAPPLE_TIER:
		return {"score": 0, "coins": 0}
	var result: Dictionary = {
		"score": PINEAPPLE_BONUS_SCORE * count,
		"coins": PINEAPPLE_BONUS_COINS * count,
	}
	if result["score"] > 0 or result["coins"] > 0:
		EventBus.card_effect_triggered.emit("pineapple_express")
	return result


func _apply_scoring_effects(_old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
	## Compute and apply all scoring/economy card bonuses for this merge.
	var bonus_score: int = 0
	var bonus_coins: int = 0

	# Score bonuses (Plan 01)
	bonus_score += _apply_quick_fuse(new_tier)
	bonus_score += _apply_fruit_frenzy(new_tier)
	bonus_score += _apply_big_game_hunter(new_tier)

	# Coin bonuses (Plan 02)
	bonus_coins += _apply_golden_touch()
	bonus_coins += _apply_lucky_break()

	# Mixed bonus (Plan 02)
	var pineapple: Dictionary = _apply_pineapple_express(new_tier)
	bonus_score += pineapple["score"]
	bonus_coins += pineapple["coins"]

	# Apply score bonus
	if bonus_score > 0:
		GameManager.score += bonus_score
		EventBus.bonus_awarded.emit(bonus_score, merge_pos, "score")

	# Apply coin bonus -- emit coins_awarded so HUD updates automatically
	if bonus_coins > 0:
		GameManager.coins += bonus_coins
		EventBus.coins_awarded.emit(bonus_coins, GameManager.coins)
		EventBus.bonus_awarded.emit(bonus_coins, merge_pos, "coins")


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
