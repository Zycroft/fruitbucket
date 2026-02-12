class_name RunStatsTracker
extends Node
## Tracks per-run statistics for the run summary screen.
## Lives in the game scene tree (not autoload) for automatic cleanup on reset.

## Biggest chain length achieved this run.
var biggest_chain: int = 0

## Highest fruit tier created (0-indexed code tier).
var highest_tier: int = 0

## Total number of merges performed.
var total_merges: int = 0

## Total coins earned from all sources.
var total_coins_earned: int = 0

## Unique card_ids ever held during this run.
var cards_used: Array[String] = []

## Tick count at run start for time tracking.
var _start_time_msec: int = 0


func _ready() -> void:
	add_to_group("run_stats_tracker")
	_start_time_msec = Time.get_ticks_msec()

	EventBus.fruit_merged.connect(_on_fruit_merged)
	EventBus.chain_ended.connect(_on_chain_ended)
	EventBus.coins_awarded.connect(_on_coins_awarded)
	EventBus.bonus_awarded.connect(_on_bonus_awarded)
	EventBus.card_purchased.connect(_on_card_purchased)
	EventBus.starter_pick_completed.connect(_on_starter_pick)


func _on_fruit_merged(_old_tier: int, new_tier: int, _position: Vector2) -> void:
	total_merges += 1
	highest_tier = maxi(highest_tier, new_tier)


func _on_chain_ended(chain_length: int) -> void:
	biggest_chain = maxi(biggest_chain, chain_length)


func _on_coins_awarded(new_coins: int, _total_coins: int) -> void:
	total_coins_earned += new_coins


func _on_bonus_awarded(amount: int, _position: Vector2, bonus_type: String) -> void:
	if bonus_type == "coins":
		total_coins_earned += amount


func _on_card_purchased(card: CardData, _slot_index: int) -> void:
	if card.card_id not in cards_used:
		cards_used.append(card.card_id)


func _on_starter_pick(card: CardData) -> void:
	if card.card_id not in cards_used:
		cards_used.append(card.card_id)


func get_time_played_seconds() -> int:
	## Return elapsed run time in whole seconds.
	return (Time.get_ticks_msec() - _start_time_msec) / 1000


func get_stats() -> Dictionary:
	## Return all tracked stats as a dictionary for the run summary.
	return {
		"biggest_chain": biggest_chain,
		"highest_tier": highest_tier,
		"total_merges": total_merges,
		"total_coins_earned": total_coins_earned,
		"cards_used": cards_used,
		"time_played": get_time_played_seconds(),
		"final_score": GameManager.score,
	}
