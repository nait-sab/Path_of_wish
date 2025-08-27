extends Node

# Old fake items for testing
var templates : Array = [
	{
		"name":"Epée rouillée", 
		"type":"weapon", 
		"width":1, 
		"height":1, 
		"atk":5, 
		"mana_cost":2
	}, {
		"name":"Couteau", 
		"type":"weapon", 
		"width":1, 
		"height":2, 
		"atk":8,
		"mana_cost":4
	}, {
		"name":"Baguette", 
		"type":"weapon", 
		"width":1, 
		"height":3, 
		"atk":8,
		"mana_cost":1
	}, {
		"name":"Capuche de toile", 
		"type":"helmet", 
		"width":2, 
		"height":2, 
		"def":1
	}, {
		"name":"Gants en cuir", 
		"type":"helmet",
		"rarity": "magic",
		"width":2, 
		"height":2, 
		"def":5
	}, {
		"name":"Plastron Karui", 
		"type":"helmet",
		"rarity": "rare",
		"width":2, 
		"height":3, 
		"def":10
	}, {
		"name":"Bottes céleste", 
		"type":"boots",
		"rarity": "unique", 
		"width":2, 
		"height":2, 
		"def":30
	}, {
		"name":"Flasque de mana mineure", 
		"type":"flask", 
		"width":1, 
		"height":2
	}, {
		"name":"Orbe du chaos", 
		"type":"currency", 
		"stack":20, 
		"width":1, 
		"height":1
	}, {
		"name":"Orbe du chaos", 
		"type":"currency", 
		"stack":20, 
		"width":1, 
		"height":1
	}, {
		"name":"Parchemin", 
		"type":"currency", 
		"stack":20, 
		"width":1, 
		"height":1
	}, {
		"name":"Orbe d'altération", 
		"type":"currency", 
		"stack":20, 
		"width":1, 
		"height":1
	},
]

# Real item models from json data
var item_models: Array = []

# Copy of models stocked by their own id
var item_map: Dictionary = {}

func _ready() -> void:
	_load_all_items()
	
func _load_all_items() -> void:
	item_models.clear()
	item_map.clear()
	
	var data_dir: DirAccess = DirAccess.open("res://data/items")
	if data_dir == null:
		push_warning("ItemDB: res://data/items introuvable")
		return
		
	_scan_dir(data_dir)
	print("ItemDB: %d modèles chargés depuis data/items" % item_models.size())
	
func _scan_dir(dir: DirAccess) -> void:
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			var sub_dir = DirAccess.open(dir.get_current_dir() + "/" + file_name)
			if sub_dir:
				_scan_dir(sub_dir)
		else:
			if file_name.ends_with(".json"):
				var full_path = dir.get_current_dir() + "/" + file_name
				_load_json(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
	
func _load_json(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("ItemDB: Impossible d'ouvrir %s (méthode _load_json)" % path)
		return

	var text: String = file.get_as_text()
	file.close()

	var json = JSON.parse_string(text)
	if typeof(json) == TYPE_ARRAY:
		for model in json:
			if typeof(model) == TYPE_DICTIONARY:
				_register_model(model, path)
	elif typeof(json) == TYPE_DICTIONARY:
		_register_model(json, path)
	else:
		push_warning("ItemDB: Format JSON non reconnu dans %s (méthode _load_json)" % path)

func _register_model(model: Dictionary, path: String) -> void:
	if not model.has("id"):
		push_warning("ItemDB: Modèle sans id trouvé dans %s (méthode _register_model)" % path)
		return

	var id: String = model["id"]
	item_models.append(model)
	item_map[id] = model

# Generate Item instance by ID
func instantiate_by_id(item_id: String) -> Dictionary:
	if not item_map.has(item_id):
		push_warning("ItemDB: id inconnu %s" % item_id)
		return {}
		
	var instance = item_map[item_id].duplicate(true)
	instance["uid"] = "%s_%d" % [item_id, randi()]
	return instance
	
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

func instantiate_random(tags: Array = [], max_level: int = 0, rarity: Item.Rarity = Item.Rarity.NORMAL) -> Item:
	# Filter models
	var models: Array = []
	
	for model in item_models:
		# Filter by tags
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
			
		# Filter by level
		if max_level > 0 and model.get("item_level", 1) > max_level:
			continue
			
		models.append(model)
		
	if models.is_empty():
		push_warning("ItemDB: Aucun modèle trouvé pour tags=%s, max_level=%d (méthode instantiate_random)" % [
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
