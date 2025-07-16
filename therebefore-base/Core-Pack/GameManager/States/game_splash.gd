extends game_state
class_name game_splash

var splash_scenes : Array[PackedScene] = [
preload("res://Core-Pack/SplashScreens/notice_splash_screen_1.tscn"),
preload("res://Core-Pack/SplashScreens/notice_splash_screen_2.tscn"),
preload("res://Core-Pack/SplashScreens/notice_splash_screen_3.tscn"),
preload("res://Core-Pack/SplashScreens/powered_by_godot_splash_screen.tscn"),
preload("res://Core-Pack/SplashScreens/cool_bean_games_splash_screen.tscn")]

var sound_effect : AudioStream = preload("res://Core-Pack/sounds/sting.mp3")
var index : int = 0
var instance : Node
var splash_time : float = 5
var fade_out_start : float
var fade_time : float = 1
var tween : Tween
var audio : audio_manager


func enter_state(man : game_manager):
	super.enter_state(man)
	load_scene()
	set_audio()

func set_audio():
	if audio == null:
		audio = Game.get_global("audio")	

func exit_state():
	super.exit_state()


func process(delta : float):
	super.process(delta)

func load_scene():	
	if audio == null:
		audio = Game.get_global("audio")
	if index >= splash_scenes.size():
		print("splash screens ended, progressing to title")
		if instance!=null:
			instance.queue_free()
			instance=null
		manager.next_state()
		return
	if instance!=null:
		instance.queue_free()
		instance = null
	var parent := Game.ui_root
	instance = splash_scenes[index].instantiate()
	parent.add_child(instance)
	audio.play(sound_effect,enums.audio_bus.SoundEffects,false,Vector3.ZERO,1,true)
	index += 1
	fade_out_start = splash_time - fade_time
	fade_in_tween()
	Game.tree_root.get_tree().create_timer(splash_time).timeout.connect(timer_up)
	Game.tree_root.get_tree().create_timer(fade_out_start).timeout.connect(fade_timer_up)

func timer_up():
	load_scene()

func fade_timer_up():
	fade_out_tween()

func fade_in_tween():
	instance.modulate = Color(1,1,1,0)
	if tween!=null:
		tween.stop()
		tween.kill()
	tween = Game.tree_root.get_tree().create_tween()
	tween.tween_property(instance,"modulate",Color(1,1,1,1),fade_time)

func fade_out_tween():
	if tween!=null:
		tween.stop()
		tween.kill()
	tween = Game.tree_root.get_tree().create_tween()
	tween.tween_property(instance,"modulate",Color(1,1,1,0),fade_time)
