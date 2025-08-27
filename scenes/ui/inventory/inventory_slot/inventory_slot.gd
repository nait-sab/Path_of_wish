class_name InventorySlot extends Button

@export var texture_rect: TextureRect
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

func set_item(data: Item):
	item = data
	
	if item == null:
		clear()
		return
	
	texture_rect.visible = true
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
		amount_label.visible = false

func refresh():
	if item.stack_current > 1:
		amount_label.visible = true
		amount_label.text = str(item.stack_current)
	else:
		amount_label.visible = false

func clear():
	texture_rect.texture = null
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
	clear()

func _on_mouse_entered() -> void:
	var target: InventorySlot = self
	
	if is_linked and master_slot:
		target = master_slot
		
	if target.item:
		ItemTooltip.get_any().show_item(target.item)
	
func _on_mouse_exited() -> void:
	var target: InventorySlot = self
	
	if is_linked and master_slot:
		target = master_slot
		
	var tooltip = ItemTooltip.get_any()
	
	if not target.is_mouse_over_any():
		tooltip.hide_item()
		
func is_mouse_over_any() -> bool:
	var mouse_position = get_global_mouse_position()
	
	if get_global_rect().has_point(mouse_position):
		return true
		
	for slot in linked_positions:
		if slot.get_global_rect().has_point(mouse_position):
			return true

	return false
