class_name Item extends RefCounted

enum Rarity { NORMAL, MAGIC, RARE, UNIQUE }

enum Tag {
	WEAPON,
	SWORD,
	AXE,
	MACE,
	ONE_HANDED,
	TWO_HANDED,
	SHIELD,
	ARMOUR,
	HELMET,
	BODY,
	BOOT,
	GLOVE,
	JEWELRY,
	AMULET,
	RING,
	BELT,
	CHARM,
	CURRENCY,
	CONSUMABLE,
	GEM,
	RUNE,
	NULL,
	FLASK_LIFE,
	FLASK_MANA,
	QUIVER,
	BOW,
	DAGGER,
	CLAW,
	SCEPTRE,
	WAND
}

# --- Base Item (from Json data)
var id: String = ""
var name: String = ""
var item_level: int = 1
var tags: Array[Tag] = []
var size: Vector2i = Vector2i(1, 1)
var requirements: Dictionary = {
	"level": 1,
	"strength": 0,
	"dexterity": 0,
	"intelligence": 0
}
var icon_path: String = "" # Optional
var vendor_value: int = -1 # -1 if can't be seld
var stack_max: int = 1

# --- Instance Item (runtime and player save)
var rarity: Rarity = Rarity.NORMAL
var stack_current: int = 1 # <= stack_max
var mods: Array = []

# --- Loader
func load_json(json: Dictionary) -> void:
	id = str(json.get("id", id))
	name = str(json.get("name", name))
	item_level = int(json.get("item_level", item_level))
	requirements = json.get("requirements", requirements)
	icon_path = json.get("icon", "res://assets/textures/icon.svg")
	vendor_value = int(json.get("vendor_value", vendor_value))
	stack_max = int(json.get("stack_max", stack_max))
	stack_current = int(json.get("stack_current", clamp(stack_current, 1, stack_max)))
	
	# Size
	var s: Dictionary = json.get("size", size)
	size = Vector2i(int(s.get("width", 1)), int(s.get("height", 1)))
	
	# Rarity
	var rarity_found = str(json.get("rarity", "normal")).to_lower()
	match rarity_found:
		"magic": rarity = Rarity.MAGIC
		"rare": rarity = Rarity.RARE
		"unique": rarity = Rarity.UNIQUE
		_: rarity = Rarity.NORMAL
		
	# Tags
	tags.clear()
	for tag_found in json.get("tags", []):
		tags.append(self.convert_string_to_tag(tag_found))

# --- Tools
func clone() -> Item:
	var target := Item.new()
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
	target.mods = mods
	return target

func split_stack(count: int)	 -> Item:
	if stack_max <= 1:
		return null
		
	count = clamp(count, 1, stack_current)
	if count == stack_current:
		return null
		
	stack_current -= count
	var other := clone()
	other.stack_current = count
	return other
	
func to_modifiers() -> Array:
	var result: Array = []
	for mod in mods:
		if not mod.has("target") or not mod.has("form") or not mod.has("value"):
			continue
		result.append(StatEngineClass.create_modifier(mod["target"], mod["form"], mod["value"]))
	return result
	
static func convert_string_to_tag(tag: String) -> Tag:
	if Item.Tag.has(tag.to_upper()):
		return Item.Tag.get(tag.to_upper())
	return Tag.NULL
	
static func convert_tag_to_string(tag: Tag) -> String:
	return str(Tag.keys()[tag]).to_lower()
