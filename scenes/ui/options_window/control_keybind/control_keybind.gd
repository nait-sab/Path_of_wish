class_name ControlKeybind extends HBoxContainer

signal changed(action_menu: String, new_events: Array)

@export var action_name: String
@export var action_label: Label
@export var bind_button: Button
@export var clear_button: Button

var _capturing := false
var _blocker: Control

func _ready() -> void:
	_update_button_text()

func _on_assign_bind_pressed() -> void:
	_capturing = true
	bind_button.text = "Appuyer sur une touch... (Esc pour annuler)"
	bind_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clear_button.visible = false
	_show_blocker()
	set_process_input(true)

func _on_clear_bind_pressed() -> void:
	_end_capture(false)
	Options.clear_binding(action_name)
	_update_button_text()
	changed.emit(action_name, Options.get_action_bindings(action_name))

func _input(event: InputEvent) -> void:
	if not _capturing:
		return
	
	get_viewport().set_input_as_handled()
	
	# Cancel keybind
	if event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_ESCAPE:
		_end_capture(false)
		return
	
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]:
			return
		Options.rebind_single(action_name, event)
		_end_capture(true)
		return
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
			return
		Options.rebind_single(action_name, event)
		_end_capture(true)
		return

func _end_capture(apply: bool) -> void:
	_capturing = false
	set_process_input(false)
	bind_button.mouse_filter = Control.MOUSE_FILTER_STOP
	clear_button.visible = true
	_hide_blocker()
	_update_button_text()
	if apply:
		changed.emit(action_name, Options.get_action_bindings(action_name))

func _update_button_text():
	var list: Array = Options.get_action_bindings(action_name)
	if list.is_empty():
		bind_button.text = "Non assigné"
		return
	var event: InputEvent = Options._dict_to_event(list[0])
	if event == null:
		bind_button.text = "Non assigné"
	elif event is InputEventKey:
		bind_button.text = (event as InputEventKey).as_text()
	else:
		bind_button.text = event.as_text()

func _show_blocker() -> void:
	if _blocker:
		return
	var control := Control.new()
	control.name = "KeybindBlocker"
	control.top_level = true
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	control.focus_mode = Control.FOCUS_ALL
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.gui_input.connect(func(_event): get_viewport().set_input_as_handled())
	get_viewport().add_child(control)
	_blocker = control

func _hide_blocker() -> void:
	if _blocker:
		_blocker.queue_free()
		_blocker = null
