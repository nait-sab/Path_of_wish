class_name World extends Node2D

@export var player: Player
@export var enemies_node: Node2D
@export var loots_node: Node2D

const enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")
const loot_scene: PackedScene = preload("res://scenes/items/item_loot.tscn")

# Config LOOT
const LOOT_RADIUS_STEP := 24.0

func _exit_tree() -> void:
	if Game.current_char_id != "":
		Game.current_char["position"] = [player.global_position.x, player.global_position.y]
		player.save_current()
		Game.save_current()

func _input(event):
	if event.is_action_pressed("debug_space_enemy"):
		var enemy = enemy_scene.instantiate()
		enemy.level = randi() % 3 + 1
		enemy.rarity = [Item.Rarity.NORMAL, Item.Rarity.MAGIC, Item.Rarity.RARE].pick_random()
		enemy.global_position = Vector2.ZERO
		print("[SPAWN ENEMY] %s - %s" % [enemy.level, str(enemy.rarity)])
		enemies_node.add_child(enemy)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		var interfaces: Array = []
		interfaces.append(Inventory.get_any())
		interfaces.append(CharacterSheet.get_any())
		interfaces.append(SkillsWindow.get_any())
		
		var held_item = HeldItem.get_any().item
		if held_item == null:
			return
		var mouse_pos: Vector2 = event.position
		
		for interface in interfaces:
			if interface.is_point_over(mouse_pos):
				return
			
		_drop_held_item_to_ground()
		
func spawn_loot(item: Item, origin: Vector2) -> void:
	var instance: ItemLoot = loot_scene.instantiate()
	instance.setup(item)
	instance.global_position = _find_free_loot_position(instance, origin)
	loots_node.add_child(instance)
	instance.pickup_requested.connect(_on_loot_pickup_requested)
	
func _drop_held_item_to_ground() -> void:
	spawn_loot(HeldItem.get_any().item.clone(), player.global_position)
	HeldItem.get_any().clear_item()

func _find_free_loot_position(new_loot: ItemLoot, origin: Vector2) -> Vector2:
	var new_size: Vector2 = new_loot.collision.shape.extents * 2.0
	var padding := Vector2(4, 4)	
	var radius := 0.0
	var attempts := 0
	
	while true:
		if attempts > 20:
			radius += LOOT_RADIUS_STEP
			attempts = 0
			
		var angle := randf() * TAU
		var distance := randf() * radius
		var candidate := origin + Vector2(cos(angle), sin(angle)) * distance
		var rect_a := Rect2(candidate - new_size * .5 - padding, new_size + padding * 2.0)
		var overlap := false
		
		for loot: ItemLoot in loots_node.get_children():
			var other_size: Vector2 = loot.collision.shape.extents * 2.0
			var rect_b := Rect2(loot.global_position - other_size * .5 - padding, other_size + padding * 2.0)
			if rect_a.intersects(rect_b):
				overlap = true
				break
				
		if not overlap:
			return candidate
			
		attempts += 1
			
	return Vector2(radius, origin.y)
	
func _on_loot_pickup_requested(loot: ItemLoot) -> void:
	if player and is_instance_valid(loot):
		player.request_pickup(loot)
