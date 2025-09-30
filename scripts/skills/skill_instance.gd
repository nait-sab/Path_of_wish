class_name SkillInstance extends RefCounted

var gem: Gem
var level: int = 1
var is_support: bool = false
var origin_item_id: int = 0

var def: Dictionary = {}
var final: Dictionary = {}
var applied_supports: Array[Dictionary] = []

func setup_from_gem(_gem: Gem) -> void:
	gem = _gem
	level = max(1, int(gem.item_level))
	is_support = gem.support_id != ""
	origin_item_id = int(gem.get_instance_id())

	if is_support:
		def = SupportDb.get_support(gem.support_id, level)
	else:
		def = SkillDb.get_skill(gem.skill_id, level)

	final = def.duplicate(true)
	final["gem_name"] = gem.name
	final["description"] = gem.description
	final["xp_current"] = gem.xp_current
	final["xp_to_next"] = gem.xp_to_next
	final["spirit_cost"] = gem.spirit_cost
	final["requirements"] = gem.requirements

func apply_supports(supports: Array[SkillInstance]) -> void:
	if is_support:
		return

	var base_tags: Array = final.get("tags", [])
	var mana_cost: float = final.get("mana_cost", 0)

	for support in supports:
		# Skip skill instance
		if not support.is_support:
			continue

		var applies_to: Array = support.final.get("applies_to_tags", [])
		if applies_to.is_empty():
			continue

		# Vérifie compatibilité tags
		var ok := false
		for tag in base_tags:
			if tag in applies_to:
				ok = true
				break
		if not ok:
			continue

		applied_supports.append(support.final)

		var effects: Dictionary = support.final.get("effects", {})
		for key in effects.keys():
			match key:
				"mana_multiplier_percent":
					mana_cost = ceil(mana_cost * (effects[key] / 100.0))
				"added_fire_from_physical_percent":
					final["added_fire_from_physical_percent"] = final.get("added_fire_from_physical_percent", 0) + effects[key]
				_:
					print("Support effect without any case: %s", str(key))
	
	final["mana_cost"] = mana_cost

static func make_default_attack() -> SkillInstance:
	var instance := SkillInstance.new()
	instance.final = {
		"id": "default_attack",
		"name": "Attaque par défaut",
		"icon": "default_attack",
		"level": "1",
		"cast_speed_scalar": 1.0,
		"weapon_physical_percent": 100.0,
		"uses_weapon": true,
		"unarmed_min": 2,
		"unarmed_max": 6,
	}
	return instance

func dump() -> void:
	print("--- SkillInstance ---")
	print("Gem: %s (level %d)" % [gem.name, level])
	print("Support ?: %s" % str(is_support))
	print("Tags / Applies: ", final.get("tags", final.get("applies_to_tags", [])))
	print("Mana Cost: ", final.get("mana_cost", 0))
	print("Uses Weapon: ", final.get("uses_weapon", false))
	if final.has("weapon_physical_percent"):
		print("Weapon % Phys: ", final["weapon_physical_percent"])
	if final.has("damage_base"):
		print("Damage Base: ", final["damage_base"])
	if final.has("radius"):
		print("Radius: ", final["radius"])
	if final.has("added_fire_from_physical_percent"):
		print("Added Fire% Phys: ", final["added_fire_from_physical_percent"])
	print("Reqs: ", final.get("requirements", {}))
	print("XP: %d / %d" % [final.get("xp_current",0), final.get("xp_to_next",0)])
	print("---------------------")
