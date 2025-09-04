extends Control

@export var list: ItemList

func _ready():
	Game.connect("character_list_changed", Callable(self, "_refresh"))
	_refresh()
	
func _refresh():
	list.clear()
	var account := Game.account
	
	for id in account.get("characters", []):
		var character := SaveManager.load_character(id)
		list.add_item("%s (%s)" % [character.get("name", "?"), character.get("class", "?")])
		list.set_item_metadata(list.item_count - 1, id)

func _on_button_create_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/character_create/character_create.tscn")

func _on_button_delete_pressed() -> void:
	var index := list.get_selected_items()
	
	if index.size() == 0:
		return
		
	var id : String = list.get_item_metadata(index[0])
	var path := SaveManager.character_path(id)
	
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	
	Game.account["characters"].erase(id)
	SaveManager.save_account(Game.account)
	_refresh()

func _on_button_play_pressed() -> void:
	var index := list.get_selected_items()
	
	if index.size() == 0:
		return
		
	var id : String = list.get_item_metadata(index[0])
	Game.select_character(id)
	MusicManager.stop()
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu/main_menu.tscn")
