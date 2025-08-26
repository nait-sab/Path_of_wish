class_name StatEngineClass extends Node

signal stats_updated(final_stats: Dictionary)

# Modifier forms
enum ModifierForm { FLAT, INCREASED, MORE }

# Supported Stats
enum StatID {
	LIFE_MAX,
	MANA_MAX,
	ARMOUR,
	EVASION_RATING,
	ENERGY_SHIELD,
	RESISTANCE_FIRE,
	RESISTANCE_FIRE_MAX,
	RESISTANCE_COLD,
	RESISTANCE_COLD_MAX,
	RESISTANCE_LIGHTNING,
	RESISTANCE_LIGHTNING_MAX,
	RESISTANCE_CHAOS,
	RESISTANCE_CHAOS_MAX,
	LIFE_REGEN_PERCENT,
	MANA_REGEN_PERCENT,
	MOVE_SPEED_PERCENT,
	ATTACK_SPEED_PERCENT,
	BLOCK_CHANCE_PERCENT,
	GLOBAL_PHYSIQUE_INCREASE_PERCENT,
	NULL,
}

# Some stats are scalar (FLAT with increased then MORE)
# Other are just "base" : base * (1 + increased / 100) * more
const SCALAR_STATS: Dictionary = {
	StatID.LIFE_REGEN_PERCENT: true,
	StatID.MANA_REGEN_PERCENT: true,
	StatID.RESISTANCE_FIRE: true,
	StatID.RESISTANCE_FIRE_MAX: true,
	StatID.RESISTANCE_COLD: true,
	StatID.RESISTANCE_COLD_MAX: true,
	StatID.RESISTANCE_LIGHTNING: true,
	StatID.RESISTANCE_LIGHTNING_MAX: true,
	StatID.RESISTANCE_CHAOS: true,
	StatID.RESISTANCE_CHAOS_MAX: true,
	StatID.MOVE_SPEED_PERCENT: true,
	StatID.ATTACK_SPEED_PERCENT: true,
	StatID.GLOBAL_PHYSIQUE_INCREASE_PERCENT: true
}

# Name -> Array[Modifier]; Modifier = {stat: int, form: int, value: float)
var _sources: Dictionary = {}
# Final Cache StatId -> float
var _cache_final: Dictionary = {}

# --- Helpers
static func create_modifier(stat: Variant, form: Variant, value: float) -> Dictionary:
	var stat_id: int = (stat if typeof(stat) == TYPE_INT else _convert_stat_name_to_id(str(stat)))
	
	if stat_id == -1:
		push_warning("StatEngine: Unknow stat '%s'" % stat)
		return {}
		
	var form_id: int
	if typeof(form) == TYPE_INT:
		form_id = form
	else:
		match str(form).to_lower():
			"flat": form_id = ModifierForm.FLAT
			"increased": form_id = ModifierForm.INCREASED
			"more": form_id = ModifierForm.MORE
			_: form_id = -1
			
	if form_id == -1:
		push_warning("StatEngine: Unknow form '%s'" % form)
		return {}
		
	return { "stat": stat_id, "form": form_id, "value": float(value) }
	
# --- API
func clear() -> void:
	_sources.clear()
	_cache_final.clear()
	emit_signal("stats_updated", get_final_stats())
	
func set_source(source_name: String, modifiers: Array) -> void:
	var source: Array = []
	
	for modifier in modifiers:
		var mod = modifier
		if modifier is Array and modifier.size() == 3:
			mod = create_modifier(modifier[0], modifier[1], modifier[2])
		elif modifier is Dictionary:
			if not (modifier.has("stat") and modifier.has("form") and modifier.has("value")):
				push_warning("StatEngine: Bad modifier in '%s': %s" % [source_name, str(modifier)])
				continue
			mod = create_modifier(modifier.stat, modifier.form, modifier.value)
		else:
			push_warning("StatEngine: Bad modifier in '%s': %s" % [source_name, typeof(modifier)])
			continue
		if mod.is_empty():
			continue
		source.append(mod)
	
	_sources[source_name] = source
	recompute()
	
func clear_source(source_name: String) -> void:
	if _sources.erase(source_name):
		recompute()
		
func recompute() -> void:
	var flats: Dictionary = {}
	var increaseds: Dictionary = {}
	var mores: Dictionary = {}
	
	for modifiers in _sources.values():
		for modifier in modifiers:
			var sid: int = modifier.stat
			match modifier.form:
				ModifierForm.FLAT:
					flats[sid] = flats.get(sid, 0.0) + modifier.value
				ModifierForm.INCREASED:
					increaseds[sid] = increaseds.get(sid, 0.0) + modifier.value
				ModifierForm.MORE:
					mores[sid] = mores.get(sid, 1.0) * (1.0 + modifier.value / 100.0)
					
	_cache_final.clear()
	var all_stats: Dictionary = {}
	for key in flats.keys(): all_stats[key] = true
	for key in increaseds.keys(): all_stats[key] = true
	for key in mores.keys(): all_stats[key] = true
	
	for sid in all_stats.keys():
		if SCALAR_STATS.has(sid):
			var scalar := float(flats.get(sid, 0.0)) + float(increaseds.get(sid, 0.0))
			scalar *= float(mores.get(sid, 1.0))
			_cache_final[sid] = scalar
		else:
			var base := float(flats.get(sid, 0.0))
			var increased_multiplier := 1.0 + float(increaseds.get(sid, 0.0)) / 100.0
			var more_multiplier := float(mores.get(sid, 1.0))
			_cache_final[sid] = base * increased_multiplier * more_multiplier
			
	emit_signal("stats_updated", get_final_stats())
	
func get_stat(stat: Variant) -> float:
	var sid: int = (stat if typeof(stat) == TYPE_INT else _convert_stat_name_to_id(str(stat)))
	if sid == -1:
		return 0.0
	return float(_cache_final.get(sid, 0.0))
	
func get_final_stats() -> Dictionary:
	var result: Dictionary = {}
	for sid in _cache_final.keys():
		result[_convert_stat_id_to_name(sid)] = _cache_final[sid]
	return result

static func _convert_stat_name_to_id(stat: String) -> StatID:
	if StatID.has(stat.to_upper()):
		return StatID.get(stat.to_upper())
	return StatID.NULL
	
static func _convert_stat_id_to_name(stat: StatID) -> String:
	return str(StatID.keys()[stat]).to_lower()
