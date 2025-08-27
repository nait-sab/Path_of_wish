extends Node2D

signal toggle_character_sheet

@export var player: Player
@export var enemies_node: Node2D
@export var loots_node: Node2D

const enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")
const loot_scene: PackedScene = preload("res://scenes/items/item_loot.tscn")

func _exit_tree() -> void:
	if Game.current_char_id != "":
		Game.current_char["position"] = [player.global_position.x, player.global_position.y]
		player.save_current()
		Game.save_current()

func _input(event):
	if event.is_action_pressed("toggle_character_sheet"):
		emit_signal("toggle_character_sheet")
		
	if event.is_action_pressed("debug_stats"):
		var stats = StatEngine.get_final_stats()
		print("--- DEBUG Stats ---")
		for key in stats.keys():
			print("%s : %s" % [key, str(stats[key])])
		print("-------------------")
		
	if event.is_action_pressed("debug_space_enemy"):
		var enemy = enemy_scene.instantiate()
		enemy.level = randi() % 3 + 1
		enemy.rarity = [Item.Rarity.NORMAL, Item.Rarity.MAGIC, Item.Rarity.RARE].pick_random()
		enemy.global_position = Vector2.ZERO
		print("[SPAWN ENEMY] %s - %s" % [enemy.level, str(enemy.rarity)])
		enemies_node.add_child(enemy)
		
func spawn_loot(item: Item, origin: Vector2) -> void:
	var instance: ItemLoot = loot_scene.instantiate()
	instance.setup(item)
	var angle = randf() * TAU
	var distance := 16.0 + randf() * TAU
	instance.global_position = origin + Vector2(cos(angle), sin(angle)) * distance
	loots_node.add_child(instance)
	instance.pickup_requested.connect(_on_loot_pickup_requested)
	
func _on_loot_pickup_requested(loot: ItemLoot) -> void:
	if player and is_instance_valid(loot):
		player.request_pickup(loot)
