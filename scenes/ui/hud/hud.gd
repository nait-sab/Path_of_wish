class_name HUD extends Control

@export_category("Left Panel")
@export var life_orb: TextureProgressBar
@export var energy_shield_gauge: TextureProgressBar
@export var life_label: Label
@export var energy_shield_label: Label

@export_category("Center Panel")
@export var experience_jauge: TextureProgressBar

@export_category("Right Panel")
@export var mana_orb: TextureProgressBar
@export var spirit_gauge: TextureProgressBar
@export var mana_label: Label
@export var spirit_label: Label

var player: Player

func _ready() -> void:
	await get_tree().current_scene.ready
	player = get_tree().get_first_node_in_group("Player")
	
	if player:
		player.connect("stats_changed", Callable(self, "_on_stats_changed"))
		_on_stats_changed(player)
		
func _on_stats_changed(target: Player) -> void:
	# Life
	sync_jauge(life_orb, target.life, _get_stat("life_max"))
	life_label.text = "Vie : %d/%d" % [
		roundi(target.life), roundi(_get_stat("life_max"))
	]
	
	# Mana
	sync_jauge(mana_orb, target.mana, _get_stat("mana_max"))
	mana_label.text = "Mana : %d/%d" % [
		roundi(target.mana), roundi(_get_stat("mana_max"))
	]
	
	# Energy Shield
	if _get_stat("energy_shield_max") > 0.0:
		energy_shield_gauge.visible = true
		energy_shield_label.visible = true
		sync_jauge(energy_shield_gauge, target.energy_shield, _get_stat("energy_shield_max"))
		energy_shield_label.text = "Bouclier : %d/%d" % [
			roundi(target.energy_shield), roundi(_get_stat("energy_shield_max"))
		]
	else:
		energy_shield_gauge.visible = false
		energy_shield_label.visible = false
	
	# Spirit
	sync_jauge(spirit_gauge, 80, 230)
	spirit_label.text = "Esprit : %d/%d" % [spirit_gauge.value, spirit_gauge.max_value]
	
	# Experience
	sync_jauge(experience_jauge, 80, 230)

func _get_stat(stat_name: String) -> float:
	var value := StatEngine.get_stat(stat_name)
	return max(0.0, value)
	
func sync_jauge(jauge: TextureProgressBar, current: float, max: float) -> void:
	jauge.max_value = max(1.0, max)
	jauge.value = clamp(current, 0.0, jauge.max_value)
