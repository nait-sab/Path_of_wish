extends Node

var _list: Dictionary = {}

func _ready() -> void:
	_load_data("res://data/skills")

func _load_data(root: String) -> void:
	_list.clear()
	var dir := DirAccess.open(root)
	if dir == null:
		push_warning("SkillDb: Can't found %s" % root)
		return
	_scan_dir(dir)

func _scan_dir(dir: DirAccess) -> void:
	dir.list_dir_begin()
	var dir_name := dir.get_next()
	while dir_name != "":
		if dir.current_is_dir() and dir_name not in [".",".."]:
			var sub := DirAccess.open(dir.get_current_dir() + "/" + dir_name)
			if sub: 
				_scan_dir(sub)
		elif dir_name.to_lower().ends_with(".json"):
			_load_file(dir.get_current_dir() + "/" + dir_name)
		dir_name = dir.get_next()
	dir.list_dir_end()

func _load_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("SkillDb: Can't found %s" % path)
		return
	var txt := file.get_as_text()
	file.close()
	var json: Dictionary = JSON.parse_string(txt)
	if typeof(json) != TYPE_DICTIONARY:
		push_warning("SkillDb: Incorrect JSON format, skill can't use a list")
		return
	var id := str(json.get("id", ""))
	if id == "":
		push_warning("SkillDb: Skill withresult id")
		return
	_list[id] = json

# --- Helpers
static func _as_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	elif typeof(value) == TYPE_STRING and value != "":
		return [value]
	return []

static func _pick_level_block(levels: Array, want_level: int) -> Dictionary:
	var best := {}
	var best_level := -1

	for level in levels:
		var skill_level := int(level.get("level", 1))
		if skill_level == want_level:
			return level
		if skill_level < want_level and skill_level > best_level:
			best_level = skill_level
			best = level
	if not best.is_empty():
		return best
	return levels[0] if levels.size() > 0 else {}

func get_skill(id: String, level: int) -> Dictionary:
	var model: Dictionary = _list.get(id, {})
	if model == {}:
		push_warning("SupportDb.get_support: unknown id %s" % id)
		return {}
	var result := {}
	result["id"] = model.get("id","")
	result["type"] = model.get("type", "support")
	result["tags"] = _as_array(model.get("tags", []))
	result["drop_level"] = int(model.get("drop_level", 1))
	result["uses_weapon"] = bool(model.get("uses_weapon", false))

	var levels: Array = model.get("levels", [])
	var skill_level := _pick_level_block(levels, level)
	# merge level fields into result
	for key in skill_level.keys():
		result[str(key)] = skill_level[key]

	# normalize some types
	if result.has("requirements"):
		var requirements: Dictionary = result["requirements"]
		result["requirements"] = {
			"level": int(requirements.get("level", 1)),
			"strength": int(requirements.get("strength", 0)),
			"dexterity": int(requirements.get("dexterity", 0)),
			"intelligence": int(requirements.get("intelligence", 0)),
		}
	if result.has("mana_cost"):
		result["mana_cost"] = int(result["mana_cost"])
	if result.has("xp_to_next"):
		result["xp_to_next"] = int(result["xp_to_next"])

	return result
