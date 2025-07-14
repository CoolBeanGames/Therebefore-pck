extends Node
class_name Inputs

const CONFIGPATH = "user://input.cfg"

func _ready() -> void:
	_load_config()

func _process(delta: float) -> void:
	pass

func _set_defaults():
	# Optional: Add default input mappings here
	pass

func _save_config():
	var config := ConfigFile.new()
	for action in InputMap.get_actions():
		var events = InputMap.action_get_events(action)
		var serial := []
		for e in events:
			serial.append(e.serialize())
		config.set_value("Inputs", action, serial)
	config.save(CONFIGPATH)

func _load_config():
	var config := ConfigFile.new()
	var err = config.load(CONFIGPATH)
	if err != OK:
		print("Error loading input config file")
		return
	
	for key in config.get_section_keys("Inputs"):
		var event_array = config.get_value("Inputs", key, [])

		if not InputMap.has_action(key):
			InputMap.add_action(key)

		InputMap.action_erase_events(key)

		for ev_dict in event_array:
			if typeof(ev_dict) == TYPE_DICTIONARY and ev_dict.has("class"):
				var ev = _reconstruct_input_event(ev_dict)
				if ev != null:
					InputMap.action_add_event(key, ev)

func _reconstruct_input_event(data: Dictionary) -> InputEvent:
	var ev = null
	match data["class"]:
		"InputEventKey":
			ev = InputEventKey.new()
			ev.physical_keycode = data.get("physical_keycode", 0)
			ev.pressed = true
		"InputEventMouseButton":
			ev = InputEventMouseButton.new()
			ev.button_index = data.get("button_index", 0)
			ev.pressed = true
		"InputEventJoypadButton":
			ev = InputEventJoypadButton.new()
			ev.button_index = data.get("button_index", 0)
			ev.device = data.get("device", 0)
			ev.pressed = true
		# Add others as needed
		_:
			printerr("Unknown event class: %s" % data["class"])
	return ev
