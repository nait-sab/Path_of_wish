class_name SkillWindowSlot extends VBoxContainer

signal slot_changed(slot: SkillWindowSlot)

@export var default_support_count: int = 2

@export_category("Skill infos")
@export var skill_icon: TextureRect
@export var skill_name: Label
@export var skill_level: Label
@export var dps_button: Button

@export_category("Slots")
@export var skill_slot: TextureButton
@export var support_slots: Array[TextureButton]

var skill_gem: Gem = null
var support_gems: Array[Gem] = []

func _ready() -> void:
	support_gems.clear()
	for _i in range(support_slots.size()):
		support_gems.append(null)
		
	skill_slot.pressed.connect(_on_skill_slot_pressed)
	for index in range(support_slots.size()):
		support_slots[index].pressed.connect(func(): _on_support_slot_pressed(index))
	
	refresh_ui()
	
func refresh_ui() -> void:
	if skill_gem:
		skill_icon.texture = preload("res://assets/textures/icon.svg")
		skill_slot.texture_normal = preload("res://assets/textures/icon.svg")
		skill_name.text = skill_gem.name
		skill_level.text = "Niveau : %d" % int(max(1, skill_gem.item_level))
		dps_button.visible = true
		dps_button.text = "DPS : --"
	else:
		skill_icon.texture = null
		skill_slot.texture_normal = null
		skill_name.text = ""
		skill_level.text = ""
		dps_button.visible = false
		dps_button.text = ""
		
	for index in range(support_slots.size()):
		var button := support_slots[index]
		var gem := support_gems[index]
		var unlocked := (index > default_support_count)
		button.disabled = unlocked
		if gem:
			button.texture_normal = preload("res://assets/textures/icon.svg")
		else:
			button.texture_normal = null

func _on_skill_slot_pressed() -> void:
	var held_item := HeldItem.get_any().item
	
	if held_item and held_item is Gem and (held_item as Gem).skill_id != "":
		var new_skill := held_item as Gem
		var old := skill_gem
		skill_gem = new_skill
		if old:
			HeldItem.get_any().set_item(old)
		else:
			HeldItem.get_any().clear_item()
			
		# TODO - Use this when we can check inventory to throw all support inside
		#for index in range(support_gems.size()):
		#	support_gems[index] = null
		
		refresh_ui()
		slot_changed.emit(self)
		return
		
	if held_item == null and skill_gem != null:
		HeldItem.get_any().set_item(skill_gem)
		skill_gem = null
		refresh_ui()
		slot_changed.emit(self)
		return
		
func _on_support_slot_pressed(index: int) -> void:
	if index >= default_support_count:
		return
		
	# TODO - Use this when we can check inventory to throw all support inside
	#if skill_gem == null:
	#	return

	var held_item := HeldItem.get_any().item
	
	if held_item and held_item is Gem and (held_item as Gem).support_id != "":
		var new_skill := held_item as Gem
		var old := support_gems[index]
		support_gems[index] = new_skill
		if old:
			HeldItem.get_any().set_item(old)
		else:
			HeldItem.get_any().clear_item()		
		refresh_ui()
		slot_changed.emit(self)
		return
		
	if held_item == null and support_gems[index] != null:
		HeldItem.get_any().set_item(support_gems[index])
		support_gems[index] = null
		refresh_ui()
		slot_changed.emit(self)
		return
		
func build_instance() -> SkillInstance:
	if skill_gem == null:
		return null
	
	var instance = SkillInstance.new()
	instance.setup_from_gem(skill_gem)
	
	var supports: Array[SkillInstance] = []
	for gem in support_gems:
		if gem != null:
			var support := SkillInstance.new()
			support.setup_from_gem(gem)
			supports.append(support)
			
	instance.apply_supports(supports)
	return instance
