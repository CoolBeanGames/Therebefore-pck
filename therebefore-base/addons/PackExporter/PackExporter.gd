@tool
extends EditorPlugin

var export_list_resource: PCKList
const OUTPUT_DIR := "res://Packages/"

var _has_exported := false
var _was_playing := false

func _enter_tree():
	print("📦 PackExporter plugin loaded")
	export_list_resource = ResourceLoader.load("res://addons/PackExporter/PckList.tres")
	add_tool_menu_item("Build PCK Files", func(): _export_all_to_pck())
	set_process(true)

func _exit_tree():
	remove_tool_menu_item("Build PCK Files")
	set_process(false)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return  # Don't run inside the actual game

	if get_editor_interface().is_playing_scene():
		if not _was_playing:
			# Just started Play mode — export now
			print("🔧 Auto-exporting PCKs before running the project...")
			_export_all_to_pck()
			_was_playing = true
	else:
		# Reset once back in editor
		_was_playing = false

func _export_all_to_pck():
	if not export_list_resource:
		printerr("❌ No Export List resource assigned!")
		return

	var folders = export_list_resource.folders
	if typeof(folders) != TYPE_DICTIONARY:
		printerr("❌ Export List resource 'folders' is not a dictionary!")
		return

	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

	for name in folders.keys():
		var source_dir: String = folders[name]
		var output_file := OUTPUT_DIR.path_join("%s.pck" % name)
		var temp_file := output_file + ".tmp"

		var packer := PCKPacker.new()
		print("📦 Packing %s → %s..." % [source_dir, temp_file])
		var result := packer.pck_start(temp_file, 4)
		if result != OK:
			printerr("❌ Failed to start temporary PCK: %s" % temp_file)
			continue

		_add_folder_to_pck(source_dir, "", packer)
		packer.flush()
		print("✅ Finished temporary pack: %s" % temp_file)

		var dir_access := DirAccess.open("res://")
		if not dir_access:
			printerr("❌ Failed to open DirAccess for file operations.")
			continue

		if _files_are_different(temp_file, output_file):
			var update_success := true

			if FileAccess.file_exists(output_file):
				var remove_err = dir_access.remove(output_file)
				if remove_err != OK:
					printerr("❌ Failed to remove existing PCK: %s" % output_file)
					update_success = false

			var rename_err = dir_access.rename(temp_file, output_file)
			if rename_err != OK:
				printerr("❌ Failed to move new PCK into place: %s" % output_file)
				update_success = false

			if update_success:
				print("✅ Updated: %s" % output_file)
			else:
				printerr("❌ Error updating: %s" % output_file)
		else:
			var cleanup_err = dir_access.remove(temp_file)
			if cleanup_err != OK:
				printerr("⚠️ Failed to delete temp file: %s" % temp_file)
			print("🟢 Unchanged: %s" % output_file)

func _files_are_different(path_a: String, path_b: String) -> bool:
	if not FileAccess.file_exists(path_a) or not FileAccess.file_exists(path_b):
		return true  # One is missing, treat as different

	var file_a = FileAccess.open(path_a, FileAccess.READ)
	var file_b = FileAccess.open(path_b, FileAccess.READ)

	if file_a.get_length() != file_b.get_length():
		file_a.close()
		file_b.close()
		return true

	while not file_a.eof_reached():
		var chunk_a = file_a.get_buffer(4096)
		var chunk_b = file_b.get_buffer(4096)
		if chunk_a != chunk_b:
			file_a.close()
			file_b.close()
			return true

	file_a.close()
	file_b.close()
	return false

func _add_folder_to_pck(abs_path: String, virtual_prefix: String, packer: PCKPacker):
	var dir := DirAccess.open(abs_path)
	if not dir:
		printerr("❌ Cannot open directory: %s" % abs_path)
		return

	dir.list_dir_begin()
	while true:
		var fname := dir.get_next()
		if fname == "":
			break
		if fname == "." or fname == "..":
			continue

		var full_path := abs_path.path_join(fname)
		var virt_path := virtual_prefix.path_join(fname)

		if dir.current_is_dir():
			_add_folder_to_pck(full_path, virt_path, packer)
		else:
			packer.add_file(full_path, virt_path)
			print("   ➕ Added file: %s" % virt_path)

	dir.list_dir_end()
