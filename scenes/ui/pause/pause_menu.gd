class_name PauseMenu extends Control

@export var options_window_scene : PackedScene

var _options_window : Control

func _ready():
	add_to_group("PauseMenu")
	visible = false

static func get_any() -> PauseMenu:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("PauseMenu") as PauseMenu

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		toggle()
		
	if event.is_action_pressed("toggle_options"):
		_on_options_pressed()

func open_options() -> void:
	_on_options_pressed()
	toggle()

func _has_windows() -> bool:
	return _options_window != null and is_instance_valid(_options_window)

func toggle() -> void:
	visible = not visible
	
	if visible:
		get_tree().paused = true
		process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		if _options_window:
			_options_window.queue_free()
		get_tree().paused = false
		process_mode = Node.PROCESS_MODE_INHERIT

func _on_options_pressed() -> void:
	if _options_window == null or not is_instance_valid(_options_window):
		_options_window = options_window_scene.instantiate()
		_options_window.tree_exited.connect(func (): _options_window = null)
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
