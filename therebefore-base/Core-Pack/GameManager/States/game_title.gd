extends game_state
class_name game_title

var title_scene : PackedScene = preload("res://Core-Pack/Title/TitleScreen.tscn")
var instance : Control

func enter_state(man : game_manager):
	super.enter_state(man)
	instance = title_scene.instantiate()
	Game.ui_root.add_child(instance)

func exit_state():
	super.exit_state()
	instance.queue_free()
	instance = null

func process(delta : float):
	super.process(delta)
