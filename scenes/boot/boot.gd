extends Node2D

@export_category("Data")
@export var intro_textures: Array[Texture2D]
@export var display_time: float = 1.8

@export_category("Components")
@export var sprite: Sprite2D
@export var timer: Timer

var _index: int = 0

func _ready():
	if intro_textures.is_empty():
		_go_menu()

	return _show_current()
	
func _unhandled_input(event):
	if event.is_action_pressed("skip"):
		_go_menu()

func _on_timer_timeout() -> void:
	_index += 1
	
	if _index >= intro_textures.size():
		_go_menu()
	else:
		_show_current()
		
func _show_current():
	sprite.texture = intro_textures[_index]
	timer.start(display_time)
	
func _go_menu():
	get_tree().change_scene_to_file("res://scenes/menus/main_menu/main_menu.tscn")
