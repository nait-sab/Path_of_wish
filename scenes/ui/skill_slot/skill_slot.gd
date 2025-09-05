class_name SkillSlot extends Button

@export_category("Data")
@export var keybind: String = "A"
@export var skill_icon: Texture2D

@export_category("Components")
@export var keybind_label: Label
@export var skill_texture: TextureRect
@export var skill_placeholder: Texture2D

var current_instance: SkillInstance

# Temporary variable
const TEMP_ICON = preload("res://assets/textures/ui/skill_slot/skill_placeholder.png")

func _ready() -> void:
	keybind_label.text = keybind

func _on_pressed() -> void:
	SkillPicker.get_any().open(self)

func reset() -> void:
	current_instance = null
	skill_texture.texture = TEMP_ICON
	skill_texture.modulate = Color(1, 1, 1)

func apply_skill_instance(instance: SkillInstance) -> void:
	current_instance = instance
	# Change to the real icon later and remove modulate
	skill_texture.texture = TEMP_ICON
	skill_texture.modulate = Color.from_hsv(randf(), .35, .95, 1)
