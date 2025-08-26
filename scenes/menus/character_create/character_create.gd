extends Control

@export var character_name: LineEdit
@export var character_class: OptionButton

func _ready():
	character_class.clear()
	for clazz in ["Force", "Dextérité", "Intelligence"]:
		character_class.add_item(clazz)

func _on_button_validate_pressed() -> void:
	var name := character_name.text.strip_edges()
	
	if name == "":
		return
		
	var clazz := character_class.get_item_text(character_class.get_selected())
	Game.create_character(name, clazz)
	get_tree().change_scene_to_file("res://scenes/menus/character_select/character_select.tscn")

func _on_button_cancel_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/character_select/character_select.tscn")
