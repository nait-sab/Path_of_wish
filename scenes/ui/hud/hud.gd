class_name HUD extends Control

@export_category("Left Panel")
@export var life_orb: TextureProgressBar
@export var energy_shield_gauge: TextureProgressBar
@export var life_label: Label
@export var energy_shield_label: Label

@export_category("Center Panel")
@export var experience_jauge: TextureProgressBar
@export var clock_label: Label
@export var clock_timer: Timer

@export_category("Right Panel")
@export var mana_orb: TextureProgressBar
@export var spirit_gauge: TextureProgressBar
@export var mana_label: Label
@export var spirit_label: Label

var player: Player
var _show_values := true
var _show_clock := true

func _ready() -> void:
	await get_tree().current_scene.ready
	player = get_tree().get_first_node_in_group("Player")
	
	Options.interface_changed.connect(_on_interface_changed)
	apply_interface_options()
	
	if player:
		player.connect("stats_changed", Callable(self, "_on_stats_changed"))
		_on_stats_changed(player)

func _on_interface_changed(options: Dictionary) -> void:
	apply_interface_options()
	_on_stats_changed(player)

func apply_interface_options() -> void:
	_show_values = bool(Options.get_option("interface/show_resource_values"))
	_show_clock = bool(Options.get_option("interface/show_clock"))
	
	clock_label.visible = _show_clock
	if _show_clock:
		_update_clock()
		if clock_timer.is_stopped():
			clock_timer.start()
	else:
		clock_timer.stop()

func _update_clock() -> void:
	var time: Array = Time.get_time_string_from_system().split(":")
	clock_label.text = "%02d:%02d" % [int(time[0]), int(time[1])]

func _on_stats_changed(target: Player) -> void:
	# Life
	sync_jauge(life_orb, target.life, _get_stat("life_max"))
	life_label.text = "Vie : %d/%d" % [
		roundi(target.life), roundi(_get_stat("life_max"))
	]
	life_label.visible = _show_values
	
	# Mana
	sync_jauge(mana_orb, target.mana, _get_stat("mana_max"))
	mana_label.text = "Mana : %d/%d" % [
		roundi(target.mana), roundi(_get_stat("mana_max"))
	]
	mana_label.visible = _show_values
	
	# Energy Shield
	var energy_shield_max = _get_stat("energy_shield_max")
	if energy_shield_max > 0.0:
		energy_shield_gauge.visible = true
		sync_jauge(energy_shield_gauge, target.energy_shield, _get_stat("energy_shield_max"))
	else:
		energy_shield_gauge.visible = false
	
	energy_shield_label.visible = _show_values and energy_shield_max > 0.0
	if energy_shield_label.visible and energy_shield_max > 0.0:
		energy_shield_label.text = "Bouclier : %d/%d" % [
			roundi(target.energy_shield), roundi(_get_stat("energy_shield_max"))
		]
	
	# Spirit
	sync_jauge(spirit_gauge, 80, 230)
	spirit_label.text = "Esprit : %d/%d" % [spirit_gauge.value, spirit_gauge.max_value]
	spirit_label.visible = _show_values
	
	# Experience
	sync_jauge(experience_jauge, 80, 230)

func _get_stat(stat_name: String) -> float:
	var value := StatEngine.get_stat(stat_name)
	return max(0.0, value)
	
func sync_jauge(jauge: TextureProgressBar, current: float, max: float) -> void:
	jauge.max_value = max(1.0, max)
	jauge.value = clamp(current, 0.0, jauge.max_value)

func _on_clock_timer_timeout() -> void:
	_update_clock()
