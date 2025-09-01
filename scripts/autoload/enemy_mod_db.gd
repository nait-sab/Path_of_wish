extends Node

var mods_list: Array = []

const path := "res://data/enemy_mods.json"

func _ready() -> void:
	if DataReader.list_categories().is_empty():
		DataReader.data_indexed.connect(load_data)
	else:
		load_data()

func load_data() -> void:
	mods_list = DataReader.get_by_category("enemy_mods")
	print("[ENEMY_MOD_DB] Init done -> %d items loaded" % mods_list.size())
	
func roll_for_enemy(level: int, rarity: Item.Rarity = Item.Rarity.NORMAL) -> Array:
	var caps := {
		Item.Rarity.NORMAL: { "prefix": 0, "suffix": 0 },
		Item.Rarity.MAGIC:  { "prefix": 1, "suffix": 1 },
		Item.Rarity.RARE:   { "prefix": 3, "suffix": 3 },
		Item.Rarity.UNIQUE: { "prefix": 0, "suffix": 0 }
	}
	var want: Dictionary = caps.get(rarity, { "prefix": 0, "suffix": 0 })
	var chosen: Array = []
	chosen.append_array(_pick_mods(level, "prefix", want.prefix))
	chosen.append_array(_pick_mods(level, "suffix", want.suffix))
	return chosen
		
func _candidates(level: int, want_type: String) -> Array:
	var result: Array = []
	for mod in mods_list:
		if mod.get("type", "") != want_type:
			continue
		if mod.get("min_level", 1) > level:
			continue
		result.append(mod)
	return result
	
func _weighted_pick(items: Array) -> Dictionary:
	if items.is_empty():
		return {}

	var total = 0.0
	for item in items:
		total += float(item.get("weight", 1))

	var random = randf() * total
	var acc = 0.0
	
	for item in items:
		acc += float(item.get("weight",1))
		if random <= acc:
			return item
	return items[items.size() - 1]
	
func _roll_value(minv: float, maxv: float) -> float:
	var weight := randf()
	var value: float = lerp(minv, maxv, weight)
	return value
	
func _roll_one(model: Dictionary) -> Dictionary:
	var rolled_effects: Array = []
	for effect in model.get("effects", []):
		var minv := float(effect.get("min", 0))
		var maxv := float(effect.get("max", minv))
		var value_type := str(effect.get("value_type", "int"))
		var value := _roll_value(minv, maxv)
		
		if value_type == "int":
			value = roundi(value)
		
		rolled_effects.append({
			"stat": effect.get("stat",""),
			"form": effect.get("form","flat"),
			"value": value,
			"min": minv,
			"max": maxv,
			"value_type": value_type
		})
	return {
		"id": model.get("id",""),
		"name": model.get("name",""),
		"type": model.get("type","prefix"),
		"group": model.get("group",""),
		"effects": rolled_effects
	}
	
func _pick_mods(level: int, want_type: String, n: int) -> Array:
	var chosen: Array = []
	var used_groups: Dictionary = {}
	var pool := _candidates(level, want_type)
	pool.shuffle()
	
	while n > 0 and pool.size() > 0:
		var model := _weighted_pick(pool)
		var group: String = model.get("group","")
		if group != "" and used_groups.has(group):
			var new_pool: Array = []
			for x in pool:
				if x.get("group","") != group:
					new_pool.append(x)
			pool = new_pool
			continue
		chosen.append(_roll_one(model))
		if group != "":
			used_groups[group] = true
		pool.erase(model)
		n -= 1
	return chosen 
	
func _to_stat_modifiers(rolled: Array) -> Array:
	var mods: Array = []
	for mod in rolled:
		for effect in mod.get("effects", []):
			mods.append({
				"stat": effect.get("stat", ""),
				"form": effect.get("form", "flat"),
				"value": float(effect.get("value", 0))
			})
	return mods
