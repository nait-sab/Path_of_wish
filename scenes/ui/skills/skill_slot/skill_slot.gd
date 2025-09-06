class_name SkillSlot extends Button

@export_category("Data")
@export var keybind: String = "A"

@export_category("Components")
@export var keybind_label: Label
@export var skill_icon: SkillIcon
@export var skill_placeholder: Texture2D

var current_instance: SkillInstance

func _ready() -> void:
	keybind_label.text = keybind
	reset()
	await get_tree().current_scene.ready
	SkillsWindow.get_any().skills_changed.connect(_on_skills_changed)

func _on_pressed() -> void:
	SkillPicker.get_any().open(self)

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
