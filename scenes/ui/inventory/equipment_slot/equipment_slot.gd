class_name EquipmentSlot extends Button

@export_category("Data")
@export var accept_tags: Array[Item.Tag] = []

@export_category("Data for main weapon slot")
@export var is_main_weapon_slot: bool = false
@export var second_weapon_slot: EquipmentSlot = null

@export_category("Data for second weapon slot")
@export var is_second_weapon_slot: bool = false
@export var main_weapon_slot: EquipmentSlot = null

@export_category("Components")
@export var texture_rect: TextureRect

var item: Item = null
var player : Player = null
var default_texture = load("res://assets/textures/icon.svg")

func _ready():
	player = get_tree().get_first_node_in_group("Player") as Player
	update_ui()
		
func set_item(new_item: Item) -> void:
	item = new_item
	_on_equip(item)
	update_ui()
	
func take_item() -> Item:
	var old := item
	if item != null:
		_on_unequip(item)
		item = null
		update_ui()
	return old
	
func has_item() -> bool:
	return item != null
	
func update_ui() -> void:
	if item:
		texture_rect.texture = load(item.icon_path)
		texture_rect.visible = true
	else:
		texture_rect.texture = null
		texture_rect.visible = false
	
func can_accept(cheked_item: Item) -> bool:
	if cheked_item == null:
		return false
		
	if not (cheked_item is Gear):
		return false
		
	if not _check_tags(cheked_item):
		return false
		
	if not _check_requirements(cheked_item):
		return false
		
	# No two handed weapon if the second hand isn't empty
	if is_main_weapon_slot and cheked_item.tags.has(Item.Tag.TWO_HANDED) \
	and second_weapon_slot != null and second_weapon_slot.item != null:
		return false
		
	# Special filter for lock quiver on second hand
	if is_main_weapon_slot and cheked_item.tags.has(Item.Tag.QUIVER):
		return false
		
	# Special filter for lock bow on main hand
	if is_second_weapon_slot and cheked_item.tags.has(Item.Tag.BOW):
		return false
	
	# No other item than a quiver if main hand is bow
	if is_second_weapon_slot and not cheked_item.tags.has(Item.Tag.QUIVER) \
	and main_weapon_slot.item != null and main_weapon_slot.item.tags.has(Item.Tag.BOW):
		return false
		
	# No quiver if main hand is empty or not a bow
	if is_second_weapon_slot and cheked_item.tags.has(Item.Tag.QUIVER):
		if main_weapon_slot.item == null or (main_weapon_slot.item != null and not main_weapon_slot.item.tags.has(Item.Tag.BOW)):
			return false
		
	return true
	
func get_equipped_main_hand() -> Gear:
	if main_weapon_slot != null:
		return main_weapon_slot.item
	return null

func _check_tags(checked_item: Item) -> bool:
	var valid := false
	
	for tag in checked_item.tags:
		if accept_tags.has(tag):
			valid = true
	
	return valid

func _check_requirements(checked_item: Item) -> bool:
	if checked_item == null:
		return false
		
	var requirements := checked_item.requirements
	if requirements.get("level", 1) > player.level: return false
	if requirements.get("strength", 1) > player.strength: return false
	if requirements.get("dexterity", 1) > player.dexterity: return false
	if requirements.get("intelligence", 1) > player.intelligence: return false
	
	return true

# --- Tooltip
func _on_mouse_entered() -> void:
	var target: EquipmentSlot = self
		
	if target.item:
		ItemTooltip.get_any().show_item(target.item)
	
func _on_mouse_exited() -> void:
	ItemTooltip.get_any().hide_item()

# --- StatEngine
func _on_equip(item_to_add: Item) -> void:
	if not item_to_add is Gear:
		return

	var mods_as_modifiers: Array = []
	
	# Save properties
	for key in item_to_add.properties_final.keys():
		var value = item_to_add.properties_final[key]
		
		match key:
			"armour":
				mods_as_modifiers.append(StatEngineClass.create_modifier("armour", StatEngine.ModifierForm.FLAT, value))
			"evasion":
				mods_as_modifiers.append(StatEngineClass.create_modifier("evasion", StatEngine.ModifierForm.FLAT, value))
			"energy_shield":
				mods_as_modifiers.append(StatEngineClass.create_modifier("energy_shield_max", StatEngine.ModifierForm.FLAT, value))
			"move_speed_percent":
				mods_as_modifiers.append(StatEngineClass.create_modifier("move_speed_percent", StatEngine.ModifierForm.INCREASED, value))
			"block_chance_percent":
				mods_as_modifiers.append(StatEngineClass.create_modifier("block_chance_percent", StatEngine.ModifierForm.FLAT, value))
			"armour":
				pass
	
	# Save all global modifiers
	for mod in item_to_add.mods:
		if mod.scope == "global":
			var modifier = StatEngineClass.create_modifier(mod.target, mod.form, mod.value)
			if not modifier.is_empty():
				mods_as_modifiers.append(modifier)
				
	if mods_as_modifiers.size() > 0:
		StatEngine.set_source("equip_" + str(item_to_add.id), mods_as_modifiers)
	
func _on_unequip(item_to_remove: Item) -> void:
	StatEngine.clear_source("equip_" + str(item_to_remove.id))
