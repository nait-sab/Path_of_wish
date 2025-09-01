class_name ItemTooltip extends PanelContainer

@export var item_name: Label
@export var item_description: RichTextLabel

func _ready() -> void:
	add_to_group("ItemTooltip")
	visible = false
	
static func get_any() -> ItemTooltip:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("ItemTooltip") as ItemTooltip

func show_item(item: Item):
	clear()
	
	# Name / Rarity
	item_name.text = item.name
	item_name.add_theme_color_override("font_color", rarity_color(item.rarity))
	
	# Type
	if item.tags.has(Item.Tag.WEAPON):
		append_line("Arme - " + tags_to_strings(item.tags, [Item.Tag.WEAPON]))
	elif item.tags.has(Item.Tag.ARMOUR):
		append_line("Armure - " + tags_to_strings(item.tags, [Item.Tag.ARMOUR]))
	elif item.tags.has(Item.Tag.CURRENCY):
		append_line("Currency")
	elif item.tags.has(Item.Tag.GEM):
		append_line("Gemme de compétence", null, Color.CYAN)
	else:
		append_line("objet divers")
	
	# Caracteristics
	if item is Gear:
		_add_gear_properties(item as Gear)
	elif item is Gem:
		_add_gem_properties(item as Gem)
		
	_add_requirement(item)
	
	# Mods
	for mod in item.mods:
		var value = mod.value
		if typeof(value) == TYPE_ARRAY and value.size() == 2:
			append_line(mod.name, value)
		else:
			append_line(mod.name, value)
	
	# Value
	if item.vendor_value >= 0:
		append_line("Valeur : %d" % item.vendor_value, null, Color.YELLOW)
	else:
		append_line("Objet lié", null, Color(1, .3, .3))
		
	# Quantity
	if item.tags.has(Item.Tag.CURRENCY):
		append_line("Pile: %d / %d" % [item.stack_current, item.stack_max], null, Color(.7, .7, .7))
	
	call_deferred("_after_fill")
	visible = true
	
func _after_fill() -> void:
	if is_instance_valid(item_description):
		item_description.fit_content = true
	reset_size()
	
func hide_item():
	visible = false
	
func _process(_delta: float) -> void:
	if not visible:
		return
		
	var new_position = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var tooltip_size = size
	
	if new_position.x + tooltip_size.x > viewport_size.x:
		new_position.x = viewport_size.x - tooltip_size.x
	if new_position.y + tooltip_size.y > viewport_size.y:
		new_position.y = viewport_size.y - tooltip_size.y
		
	new_position.x = max(new_position.x, 0)
	new_position.y = max(new_position.y, 0)
	position = new_position

# --- Block Gear
func _add_gear_properties(gear: Gear):
	# Armour
	if gear.properties_final.has("armour"):
		append_line("Armure : %d" % int(gear.properties_final["armour"]))
		
	# Evasion
	if gear.properties_final.has("evasion_rating"):
		append_line("Evasion : %d" % int(gear.properties_final["evasion_rating"]))
		
	# Energy Shield
	if gear.properties_final.has("energy_shield"):
		append_line("Bouclier d'énergie : %d" % int(gear.properties_final["energy_shield"]))
	
	if gear.tags.has(Item.Tag.WEAPON):
		# Physical damages
		if gear.properties_final.has("physical_min") and gear.properties_final.has("physical_max"):
			var physical_range = gear.get_final_physical_range()
			append_line("Dégâts physiques : %d - %d" % [physical_range.x, physical_range.y])

		# Critical
		if gear.properties_final.has("critical_chance"):
			append_line("Chances de critique: %.1f%%" % gear.properties_final["critical_chance"])

		# Speed attack
		var speed_attack = gear.get_final_attack_speed()
		append_line("Attaques par seconde: %.1f" % speed_attack)
		
		# DPS total
		var dps = gear.get_final_dps()
		if dps > 0:
			append_line("DPS moyen: %d" % dps, null, Color(.6, 1, .6))
		
# --- Block Gem
func _add_gem_properties(gem: Gem):
	append_line("Niveau %d" % gem.item_level, null, Color(.5, .9, 1))
	if gem.spirit_cost > 0:
		append_line("Coût en esprit : %d" % gem.spirit_cost)
	if gem.description != "":
		append_line(gem.description, null, Color(.8, .8, .8))
		
# --- Block requirements
func _add_requirement(item: Item):
	var requirements = item.requirements
	var parts = []
	if requirements.get("level", 1) > 0:
		parts.append("Niveau requis : %d" % requirements.get("level", 1))
	if requirements.get("strength", 0) > 0:
		parts.append("Force %d" % requirements.get("strength", 1))
	if requirements.get("dexterity", 0) > 0:
		parts.append("Dextérité %d" % requirements.get("dexterity", 1))
	if requirements.get("intelligence", 0) > 0:
		parts.append("Intelligence %d" % requirements.get("intelligence", 1))
	if parts.size() > 0:
		append_line("Stats : " + ", ".join(parts), null, Color(.9, .3, .3))

# --- Helpers
func clear():
	item_description.clear()
	
func append_line(text: String, value: Variant = null, color: Color = Color.WHITE, big: bool = false):
	if value != null:
		var content = text.split('#')
		if content.size() == 3 and typeof(value) == TYPE_ARRAY:
			text = content[0] + str(value[0]) + content[1] + str(value[1]) + content[2] 
		else:
			if typeof(value) == TYPE_FLOAT:
				value = "%.1f" % value
			text = text.replace("#", str(value))
	
	if big:
		item_description.append_text("[center][b][color=%s]%s[/color][/b][/center]\n" % [
			color.to_html(), text
		])
	else:
		item_description.append_text("[color=%s]%s[/color]\n" % [
			color.to_html(), text
		])
		
func rarity_color(rarity: Item.Rarity) -> Color:
	match rarity:
		Item.Rarity.NORMAL: return Color.WHITE
		Item.Rarity.MAGIC: return Color(.3, .5, 1)
		Item.Rarity.RARE: return Color(1, 1, .3)
		Item.Rarity.UNIQUE: return Color(1, .5, .1)
		_: return Color.WHITE

func tags_to_strings(tags: Array, tags_ignored: Array = []) -> String:
	var list = []
	for tag in tags:
		if tags_ignored.has(tag):
			continue
		if typeof(tag) == TYPE_STRING:
			list.append(tag.capitalize())
		elif typeof(tag) == TYPE_INT:
			list.append(str(Item.Tag.keys()[tag]).capitalize())
	return " / ".join(list)
