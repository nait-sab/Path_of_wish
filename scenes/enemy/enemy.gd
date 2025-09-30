class_name Enemy extends CharacterBody2D

@export_category("Base")
@export var level := 1
@export var rarity: Item.Rarity = Item.Rarity.NORMAL

@export_category("Combat")
@export var aggro_range := 500
@export var attack_range := 200
@export var attack_cooldown := 1.0
@export var break_duration := 3.0

@export_category("Components")
@export var sprite: Sprite2D
@export var life_bar: ProgressBar
@export var detection_zone: CollisionShape2D
@export var timer_attack_cooldown: Timer
@export var timer_break_cooldown: Timer

var stat_block: StatBlock

var life : float = 0
var life_max_cached: float = 0
var energy_shield : float = 0
var energy_shield_max_cached: float = 0
var damage: float = 0
var movement_speed: float = 0

var is_dead := false
var target: Player = null

# break settings
var break_value: float = 0
var break_max: float = 0
var is_broken := false

func _ready():
	add_to_group("Enemy")

	# Setup actual attack system
	detection_zone.shape.radius = aggro_range
	timer_attack_cooldown.wait_time = attack_cooldown
	timer_break_cooldown.wait_time = break_duration
	
	# Setup local stat block
	stat_block = StatBlock.new()
	add_child(stat_block)
	
	# Setup base stats
	apply_base_stats()
	
	# Setup local variables
	life_max_cached = stat_block.get_stat("life_max")
	life = life_max_cached
	energy_shield_max_cached = stat_block.get_stat("energy_shield_max")
	energy_shield = energy_shield_max_cached
	damage = stat_block.get_stat("damage")
	var base_speed = stat_block.get_stat("move_speed")
	movement_speed = base_speed * (1.0 + stat_block.get_stat("move_speed_percent") / 100.0)
	
	life_bar.max_value = life_max_cached
	life_bar.value = life
	
	# Setup Break
	break_max = life_max_cached * 1.5
	
	print("[ENEMY SPAWN] : Level %d (%s)" % [level, str(rarity)])
	print(stat_block.get_final_stats())
	
func _physics_process(_delta: float) -> void:
	if is_dead:
		die()
		return
		
	if is_broken:
		velocity = Vector2.ZERO
		return
		
	if target:
		var distance := global_position.distance_to(target.global_position)
			
		if distance > attack_range:
			velocity = (target.global_position - global_position).normalized() * movement_speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			if timer_attack_cooldown.is_stopped():
				attack_target()
	else:
		velocity = Vector2.ZERO
		
	# TODO - Regen
		
func attack_target():
	if not target or is_broken:
		return
	
	var packet := (DamagePacket.new()).melee_physical(damage)
	packet.can_crit = true
	packet.crit_chance = 0.05
	packet.crit_multiplier = 1.5
	
	if "receive_hit" in target:
		target.receive_hit(packet)
	
	timer_attack_cooldown.start()
	
func receive_hit(packet: DamagePacket) -> DamageReport:
	if is_dead:
		return DamageReport.new()
	
	var defender_get := Callable(stat_block, "get_stat")
	var defender_state := {
		"life": life,
		"energy_shield": energy_shield
	}
	
	var report := DamageResolver.resolve(defender_get, defender_state, packet, {
		"is_broken": is_broken
	})
	
	var energy_shield_damage := report.applied_to_energy_shield
	var life_damage := report.applied_to_life
	
	if energy_shield_damage > 0.0 and energy_shield > 0.0:
		energy_shield = max(0.0, energy_shield - energy_shield_damage)
		
	if life_damage > 0.0:
		life = clamp(life - life_damage, 0.0, life_max_cached)
		life_bar.value = life
		
	_add_break(report.final_total)
	
	if life <= 0.0:
		die()
		
	return report;

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body

func _on_detection_range_body_exited(body: Node2D) -> void:
	if body == target:
		target = null

func _add_break(amount: float) -> void:
	if is_broken:
		return
	break_value = clamp(break_value + amount, 0.0, break_max)
	if break_value >= break_max:
		_trigger_break()
		
func _trigger_break() -> void:
	is_broken = true
	break_value = break_max
	print("[Enemy] is broken !")
	timer_break_cooldown.start()

func _on_break_cooldown_timeout() -> void:
	is_broken = false
	break_value = 0
	print("[Enemy] has not more broken")

func die():
	is_dead = true
	var drops := LootDb.roll_for_enemy(level, rarity)
	for item: Item in drops:
		get_tree().root.get_node("World").spawn_loot(item, global_position)
	queue_free()

# --- Stats Calc
func _base_life_for_level() -> int:
	return roundi(level * 20.0 * _rarity_multiplier())
	
func _base_damage_for_level() -> int:
	return roundi(level * 2.5 * _rarity_multiplier())
	
func _base_speed_for_level() -> float:
	return roundi(200 + level * .5 * _rarity_multiplier())
	
func _base_armour_for_level() -> float:
	return roundi(level * 10 * _rarity_multiplier())
	
func _base_evasion_rating_for_level() -> float:
	return roundi(level * 8 * _rarity_multiplier())
	
func _base_energy_shield_for_level() -> float:
	return roundi(level * 5 * _rarity_multiplier())
	
func _rarity_multiplier() -> float:
	match rarity:
		Item.Rarity.NORMAL: return 1.0
		Item.Rarity.MAGIC: return 1.5
		Item.Rarity.RARE: return 3.0
		Item.Rarity.UNIQUE: return 5.0
		_: return 1.0
	
func apply_base_stats():
	var base_life = _base_life_for_level()
	var base_damage = _base_damage_for_level()
	var base_speed = _base_speed_for_level()
	var base_armour = _base_armour_for_level()
	var base_evasion_rating = _base_evasion_rating_for_level()
	var base_energy_shield = _base_energy_shield_for_level()
	
	var base_mods = [
		stat_block.create_modifier("life_max", StatBlock.ModifierForm.FLAT, base_life),
		stat_block.create_modifier("damage", StatBlock.ModifierForm.FLAT, base_damage),
		stat_block.create_modifier("move_speed", StatBlock.ModifierForm.FLAT, base_speed),
		stat_block.create_modifier("armour", StatBlock.ModifierForm.FLAT, base_armour),
		stat_block.create_modifier("evasion_rating", StatBlock.ModifierForm.FLAT, base_evasion_rating),
		stat_block.create_modifier("energy_shield_max", StatBlock.ModifierForm.FLAT, base_energy_shield),
		
		# Resistances
		stat_block.create_modifier("resistance_fire", StatBlock.ModifierForm.FLAT, 0),
		stat_block.create_modifier("resistance_fire_max", StatBlock.ModifierForm.FLAT, 75),
		stat_block.create_modifier("resistance_cold", StatBlock.ModifierForm.FLAT, 0),
		stat_block.create_modifier("resistance_cold_max", StatBlock.ModifierForm.FLAT, 75),
		stat_block.create_modifier("resistance_lightning", StatBlock.ModifierForm.FLAT, 0),
		stat_block.create_modifier("resistance_lightning_max", StatBlock.ModifierForm.FLAT, 75),
		stat_block.create_modifier("resistance_chaos", StatBlock.ModifierForm.FLAT, 0),
		stat_block.create_modifier("resistance_chaos_max", StatBlock.ModifierForm.FLAT, 75),
	]

	stat_block.set_source("base", base_mods)
	
	var rolled_mods: Array = EnemyModDb.roll_for_enemy(level, rarity)
	var raw_modifiers: Array = EnemyModDb._to_stat_modifiers(rolled_mods)
	
	var modifiers: Array = []
	for raw in raw_modifiers:
		modifiers.append(stat_block.create_modifier(raw.stat, raw.form, raw.value))

	stat_block.set_source("mods", modifiers)
