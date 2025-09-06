class_name OptionsWindow extends Control

@export_category("Graphismes")
@export var window_mode : OptionButton
@export var window_vsync : CheckBox
@export var window_resolution : OptionButton

@export_category("Jeu")

@export_category("Interface")
@export var see_clock : CheckBox
@export var isolate_cursor	: CheckBox
@export var see_life_and_mana : CheckBox

@export_category("Son")
@export var device : OptionButton
@export var general_volume : HSlider
@export var music_volume : HSlider

@export_category("Contrôles")
@export var controls_list: VBoxContainer
const CONTROL_KEYBIND_SCENE: PackedScene = preload("res://scenes/ui/options_window/control_keybind/control_keybind.tscn")
const CONTROL_ROWS := [
	# Flasks
	{ "label": "Utiliser le flacon N°1", "action": "flask_1" },
	{ "label": "Utiliser le flacon N°2", "action": "flask_2" },
	
	# Skills
	{ "label": "Utiliser l'aptitude N°1", "action": "skill_slot_1" },
	{ "label": "Utiliser l'aptitude N°2", "action": "skill_slot_2" },
	{ "label": "Utiliser l'aptitude N°3", "action": "skill_slot_3" },
	{ "label": "Utiliser l'aptitude N°4", "action": "skill_slot_4" },
	{ "label": "Utiliser l'aptitude N°5", "action": "skill_slot_5" },
	{ "label": "Utiliser l'aptitude N°6", "action": "skill_slot_6" },
	{ "label": "Utiliser l'aptitude N°7", "action": "skill_slot_7" },
	{ "label": "Utiliser l'aptitude N°8", "action": "skill_slot_8" },
	
	# HUD
	{ "label": "Options", "action": "toggle_options" },
	{ "label": "Inventaire", "action": "toggle_inventory" },
	{ "label": "Feuille de personnage", "action": "toggle_character_sheet" },
	{ "label": "Panneau des aptitudes", "action": "toggle_skills_window" },
]

func _ready() -> void:
	add_to_group("OptionsWindow")
	
	# Set settings value (ex: dropdowns)
	_populate_graphics()
	_populate_audio_devices()
	_populate_controls()
	_refresh_ui_from_pending()

static func get_any() -> OptionsWindow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("OptionsWindow") as OptionsWindow

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_options"):
		PauseMenu.get_any().open_options()

# -------------------------------------------------
# Helpers
# -------------------------------------------------

func _select_option_by_metadata(button: OptionButton, meta: Variant) -> void:
	for index in range(button.item_count):
		if button.get_item_metadata(index) == meta:
			button.select(index)
			return

# Lock resolution during borderless -> Handled by OS
func _update_resolution_state() -> void:
	var mode := str(Options.get_option("graphics/window_mode"))
	window_resolution.disabled = (mode == "borderless")

func _refresh_ui_from_pending() -> void:
	# --- Graphismes
	var mode := str(Options.get_option("graphics/window_mode"))
	_select_option_by_metadata(window_mode, mode)

	var vsync := str(Options.get_option("graphics/vsync"))
	window_vsync.button_pressed = (vsync == "enabled")

	var actual_resolution = Options.get_option("graphics/resolution")
	var resolution = Converter.convert_value_to_vector2i(actual_resolution, Vector2i(1920, 1080))
	_select_option_by_metadata(window_resolution, resolution)

	# --- Interface
	see_clock.button_pressed = bool(Options.get_option("interface/show_clock"))
	isolate_cursor.button_pressed = bool(Options.get_option("interface/confine_cursor"))
	see_life_and_mana.button_pressed = bool(Options.get_option("interface/show_resource_values"))

	# --- Son
	var actual_device := str(Options.get_option("audio/device"))
	_select_option_by_metadata(device, actual_device)
	general_volume.value = int(Options.get_option("audio/master_volume"))
	music_volume.value = int(Options.get_option("audio/music_volume"))
	
	_update_resolution_state()

# -------------------------------------------------
# Populates
# -------------------------------------------------

func _populate_graphics() -> void:
	window_mode.clear()
	window_mode.add_item("Fenêtré")
	window_mode.add_item("Fenêtré plein écran")
	window_mode.set_item_metadata(0, "windowed")
	window_mode.set_item_metadata(1, "borderless")

	# Resolution
	var screen := DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen)
	
	var resolutions: Array[Vector2i] = [
		Vector2i(1280, 720),
		Vector2i(1366, 768),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1080), # Ultrawide only
		Vector2i(2560, 1440),
		Vector2i(3440, 1440), # Ultrawide only
		Vector2i(3840, 1600), # Ultrawide only
		Vector2i(3840, 2160),
	]
	
	if not resolutions.has(screen_size):
		resolutions.append(screen_size)
		
	var filtered: Array[Vector2i] = []
	var seen := {}
	for resolution in resolutions:
		if resolution.x >= 1280 and resolution.y >= 720 and resolution.x <= screen_size.x and resolution.y <= screen_size.y:
			var key := "%dx%d" % [resolution.x, resolution.y]
			if not seen.has(key):
				seen[key] = true
				filtered.append(resolution)
	
	filtered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return int(a.x) * int(a.y) < int(b.x) * int(b.y)
	)

	window_resolution.clear()
	for resolution in filtered:
		window_resolution.add_item("%dx%d" % [resolution.x, resolution.y])
		window_resolution.set_item_metadata(window_resolution.item_count - 1, resolution)

func _populate_audio_devices() -> void:
	device.clear()
	
	var seen := {}
	
	device.add_item("Default")
	device.set_item_metadata(0, "Default")
	seen["Default"] = true
	
	var index := 1
	for device_found in AudioServer.get_output_device_list():
		if seen.has(device_found):
			continue
		device.add_item(device_found)
		device.set_item_metadata(index, device_found)
		index += 1

func _populate_controls() -> void:
	for control in controls_list.get_children():
		control.queue_free()
	
	for row in CONTROL_ROWS:
		var control :=CONTROL_KEYBIND_SCENE.instantiate()
		control.action_name = row["action"]
		control.action_label.text = row["label"]
		controls_list.add_child(control)

# -------------------------------------------------
# Graphics options
# -------------------------------------------------

func _on_window_mode_selected(index: int) -> void:
	var meta = window_mode.get_item_metadata(index)
	Options.set_pending("graphics/window_mode", meta)
	_update_resolution_state()

func _on_window_vsync_pressed() -> void:
	var value := "enabled" if window_vsync.button_pressed else "disabled"
	Options.set_pending("graphics/vsync", value)

func _on_window_resolution_selected(index: int) -> void:
	var meta = window_resolution.get_item_metadata(index)
	Options.set_pending("graphics/resolution", meta)

# -------------------------------------------------
# Interface options
# -------------------------------------------------

func _on_see_clock_pressed() -> void:
	Options.set_pending("interface/show_clock", see_clock.button_pressed)
	
func _on_isolate_cursor_pressed() -> void:
	Options.set_pending("interface/confine_cursor", isolate_cursor.button_pressed)
	
func _on_see_life_mana_pressed() -> void:
	Options.set_pending("interface/show_resource_values", see_life_and_mana.button_pressed)
	
# -------------------------------------------------
# Sound options
# -------------------------------------------------

func _on_audio_device_selected(index: int) -> void:
	var meta := str(device.get_item_metadata(index))
	Options.set_pending("audio/device", meta)

func _on_general_volume_value_changed(value: float) -> void:
	Options.set_pending("audio/master_volume", int(round(value)))

func _on_music_volume_value_changed(value: float) -> void:
	Options.set_pending("audio/music_volume", int(round(value)))
	
# -------------------------------------------------
# Controls options
# -------------------------------------------------

func _on_reset_controls_pressed() -> void:
	Options.reset_controls_to_defaults()
	_populate_controls()

# -------------------------------------------------
# Bottom buttons
# -------------------------------------------------

func _on_save_pressed() -> void:
	Options.apply_pending()
	_refresh_ui_from_pending()
	
func _on_default_pressed() -> void:
	Options.reset_to_defaults()
	Options.apply_pending()
	_refresh_ui_from_pending()
	
func _on_close_button_pressed() -> void:
	_close_window()

func _on_close_pressed() -> void:
	_close_window()

func _close_window():
	Options.revert_pending()
	queue_free()
