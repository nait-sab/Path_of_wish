class_name CharacterSheet extends CanvasLayer

@export_category("Informations")
@export var level_class: Label
@export var map_name: Label
@export var character_name: Label
@export var strength_value: Label
@export var dexterity_value: Label
@export var intelligence_value: Label

@export_category("Stats")
@export var life_value: Label
@export var energy_shield_value: Label
@export var mana_value: Label
@export var spirit_value: Label
@export var armour_value: Label
@export var evasion_value: Label
@export var block_value: Label

@export_category("Resistances")
@export var fire_value: Label
@export var fire_max_value: Label
@export var cold_value: Label
@export var cold_max_value: Label
@export var lightning_value: Label
@export var lightning_max_value: Label
@export var chaos_value: Label
@export var chaos_max_value: Label

@export_category("Components")
@export var panel: Panel
@export var header: Control
@export var details: VBoxContainer

var player: Player
var dragging = false
var drag_offset = Vector2.ZERO

const REF_HIT_BY_LEVEL := {
	1:30, 2:32, 3:35, 4:38, 5:41, 6:45, 7:50, 8:55, 9:60, 10:65
}

const REF_ACCURARY_BY_LEVEL := {
	1:140, 2:160, 3:180, 4:200, 5:220, 6:240, 7:260, 8:280, 9:300, 10:320
}

func _ready():
	visible = false
	player = get_tree().get_first_node_in_group("Player")
	StatEngine.stats_updated.connect(_on_stat_engine_changed)
	_refresh()
	
	var world = get_parent()
	if world and world.has_signal("toggle_character_sheet"):
		world.connect("toggle_character_sheet", Callable(self, "toggle"))
	
func toggle():
	visible = not visible
	if visible:
		_refresh()

func _on_close_button_pressed() -> void:
	toggle()
	
func _on_stat_engine_changed(_final_stats: Dictionary) -> void:
	if visible:
		_refresh()
	
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var header_rect = Rect2(header.global_position, header.size)
			if header_rect.has_point(event.position):
				dragging = true
				drag_offset = event.position - panel.global_position
		else:
			dragging = false

	if event is InputEventMouseMotion and dragging:
		var new_position = event.position - drag_offset
		var viewport_size = get_viewport().get_visible_rect().size
		new_position.x = clamp(new_position.x, 0, viewport_size.x - panel.size.x)
		new_position.y = clamp(new_position.y, 0, viewport_size.y - panel.size.y)
		panel.global_position = new_position
		
func _refresh():
	var infos: Dictionary = Game.current_char
	#var stats: Dictionary = infos.get("stats", {})
	
	# Informations
	level_class.text = "Niveau %d %s" % [player.level, infos.get("class", "Unknow")]
	map_name.text = "Map de test"
	character_name.text = infos.get("name", "Unknow")
	strength_value.text = str(player.strength)
	dexterity_value.text = str(player.dexterity)
	intelligence_value.text = str(player.intelligence)
	
	# Stats
	life_value.text = str(int(StatEngine.get_stat("life_max")))
	energy_shield_value.text = str(StatEngine.get_stat("energy_shield_max"))
	mana_value.text = str(int(StatEngine.get_stat("mana_max")))
	spirit_value.text = str(StatEngine.get_stat("spirit"))
	armour_value.text = "%d%%" % estimate_phys_reduction_percent(StatEngine.get_stat("armour"), player.level)
	evasion_value.text = "%d%%" % estimate_evade_percent(StatEngine.get_stat("evasion_rating"), player.level)
	block_value.text = "%d%%" % int(StatEngine.get_stat("block_chance_percent"))
	
	# Resistances
	fire_value.text = "%d%%" % int(StatEngine.get_stat("resistance_fire"))
	fire_max_value.text = "(Max: %d%%)" % int(StatEngine.get_stat("resistance_fire_max"))
	cold_value.text = "%d%%" % int(StatEngine.get_stat("resistance_cold"))
	cold_max_value.text = "(Max: %d%%)" % int(StatEngine.get_stat("resistance_cold_max"))
	lightning_value.text = "%d%%" % int(StatEngine.get_stat("resistance_lightning"))
	lightning_max_value.text = "(Max: %d%%)" % int(StatEngine.get_stat("resistance_lightning_max"))
	chaos_value.text = "%d%%" % int(StatEngine.get_stat("resistance_chaos"))
	chaos_max_value.text = "(Max: %d%%)" % int(StatEngine.get_stat("resistance_chaos_max"))
	
	# Details
	_clear_details()
	
	# Life
	var life_details = []
	life_details.append(["Vie Maximale",  "%d" % int(StatEngine.get_stat("life_max"))])
	
	if StatEngine.get_stat("life_regen_percent") > 0:
		var value = "%.1f" % float(StatEngine.get_stat("life_max") * StatEngine.get_stat("life_regen_percent") / 100.0)
		life_details.append(["Récupération de vie par seconde totale",  value])
	
	_add_detail_section("Vie", life_details)
	
	# Mana
	_add_detail_section("Mana", [
		["Mana maximale",  "%d" % int(StatEngine.get_stat("mana_max"))],
		["Récupération de mana par seconde",  "%.1f" % float(StatEngine.get_stat("mana_max") * StatEngine.get_stat("mana_regen_percent") / 100.0)]
	])
	
	# Armour
	var armour := int(StatEngine.get_stat("armour"))
	if armour > 0:
		_add_detail_section("Armure", [
			["Armure", "%d" % armour],
			["Estimation de la réduction des dégâts physiques", "%d%%" % estimate_phys_reduction_percent(armour, player.level)]
		])
	
	# Evasion
	var evasion_rating := int(StatEngine.get_stat("evasion_rating"))
	if evasion_rating > 0:
		_add_detail_section("Evasion", [
			["Score d'évasion", "%d" % evasion_rating],
			["Estimation des chances d'éviter", "%d%%" % estimate_evade_percent(armour, player.level)]
		])
	
	# Resistances
	_add_detail_section("Résistances", [
		["Résistance au feu", "%d (Max %d%%)" % [int(StatEngine.get_stat("resistance_fire")), int(StatEngine.get_stat("resistance_fire_max"))]],
		["Résistance au froid", "%d (Max %d%%)" % [int(StatEngine.get_stat("resistance_cold")), int(StatEngine.get_stat("resistance_cold_max"))]],
		["Résistance à la foudre", "%d (Max %d%%)" % [int(StatEngine.get_stat("resistance_lightning")), int(StatEngine.get_stat("resistance_lightning_max"))]],
		["Résistance au chaos", "%d (Max %d%%)" % [int(StatEngine.get_stat("resistance_chaos")), int(StatEngine.get_stat("resistance_chaos_max"))]]
	])
	
	# Divers
	var divers = []
	divers.append(["Modificateur de vitesse de déplacement", "%1.f%%" % StatEngine.get_stat("movement_speed_percent")])
	_add_detail_section("Divers", divers)

# --- Helpers
func _add_detail_section(title: String, lines: Array) -> void:
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", Color(.8, .8, 1))
	title_label.add_theme_font_size_override("font_size", 16)
	details.add_child(title_label)
	
	for line in lines:
		var h_box = HBoxContainer.new()
		
		var line_label = Label.new()
		line_label.text = line[0]
		line_label.size_flags_horizontal = 3
		h_box.add_child(line_label)
		
		var line_value = Label.new()
		line_value.text = line[1]
		h_box.add_child(line_value)
		
		details.add_child(h_box)
		
func _clear_details() -> void:
	for child in details.get_children():
		child.queue_free()
		
# --- Calc
func estimate_phys_reduction_percent(armour: float, level: int) -> int:
	if armour == 0.0:
		return 0
	var ref_hit := int(REF_HIT_BY_LEVEL.get(level, 60))
	var reduction := 0
	if ref_hit > 0:
		reduction = armour / (armour + 10.0 * ref_hit)
	return roundi(clamp(reduction * 100, 0, 90))
	
func estimate_evade_percent(evasion: float, level: int) -> int:
	if evasion == 0.0:
		return 0
	var accuracy := int(REF_ACCURARY_BY_LEVEL.get(level, 300))
	var hit_chance := float(float(accuracy) / (accuracy + max(evasion, 0)))
	hit_chance = clamp(hit_chance, 0.05, 0.95)
	return roundi((1.0 - hit_chance) * 100.0)
