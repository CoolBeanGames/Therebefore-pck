extends Node

@export var status_label: Label = null
@export var Canvas : CanvasLayer

var pck_search_directory_path: String
var _loader_scripts := []  # Stores dictionaries with { path: String, pack: String }

func _ready():
	print("--- MinimalPckLoader Initializing ---")
	if OS.has_feature("editor"):
		pck_search_directory_path = "res://Packages"
	else:
		pck_search_directory_path = OS.get_executable_path().get_base_dir().path_join("Packages")

	_update_status("Looking for PCK files...")

	await get_tree().process_frame

	var pck_files = _scan_for_pcks(pck_search_directory_path)
	pck_files.sort()  # Sort by filename: 0000.pck, 0001.pck, etc.

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

		_cache_loader_scripts_for_pck(pck_name)

	_update_status("All PCKs mounted. Executing loaders...")
	await get_tree().process_frame

	_run_all_cached_loaders()

	_update_status("All PCKs processed.")
	await 0.5
	Canvas.queue_free()

# --- Helper: Scan for .pck files recursively ---
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

# --- Helper: Cache any load.gd found after mounting a PCK ---
func _cache_loader_scripts_for_pck(pck_name: String):
	var all_load_paths = _find_all_load_scripts("res://")
	for path in all_load_paths:
		if path in _loader_scripts.map(func(it): return it.path):
			continue  # Already cached
		_loader_scripts.append({ "path": path, "pack": pck_name })

# --- Helper: Recursively find all res://*/load.gd files ---
func _find_all_load_scripts(dir_path: String) -> Array:
	var found := []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found

	dir.list_dir_begin()
	while true:
		var fname = dir.get_next()
		if fname == "":
			break
		if fname == "." or fname == "..":
			continue

		var full_path = dir_path.path_join(fname)

		if dir.current_is_dir():
			found.append_array(_find_all_load_scripts(full_path))
		elif fname == "load.gd":
			found.append(full_path)

	dir.list_dir_end()
	return found

# --- Call load() on each cached script in PCK load order ---
func _run_all_cached_loaders():
	_loader_scripts.sort_custom(func(a, b): return a.pack < b.pack)

	for entry in _loader_scripts:
		var path = entry.path
		print("Calling load() on %s" % path)

		var script = ResourceLoader.load(path)
		if script == null or not (script is GDScript):
			printerr("Invalid script at: %s" % path)
			continue

		var instance = script.new()
		if not instance.has_method("load"):
			printerr("Script at %s has no load() method." % path)
			continue

		instance.load()

# --- UI + print ---
func _update_status(msg: String):
	if status_label:
		status_label.text = msg
	print(msg)
