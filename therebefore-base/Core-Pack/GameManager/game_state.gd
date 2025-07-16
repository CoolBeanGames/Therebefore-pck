extends Node
class_name game_state

var manager : game_manager

func enter_state(man : game_manager):
	manager = man

func exit_state():
	pass

func process(delta : float):
	pass
