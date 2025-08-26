extends Node2D

signal toggle_character_sheet
signal toggle_inventory

@export var player: Player
@export var enemies_node: Node2D

const enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")

func _exit_tree() -> void:
	if Game.current_char_id != "":
		Game.current_char["position"] = [player.global_position.x, player.global_position.y]
		player.save_current()
		Game.save_current()

func _input(event):
	if event.is_action_pressed("toggle_character_sheet"):
		emit_signal("toggle_character_sheet")
		
	if event.is_action_pressed("toggle_inventory"):
		emit_signal("toggle_inventory")
		
	if event.is_action_pressed("debug_stats"):
		var stats = StatEngine.get_final_stats()
		print("--- DEBUG Stats ---")
		for key in stats.keys():
			print("%s : %s" % [key, str(stats[key])])
		print("-------------------")
		
	if event.is_action_pressed("debug_space_enemy"):
		var enemy = enemy_scene.instantiate()
		enemy.level = randi() % 3 + 1
		print(enemy.level)
		enemy.rarity = [Item.Rarity.NORMAL, Item.Rarity.MAGIC, Item.Rarity.RARE].pick_random()
		print(enemy.rarity)
		enemy.global_position = Vector2.ZERO
		enemies_node.add_child(enemy)
		
