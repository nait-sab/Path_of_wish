extends CanvasLayer

func _ready():
	visible = false
	
	var world = get_parent()
	if world and world.has_signal("toggle_pause"):
		world.connect("toggle_pause", Callable(self, "toggle"))
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		toggle()
	
func toggle():
	visible = not visible
	
	if visible:
		get_tree().paused = true
		process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		get_tree().paused = false
		process_mode = Node.PROCESS_MODE_INHERIT

func _on_options_pressed() -> void:
	pass

func _on_quitter_pressed() -> void:
	# Clear StatEngine and reset data
	toggle()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/character_select/character_select.tscn")
	StatEngine.clear()
	Game.current_char = {}
