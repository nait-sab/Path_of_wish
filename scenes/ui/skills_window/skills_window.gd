class_name SkillsWindow extends Control

const SKILL_WINDOW_SLOT: PackedScene = preload("res://scenes/ui/skills_window/skill_slot/skill_window_slot.tscn")

@export var skill_slot_number: int = 5
@export var skill_slots_container: VBoxContainer

var dragging = false
var drag_offset = Vector2.ZERO

var _instances: Array[SkillInstance] = []

func _ready():
	visible = false
	add_to_group("SkillsWindow")
	
	Inventory.get_any().equipment_changed.connect(_on_equipment_changed)
	
	for child in skill_slots_container.get_children():
		child.queue_free()
		
	for _n in range(skill_slot_number):
		var instance = SKILL_WINDOW_SLOT.instantiate()
		skill_slots_container.add_child(instance)
		_instances.append(null)
		instance.connect("slot_changed", Callable(self, "_on_slot_changed"))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_skills_window"):
		_toggle()
		
func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var rect = Rect2(global_position, size)
			if rect.has_point(event.position):
				dragging = true
				drag_offset = event.position - global_position
		else:
			dragging = false
			
	if event is InputEventMouseMotion and dragging:
		var new_position = event.position - drag_offset
		var viewport_size = get_viewport().get_visible_rect().size
		new_position.x = clamp(new_position.x, 0, viewport_size.x - size.x)
		new_position.y = clamp(new_position.y, 0, viewport_size.y - size.y)
		global_position = new_position
		
static func get_any() -> SkillsWindow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("SkillsWindow") as SkillsWindow
	
func is_point_over(pos: Vector2) -> bool:
	return get_global_rect().has_point(pos)
	
func _toggle():
	visible = not visible

func _on_close_button_pressed() -> void:
	_toggle()
	
func _on_slot_changed(slot: SkillWindowSlot) -> void:
	var index = skill_slots_container.get_children().find(slot)
	if index == -1:
		return
	_instances[index] = slot.build_instance()
	_update_slot_header(slot, _instances[index])
	
func _on_equipment_changed() -> void:
	for index in range(skill_slots_container.get_child_count()):
		var slot: SkillWindowSlot = skill_slots_container.get_child(index)
		_instances[index] = slot.build_instance()
		_update_slot_header(slot, _instances[index])
	
func _update_slot_header(slot: SkillWindowSlot, instance: SkillInstance) -> void:
	if slot.skill_gem != null:
		slot.dps_button.text = "DPS : %s" % _estimate_dps(instance)

func _estimate_dps(instance: SkillInstance) -> int:
	var weapon = Inventory.get_any().get_main_weapon()
	var packet := SkillMath.build_packet_average(instance, Callable(StatEngine, "get_stat"), weapon)
	return roundi(packet.total())
