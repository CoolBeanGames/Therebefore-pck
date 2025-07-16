extends Control


func _on_start_button_button_down() -> void:
	Game.get_global("game_manager").next_state()


func _on_quit_button_button_down() -> void:
	Game.tree_root.get_tree().quit()
