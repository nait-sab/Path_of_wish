class_name Devtool extends CanvasLayer

@export var root: Panel

func ready():
	if not OS.is_debug_build():
		queue_free()
		return

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("toggle_devtool"):
		_toggle()

func _on_debug_button_1_pressed() -> void:
	# TODO : Move the enemy spawn action here
	pass

func _on_debug_button_2_pressed() -> void:
	# TODO : Move the display of StatEngine here
	pass

func _on_exit_pressed() -> void:
	_toggle()

func _toggle() -> void:
	root.visible = not root.visible
