extends input_set
class_name button_set

signal pressed
signal released
signal held

@export var bindings: Array[InputEvent] = []

var _was_pressed := false

func _process():
	var is_now_pressed := is_pressed()
	
	if is_now_pressed and not _was_pressed:
		emit_signal("pressed")
	elif not is_now_pressed and _was_pressed:
		emit_signal("released")
	elif is_now_pressed:
		emit_signal("held")
	
	_was_pressed = is_now_pressed

func is_pressed() -> bool:
	for ev in bindings:
		if ev is InputEventKey and Input.is_physical_key_pressed(ev.physical_keycode):
			return true
		elif ev is InputEventMouseButton and Input.is_mouse_button_pressed(ev.button_index):
			return true
		elif ev is InputEventJoypadButton and Input.is_joy_button_pressed(ev.device, ev.button_index):
			return true
	return false
