extends Node

@export var status_label: Label = null

var pck_search_directory_path: String

func _ready():
	print("--- MinimalPckLoader Initializing ---")
	if OS.has_feature("editor"):
		pck_search_directory_path = "res://Packages"
	else:
		pck_search_directory_path = OS.get_executable_path().get_base_dir().path_join("Packages")
	_update_status("Looking for PCK files...")

	await get_tree().process_frame

	var pck_files = _scan_for_pcks(pck_search_directory_path)
	if pck_files.is_empty():
		_update_status("No PCK files found.")
		return

	for pck_path in pck_files:
		var pck_name = pck_path.get_file()
		_update_status("Loading PCK: %s" % pck_name)
		await get_tree().process_frame

		var success = ProjectSettings.load_resource_pack(pck_path)
		if not success:
			_update_status("ERROR loading: %s" % pck_name)
			continue

		await _try_run_loader_script()

	_update_status("All PCKs processed.")

func _scan_for_pcks(dir_path: String) -> Array:
	var results := []
	var dir = DirAccess.open(dir_path)
	if not dir:
		printerr("ERROR: Could not open directory: %s" % dir_path)
		return results

	dir.list_dir_begin()
	while true:
		var fname = dir.get_next()
		if fname == "":
			break
		if fname == "." or fname == "..":
			continue

		var full_path = dir_path.path_join(fname)

		if dir.current_is_dir():
			results.append_array(_scan_for_pcks(full_path))
		elif fname.get_extension() == "pck":
			results.append(full_path)

	dir.list_dir_end()
	return results

func _try_run_loader_script():
	const loader_path = "res://load.gd"
	if not ResourceLoader.exists(loader_path):
		print("No load.gd found in this PCK.")
		return

	var script = ResourceLoader.load(loader_path)
	if script == null or not (script is GDScript):
		printerr("Invalid script at: %s" % loader_path)
		return

	var instance = script.new()
	if not instance.has_method("load"):
		printerr("Script at %s has no load() method." % loader_path)
		return

	print("Calling load() on %s" % loader_path)
	instance.load()

func _update_status(msg: String):
	if status_label:
		status_label.text = msg
	print(msg)
