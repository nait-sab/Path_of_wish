class_name Gear extends Item

# Item base properties from json
var properties: Dictionary = {}

# Flat bonus from mods
var properties_final: Dictionary = {}

# Multipliers locaux par target
# Multipliers[target] = { increased: float, more: float }
var multipliers: Dictionary = {}

# --- Loading from json data
func load_json(json: Dictionary) -> void:
	super.load_json(json)
	properties = json.get("properties", properties)

# --- Tools
func clone() -> Gear:
	var target = Gear.new()
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
	target.properties = properties.duplicate(true)
	target.mods = mods.duplicate(true)
	target.properties_final = properties_final.duplicate(true)
	target.multipliers = multipliers.duplicate(true)
	return target
	
# --- Mods
func _reset_derived() -> void:
	multipliers.clear()
	properties_final = properties.duplicate(true)
	
func _add_increased(target: String, value: float) -> void:
	var entry: Dictionary = multipliers.get(target, { "increased": 0.0, "more": 1.0 })
	entry.increased += float(value)
	multipliers[target] = entry
	
func _add_more(target: String, value: float) -> void:
	var entry: Dictionary = multipliers.get(target, { "increased": 0.0, "more": 1.0 })
	entry.more *= (1.0 + float(value) / 100.0)
	multipliers[target] = entry

func apply_local_mods() -> void:
	# Reset item properties
	_reset_derived()
	
	for mod in mods:
		if mod.get("scope", "") != "local":
			continue
			
		var target = mod.get("target", "")

		match mod.get("form", ""):
			"flat":
				if target == "physical_min_max":
					var value = mod.value
					if typeof(value) == TYPE_ARRAY and value.size() == 2:
						var add_min := float(value[0])
						var add_max := float(value[1])
						properties_final["physical_min"] = float(properties_final.get("physical_min", 0.0)) + add_min
						properties_final["physical_max"] = float(properties_final.get("physical_max", 0.0)) + add_max
					else:
						properties_final[target] = float(properties_final.get(target, 0.0)) + float(mod.get("value", 0.0))

			"increased":
				_add_increased(target, float(mod.get("value", 0.0)))

			"more":
				_add_more(target, float(mod.get("value", 0.0)))
				
			_:
				push_warning("Gear: form of mod unknow %s from method (apply_local_mods)" % mod.form)

# --- Helpers
func _apply_multiplier(target: String, base: float) -> float:
	var multiplier = multipliers.get(target, null)
	if multiplier == null:
		return base
	return base * (1.0 + float(multiplier.increased) / 100.0) * float(multiplier.more)

# --- Calc methods
func get_final_attack_speed() -> float:
	var base = float(properties_final.get("attack_per_second", 1.0))
	return float("%.1f" % _apply_multiplier("attack_speed_percent", base))
	
func get_final_physical_range() -> Vector2:
	var minv := float(properties_final.get("physical_min", 0.0))
	var maxv := float(properties_final.get("physical_max", 0.0))	
	var multiplier = multipliers.get("physical_increased_percent", null)
	if multiplier != null:
		var multiplier_total = (1.0 + float(multiplier.increased) / 100.0) * float(multiplier.more)
		minv *= multiplier_total
		maxv *= multiplier_total
	return Vector2(roundi(minv),roundi(maxv))
	
func get_final_dps() -> int:
	var attack_speed = get_final_attack_speed()
	var physical_range = get_final_physical_range()
	var physical_average = (physical_range.x + physical_range.y) * .5
	
	# TODO Add other types of damage
	
	var total_average = physical_average
	var dps = total_average * attack_speed
	
	return roundi(dps)
