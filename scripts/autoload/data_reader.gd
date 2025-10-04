extends Node

signal data_indexed()

const ROOT_PATH := "res://data"
const JSON_EXTENSION := ".json"

const SKIP_CATEGORIES := {
	"skills": true,
	"supports": true,
}

var _collections: Dictionary = {}
# Debug
var _sources: Dictionary = {}

func _ready() -> void:
	reload()

# ----------------------------------------------
# API
# ----------------------------------------------

func reload() -> void:
	_collections.clear()
	_sources.clear()
	_scan_dir(ROOT_PATH)
	data_indexed.emit()
	
func list_categories() -> PackedStringArray:
	return PackedStringArray(_collections.keys())
	
func get_by_category(category: String) -> Array:
	var bucket: Dictionary = _collections.get(category, {})
	return bucket.values()
	
func get_one_by_category(category: String, id: String) -> Dictionary:
	var bucket: Dictionary = _collections.get(category, null)
	if bucket == null:
		return {}
	return bucket.get(id, {})
	
func find(category: String, predicate: Callable) -> Array:
	var result: Array = []
	var bucket: Dictionary = _collections.get(category, {})
	for entry in bucket.values():
		var ok := false
		if predicate.is_valid():
			ok = predicate.call(entry)
		if ok:
			result.append(entry)
	return result
	
func debug_print() -> void:
	print("[DataReader] --- Collections ---")
	for key in _collections.keys():
		print("  - ", key, " : ", _collections[key].keys().size(), " items")

# ----------------------------------------------
# SCAN / PARSE
# ----------------------------------------------

func _scan_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("[DataReader] Can't open dir %s" % path)
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		var full := path.path_join(entry)
		if dir.current_is_dir():
			_scan_dir(full)
		elif entry.to_lower().ends_with(JSON_EXTENSION):
			_index_json_file(full)
	dir.list_dir_end()
	
func _index_json_file(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_warning("[DataReader] Can't read file %s" % file_path)
		return
	var txt: String = file.get_as_text()
	file.close()
	
	var json: Variant = JSON.parse_string(txt)
	if json == null:
		push_warning("[DataReader] Invalid JSON format in %s" % file_path)
		return
		
	var category := _category_for(file_path)
	if category == "":
		return
	
	# Skip resources data
	if SKIP_CATEGORIES.has(category):
		return
	
	if not _collections.has(category):
		_collections[category] = {}
	
	match typeof(json):
		TYPE_ARRAY:
			_index_array_as_entries(category, json as Array, file_path)
		TYPE_DICTIONARY:
			_index_object_as_entry(category, json as Dictionary, file_path)
		_:
			push_warning("[DataReader] JSON ignored (type=%s) at %s" % [str(typeof(json)), file_path])

# ----------------------------------------------
# Helpers
# ----------------------------------------------

func _category_for(file_path: String) -> String:
	var relative := file_path.replace(ROOT_PATH + "/", "")
	var parts := relative.split("/")
	if parts.size() == 1 and relative.ends_with(JSON_EXTENSION):
		return _file_stem(relative)
	if parts.size() >= 1:
		return parts[0]
	return ""

func _index_array_as_entries(category: String, array: Array, file_path: String) -> void:
	for index in range(array.size()):
		var entry: Dictionary = array[index]
		
		if typeof(entry) != TYPE_DICTIONARY:
			push_warning("[DataReader] Data is not object -> ignored (%s #%d)" % [category, index])
			continue
			
		var id := str(entry.get("id", ""))
		if id == "":
			id = "%s_%d" % [_file_stem(file_path), index]
			push_warning("[DataReader] Date without id in %s => id='%s'" % [file_path, id])
		
		if _collections[category].has(id):
			push_warning("[DataReader] Id '%s' already exist in %s (old=%s, new=%s)" % [
				id, category, _sources.get("%s:%s" % [category, id], "??"), file_path
			])
			
		_collections[category][id] = entry
		_sources["%s:%s" % [category, id]] = file_path
	
func _index_object_as_entry(category: String, object: Dictionary, file_path: String) -> void:
	var id := str(object.get("id", ""))
	if id == "":
		id = _file_stem(file_path)
	if _collections[category].has(id):
		push_warning("[DataReader] id en double '%s' dans %s (ancien=%s, nouveau=%s)" % [
			id, category, _sources.get("%s:%s" % [category, id], "??"), file_path
		])
	_collections[category][id] = object
	_sources["%s:%s" % [category, id]] = file_path

# -------------------------------------------------------------------
# Tools
# -------------------------------------------------------------------

func _file_stem(file_path: String) -> String:
	var file_name := file_path.get_file()
	return file_name.substr(0, max(0, file_name.length() - JSON_EXTENSION.length()))
