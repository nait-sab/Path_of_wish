class_name SkillSlot extends Button

signal triggered(slot: SkillSlot)

@export_category("Data")
@export var action_name: String = ""

@export_category("Components")
@export var keybind_label: Label
@export var skill_icon: SkillIcon
@export var skill_placeholder: Texture2D

var current_instance: SkillInstance

func _ready() -> void:
	_refresh_bind_label()
	Options.controls_changed.connect(_on_controls_changed)
	reset()
	await get_tree().current_scene.ready
	SkillsWindow.get_any().skills_changed.connect(_on_skills_changed)

func _on_pressed() -> void:
	SkillPicker.get_any().open(self)

func _unhandled_input(event: InputEvent) -> void:
	if action_name != "" and event.is_action_pressed(action_name) and not event.is_echo() and current_instance != null:
		triggered.emit(self)
		print("Trigger %s" % current_instance.final.get("id", ""))

func reset() -> void:
	current_instance = null
	skill_icon.setupByTexture(skill_placeholder, SkillIcon.IconMode.SQUARE)

func apply_skill_instance(instance: SkillInstance) -> void:
	current_instance = instance
	skill_icon.setupById(instance.final.get("id", ""), SkillIcon.IconMode.SQUARE)

func _on_skills_changed() -> void:
	if current_instance == null:
		return
	if not SkillsWindow.get_any().get_instances().has(current_instance):
		reset()

func _on_controls_changed(_opts: Dictionary) -> void:
	_refresh_bind_label()

func _refresh_bind_label() -> void:
	if action_name != "":
		keybind_label.text = Options.get_action_short_label(action_name)
