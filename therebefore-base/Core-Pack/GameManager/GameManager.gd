extends Node
class_name game_manager

var current_state : game_state

var load_state : game_loading = game_loading.new()
var splash_state : game_splash = game_splash.new()
var title_state : game_title = game_title.new()
var play_state : game_play = game_play.new()

var states : Array[game_state] = [load_state,splash_state,title_state,play_state]
var state_index : int = 0

func _ready() -> void:
	Game.add_global("game_manager",self)
	current_state = states[0]
	current_state.enter_state(self)

func _process(delta: float) -> void:
	current_state.process(delta)

func next_state():
	if state_index == states.size()-1:
		print("Error: attempted to progress state but index would go out of bounds, aborting")
		return
	current_state.exit_state()
	state_index += 1
	current_state = states[state_index]
	current_state.enter_state(self)

func return_to_title():
	state_index = 0
	next_state()
