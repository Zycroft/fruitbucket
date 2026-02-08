extends Camera2D
## Camera2D script with trauma-based FastNoiseLite shake.
## Add to group "shake_camera" for group-based discovery.
## Call add_trauma() to trigger shake; trauma decays smoothly each frame.

## How quickly trauma decays per second.
@export var decay: float = 0.8
## Maximum pixel offset for shake.
@export var max_offset: Vector2 = Vector2(12, 8)
## Maximum rotation in radians for shake.
@export var max_roll: float = 0.02

var trauma: float = 0.0
var trauma_power: int = 2
var _noise: FastNoiseLite = FastNoiseLite.new()
var _noise_y: float = 0.0


func _ready() -> void:
	add_to_group("shake_camera")
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.5


func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = maxf(trauma - decay * delta, 0.0)
		_apply_shake()
	else:
		offset = Vector2.ZERO
		rotation = 0.0


func _apply_shake() -> void:
	var amount: float = pow(trauma, trauma_power)
	_noise_y += 1.0
	offset.x = max_offset.x * amount * _noise.get_noise_2d(float(_noise.seed), _noise_y)
	offset.y = max_offset.y * amount * _noise.get_noise_2d(float(_noise.seed * 2), _noise_y)
	rotation = max_roll * amount * _noise.get_noise_2d(float(_noise.seed * 3), _noise_y)
