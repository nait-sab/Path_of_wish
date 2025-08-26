class_name Consumable extends Item

var is_consumable: bool = true

func load_json(json: Dictionary) -> void:
	super.load_json(json)
	is_consumable = json.get("consumable", true)
	
func use(_target = null) -> bool:
	if not is_consumable:
		return false
		
	if stack_max > 1:
		stack_current -= 1
		if stack_current < 0:
			stack_current = 0
	else:
		stack_current = 0
		
	print("Consumable used : %s, stack left : %s", [name, stack_current])
		
	# TODO action
	return true

# --- Tools
func clone() -> Consumable:
	var target = Consumable.new()
	target.id = id
	target.name = name
	target.item_level = item_level
	target.tags = tags.duplicate()
	target.size = size
	target.requirements = requirements.duplicate(true)
	target.icon_path = icon_path
	target.vendor_value = vendor_value
	target.stack_max = stack_max
	target.rarity = rarity
	target.stack_current = stack_current
	target.is_consumable = is_consumable
	target.mods = mods
	return target
