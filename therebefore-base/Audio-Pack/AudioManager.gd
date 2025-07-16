extends Node
class_name audio_manager

var player_parent = Node.new()
var active_parent = Node.new()
var inactive_parent = Node.new()

var prefab : PackedScene = preload("res://Audio-Pack/AudioPlayer.tscn")

func _ready() -> void:
	var parent = Game.tree_root
	parent.add_child(player_parent)
	player_parent.add_child(active_parent)
	player_parent.add_child(inactive_parent)
	print("Audio Player initialized")

func play(stream : AudioStream, bus : enums.audio_bus, use_position : bool = false ,position : Vector3 = Vector3.ZERO, volume : float = 1, random_pitch : bool = false, pitch_range : Vector2 = Vector2(0.9,0.1) ) -> audio_player:
	var player = get_player()
	player.start(stream,bus,use_position,position,volume,random_pitch,pitch_range)
	return player

func push(player : audio_player):
	active_parent.remove_child(player)
	inactive_parent.add_child(player)

func pop() -> audio_player:
	var ret : audio_player = inactive_parent.get_child(0)
	inactive_parent.remove_child(ret)
	active_parent.add_child(ret)
	return ret


func create() -> audio_player:
	var instance = prefab.instantiate()
	var player : audio_player = instance
	player.finished.connect(finished)
	player.stopped.connect(finished)
	active_parent.add_child(player)
	return player

func finished(player : audio_player):
	push(player)

func get_player()->audio_player:
	if inactive_parent.get_child_count() > 0:
		return pop()
	return create()
