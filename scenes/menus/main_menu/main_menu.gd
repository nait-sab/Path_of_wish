extends Control

@export var ui_node : CanvasLayer
@export var options_window_scene : PackedScene
var _options_window : Control

func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/character_select/character_select.tscn")

func _on_button_options_pressed() -> void:
	if _options_window == null or not is_instance_valid(_options_window):
		_options_window = options_window_scene.instantiate()
		ui_node.add_child(_options_window)

func _on_button_quit_pressed() -> void:
	Game.save_current()
	get_tree().quit()
