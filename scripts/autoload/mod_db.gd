extends Node

var mods_by_id: Dictionary = {}
var mods_list: Array = []

func _ready():
	_load_all_mods()
	
func _load_all_mods():
	mods_by_id.clear()
	mods_list.clear()
	
	var dir_source = DirAccess.open("res://data/mods")
	if dir_source == null:
		push_warning("ModDB: data/mods can't be found")
		return
	_scan_dir(dir_source)
	
func _scan_dir(dir: DirAccess):
	dir.list_dir_begin()
	var dir_name = dir.get_next()
	while dir_name != "":
		if dir.current_is_dir() and dir_name not in [".", ".."]:
			var sub = DirAccess.open(dir.get_current_dir() + "/" + dir_name)
			if sub:
				_scan_dir(sub)
		elif dir_name.ends_with(".json"):
			var path = dir.get_current_dir() + "/" + dir_name
			_load_mod_file(path)
		dir_name = dir.get_next()
	dir.list_dir_end()
	
func _load_mod_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("ModDB: Can't read %s" % path)
		return

	var txt = file.get_as_text()
	file.close()
	
	var json = JSON.parse_string(txt)
	if typeof(json) == TYPE_ARRAY:
		for mod in json:
			_register_mod(mod)
	elif typeof(json) == TYPE_DICTIONARY:
		_register_mod(json)

func _register_mod(mod: Dictionary):
	if not mod.has("id"):
		push_warning("ModDB: Mod without id: %s" % str(mod))
		return
	mods_list.append(mod)
	mods_by_id[mod.id] = mod

func find_candidates(tags: Array, min_ilvl: int, want_type: String) -> Array:
	var result = []
	for mod in mods_list:
		if want_type != "" and mod.get("type", "") != want_type:
			continue
		if mod.get("min_item_level", 1) > min_ilvl:
			continue
		
		var mod_tags: Array = mod.get("tags", [])
		if mod_tags.is_empty():
			result.append(mod)
			continue
			
		var ok = false
		for tag in tags:
			if tag in mod_tags:
				ok = true
				break
		if ok:
			result.append(mod)

	return result

func _weighted_pick(items: Array, key_weight: String = "weight") -> Dictionary:
	if items.is_empty():
		return {}

	var total = 0.0
	for item in items:
		total += float(item.get(key_weight, 1))

	var random = randf() * total
	var acc = 0.0
	
	for item in items:
		acc += float(item.get(key_weight,1))
		if random <= acc:
			return item

	return items[items.size() - 1]

func roll_from_model(model: Dictionary, item_level: int) -> Dictionary:
	var tiers = model.get("tiers", [])
	if tiers.is_empty():
		push_warning("ModDB: Mod without any tier %s" % model.get("id", "?"))
		return {}
		
	# Filter tiers
	var valid_tiers = []
	for tier in tiers:
		if tier.has("min_item_level") and tier.min_item_level > item_level:
			continue
		valid_tiers.append(tier)

	if valid_tiers.is_empty():
		return {}

	var picked = _weighted_pick(valid_tiers)
	
	if picked.is_empty():
		return {}
	
	var value
	var minv = picked.get("min", 0)
	var maxv = picked.get("max", minv)
	
	# Mod with multiple values
	if typeof(minv) == TYPE_ARRAY:
		value = []
		for index in range(min(minv.size(), maxv.size())):
			var rolled = lerp(float(minv[index]), float(maxv[index]), randf())
			if model.get("value_type", "int") in ["int", "int[]"]:
				rolled = roundi(rolled)
			value.append(rolled)
		
		value = [
			clamp(value[0], int(minv[0]), int(minv[1])),
			clamp(value[1], int(maxv[0]), int(maxv[1]))
		]
		
		if value.size() == 2 and value[0] > value[1]:
			value = [value[1], value[0]]
		
	else:
		var rolled = lerp(float(minv), float(maxv), randf())
		if model.get("value_type", "int") == "int":
			rolled = roundi(rolled)
		value = rolled
	
	return {
		"id": model.id,
		"name": model.get("name", ""),
		"type": model.get("type", ""),
		"scope": model.get("scope", "local"),
		"target": model.get("target", ""),
		"form": model.get("form", "flat"),
		"value": value,
		"group": model.get("group", ""),
		"tier_min": minv,
		"tier_max": maxv,
		"tier_weight": picked.get("weight", 1),
		"tier_index": tiers.find(picked)
	}

func pick_n(kind: String, n: int, item_tags: Array, item_level: int, chosen: Array) -> void:
	var used_groups = {}
	var candidates = find_candidates(item_tags, item_level, kind)
	
	candidates.shuffle()
	while n > 0 and candidates.size() > 0:
		var model = _weighted_pick(candidates, "weight")

		var group = model.get("group", "")
		if group != "" and used_groups.has(group):
			candidates = candidates.filter(func(x): return x.get("group", "") != group)
			continue

		var rolled = roll_from_model(model, item_level)
		chosen.append(rolled)
		if group != "": 
			used_groups[group] = true
		candidates.erase(model)
		n -= 1

func roll_mods_for_item(item_tags: Array, item_level: int, rarity: Item.Rarity) -> Array:
	var rarity_caps = {
		Item.Rarity.NORMAL: { "prefix": 0, "suffix": 0 },
		Item.Rarity.MAGIC: { "prefix": 1, "suffix": 1 },
		Item.Rarity.RARE: { "prefix": 3, "suffix": 3 },
		Item.Rarity.UNIQUE: { "prefix": 0, "suffix": 0 }
	}
	var want = rarity_caps.get(rarity, { "prefix": 0, "suffix" : 0 })
	var chosen = []

	pick_n("prefix", want.prefix, item_tags, item_level, chosen)
	pick_n("suffix", want.suffix, item_tags, item_level, chosen)
	
	return chosen
