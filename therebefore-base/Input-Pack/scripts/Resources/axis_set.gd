extends input_set
class_name axis_set

signal moved(new_value: Vector2)

var x_positive: Array[InputEvent] = []
var x_negative: Array[InputEvent] = []
var y_positive: Array[InputEvent] = []
var y_negative: Array[InputEvent] = []

var _last_value := Vector2.ZERO

func _process():
	var value = get_value()
	if not vector_equal_approx(value, _last_value):
		emit_signal("moved", value)
	_last_value = value

func get_value() -> Vector2:
	var result := Vector2.ZERO

	for ev in x_positive:
		if _is_active(ev): result.x += 1.0
	for ev in x_negative:
		if _is_active(ev): result.x -= 1.0
	for ev in y_positive:
		if _is_active(ev): result.y -= 1.0
	for ev in y_negative:
		if _is_active(ev): result.y += 1.0

	return result.limit_length(1.0)

func set_bindings(x_pos, x_neg, y_pos := [], y_neg := []):
	x_positive = x_pos.duplicate()
	x_negative = x_neg.duplicate()
	y_positive = y_pos.duplicate()
	y_negative = y_neg.duplicate()

func _is_active(event: InputEvent) -> bool:
	if event is InputEventKey:
		return Input.is_physical_key_pressed(event.physical_keycode)
	elif event is InputEventJoypadButton:
		return Input.is_joy_button_pressed(event.device, event.button_index)
	elif event is InputEventMouseButton:
		return Input.is_mouse_button_pressed(event.button_index)
	return false

func vector_equal_approx(a: Vector2, b: Vector2, epsilon := 0.001) -> bool:
	return abs(a.x - b.x) < epsilon and abs(a.y - b.y) < epsilon
