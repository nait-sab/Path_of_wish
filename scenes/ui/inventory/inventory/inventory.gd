class_name Inventory extends CanvasLayer

@export var equipment_control: Control
@export var grid: GridContainer
@export var held_icon: HeldItem
@export var gold_label: Label

var player: Player
var slots: Array = []
var equipment_slots: Array = []
var held_item: Item = null

func _ready():
	visible = false
	player = get_tree().get_first_node_in_group("Player") as Player
	gold_label.text = "Gold : %s" % str(player.gold)
	slots = grid.get_children()
	equipment_slots = _collect_equip_slots(equipment_control)
	
	# For debug !
	insert(ItemDb.instantiate_random([Item.Tag.SWORD], 1, Item.Rarity.RARE))
	insert(ItemDb.instantiate_random([Item.Tag.BOW], 1, Item.Rarity.RARE))
	insert(ItemDb.instantiate_random([Item.Tag.QUIVER], 1, Item.Rarity.RARE))
	insert(ItemDb.instantiate_random([Item.Tag.SHIELD], 1, Item.Rarity.RARE))
	insert(ItemDb.instantiate_random([Item.Tag.GLOVE], 1, Item.Rarity.RARE))
	insert(ItemDb.instantiate_random([Item.Tag.GLOVE], 1, Item.Rarity.RARE))
	insert(ItemDb.instantiate_random([Item.Tag.GLOVE], 1, Item.Rarity.RARE))
	insert(ItemDb.instantiate_random([Item.Tag.GLOVE], 1, Item.Rarity.RARE))

	connect_equip_slots()
	connect_slots()
	
	var world = get_parent()
	if world and world.has_signal("toggle_inventory"):
		world.connect("toggle_inventory", Callable(self, "toggle"))
		
func _index_to_col_row(index: int) -> Vector2i:
	return Vector2i(index % grid.columns, int(float(index) / grid.columns))
		
func _collect_equip_slots(root: Node) -> Array[EquipmentSlot]:
	var result: Array[EquipmentSlot] = []
	for child in root.get_children():
		if child is EquipmentSlot:
			result.append(child)
		else:
			result.append_array(_collect_equip_slots(child))
	return result
		
func connect_equip_slots():
	for slot: EquipmentSlot in equipment_slots:
		slot.pressed.connect(on_equipment_slot_clicked.bind(slot))
		
func connect_slots():
	for slot: InventorySlot in slots:
		slot.pressed.connect(on_slot_clicked.bind(slot))
		
func toggle():
	visible = not visible
	
func insert(item: Item):
	# Increase stackable items if possible
	if item.tags.has(Item.Tag.CURRENCY) and item.stack_max > 1:
		for slot in slots:
			if slot.item and slot.item.id == item.id:
				var item_found: Item = slot.item
				
				if item_found.stack_current < item_found.stack_max:
					var still_due_stack = item_found.stack_max - item_found.stack_current
					var quantity_to_add = min(still_due_stack, item.stack_current)
					item_found.stack_current += quantity_to_add
					item.stack_current -= quantity_to_add
					slot.refresh()
					if item.stack_current <= 0:
						return
				
	# Search a free slot for the full object
	var rows := int(ceil(float(slots.size()) / float(grid.columns)))
	for row in range(rows):
		for col in range(grid.columns):
			if can_place_item_at(col, row, item):
				place_item_at(col, row, item.clone())
				return
				
func on_equipment_slot_clicked(slot: EquipmentSlot):
	if held_item != null:
		var item := held_item
		if not slot.can_accept(item):
			return
		var previous := slot.take_item()
		slot.set_item(item)
		if previous:
			held_item = previous.clone()
			held_icon.set_item(held_item)
		else:
			held_icon.clear_item()
			held_item = null
		slot.update_ui()
	else:
		if slot.has_item():
			var taken := slot.take_item()
			held_item = taken.clone()
			held_icon.set_item(held_item)
			slot.update_ui()
	
func on_slot_clicked(slot: InventorySlot):
	if held_item == null:
		# Take a new item
		if slot.is_linked:
			slot = slot.master_slot
		if slot.item:
			held_item = slot.item.clone()
			slot.clear_item()
			held_icon.set_item(held_item)
	else:
		# Try to place or swap the item
		var index = slots.find(slot)
		var col = _index_to_col_row(index).x
		var row = _index_to_col_row(index).y
		
		# target is totally empty, just place the item
		if can_place_item_at(col, row, held_item):
			if place_item_at(col, row, held_item.clone()):
				held_icon.clear_item()
				held_item = null
				
			return
			
		# Check if the slots have only one master to swap
		var target_master := find_single_master_in_area(col, row, held_item)
		
		if target_master != null:
			var temp_item = target_master.item.clone()
			target_master.clear_item()
			
			if place_item_at(col, row, held_item.clone()):
				held_item = temp_item
				held_icon.set_item(temp_item.clone())
			else:
				var master_index := slots.find(target_master)
				var master_col = master_index % grid.columns
				var master_row = int(float(master_index) / grid.columns)
				place_item_at(master_col, master_row, temp_item.clone())
				
			return
			
		# Play audio to say it's impossible to move

func can_place_item_at(col: int, row: int, item: Item) -> bool:
	if col + item.size.x > grid.columns:
		return false
		
	if row + item.size.y > int(ceil(float(slots.size()) / float(grid.columns))):
		return false
	
	for y in range(item.size.y):
		for x in range(item.size.x):
			var index = (row + y) * grid.columns + (col + x)
			
			# No enough slots for the item
			if index >= slots.size():
				return false
			
			# A slot is occupied or used by a bigger item
			if slots[index].item or slots[index].is_linked: 
				return false

	return true
	
func place_item_at(col: int, row: int, item: Item):
	if not can_place_item_at(col, row, item):
		return false
		
	var master_index = row * grid.columns + col
	var master_slot: InventorySlot = slots[master_index]
	master_slot.is_master = true
	master_slot.linked_positions.clear()
	master_slot.set_item(item)
	
	for y in range(item.size.y):
		for x in range(item.size.x):
			var index = (row + y) * grid.columns + (col + x)
			if index == master_index:
				continue
				
			var linked_slot: InventorySlot = slots[index]
			linked_slot.is_linked = true
			linked_slot.master_slot = master_slot
			linked_slot.item = null
			linked_slot.texture_rect.visible = false
			linked_slot.amount_label.visible = false
			master_slot.linked_positions.append(linked_slot)
			
	return true
	
func find_single_master_in_area(col: int, row: int, item: Item) -> InventorySlot:
	var target_master: InventorySlot = null
	
	for y in range(item.size.y):
		for x in range(item.size.x):
			var index = (row + y) * grid.columns + (col + x)
			
			# Detect if we exit the grid
			if index < 0 or index >= slots.size():
				return null
				
			var slot: InventorySlot = slots[index]
			
			# ignore If empty or without link
			if slot.item == null and not slot.is_linked:
				continue
				
			# Get the master of the item
			var master := (slot.master_slot if slot.is_linked else slot)
			
			# Set the first master
			if target_master == null:
				target_master = master
				
			# Found a different master, block swap
			elif master != target_master:
				return null
	
	# return null or unique master
	return target_master
