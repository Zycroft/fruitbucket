class_name MergeFeedback
extends Node
## Central feedback orchestrator for merge events. Connects to EventBus signals
## and dispatches particle bursts, screen shake, and SFX with intensity scaled
## by fruit tier and chain position.

## Preloaded particle scene for merge bursts.
var _particle_scene: PackedScene = preload("res://scenes/effects/merge_particles.tscn")

## All 8 FruitData resources, indexed by tier (0 = Cherry, 7 = Watermelon).
var _fruit_types: Array[FruitData] = []


func _ready() -> void:
	add_to_group("merge_feedback")
	_load_fruit_types()
	EventBus.fruit_merged.connect(_on_fruit_merged)
	EventBus.score_awarded.connect(_on_score_awarded)


func _load_fruit_types() -> void:
	## Load all 8 FruitData .tres files in tier order.
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
			push_error("MergeFeedback: Failed to load FruitData at %s" % path)


func _on_fruit_merged(old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
	## Called on every merge via EventBus.fruit_merged.
	## Orchestrates particles, shake, and SFX scaled by tier intensity.
	var tier_intensity: float = clampf(float(new_tier) / 7.0, 0.1, 1.0)
	if new_tier >= 8:
		tier_intensity = 1.0

	_spawn_particles(merge_pos, new_tier, tier_intensity)
	_trigger_shake(tier_intensity * 0.6)
	SfxManager.play_merge(new_tier, tier_intensity)

	# Watermelon vanish: new_tier equals fruit count (beyond max index).
	if new_tier >= _fruit_types.size():
		_on_watermelon_vanish(merge_pos)


func _spawn_particles(pos: Vector2, tier: int, intensity: float) -> void:
	## Instantiate a particle burst at the merge position.
	var particles: CPUParticles2D = _particle_scene.instantiate()

	# Find a persistent container for the particle node.
	var container: Node2D = get_tree().get_first_node_in_group("effects_container")
	if not container:
		container = get_tree().get_first_node_in_group("fruit_container")
	if container:
		container.add_child(particles)
	else:
		push_warning("MergeFeedback: No effects_container or fruit_container found")
		add_child(particles)

	# Set position AFTER adding to tree so global_position works correctly.
	particles.global_position = pos
	_configure_particles(particles, tier, intensity)

	# Connect finished->queue_free at runtime (avoids editor crash bug #107743).
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


func _configure_particles(particles: CPUParticles2D, tier: int, intensity: float) -> void:
	## Set particle color from FruitData and scale count/velocity/size by intensity.
	var color: Color
	if tier < _fruit_types.size():
		color = _fruit_types[tier].color
	else:
		color = Color(1.0, 0.9, 0.3)  # Gold for watermelon vanish.

	particles.color = color

	# Color ramp: tier color fading to transparent over lifetime.
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	particles.color_ramp = gradient

	# Scale particle count, velocity, and size by intensity.
	particles.amount = int(lerpf(8.0, 30.0, intensity))
	particles.initial_velocity_min = lerpf(40.0, 120.0, intensity)
	particles.initial_velocity_max = lerpf(80.0, 200.0, intensity)
	particles.scale_amount_min = lerpf(1.5, 4.0, intensity)
	particles.scale_amount_max = lerpf(3.0, 8.0, intensity)


func _trigger_shake(trauma_amount: float) -> void:
	## Apply trauma to the shake camera if it exists.
	var camera: Camera2D = get_tree().get_first_node_in_group("shake_camera")
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(trauma_amount)


func _on_score_awarded(points: int, position: Vector2, chain_count: int, multiplier: int) -> void:
	## Chain escalation: add extra shake and accent sounds for chains of 2+.
	if chain_count < 2:
		return

	# Diminishing extra trauma to avoid shake overload during long chains.
	var extra_trauma: float = minf(0.15, 0.08 + float(chain_count - 2) * 0.02)
	_trigger_shake(extra_trauma)

	# Ascending accent ding for 3+ chains.
	if chain_count >= 3:
		SfxManager.play_chain_accent(chain_count)


func _on_watermelon_vanish(merge_pos: Vector2) -> void:
	## Special maximum-spectacle treatment for watermelon pair vanish.
	## Extra-large gold particle burst, big shake, deep boom.
	var particles: CPUParticles2D = _particle_scene.instantiate()

	var container: Node2D = get_tree().get_first_node_in_group("effects_container")
	if not container:
		container = get_tree().get_first_node_in_group("fruit_container")
	if container:
		container.add_child(particles)
	else:
		add_child(particles)

	particles.global_position = merge_pos

	# Gold burst configuration -- maximum spectacle.
	particles.amount = 40
	var gold := Color(1.0, 0.9, 0.3)
	particles.color = gold
	var gradient := Gradient.new()
	gradient.set_color(0, gold)
	gradient.set_color(1, Color(gold.r, gold.g, gold.b, 0.0))
	particles.color_ramp = gradient
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 300.0
	particles.lifetime = 0.8
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 10.0

	# Runtime-only cleanup connection.
	particles.finished.connect(particles.queue_free)
	particles.emitting = true

	# Maximum shake.
	_trigger_shake(0.6)

	# Deep boom sound.
	SfxManager.play_watermelon_vanish()
