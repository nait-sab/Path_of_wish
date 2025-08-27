extends Node

var account: Dictionary
var current_char: Dictionary
var current_char_id: String = ""

signal character_list_changed

func _ready():
	account = SaveManager.load_account()
	
func refresh_account():
	account = SaveManager.load_account()
	emit_signal("character_list_changed")
	
func create_character(character_name: String, clazz: String) -> String:
	var id := str(Time.get_unix_time_from_system())
	var data := SaveManager.default_character(id, character_name, clazz)
	SaveManager.save_character(data)
	
	if not account.has("characters"):
		account["characters"] = []
		
	account["characters"].append(id)
	SaveManager.save_account(account)
	refresh_account()
	return id
	
func select_character(id: String) -> void:
	current_char_id = id
	current_char = SaveManager.load_character(id)
	
func save_current():
	if current_char_id != "":
		SaveManager.save_character(current_char)
