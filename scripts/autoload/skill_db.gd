extends Node

const SKILLS_DIR := "res://data/skills"
const EXTENSION := ".tres"

## String => SkillResource
var _by_id: Dictionary = {}
var _all: Array[SkillResource] = []

func _ready() -> void:
	_load()

func _load() -> void:
	_by_id.clear()
	_all.clear()
	
	var dir := DirAccess.open(SKILLS_DIR)
	if dir == null:
		push_warning("[SKILL_DB] Missing dir %s" % SKILLS_DIR)
		return
	
	dir.list_dir_begin()
	while true:
		var dir_name := dir.get_next()
		if dir_name == "":
			break
		if dir.current_is_dir():
			continue
		var low := dir_name.to_lower()
		if not low.ends_with(EXTENSION):
			continue
		var path := SKILLS_DIR.path_join(dir_name)
		var resource := ResourceLoader.load(path)
		if resource == null:
			push_warning("[SKILL_DB] Failed to load %s" % path)
			continue
		if not resource is SkillResource:
			push_warning("[SKILL_DB] Resource isn't SkillResource at %s" % path)
			continue
		_register_skill(resource)
	
	dir.list_dir_end()
	print("[SKILL_DB] Init done -> %d items loaded" % _all.size())

func _register_skill(resource: SkillResource) -> void:
	_by_id[resource.id] = resource
	_all.append(resource)

# --- API
## List of SkillResource
func get_all() -> Array:
	return _all

func has(id: String) -> bool:
	return _by_id.has(id)

func get_skill(id: String) -> SkillResource:
	if not has(id):
		print("[SKILL_DB] ID not found : %s" % id)
		return null
	
	return _by_id.get(id)

func get_level(id: String, level: int) -> SkillLevelResource:
	if not has(id):
		print("[SKILL_DB] ID not found : %s" % id)
		return null
	
	var skill: SkillResource = _by_id.get(id)
	
	for level_infos: SkillLevelResource in skill.levels:
		if level_infos.level == level:
			return level_infos
	
	return null
