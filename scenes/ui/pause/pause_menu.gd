class_name PauseMenu extends Control

@export var options_window_scene : PackedScene

var _options_window : Control

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
	if _options_window == null or not is_instance_valid(_options_window):
		_options_window = options_window_scene.instantiate()
		add_child(_options_window)

func _on_quitter_pressed() -> void:
	# Clear StatEngine and reset data
	toggle()
	get_tree().paused = false
	
	var music: AudioStream = load("res://assets/music/island-of-the-lost-dark-fantasy-background-music.ogg")
	MusicManager.play_theme(music, true)
	
	get_tree().change_scene_to_file("res://scenes/menus/character_select/character_select.tscn")
	StatEngine.clear()
	Game.current_char = {}
