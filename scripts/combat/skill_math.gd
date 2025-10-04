class_name SkillMath extends RefCounted

# --- API
static func build_packet(instance: SkillInstance, _get_stat: Callable, weapon: Gear) -> DamagePacket:
	var packet := DamagePacket.new()

	return _calculate_damage_packet(
		packet,
		instance,
		weapon,
		false
	)

static func build_packet_average(instance: SkillInstance, _get_stat: Callable, weapon: Gear) -> DamagePacket:
	var packet := DamagePacket.new()

	return _calculate_damage_packet(
		packet,
		instance,
		weapon,
		true
	)

static func final_mana_cost(skill: SkillInstance, _stat_get: Callable) -> int:
	var base := float(skill.mana_cost)
	# TODO - Handle special stats like mana cost reduction, ect
	return int(round(base))

# --- Helpers
static func _calculate_damage_packet(packet: DamagePacket, instance: SkillInstance, weapon: Gear, is_average: bool) -> DamagePacket:
	packet = _calculate_weapon_damage(packet, instance, weapon, is_average)
	packet = _calculate_damage_base(packet, instance, is_average)
	packet = _calculate_modifiers(packet, instance)
	packet = _calculate_critical(packet, instance, is_average)
	if is_average:
		packet = _calculate_weapon_speed(packet, instance, weapon)
	
	return packet

static func _calculate_weapon_damage(packet: DamagePacket, instance: SkillInstance, weapon: Gear, is_average: bool) -> DamagePacket:
	if not instance.uses_weapon or weapon == null:
		return packet
	
	var physical_range: Vector2 = weapon.get_final_physical_range()
	var physical_percent: float = instance.weapon_physical_percent / 100.0
	
	if physical_percent > 0.0 and physical_range != Vector2.ZERO:
		var physical_hit: float = 0.0
		if is_average:
			physical_hit = (float(physical_range.x) + float(physical_range.y)) / 2
		else:
			physical_hit = randf_range(float(physical_range.x), float(physical_range.y))
		packet.physical += physical_hit * physical_percent
	return packet

static func _calculate_damage_base(packet: DamagePacket, instance: SkillInstance, is_average: bool) -> DamagePacket:
	if instance.damage_base.is_empty():
		return packet
	
	for damage_type in instance.damage_base.keys():
		var value = instance.damage_base[damage_type]
		var roll = 0.0
		
		if typeof(value) == TYPE_ARRAY and value.size() == 2:
			if is_average:
				roll = (float(value[0]) + float(value[1])) / 2
			else:
				roll = randf_range(float(value[0]), float(value[1]))
		else:
			roll = float(value)
		
		match str(damage_type):
			"physical": packet.physical += roll
			"fire": packet.fire += roll
			"cold": packet.cold += roll
			"lightning": packet.lightning += roll
			"chaos": packet.chaos += roll
	return packet

static func _calculate_modifiers(packet: DamagePacket, instance: SkillInstance) -> DamagePacket:
	if instance.added_fire_from_physical_percent != 0.0 and packet.physical > 0.0:
		packet.fire += packet.physical * (instance.added_fire_from_physical_percent / 100.0)
	return packet

static func _calculate_critical(packet: DamagePacket, instance: SkillInstance, is_average: bool) -> DamagePacket:
	# TODO: Get the multiplier from player stats. 150% fixed for now
	var critical_multiplier = 150.0 / 100.0
	var is_critical: bool = randf() < (instance.crit_chance_percent / 100.0)
	var average_critical: float = 1.0 + (critical_multiplier - 1.0) * (instance.crit_chance_percent / 100.0)
	
	if is_critical and not is_average:
		packet.physical *= critical_multiplier
		packet.fire *= critical_multiplier
		packet.cold *= critical_multiplier
		packet.lightning *= critical_multiplier
		packet.chaos *= critical_multiplier
	if is_average:
		packet.physical *= average_critical
		packet.fire *= average_critical
		packet.cold *= average_critical
		packet.lightning *= average_critical
		packet.chaos *= average_critical
	return packet

static func _calculate_weapon_speed(packet: DamagePacket, instance: SkillInstance, weapon: Gear) -> DamagePacket:
	if weapon == null:
		return packet
	var speed := 1.0
	if instance.uses_weapon:
		speed = weapon.get_final_attack_speed() * instance.attack_speed_scalar
	else:
		speed = instance.cast_speed_scalar
	packet.physical *= speed
	packet.fire *= speed
	packet.cold *= speed
	packet.lightning *= speed
	packet.chaos *= speed
	return packet
