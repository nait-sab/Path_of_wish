extends Node

const ACCOUNT_FILE := "user://account.json"
const CHAR_DIR := "user://characters"

func _ready():
	DirAccess.make_dir_recursive_absolute(CHAR_DIR)
	
func save_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		
func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
		
	var file := FileAccess.open(path, FileAccess.READ)
	var txt := file.get_as_text()
	file.close()
	var content := JSON.new()
	
	if content.parse(txt) != OK:
		return {}
		
	return content.data
	
func default_account() -> Dictionary:
	return {"version":1, "settings": {}, "characters":[]}
	
func load_account() -> Dictionary:
	var account := load_json(ACCOUNT_FILE)
	
	if account.is_empty():
		account = default_account()
		save_json(ACCOUNT_FILE, account)
		
	return account
	
func save_account(account: Dictionary) -> void:
	save_json(ACCOUNT_FILE, account)
	
func character_path(id: String) -> String:
	return CHAR_DIR + "/" + id + ".json"
	
func default_character(id: String, character_name: String, clazz: String) -> Dictionary:
	return {
		"version":1,
		"id": id,
		"name": character_name,
		"class": clazz,
		"position": Vector2.ZERO,
		"stats": {
			"level":1,
			"experience":0,
			"strength":0,
			"dexterity":0,
			"intelligence":0,
			"life_max":100, 
			"life":100, 
			"mana_max":50, 
			"mana": 50, 
			"atk":10, 
			"def": 0, 
			"move_speed":200.0,
			"gold": 0
		},
		"inventory": {
			"w":12, 
			"h":5, 
			"items":[]
		},
		"equipment": {
			"helmet":null, 
			"chest":null, 
			"gloves": null, 
			"boots": null, 
			"weapon":null, 
			"offhand": null, 
			"belt":null, 
			"ring1":null, 
			"ring2":null, 
			"amulet": null
		},
	}
	
func load_character(id: String) -> Dictionary:
	return load_json(character_path(id))
	
func save_character(data: Dictionary) -> void:
	save_json(character_path(data.get("id", "unknow")), data)
