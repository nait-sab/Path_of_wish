class_name Gem extends Item

var skill_id: String = ""
var icon_id: String = ""
var support_id: String = ""
var description: String = ""
var spirit_cost: int = 0
var xp_current: int = 0
var xp_to_next: int = 100
var allowed_weapon_tags: Array[Item.Tag] = []

func load_json(json: Dictionary) -> void:
	super.load_json(json)
	skill_id = json.get("skill_id", skill_id)
	icon_id = json.get("icon_id", icon_id)
	support_id = json.get("support_id", support_id)
	description = json.get("description", description)
	spirit_cost = json.get("spirit_cost", spirit_cost)
	xp_current = json.get("xp_current", xp_current)
	xp_to_next = json.get("xp_to_next", xp_to_next)
	
	# Allowed weapon tags
	allowed_weapon_tags.clear()
	for tag_found in json.get("allowed_weapon_tags", allowed_weapon_tags):
		allowed_weapon_tags.append(self.convert_string_to_tag(tag_found))

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
	target.skill_id = skill_id
	target.icon_id = icon_id
	target.support_id = support_id
	target.description = description
	target.spirit_cost = spirit_cost
	target.xp_current = xp_current
	target.xp_to_next = xp_to_next
	target.allowed_weapon_tags = allowed_weapon_tags.duplicate(true)
	return target

func get_icon_texture() -> Texture2D:
	return IconLoader.load_skill_icon(icon_id)
