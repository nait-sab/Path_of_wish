class_name Gem extends Item

const MAX_SUPPORTS_BASE: int = 2
const MAX_SUPPORTS_LIMIT: int = 5

var xp: int = 0
var xp_to_next: int = 100
var max_supports: int = MAX_SUPPORTS_BASE
var is_support: bool = false
var description: String = ""
var spirit_cost: int = 0
var allowed_weapon_tags: Array[Item.Tag] = []
var supports: Array[Gem] = []

func load_json(json: Dictionary) -> void:
	super.load_json(json)
	description = json.get("description", description)
	spirit_cost = json.get("spirit_cost", spirit_cost)
	
	# Allowed weapon tags
	allowed_weapon_tags.clear()
	for tag_found in json.get("allowed_weapon_tags", allowed_weapon_tags):
		allowed_weapon_tags.append(self.convert_string_to_tag(tag_found))

func can_add_support(_gem: Gem) -> bool:
	if supports.size() >= max_supports:
		return false
		
	# TODO rules like not same support
	
	return true
	
func add_support(gem: Gem) -> bool:
	if not can_add_support(gem):
		return false
	supports.append(gem)
	return true
	
func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		item_level += 1
		xp_to_next = int(xp_to_next * 1.5)

# --- Tools
func clone() -> Gem:
	var target = Gem.new()
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
	target.xp = xp
	target.xp_to_next = xp_to_next
	target.spirit_cost = spirit_cost
	target.allowed_weapon_tags = allowed_weapon_tags.duplicate(true)
	target.max_supports = max_supports
	for support in supports:
		target.supports.append(support.clone())
	return target
