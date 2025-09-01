extends Node

# All models from JSON data
var item_models: Array = []
# Copy of all models by their own id
var item_map: Dictionary = {}

func _ready() -> void:
	if DataReader.list_categories().is_empty():
		DataReader.data_indexed.connect(load_data)
	else:
		_load_all_items()

func load_data() -> void:
	_load_all_items()
	
func _load_all_items() -> void:
	item_models.clear()
	item_map.clear()
	
	item_models = DataReader.get_by_category("items")
	if item_models.is_empty():
		push_warning("[ITEM_DB] No item found in DataReader")
	else:
		for model in item_models:
			if typeof(model) != TYPE_DICTIONARY:
				continue
			var id := str(model.get("id", ""))
			if id == "":
				push_warning("[ITEM_DB] Item found without id -> Skipped")
				continue
			item_map[id] = model
	print("[ITEM_DB] Init done -> %d items loaded" % item_models.size())

func _instantiate_from_model(model: Dictionary) -> Item:
	var instance: Item = null
	var tags: Array = model.get("tags", [])

	if tags.has("weapon") or tags.has("armour") or tags.has("jewelry"):
		instance = Gear.new()
	elif tags.has("consumable"):
		instance = Consumable.new()
	elif tags.has("gem"):
		instance = Gem.new()
	else:
		instance = Item.new()

	instance.load_json(model)
	return instance

# Generate Item instance by ID
func instantiate_by_id(item_id: String, rarity: Item.Rarity = Item.Rarity.NORMAL) -> Item:
	if not item_map.has(item_id):
		push_warning("[ITEM_DB] Item with id %s not found" % item_id)
		return null
	
	var item := _instantiate_from_model(item_map[item_id])
		
	if item is Gear:
		item.rarity = rarity
		var item_tags: Array[String] = []
		for item_tag in item.tags:
			item_tags.append(Item.convert_tag_to_string(item_tag))
		var rolled_mods = ModDb.roll_mods_for_item(item_tags, item.item_level, rarity)
		item.mods = rolled_mods
		item.apply_local_mods()
		
	return item

func instantiate_random(tags: Array = [], max_level: int = 0, rarity: Item.Rarity = Item.Rarity.NORMAL) -> Item:
	var models := _filter_models(tags, max_level)
	if models.is_empty():
		push_warning("[ITEM_DB] No model match for tags=%s, max_level=%d" % [
			tags, max_level
		])
		return null
	
	var item: Item = _instantiate_from_model(models.pick_random())
	
	if item is Gear:
		item.rarity = rarity
		var item_tags: Array[String] = []
		for item_tag in item.tags:
			item_tags.append(Item.convert_tag_to_string(item_tag))
		var rolled_mods = ModDb.roll_mods_for_item(item_tags, item.item_level, rarity)
		item.mods = rolled_mods
		item.apply_local_mods()
		
	return item

func _filter_models(tags: Array, max_level: int) -> Array:
	var models: Array[Dictionary] = []
	
	for model in item_models:
		# 1 - Filter tags
		var has_all_tags: bool = true
		for tag in tags:
			var tag_searched = tag
			if typeof(tag_searched) == TYPE_INT:
				tag_searched = Item.convert_tag_to_string(tag_searched)
			if not model.get("tags", []).has(tag_searched):
				has_all_tags = false
				break
		if not has_all_tags:
			continue
			
		# 2 - Filter level
		if max_level > 0 and model.get("item_level", 1) > max_level:
			continue
		
		models.append(model)
	return models
