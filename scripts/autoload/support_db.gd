extends Node

const SUPPORTS_DIR := "res://data/supports"
const EXTENSION := ".tres"

## String => SupportResource
var _by_id: Dictionary = {}
var _all: Array[SupportResource] = []

func _ready() -> void:
	_load()

func _load() -> void:
	_by_id.clear()
	_all.clear()
	
	var dir := DirAccess.open(SUPPORTS_DIR)
	if dir == null:
		push_warning("[SUPPORT_DB] Missing dir %s" % SUPPORTS_DIR)
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
		var path := SUPPORTS_DIR.path_join(dir_name)
		var resource := ResourceLoader.load(path)
		if resource == null:
			push_warning("[SUPPORT_DB] Failed to load %s" % path)
			continue
		if not resource is SupportResource:
			push_warning("[SUPPORT_DB] Resource isn't SupportResource at %s" % path)
			continue
		_register_support(resource)
	
	dir.list_dir_end()
	print("[SUPPORT_DB] Init done -> %d items loaded" % _all.size())

func _register_support(resource: SupportResource) -> void:
	_by_id[resource.id] = resource
	_all.append(resource)

# --- API
## List of SupportResource
func get_all() -> Array:
	return _all

func has(id: String) -> bool:
	return _by_id.has(id)

func get_support(id: String) -> SupportResource:
	if not has(id):
		print("[SUPPORT_DB] ID not found : %s" % id)
		return null
	
	return _by_id.get(id)

func get_level(id: String, level: int) -> SkillLevelResource:
	if not has(id):
		print("[SUPPORT_DB] ID not found : %s" % id)
		return null
	
	var support: SupportResource = _by_id.get(id)
	
	for level_infos: SkillLevelResource in support.levels:
		if level_infos.level == level:
			return level_infos
	
	return null
