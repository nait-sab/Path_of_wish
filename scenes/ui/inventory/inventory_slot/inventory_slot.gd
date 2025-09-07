class_name InventorySlot extends Button

@export var texture_rect: TextureRect
@export var skill_icon: SkillIcon
@export var amount_label: Label

var master_slot: Button = null
var is_master: bool = false
var is_linked: bool = false
var linked_positions: Array = []

var item: Item
var default_texture = preload("res://assets/textures/icon.svg")

const SLOT_SIZE: int = 48

func _ready():
	if item == null:
		clear()
	else:
		set_item(item)

func set_item(data: Item):
	item = data
	
	if item == null:
		clear()
		return
	
	texture_rect.visible = true
	skill_icon.visible = false
	
	if item is Gem:
		texture_rect.visible = false
		skill_icon.visible = true
		skill_icon.setupByTexture(item.get_icon_texture())
	else:
		texture_rect.texture = default_texture
	
	refresh()

	# Draw correctly the icon by item size
	if is_master:
		var panel: Panel = texture_rect.get_parent()
		panel.size = Vector2(
			item.size.x * InventorySlot.SLOT_SIZE,
			item.size.y * InventorySlot.SLOT_SIZE
		)
	else:
		texture_rect.visible = false
		skill_icon.visible = false
		amount_label.visible = false

func refresh():
	if item.stack_current > 1:
		amount_label.visible = true
		amount_label.text = str(item.stack_current)
	else:
		amount_label.visible = false

func clear():
	texture_rect.texture = null
	texture_rect.visible = true
	skill_icon.visible = false
	amount_label.visible = false

func clear_item():
	item = null
	master_slot = null
	is_master = false
	is_linked = false
	
	# Free linked slots
	for linked: InventorySlot in linked_positions:
		linked.is_linked = false
		linked.master_slot = null
		linked.texture_rect.visible = true
		linked.amount_label.visible = false
		linked.item = null
	
	linked_positions.clear()
	texture_rect.visible = true
	skill_icon.visible = false
	clear()

func _on_mouse_entered() -> void:
	var target: InventorySlot = master_slot if is_linked and master_slot else self
	if target.item:
		ItemTooltip.get_any().show_item(target.item, target)
	
func _on_mouse_exited() -> void:
	await get_tree().process_frame
	if _is_hovering_self_or_links():
		return
	
	var target: InventorySlot = master_slot if is_linked and master_slot else self
	ItemTooltip.get_any().request_hide(target)

func _is_hovering_self_or_links() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false
	var root: InventorySlot = master_slot if is_linked and master_slot else self
	if _is_over_slot_or_child(hovered, root):
		return true
	for slot in root.linked_positions:
		if _is_over_slot_or_child(hovered, slot):
			return true
	return false

func _is_over_slot_or_child(hovered: Control, slot: Control) -> bool:
	return hovered == slot or slot.is_ancestor_of(hovered)
