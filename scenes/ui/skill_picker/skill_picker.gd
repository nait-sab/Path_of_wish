class_name SkillPicker extends Control

@export var window: PanelContainer
@export var grid: GridContainer

var skill_slot: SkillSlot

# Temporary variable
const TEMP_ICON = preload("res://assets/textures/ui/skill_slot/skill_placeholder.png")

func _ready() -> void:
	add_to_group("SkillPicker")
	visible = false
	await get_tree().current_scene.ready
	
	SkillsWindow.get_any().skills_changed.connect(_build_grid)
	window.resized.connect(func(): if visible: _move_to_slot())

func open(slot: SkillSlot) -> void:
	if visible and skill_slot == slot:
		close()
		return
	skill_slot = slot
	visible = true
	_build_grid()
	await get_tree().process_frame
	_move_to_slot()

func close() -> void:
	skill_slot = null
	visible = false

static func get_any() -> SkillPicker:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("SkillPicker") as SkillPicker

func _build_grid() -> void:
	for slot in grid.get_children():
		slot.queue_free()
	
	var skills = SkillsWindow.get_any().get_instances()
	
	for skill in skills:
		if skill == null:
			continue
		var skill_button := TextureButton.new()
		skill_button.custom_minimum_size = Vector2(48, 48)
		
		# Tempory until I add icons to skills
		skill_button.texture_normal = TEMP_ICON
		skill_button.modulate = Color.from_hsv(randf(), .35, .95, 1)
		
		skill_button.pressed.connect(func(): _on_select_skill(skill))
		grid.add_child(skill_button)
	
	await get_tree().process_frame
	if visible:
		_move_to_slot()

func _on_select_skill(instance: SkillInstance):
	skill_slot.apply_skill_instance(instance)
	close()

func _on_clear_button_pressed() -> void:
	skill_slot.current_instance = null
	close()

func _move_to_slot() -> void:
	if skill_slot == null:
		return
	
	var slot_rect := skill_slot.get_global_rect()
	var screen_rect := get_viewport().get_visible_rect()
	var pos := Vector2(
		slot_rect.position.x - window.size.x / 2 + slot_rect.size.x / 2, 
		slot_rect.position.y - window.size.y
	)
	if pos.x + window.size.x > screen_rect.size.x:
		pos.x = max(0.0, slot_rect.end.x - window.size.x)
	global_position = pos

func is_point_over(pos: Vector2) -> bool:
	return window.get_global_rect().has_point(pos)
