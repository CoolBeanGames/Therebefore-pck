@tool
extends EditorPlugin

# This is an example of what your PckList.tres might look like:
#
# @export var folders: Dictionary = {
#     "Audio": "res://Audio-Pack/",
#     "Levels": "res://Levels/",
#     "Characters": "res://Characters/"
# }
#
# You'd create a new Resource script:
# extends Resource
# class_name PCKList
# @export var folders: Dictionary = {}

var export_list_resource: PCKList # Ensure PCKList is a custom resource class_name
const OUTPUT_DIR := "res://Packages/"
const MANIFEST_DIR := "user://pck_manifests/" # Using user:// for editor plugin data

var _has_exported := false # This variable is not used in the updated logic
var _was_playing := false

func _enter_tree():
	print("📦 PackExporter plugin loaded")
	# Ensure the PCKList.tres path is correct for your project
	export_list_resource = ResourceLoader.load("res://addons/PackExporter/PckList.tres")
	if not export_list_resource:
		printerr("❌ PCKList.tres not found at res://addons/PackExporter/PckList.tres. Please create it or update the path.")
		return
	if not export_list_resource is PCKList:
		printerr("❌ Loaded resource is not a PCKList. Ensure PckList.tres inherits from the PCKList custom resource.")
		return

	add_tool_menu_item("Build PCK Files", func(): _export_all_to_pck())
	set_process(true) # Enables _process callback for editor plugins

func _exit_tree():
	remove_tool_menu_item("Build PCK Files")
	set_process(false)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return  # Don't run inside the actual game

	if get_editor_interface().is_playing_scene():
		if not _was_playing:
			# Just started Play mode — export now
			print("🔧 Auto-checking and exporting PCKs before running the project...")
			_export_all_to_pck()
			_was_playing = true
	else:
		# Reset once back in editor
		_was_playing = false

func _export_all_to_pck():
	if not export_list_resource:
		printerr("❌ No Export List resource assigned or loaded!")
		return

	var folders = export_list_resource.folders
	if typeof(folders) != TYPE_DICTIONARY:
		printerr("❌ Export List resource 'folders' is not a dictionary!")
		return

	# Ensure output directories exist
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(MANIFEST_DIR)

	for name in folders.keys():
		var source_dir: String = folders[name]
		var output_file := OUTPUT_DIR.path_join("%s.pck" % name)
		var manifest_file := MANIFEST_DIR.path_join("%s_manifest.json" % name)
		var temp_file := output_file + ".tmp"

		# Generate current manifest of source files
		var current_manifest = _generate_manifest(source_dir)
		if current_manifest.is_empty() and not DirAccess.dir_exists_absolute(source_dir):
			printerr("❌ Source directory does not exist or is empty: %s" % source_dir)
			continue # Skip if source directory is invalid or empty

		# Determine if rebuild is needed
		var should_rebuild = _should_rebuild_pck(current_manifest, manifest_file, output_file)

		if should_rebuild:
			var packer := PCKPacker.new()
			print("📦 Packing %s → %s..." % [source_dir, temp_file])
			var result := packer.pck_start(temp_file, 4)
			if result != OK:
				printerr("❌ Failed to start temporary PCK: %s" % temp_file)
				continue

			_add_folder_to_pck(source_dir, "", packer)
			packer.flush()
			print("✅ Finished temporary pack: %s" % temp_file)

			var dir_access := DirAccess.open("res://") # Need DirAccess for file operations outside user://
			if not dir_access:
				printerr("❌ Failed to open DirAccess for file operations.")
				continue

			# Replace existing PCK with new one
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
				# Save the new manifest only if the PCK was successfully updated
				_save_manifest(current_manifest, manifest_file)
			else:
				printerr("❌ Error updating: %s" % output_file)
				# Clean up temp file if update failed
				var cleanup_err = dir_access.remove(temp_file)
				if cleanup_err != OK:
					printerr("⚠️ Failed to delete temp file after failed update: %s" % temp_file)
		else:
			# If no rebuild, just ensure temp file is removed if it somehow exists
			if FileAccess.file_exists(temp_file):
				var dir_access := DirAccess.open("res://") # or get_tree().get_file_access_path()
				if dir_access:
					var cleanup_err = dir_access.remove(temp_file)
					if cleanup_err != OK:
						printerr("⚠️ Failed to delete lingering temp file: %s" % temp_file)
			print("🟢 Unchanged: %s" % output_file)


# Generates a dictionary (manifest) of all files in a folder and their last modified times.
# Keys are relative paths within the source_dir, values are Unix timestamps.
func _generate_manifest(source_dir: String) -> Dictionary:
	var manifest := {}
	var dir := DirAccess.open(source_dir)

	if not dir:
		printerr("❌ _generate_manifest: Cannot open directory: %s" % source_dir)
		return manifest

	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename == "." or filename == "..":
			filename = dir.get_next()
			continue

		var full_path = source_dir.path_join(filename)
		var relative_path = filename # For this level, relative path is just filename

		if dir.current_is_dir():
			# Recursively get manifest for subdirectories
			var sub_manifest = _generate_manifest(full_path)
			for path in sub_manifest.keys():
				manifest[relative_path.path_join(path)] = sub_manifest[path]
		else:
			# Get last modified time for files
			var modified_time = FileAccess.get_modified_time(full_path)
			if modified_time != 0:
				manifest[relative_path] = modified_time
			else:
				printerr("⚠️ Could not get modified time for file: %s" % full_path)

		filename = dir.get_next()
	dir.list_dir_end()
	return manifest

# Loads a manifest from a JSON file.
func _load_manifest(manifest_file_path: String) -> Dictionary:
	var manifest := {}
	if FileAccess.file_exists(manifest_file_path):
		var file = FileAccess.open(manifest_file_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var parse_result = JSON.parse_string(content)
			if parse_result is Dictionary:
				manifest = parse_result
			else:
				printerr("❌ Error parsing manifest JSON: %s" % manifest_file_path)
		else:
			printerr("❌ Failed to open manifest file for reading: %s" % manifest_file_path)
	return manifest

# Saves a manifest to a JSON file.
func _save_manifest(manifest: Dictionary, manifest_file_path: String):
	var file = FileAccess.open(manifest_file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(manifest, "\t") # Use tab for readability
		file.store_string(json_string)
		file.close()
		# print("Manifest saved: %s" % manifest_file_path)
	else:
		printerr("❌ Failed to open manifest file for writing: %s" % manifest_file_path)

# Determines if a PCK needs to be rebuilt based on file changes or PCK existence.
func _should_rebuild_pck(current_manifest: Dictionary, manifest_file_path: String, output_pck_path: String) -> bool:
	# 1. If the PCK file doesn't exist, always rebuild.
	if not FileAccess.file_exists(output_pck_path):
		print("Reason for rebuild: PCK file does not exist.")
		return true

	# 2. Load the previously saved manifest.
	var old_manifest = _load_manifest(manifest_file_path)

	# 3. If no old manifest (first run or deleted), always rebuild.
	if old_manifest.is_empty() and not current_manifest.is_empty():
		print("Reason for rebuild: No previous manifest found.")
		return true
	if old_manifest.is_empty() and current_manifest.is_empty():
		# Edge case: empty source dir, no old manifest. Don't rebuild anything.
		return false

	# 4. Compare current manifest with old manifest.
	# Check for added, removed, or modified files.

	# Check for new files or modified timestamps
	for path in current_manifest.keys():
		if not old_manifest.has(path) or old_manifest[path] != current_manifest[path]:
			print("Reason for rebuild: File modified or added - %s" % path)
			return true

	# Check for removed files
	for path in old_manifest.keys():
		if not current_manifest.has(path):
			print("Reason for rebuild: File removed - %s" % path)
			return true

	# If we reach here, no changes detected.
	return false

# Your existing _add_folder_to_pck function remains mostly the same,
# but it now handles nested directories correctly by passing the full path
# and constructing the virtual path accurately.
func _add_folder_to_pck(abs_path: String, virtual_prefix: String, packer: PCKPacker):
	var dir := DirAccess.open(abs_path)
	if not dir:
		printerr("❌ Cannot open directory: %s" % abs_path)
		return

	dir.list_dir_begin()
	while true:
		var fname := dir.get_next()
		if fname == "":
			break # No more files
		if fname == "." or fname == "..":
			continue # Skip current and parent directory entries

		var full_path := abs_path.path_join(fname)
		var virt_path := virtual_prefix.path_join(fname) # Correctly builds virtual path

		if dir.current_is_dir():
			# Recursively call for subdirectories
			_add_folder_to_pck(full_path, virt_path, packer)
		else:
			# Only add files that are not the .gdignore file (if you use it)
			if not fname.ends_with(".gdignore"): # Avoid adding .gdignore files to PCK
				packer.add_file(full_path, virt_path)
				print("   ➕ Added file: %s (abs: %s)" % [virt_path, full_path])

	dir.list_dir_end()
