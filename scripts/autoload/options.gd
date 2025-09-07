extends Node

signal graphics_changed(options: Dictionary)
signal interface_changed(options: Dictionary)
signal audio_changed(options: Dictionary)
signal controls_changed(options: Dictionary)

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
	"controls": {
		# Flasks
		"flask_1": [{ "type": "key", "code": KEY_1 }],
		"flask_2": [{ "type": "key", "code": KEY_2 }],
		
		# Skills
		"skill_slot_1": [{ "type": "mouse", "button": MOUSE_BUTTON_LEFT }],
		"skill_slot_2": [{ "type": "mouse", "button": MOUSE_BUTTON_MIDDLE }],
		"skill_slot_3": [{ "type": "mouse", "button": MOUSE_BUTTON_RIGHT }],
		"skill_slot_4": [{ "type": "key", "code": KEY_A }],
		"skill_slot_5": [{ "type": "key", "code": KEY_E }],
		"skill_slot_6": [{ "type": "key", "code": KEY_R }],
		"skill_slot_7": [{ "type": "key", "code": KEY_T }],
		"skill_slot_8": [{ "type": "key", "code": KEY_Y }],
		
		# HUD
		"toggle_options": [{ "type": "key", "code": KEY_O }],
		"toggle_inventory": [{ "type": "key", "code": KEY_I }],
		"toggle_character_sheet": [{ "type": "key", "code": KEY_C }],
		"toggle_skills_window": [{ "type": "key", "code": KEY_G }],
	}
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
	apply_controls(current.get("controls", {}))

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

func apply_controls(options: Dictionary) -> void:
	for action in options.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for event in InputMap.action_get_events(action):
			InputMap.action_erase_event(action, event)
		
		var event_list: Array = options[action]
		for packed in event_list:
			var event := _dict_to_event(packed)
			if event != null:
				InputMap.action_add_event(action, event)
	
	controls_changed.emit(options)

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

static func _event_to_dict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var e := event as InputEventKey
		return {
			"type": "key",
			"code": e.keycode,
			"shift": e.shift_pressed,
			"ctrl": e.ctrl_pressed,
			"alt": e.alt_pressed,
			"meta": e.meta_pressed
		}
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		return {"type":"mouse", "button": mouse_button.button_index}
	return {}

static func _dict_to_event(data: Dictionary) -> InputEvent:
	var type := str(data.get("type",""))
	match type:
		"key":
			var key := InputEventKey.new()
			key.keycode = int(data.get("code", 0))
			key.shift_pressed = bool(data.get("shift", false))
			key.ctrl_pressed  = bool(data.get("ctrl", false))
			key.alt_pressed   = bool(data.get("alt", false))
			key.meta_pressed  = bool(data.get("meta", false))
			return key
		"mouse":
			var mouse_button := InputEventMouseButton.new()
			mouse_button.button_index = int(data.get("button", 1))
			return mouse_button
		_:
			return null

func get_action_bindings(action: String, from_pending: bool = true) -> Array:
	var root: Dictionary = (pending if from_pending else current)
	var data: Array = root.get("controls", {}).get(action, [])
	return data.duplicate(true)

func set_action_bindings(action: String, events_as_dict: Array) -> void:
	# Ecrase la liste de bindings pour cette action… dans pending
	var controls: Dictionary = pending.get("controls", {})
	controls[action] = events_as_dict.duplicate(true)
	pending["controls"] = controls

func rebind_single(action: String, event: InputEvent) -> void:
	set_action_bindings(action, [ _event_to_dict(event) ])

func clear_binding(action: String) -> void:
	set_action_bindings(action, [])

func reset_controls_to_defaults() -> void:
	pending["controls"] = _deep_copy(DEFAULTS["controls"])
	apply_pending()

func get_action_primary_event(action: String, from_pending: bool = true) -> InputEvent:
	var list := get_action_bindings(action, from_pending)
	if list.is_empty():
		return null
	return _dict_to_event(list[0])

func get_action_short_label(action: String, from_pending: bool = true) -> String:
	var event := get_action_primary_event(action, from_pending)
	if event == null:
		return "—"
	if event is InputEventMouseButton:
		var button_index := (event as InputEventMouseButton).button_index
		match button_index:
			MOUSE_BUTTON_LEFT:   return "LB"
			MOUSE_BUTTON_MIDDLE: return "MB"
			MOUSE_BUTTON_RIGHT:  return "RB"
			_: return "MB%d" % button_index
	elif event is InputEventKey:
		return OS.get_keycode_string((event as InputEventKey).keycode)
	return event.as_text()
