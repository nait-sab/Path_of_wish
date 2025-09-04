extends Node2D

@export_category("Data")
@export var intro_textures: Array[Texture2D]
@export var display_time: float = 1.8

@export_category("Components")
@export var sprite: Sprite2D
@export var timer: Timer

var _index: int = 0
var _skipping := false

func _ready():
	await get_tree().process_frame
	Options.apply_all()

	if intro_textures.is_empty():
		_go_menu()
		return

	_show_current()
	
func _unhandled_input(event):
	if event.is_action_pressed("skip"):
		_skip_to_menu()

func _on_timer_timeout() -> void:
	if _skipping:
		return
	_index += 1
	if _index >= intro_textures.size():
		_go_menu()
	else:
		_show_current()
		
func _show_current():
	if _skipping or not is_instance_valid(sprite):
		return
	sprite.texture = intro_textures[_index]
	_start_timer_safe()
	
func _start_timer_safe() -> void:
	call_deferred("_deferred_start_timer")

func _deferred_start_timer() -> void:
	if _skipping:
		return
	if is_instance_valid(timer) and timer.is_inside_tree():
		timer.stop()
		timer.start(display_time)

func _skip_to_menu() -> void:
	if _skipping:
		return
	_skipping = true
	if is_instance_valid(timer) and timer.is_inside_tree():
		timer.stop()
	_go_menu()
	
func _go_menu():
	get_tree().change_scene_to_file("res://scenes/menus/main_menu/main_menu.tscn")
