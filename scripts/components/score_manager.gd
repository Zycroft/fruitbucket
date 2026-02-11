class_name ScoreManager
extends Node
## Calculates score from merges, tracks cascade chains with accelerating
## multipliers, and awards coins when cumulative score crosses thresholds.
## Emits signals consumed by the HUD and floating-popup systems (Plan 02).

## Fibonacci-like accelerating chain multipliers.
## Index = chain_count - 1, clamped to array bounds.
const CHAIN_MULTIPLIERS: Array[int] = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89]

## Every COIN_THRESHOLD cumulative score awards one coin.
const COIN_THRESHOLD: int = 100

## Milestone score thresholds that trigger Phase 5 shop events.
const SCORE_THRESHOLDS: Array[int] = [500, 1500, 3500, 7000]

## Flat bonus awarded when two watermelons vanish (replaces tier score).
const WATERMELON_VANISH_BONUS: int = 1000

## All 8 FruitData resources, indexed by tier (0 = Blueberry, 7 = Watermelon).
var _fruit_types: Array[FruitData] = []

## Current chain counter -- increments on every merge, resets after timer expires.
var _chain_count: int = 0

## Coins already awarded (derived from cumulative score / COIN_THRESHOLD).
var _coins_awarded: int = 0

## How many SCORE_THRESHOLDS milestones have been crossed so far.
var _thresholds_reached: int = 0

## Timer that detects the end of a cascade chain.
var _chain_timer: Timer


func _ready() -> void:
	add_to_group("score_manager")
	_load_fruit_types()

	_chain_timer = Timer.new()
	_chain_timer.one_shot = true
	_chain_timer.wait_time = 1.0
	add_child(_chain_timer)
	_chain_timer.timeout.connect(_on_chain_expired)

	EventBus.fruit_merged.connect(_on_fruit_merged)


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
			push_error("ScoreManager: Failed to load FruitData at %s" % path)


func _on_fruit_merged(old_tier: int, new_tier: int, merge_pos: Vector2) -> void:
	## Called on every merge via EventBus.fruit_merged.
	## Calculates score with chain multiplier, updates GameManager, emits signals.

	# --- Chain tracking ---
	_chain_count += 1
	_chain_timer.start()  # Restart the settling window on every merge.

	# --- Base score ---
	var base_score: int = 0
	if new_tier >= _fruit_types.size():
		# Watermelon pair vanish: flat bonus replaces tier score.
		base_score = WATERMELON_VANISH_BONUS
	else:
		base_score = _fruit_types[new_tier].score_value

	# --- Chain multiplier ---
	var multiplier_index: int = clampi(_chain_count - 1, 0, CHAIN_MULTIPLIERS.size() - 1)
	var multiplier: int = CHAIN_MULTIPLIERS[multiplier_index]

	# --- Apply score ---
	var total_score: int = base_score * multiplier
	GameManager.score += total_score
	EventBus.score_awarded.emit(total_score, merge_pos, _chain_count, multiplier)

	# --- Coin economy ---
	var new_coins: int = GameManager.score / COIN_THRESHOLD - _coins_awarded
	if new_coins > 0:
		_coins_awarded += new_coins
		GameManager.coins += new_coins
		EventBus.coins_awarded.emit(new_coins, GameManager.coins)

	# --- Score thresholds ---
	while _thresholds_reached < SCORE_THRESHOLDS.size() and GameManager.score >= SCORE_THRESHOLDS[_thresholds_reached]:
		EventBus.score_threshold_reached.emit(SCORE_THRESHOLDS[_thresholds_reached])
		_thresholds_reached += 1


func get_chain_count() -> int:
	## Public read-only accessor for current chain count.
	## Used by CardEffectSystem for Quick Fuse and Fruit Frenzy.
	return _chain_count


func _on_chain_expired() -> void:
	## Timer fired -- no merge occurred within the settling window.
	## Emit chain_ended if the chain was meaningful (> 1 merge).
	if _chain_count > 1:
		EventBus.chain_ended.emit(_chain_count)
	_chain_count = 0
