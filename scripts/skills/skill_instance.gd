class_name SkillInstance extends RefCounted

# Origin informations
var origin_gem: Gem
var level: int = 1
var is_support: bool = false
var origin_item_id: int = 0
## SkillResource or SupportResource
var resource: Resource
var skill_level: SkillLevelResource

# Final skill data
var id: String = ""
var name: String = ""
var icon: String = ""
var tags: Array[String] = []
var applies_to_tags: Array[String] = []
var xp_current: int = 0
var xp_to_next: int = 0

var uses_weapon: bool = false

var min_level: int = 0
var min_strength: int = 0
var min_dexterity: int = 0
var min_intelligence: int = 0
var mana_cost: int = 0
var attack_speed_scalar: float = 0.0
var cast_speed_scalar: float = 0.0
var weapon_physical_percent: float = 0.0
var crit_chance_percent: float = 0.0
var damage_base: Dictionary = {}
var radius: int = 0

# Modifiers
var added_fire_from_physical_percent: float = 0.0

func setup_from_gem(_gem: Gem) -> void:
	origin_gem = _gem
	level = max(1, int(origin_gem.item_level))
	is_support = origin_gem.support_id != ""
	origin_item_id = int(origin_gem.get_instance_id())

	if is_support:
		skill_level = SupportDb.get_level(origin_gem.support_id, level)
		resource = SupportDb.get_support(origin_gem.support_id)
	else:
		skill_level = SkillDb.get_level(origin_gem.skill_id, level)
		resource = SkillDb.get_skill(origin_gem.skill_id)

	_recompute()

func _recompute() -> void:
	id = resource.id
	name = origin_gem.name
	icon = origin_gem.icon_path
	xp_current = origin_gem.xp_current
	
	if resource is SkillResource:
		uses_weapon = resource.uses_weapon
		tags = resource.tags
	
	if resource is SupportResource:
		applies_to_tags = resource.applies_to_tags
	
	xp_to_next = skill_level.xp_to_next
	min_level = skill_level.min_level
	min_strength = skill_level.min_strength
	min_dexterity = skill_level.min_dexterity
	min_intelligence = skill_level.min_intelligence
	mana_cost = skill_level.mana_cost
	attack_speed_scalar = skill_level.attack_speed_scalar
	cast_speed_scalar = skill_level.cast_speed_scalar
	weapon_physical_percent = skill_level.weapon_physical_percent
	crit_chance_percent = skill_level.crit_chance_percent
	damage_base = skill_level.damage_base
	radius = skill_level.radius

func apply_supports(supports: Array[SkillInstance]) -> void:
	if is_support:
		return

	for support in supports:
		# Skip skill instance
		if not support.is_support:
			continue

		if support.applies_to_tags.is_empty():
			continue

		# Check compatibility tags
		var ok := false
		for tag in tags:
			if tag in support.applies_to_tags:
				ok = true
				break
		if not ok:
			continue

		var effects = support.skill_level.effects
		
		for key in effects.keys():
			match key:
				"mana_multiplier_percent":
					mana_cost = ceil(mana_cost * (effects[key] / 100.0))
				"added_fire_from_physical_percent":
					added_fire_from_physical_percent += effects[key]
				_:
					print("Support effect without any case: %s", str(key))

static func make_default_attack() -> SkillInstance:
	var instance := SkillInstance.new()
	instance.id = "default_attack"
	instance.name = "Attaque par défaut"
	instance.icon = "default_attack"
	instance.level = 1
	instance.cast_speed_scalar = 1.0
	instance.weapon_physical_percent = 100.0
	instance.uses_weapon = true
	instance.damage_base = {
		"physical": [2, 6]
	}
	return instance

func dump() -> void:
	print("--- SkillInstance ---")
	print("Gem: %s (level %d)" % [origin_gem.name, level])
	print("Support ?: %s" % str(is_support))
	print("Tags: ", tags)
	print("Applies: ", applies_to_tags)
	print("Mana Cost: ", mana_cost)
	print("Uses Weapon: ", uses_weapon)
	print("Weapon % Phys: ", weapon_physical_percent)
	print("Damage Base: ", damage_base)
	print("Radius: ", radius)
	print("Added Fire% Phys: ", added_fire_from_physical_percent)
	print("Min level", min_level)
	print("Min strength", min_strength)
	print("Min dexterity", min_dexterity)
	print("Min intelligence", min_intelligence)
	print("XP: %d / %d" % [xp_current, xp_to_next])
	print("---------------------")
