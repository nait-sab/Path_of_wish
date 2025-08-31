class_name SkillMath extends RefCounted

static func build_packet(skill: SkillInstance, _get_stat: Callable, main_hand: Gear) -> DamagePacket:
	# 1 - Get weapon stats
	var physical_range: Vector2 = Vector2.ZERO
	var attack_speed: float = 1.0
	
	if main_hand:
		physical_range = main_hand.get_final_physical_range()
		attack_speed = main_hand.get_final_attack_speed()
		
	# 2 - Split the skill damage types
	var base_physical := 0.0
	var base_fire := 0.0
	var base_cold := 0.0
	var base_lightning := 0.0
	var base_chaos := 0.0
	
	# Skill using weapon stats
	if skill.final.get("uses_weapon", false):
		var weapon_packet := float(skill.final.get("weapon_physical_percent", 0.0)) / 100.0
		if weapon_packet > 0.0 and physical_range != Vector2.ZERO:
			var hit_physical := randf_range(physical_range.x, physical_range.y)
			base_physical += hit_physical * weapon_packet
	
	# Skill with base damage (ex: spell)
	if skill.final.has("damage_base"):
		var data := skill.final["damage_base"] as Dictionary
		for key in data.keys():
			var value = data[key]
			var rolled := 0.0
			
			if typeof(value) == TYPE_ARRAY and value.size() == 2:
				rolled = randf_range(float(value[0]), float(value[1]))
			else:
				rolled = float(value)
			
			match str(key):
				"physical": 		base_physical += rolled
				"fire": 			base_fire += rolled
				"cold": 			base_cold += rolled
				"lightning": 	base_lightning += rolled
				"chaos": 		base_chaos += rolled
	
	# Supports
	var added_fire_percent := float(skill.final.get("added_fire_from_physical_percent", 0.0))
	if added_fire_percent != 0.0 and base_physical > 0.0:
		base_fire += base_physical * (added_fire_percent / 100.0)
		
	# TODO - Effectiveness coming from equipments
	#var effectiveness := float(skill.final.get("effectiveness_of_added_damage", 1.0))
	#base_fire += flat_fire_from_stats * effectiveness
	
	# 3 - Handle crit
	var critical_chance := float(skill.final.get("crit_chance_percent", 0.0))
	var is_critical := randf() < (critical_chance / 100.0)
	if is_critical:
		# TODO - Prepare critical stats on the player ! use 50% multiplier by default
		base_physical 	*= 1.5
		base_fire 		*= 1.5
		base_cold 		*= 1.5
		base_lightning 	*= 1.5
		base_chaos 		*= 1.5
		
	# 4 - Make the packet
	var packet := DamagePacket.new()
	packet.physical 		= max(base_physical, 0.0)
	packet.fire 			= max(base_fire, 0.0)
	packet.cold 			= max(base_cold, 0.0)
	packet.lightning 	= max(base_lightning, 0.0)
	packet.chaos 		= max(base_chaos, 0.0)
	
	return packet

static func build_packet_average(skill: SkillInstance, _get_stat: Callable, main_hand: Gear) -> DamagePacket:
	# 1 - Get weapon stats
	var physical_range: Vector2 = Vector2.ZERO
	var attack_speed: float = 1.0
	
	if main_hand:
		physical_range = main_hand.get_final_physical_range()
		attack_speed = main_hand.get_final_attack_speed()
		
	# 2 - Split the skill damage types
	var base_physical := 0.0
	var base_fire := 0.0
	var base_cold := 0.0
	var base_lightning := 0.0
	var base_chaos := 0.0
	
	# Skill using weapon stats
	if skill.final.get("uses_weapon", false):
		var weapon_packet := float(skill.final.get("weapon_physical_percent", 0.0)) / 100.0
		if weapon_packet > 0.0 and physical_range != Vector2.ZERO:
			var hit_physical := (float(physical_range.x) + float(physical_range.y)) * .5
			base_physical += hit_physical * weapon_packet
	
	# Skill with base damage (ex: spell)
	if skill.final.has("damage_base"):
		var data := skill.final["damage_base"] as Dictionary
		for key in data.keys():
			var value = data[key]
			var rolled := 0.0
			
			if typeof(value) == TYPE_ARRAY and value.size() == 2:
				rolled = (float(value[0]) + float(value[1])) *.5
			else:
				rolled = float(value)
			
			match str(key):
				"physical": 		base_physical += rolled
				"fire": 			base_fire += rolled
				"cold": 			base_cold += rolled
				"lightning": 	base_lightning += rolled
				"chaos": 		base_chaos += rolled
	
	# Supports
	var added_fire_percent := float(skill.final.get("added_fire_from_physical_percent", 0.0))
	if added_fire_percent != 0.0 and base_physical > 0.0:
		base_fire += base_physical * (added_fire_percent / 100.0)
		
	# TODO - Effectiveness coming from equipments
	#var effectiveness := float(skill.final.get("effectiveness_of_added_damage", 1.0))
	#base_fire += flat_fire_from_stats * effectiveness
	
	# 3 - Handle crit
	var critical_chance := float(skill.final.get("crit_chance_percent", 0.0))
	# TODO - Prepare critical stats on the player ! use 50% multiplier by default
	var critical_multiplier := 1.5
	var average_critical := 1.0 + (critical_multiplier - 1.0) * critical_chance
	
	base_physical 	*= average_critical
	base_fire 		*= average_critical
	base_cold 		*= average_critical
	base_lightning 	*= average_critical
	base_chaos 		*= average_critical
		
	# 4 - Make the packet
	var packet := DamagePacket.new()
	packet.physical 		= max(base_physical, 0.0)
	packet.fire 			= max(base_fire, 0.0)
	packet.cold 			= max(base_cold, 0.0)
	packet.lightning 	= max(base_lightning, 0.0)
	packet.chaos 		= max(base_chaos, 0.0)
	
	return packet

static func final_mana_cost(skill: SkillInstance, stat_get: Callable) -> int:
	var base := float(skill.final.get("mana_cost", 0))
	# TODO - Handle special stats like mana cost reduction, ect
	return int(round(base))
