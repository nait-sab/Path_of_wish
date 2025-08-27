extends Node

const LOOT_TABLE_PATH := "res://data/loot_tables.json"

# Base rarity chance by loot
const RARITY_WEIGHTS_BASE := {
	Item.Rarity.NORMAL: 80.0,
	Item.Rarity.MAGIC: 18.0,
	Item.Rarity.RARE: 2.0,
	Item.Rarity.UNIQUE: 0.1,
}

# Increased base rarity chance by enemy rarity
const ENEMY_RARITY_WEIGHTS_BONUS := {
	Item.Rarity.NORMAL: {Item.Rarity.MAGIC: 0.0, Item.Rarity.RARE: 0.0, Item.Rarity.UNIQUE: 0.0},
	Item.Rarity.MAGIC: {Item.Rarity.MAGIC: 10.0, Item.Rarity.RARE: 2.0, Item.Rarity.UNIQUE: 0.1},
	Item.Rarity.RARE: {Item.Rarity.MAGIC: 20.0, Item.Rarity.RARE: 8.0, Item.Rarity.UNIQUE: 0.2},
	Item.Rarity.UNIQUE: {Item.Rarity.MAGIC: 30.0, Item.Rarity.RARE: 12.0, Item.Rarity.UNIQUE: 0.5},
}

# Total loot number by enemy rarity
const DROP_COUNT_BY_ENEMY_RARITY := {
	Item.Rarity.NORMAL: Vector2i(0, 1),
	Item.Rarity.MAGIC: Vector2i(1, 2),
	Item.Rarity.RARE: Vector2i(2, 4),
	Item.Rarity.UNIQUE: Vector2i(4, 6),
}

var _tables: Array = []

func _ready() -> void:
	_load_loot_table()
	
func _load_loot_table() -> void:
	_tables.clear()
	if not FileAccess.file_exists(LOOT_TABLE_PATH):
		push_warning("LootDB: %s not found" % LOOT_TABLE_PATH)
		return
	var file := FileAccess.open(LOOT_TABLE_PATH, FileAccess.READ)
	if file == null:
		push_warning("LootDB: can't open %s" % LOOT_TABLE_PATH)
		return
	var txt := file.get_as_text()
	file.close()
	var json = JSON.parse_string(txt)
	if typeof(json) == TYPE_ARRAY:
		_tables = json
	else:
		push_warning("LootDB: Invalid JSON format in %s" % LOOT_TABLE_PATH)
		
# --- Helpers
func _weighted_pick(items: Array) -> Dictionary:
	if items.is_empty():
		return {}
	var total := 0.0
	for item in items:
		total += float(item.get("weight", 1.0))
	var rand = randf() * total
	var acc := 0.0
	for item in items:
		acc += float(item.get("weight", 1.0))
		if rand <= acc:
			return item
	return items.back()

func _pick_rarity_for_drop(enemy_rarity: Item.Rarity) -> int:
	var weights := RARITY_WEIGHTS_BASE.duplicate(true)
	var bonus: Dictionary = ENEMY_RARITY_WEIGHTS_BONUS.get(enemy_rarity, {})
	for key in bonus.keys():
		weights[key] = float(weights.get(key, 0.0)) + float(bonus[key])
		
	var pool: Array = []
	for rarity in weights.keys():
		pool.append({"rarity": rarity, "weight": weights[rarity]})
	var picked := _weighted_pick(pool)
	return int(picked.get("rarity", Item.Rarity.NORMAL))
	
func _rand_int_in_range(value: Variant, default_value: int = 1) -> int:
	# Check if int (stable) or [min, max]
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_ARRAY and value.size() == 2:
		var a := int(value[0])
		var b := int(value[1])
		if a > b:
			var tmp = a
			a = b
			b = tmp
		return randi_range(a, b)
	return default_value
	
# --- API
func roll_one(level: int, enemy_rarity: Item.Rarity = Item.Rarity.NORMAL) -> Item:
	var candidates: Array = []
	for drop in _tables:
		var min_level := int(drop.get("min_level", 1))
		if level >= min_level:
			candidates.append(drop)
	if candidates.is_empty():
		return null
		
	var category := _weighted_pick(candidates)
	if category.is_empty():
		return null
		
	var item_rarity = _pick_rarity_for_drop(enemy_rarity)
	var tags = category.get("tags", [])
	var item := ItemDb.instantiate_random(tags, level, item_rarity)
	if item == null:
		return null
		
	if item.tags.has(Item.Tag.CURRENCY) and item.stack_max > 1:
		var stack_range = category.get("stack_range", [1, 3])
		var quantity := _rand_int_in_range(stack_range, 1)
		quantity = clamp(quantity, 1, item.stack_max)
		item.stack_current = quantity
		
	return item
	
func roll_for_enemy(level: int, enemy_rarity: Item.Rarity = Item.Rarity.NORMAL) -> Array:
	var drop_range: Vector2i = DROP_COUNT_BY_ENEMY_RARITY.get(enemy_rarity, Vector2i(0, 1))
	var number := randi_range(drop_range.x, drop_range.y)
	
	var results: Array = []
	for index in range(number):
		var item := roll_one(level, enemy_rarity)
		if item != null:
			results.append(item)
	return results
