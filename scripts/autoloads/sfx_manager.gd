extends Node
## SFX audio pool autoload with 8 pre-created AudioStreamPlayer nodes.
## Provides tier-scaled pitch/volume for merge, chain accent, and watermelon vanish sounds.
## Registered as autoload "SfxManager" in project.godot.

const POOL_SIZE: int = 8

var _available: Array[AudioStreamPlayer] = []
var _merge_stream: AudioStream = preload("res://assets/audio/sfx/merge_pop.wav")


func _ready() -> void:
	# Check if SFX bus exists; warn and fall back to Master if not.
	var sfx_bus_idx: int = AudioServer.get_bus_index("SFX")
	var bus_name: StringName = &"SFX" if sfx_bus_idx != -1 else &"Master"
	if sfx_bus_idx == -1:
		push_warning("SfxManager: 'SFX' audio bus not found, using Master")

	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		player.bus = bus_name
		player.finished.connect(_on_finished.bind(player))
		_available.append(player)


## Play a merge pop sound scaled by tier intensity (0.0-1.0).
## Higher intensity = lower pitch (bigger fruit = deeper) and louder volume.
func play_merge(tier: int, intensity: float) -> void:
	if _available.is_empty():
		return
	var player: AudioStreamPlayer = _available.pop_back()
	player.stream = _merge_stream
	player.pitch_scale = lerpf(1.3, 0.7, intensity) + randf_range(-0.05, 0.05)
	player.volume_db = lerpf(-6.0, 0.0, intensity)
	player.play()


## Play an ascending chain accent sound. Higher chain_count = higher pitch.
func play_chain_accent(chain_count: int) -> void:
	if _available.is_empty():
		return
	var player: AudioStreamPlayer = _available.pop_back()
	player.stream = _merge_stream
	player.pitch_scale = lerpf(1.5, 2.0, clampf(float(chain_count - 2) / 5.0, 0.0, 1.0))
	player.volume_db = -3.0
	player.play()


## Play a deep boom for watermelon pair vanish.
func play_watermelon_vanish() -> void:
	if _available.is_empty():
		return
	var player: AudioStreamPlayer = _available.pop_back()
	player.stream = _merge_stream
	player.pitch_scale = 0.5
	player.volume_db = 2.0
	player.play()


func _on_finished(player: AudioStreamPlayer) -> void:
	_available.append(player)
