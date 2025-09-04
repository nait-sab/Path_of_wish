extends Node

signal graphics_changed(options: Dictionary)
signal interface_changed(options: Dictionary)
signal audio_changed(options: Dictionary)

const SAVE_KEY := "settings"

# === Default Options ===
const DEFAULTS := {
	"graphics": {
		"window_mode": "windowed",
		"vsync": "enabled",
		"resolution": Vector2i(1920, 1080)
	},
	"game": {},
	"interface": {
		"show_clock": false,
		"confine_cursor": false,
		"show_resource_values": true
	},
	"audio": {
		"device": "Default",
		"master_volume": 100,
		"music_volume": 80
	},
	"controls": {}
}

var current: Dictionary = {}
var pending: Dictionary = {}

func _ready() -> void:
	 # Wait game window before start
	call_deferred("_boot_init")

func _boot_init() -> void:
	load_from_save()
	apply_all()
	pending = _deep_copy(current)

# -------------------------------------------------
# Persistance
# -------------------------------------------------

func load_from_save() -> void:
	var had_key: bool = Game.account.has(SAVE_KEY)
	var saved: Dictionary = Game.account.get(SAVE_KEY, {})
	
	current = _merge_with_defaults(saved)
	
	var graphics: Dictionary = current.get("graphics", {})
	if graphics.get("window_mode", "") == "fullscreen":
		graphics["window_mode"] = "borderless"
		current["graphics"] = graphics
	
	# If first time (no key or empty data) -> Save defauts settings
	if not had_key or saved.is_empty():
		Game.account[SAVE_KEY] = current
		SaveManager.save_account(Game.account)

func save_to_disk() -> void:
	Game.account[SAVE_KEY] = current
	SaveManager.save_account(Game.account)

# -------------------------------------------------
# API
# -------------------------------------------------

func get_option(path: String, from_pending: bool = true) -> Variant:
	var root: Dictionary = (pending if from_pending else current)
	return _get_by_path(root, path)

func set_pending(path: String, value: Variant) -> void:
	_set_by_path(pending, path, value)

func apply_pending() -> void:
	current = _deep_copy(pending)
	apply_all()
	save_to_disk()

func revert_pending() -> void:
	pending = _deep_copy(current)

func reset_to_defaults() -> void:
	pending = _deep_copy(DEFAULTS)

# -------------------------------------------------
# Global Apply
# -------------------------------------------------

func apply_all() -> void:
	apply_graphics(current.get("graphics", {}))
	apply_audio(current.get("audio", {}))
	apply_interface(current.get("interface", {}))

# -------------------------------------------------
# Apply
# -------------------------------------------------

func apply_graphics(options: Dictionary) -> void:
	var mode := str(options.get("window_mode", "windowed"))
	var saved_resolution: Variant = options.get("resolution", Vector2i(1920, 1080))
	var resolution: Vector2i = Converter.convert_value_to_vector2i(saved_resolution, Vector2i(1920, 1080))
	
	var vsync := str(options.get("vsync", "enabled"))
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync == "enabled" else DisplayServer.VSYNC_DISABLED
	)
	
	var window := get_window()
	var screen := DisplayServer.window_get_current_screen()
	var screen_position := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	
	match mode:
		"windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			window.size = resolution
			window.position = screen_position + (screen_size - resolution) / 2
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			window.size = screen_size
			window.position = screen_position
	
	graphics_changed.emit(options)

func apply_audio(options: Dictionary) -> void:
	var want_device := str(options.get("device", "Default"))
	var devices := AudioServer.get_output_device_list()
	var current_device := AudioServer.get_output_device()
	
	if want_device != "Default" and devices.has(want_device) and want_device != current_device:
		AudioServer.set_output_device(want_device)

	var volume : int = clamp(int(options.get("master_volume", 100)), 0, 100)
	AudioServer.set_bus_volume_db(0, linear_to_db(volume / 100.0))
	
	var music_index := AudioServer.get_bus_index("Music")
	if music_index != -1:
		var music_volume : int = clamp(int(options.get("music_volume", 80)), 0, 100)
		AudioServer.set_bus_volume_db(music_index, linear_to_db(music_volume / 100.0))
	
	audio_changed.emit(options)

func apply_interface(options: Dictionary) -> void:
	var confine := bool(options.get("confine_cursor", false))
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED if confine else Input.MOUSE_MODE_VISIBLE)
	
	interface_changed.emit(options)

# -------------------------------------------------
# Helpers
# -------------------------------------------------

func _merge_with_defaults(source: Dictionary) -> Dictionary:
	var data: Dictionary = _deep_copy(DEFAULTS)
	_deep_merge_into(data, source)
	return data

# Merge the source dictionary inside the base dictionary
func _deep_merge_into(base: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		var value = source[key]
		if base.has(key) and typeof(base[key]) == TYPE_DICTIONARY and typeof(value) == TYPE_DICTIONARY:
			_deep_merge_into(base[key], value)
		else:
			base[key] = value

func _deep_copy(value: Variant) -> Variant:
	return value.duplicate(true) if value is Array or value is Dictionary else value

# Get data path inside dictionary like "graphics/resolution"
func _get_by_path(root: Dictionary, path: String) -> Variant:
	var parts := path.split("/")
	var current_path: Variant = root
	for part in parts:
		if typeof(current_path) == TYPE_DICTIONARY and current_path.has(part):
			current_path = current_path[part]
		else:
			return null
	return current_path

func _set_by_path(root: Dictionary, path: String, value: Variant) -> void:
	var parts := path.split("/")
	var current_path: Variant = root
	for index in range(parts.size()):
		var key := parts[index]
		if index == parts.size() - 1:
			current_path[key] = value
		else:
			if not current_path.has(key) or typeof(current_path[key]) != TYPE_DICTIONARY:
				current_path[key] = {}
			current_path = current_path[key]
