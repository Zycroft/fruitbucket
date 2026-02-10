class_name CardEffectSystem
extends Node
## Central card effect processor. Connects to EventBus signals and reads
## CardManager.active_cards to apply physics/merge card effects at runtime.
## Lives in the game scene tree (not an autoload) for automatic cleanup on reset.


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


func _on_fruit_merged(_old_tier: int, _new_tier: int, _merge_pos: Vector2) -> void:
	## Dispatch merge-triggered effects. Filled in Task 2.
	pass


func _on_fruit_dropped(_tier: int, _pos: Vector2) -> void:
	## Dispatch drop-triggered effects. Filled in Task 2.
	pass


func _on_card_changed(_card: CardData, _slot_index: int) -> void:
	## Retroactively apply effects when a card is purchased.
	pass


func _on_card_removed(_card: CardData, _slot_index: int, _refund: int) -> void:
	## Recalculate/revert effects when a card is sold.
	pass
