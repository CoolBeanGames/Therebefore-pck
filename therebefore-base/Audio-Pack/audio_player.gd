extends Node
class_name audio_player

@export var global_player : AudioStreamPlayer
@export var local_player : AudioStreamPlayer3D
var active_player
var rng : RandomNumberGenerator

signal finished(audio_player)
signal stopped(audio_player)

func _ready() -> void:
	global_player.finished.connect(on_complete)
	local_player.finished.connect(on_complete)
	rng = RandomNumberGenerator.new()
	rng.randomize()

func start(stream : AudioStream, bus : enums.audio_bus, use_position : bool ,position : Vector3, volume : float = 1, random_pitch : bool = false, pitch_range : Vector2 = Vector2(0.9,0.1) ):
	reset()
	var player
	if use_position:
		player = setup_local(position)
	else:
		player = setup_global()
	player.stream = stream
	player.volume_db = linear_to_db(clamp(volume, -1, 1.0))
	if random_pitch:
		randomize_pitch(pitch_range,player)
	else:
		player.pitch_scale = 1
	player.bus = str(bus)
	active_player = player
	player.play()

func setup_global() -> AudioStreamPlayer:
	return global_player

func setup_local(position : Vector3) -> AudioStreamPlayer3D:
	local_player.position = position
	return local_player

func stop():
	stopped.emit(self)
	active_player.stop()
	reset()

func on_complete():
	finished.emit(self)
	reset()

func randomize_pitch(pitch : Vector2 , player):	
	player.pitch_scale =rng.randf_range(pitch.x,pitch.y)

func reset():
	if active_player!=null:
		active_player.stream = null
		active_player.pitch_scale = 1
		active_player.volume_db = 0
		active_player.stop()
		active_player.bus = "Master"
		active_player=null
