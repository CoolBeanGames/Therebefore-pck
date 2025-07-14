extends Resource
class_name input_list

@export var bindings: Dictionary = {}

func _process_all():
	for binding in bindings.values():
		if binding.has_method("_process"):
			binding._process()

func get_button(name: String) -> button_set:
	if bindings.has(name) and bindings[name] is button_set:
		return bindings[name]
	return null

func get_axis(name: String) -> axis_set:
	if bindings.has(name) and bindings[name] is axis_set:
		return bindings[name]
	return null

func add_button_binding(input_name: String, event: InputEvent):
	var btn := get_button(input_name)
	if btn == null:
		btn = button_set.new()
		btn.input_name = input_name
		bindings[input_name] = btn
	btn.bindings.append(event)

func add_axis_binding(input_name: String, event: InputEvent, direction: String):
	var axis := get_axis(input_name)
	if axis == null:
		axis = axis_set.new()
		axis.input_name = input_name
		bindings[input_name] = axis

	match direction:
		"positive": axis.x_positive.append(event)
		"negative": axis.x_negative.append(event)
		"up": axis.y_positive.append(event)
		"down": axis.y_negative.append(event)

func set_2d_axis_bindings(name: String,
		x_pos: Array[InputEvent], x_neg: Array[InputEvent],
		y_pos: Array[InputEvent], y_neg: Array[InputEvent]):
	var axis := axis_set.new()
	axis.input_name = name
	axis.set_bindings(x_pos, x_neg, y_pos, y_neg)
	bindings[name] = axis

func save_to_disk():
	ResourceSaver.save(self, "user://input_bindings.tres")

static func load_from_disk() -> input_list:
	if ResourceLoader.exists("user://input_bindings.tres"):
		var res = ResourceLoader.load("user://input_bindings.tres")
		if res is input_list:
			return res
	return null
