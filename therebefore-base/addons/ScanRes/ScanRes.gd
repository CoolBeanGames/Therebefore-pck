@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_tool_menu_item("Scan Resources", func(): scan_res())
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass


func scan_res():
	get_editor_interface().get_resource_filesystem().scan()
