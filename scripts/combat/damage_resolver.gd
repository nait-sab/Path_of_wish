# Use exemple :
# var report = DamageResolver.resolve(defender_get, state, packet, { "is_broken": enemy.is_broken })
class_name DamageResolver extends RefCounted

# defender_get: Callable(String) -> float   (ex: Callable(StatEngine, "get_stat") or Callable(stat_block, "get_stat"))
# state: { "life": float, "es": float }     (opponent *common* values)
# options: { "is_broken": bool }            (status break => +40% damages dealed)

static func resolve(defender_get: Callable, defender_state: Dictionary, packet: DamagePacket, options: Dictionary =  {}) -> DamageReport:
	var report := DamageReport.new()
	
	# Initial snapshot
	report.before = {
		"physical": packet.physical,
		"fire": packet.fire,
		"cold": packet.cold,
		"lightning": packet.lightning,
		"chaos": packet.chaos,
	}
	
	# Handle special status
	if options.get("is_broken", false):
		# Status Break => +40% damages dealed
		for key in report.before.keys():
			report.before[key] = float(report.before[key]) * 1.40
			
	# 1 - Handle Evasion Rating
	var evasion_rating := float(defender_get.call("evasion_rating"))
	var evade_chance: float = clamp(evasion_rating / (evasion_rating + 100.0), 0.0, 0.95)
	if randf() < evade_chance:
		report.evaded = true
		report.after_block = report.before.duplicate()
		report.after_armour = report.after_block.duplicate()
		report.after_resistances = report.after_armour.duplicate()
		report.final_total = 0.0
		return report
		
	# 2 - Handle Block Chance (Exemple : Reduce 50% if success)
	var block_chance := float(defender_get.call("block_chance_percent"))
	var block_effectiveness := float(defender_get.call("block_effectiveness_percent"))
	if block_effectiveness <= 0.0:
		block_effectiveness = 50.0
	var blocked := (randf() < (block_chance / 100.0))
	report.blocked = blocked
	
	report.after_block = {}
	for key in report.before.keys():
		var value := float(report.before[key])
		if blocked:
			value *= (1.0 - block_effectiveness / 100.0)
		report.after_block[key] = value
			
	# 3 - Handle Armor (only for physical damages)
	var armour := float(defender_get.call("armour"))
	var physical_after := float(report.after_block["physical"])
	if physical_after > 0.0 and armour > 0.0:
		var reduction := armour / (armour + 5.0 * physical_after)
		physical_after *= (1.0 - reduction)
	report.after_armour = report.after_block.duplicate()
	report.after_armour["physical"] = physical_after
	
	# 4 - Handle resistance (only for elemental damages)
	var result := {}
	result["physical"] = report.after_armour["physical"]
	
	var res_fire := float(defender_get.call("resistance_fire"))
	var res_fire_max := float(defender_get.call("resistance_fire_max"))
	result["fire"] = _apply_resistance(float(report.after_armour["fire"]), res_fire, res_fire_max)
	
	var res_cold := float(defender_get.call("resistance_cold"))
	var res_cold_max := float(defender_get.call("resistance_cold_max"))
	result["cold"] = _apply_resistance(float(report.after_armour["cold"]), res_cold, res_cold_max)
	
	var res_lightning := float(defender_get.call("resistance_lightning"))
	var res_lightning_max := float(defender_get.call("resistance_lightning_max"))
	result["lightning"] = _apply_resistance(float(report.after_armour["lightning"]), res_lightning, res_lightning_max)
	
	var res_chaos := float(defender_get.call("resistance_chaos"))
	var res_chaos_max := float(defender_get.call("resistance_chaos_max"))
	result["chaos"] = _apply_resistance(float(report.after_armour["chaos"]), res_chaos, res_chaos_max)
	
	report.after_resistances = result
	
	# 5 - Handle energie shield then life
	var total := 0.0
	for key in report.after_resistances.keys():
		total += float(report.after_resistances[key])
		
	var energy_shield := float(defender_state.get("energy_shield", 0.0))
	var energy_shield_damage: float = min(total, energy_shield)
	var life_damage := total - energy_shield_damage
	
	report.applied_to_energy_shield = energy_shield_damage
	report.applied_to_life = life_damage
	report.final_total = total
	return report

static func _apply_resistance(value: float, resistance: float, resistance_max: float) -> float:
	var cap: float = min(resistance, resistance_max)
	return value * (1.0 - cap / 100.0)
