extends Node

var _list: Dictionary = {}

func _ready() -> void:
	if DataReader.list_categories().is_empty():
		DataReader.data_indexed.connect(load_data)
	else:
		load_data()

func load_data() -> void:
	_list.clear()
	var skills = DataReader.get_by_category("skills")
	for skill: Dictionary in skills:
		var id := str(skill.get("id", ""))
		if id == "":
			push_warning("[SKILL_DB] Skill without id -> skip")
			continue
		_list[id] = skill
	print("[SKILL_DB] Init done -> %d items loaded" % _list.size())

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
		push_warning("[SKILL_DB] Unknown id %s" % id)
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
