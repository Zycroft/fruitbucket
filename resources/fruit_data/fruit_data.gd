class_name FruitData
extends Resource
## Data resource describing a single fruit tier.
## Each of the 8 tiers has a corresponding .tres file.

## Tier index (0-indexed: 0 = Cherry, 7 = Watermelon).
@export var tier: int = 0

## Human-readable fruit name.
@export var fruit_name: String = ""

## Collision circle radius in pixels.
@export var radius: float = 15.0

## Fruit texture (placeholder white circle until art phase).
@export var sprite: Texture2D

## Points awarded when this tier is created via merge.
@export var score_value: int = 1

## Tint color for particles and effects (used in future phases).
@export var color: Color = Color.WHITE

## RigidBody2D mass override. Scales with fruit area.
@export var mass_override: float = 1.0

## Whether this fruit can appear as a player drop (tiers 0-4 only).
@export var is_droppable: bool = true
