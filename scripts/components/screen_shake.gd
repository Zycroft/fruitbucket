extends Camera2D
## Camera2D script with trauma-based FastNoiseLite shake.
## Add to group "shake_camera" for group-based discovery.
## Call add_trauma() to trigger shake; trauma decays smoothly each frame.
## Uses position offset from base_position instead of Camera2D.offset for reliability.

## How quickly trauma decays per second.
@export var decay: float = 0.6
## Maximum pixel offset for shake.
@export var max_offset: Vector2 = Vector2(40, 25)
## Maximum rotation in radians for shake.
@export var max_roll: float = 0.03

var trauma: float = 0.0
var trauma_power: int = 2
var _noise: FastNoiseLite = FastNoiseLite.new()
var _noise_y: float = 0.0
var _base_position: Vector2


func _ready() -> void:
	add_to_group("shake_camera")
	_base_position = position
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
		position = _base_position
		rotation = 0.0


func _apply_shake() -> void:
	var amount: float = pow(trauma, trauma_power)
	_noise_y += 1.0
	var noise_x: float = _noise.get_noise_2d(_noise_y, 0.0)
	var noise_y: float = _noise.get_noise_2d(0.0, _noise_y)
	var noise_r: float = _noise.get_noise_2d(_noise_y, _noise_y)
	position.x = _base_position.x + max_offset.x * amount * noise_x
	position.y = _base_position.y + max_offset.y * amount * noise_y
	rotation = max_roll * amount * noise_r
