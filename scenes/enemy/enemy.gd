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
@export var dectection_zone: CollisionShape2D
@export var timer_attack_cooldown: Timer
@export var timer_breeak_cooldown: Timer

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
	dectection_zone.shape.radius = aggro_range
	timer_attack_cooldown.wait_time = attack_cooldown
	timer_breeak_cooldown.wait_time = break_duration
	
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
	if "apply_damage" in target:
		target.apply_damage(roundi(damage))
	timer_attack_cooldown.start()

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body

func _on_detection_range_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		
func apply_damage(amount: int):
	if is_dead: 
		return
		
	print("Damage received %d" % amount)
	
	# Break give 40% more damage
	if is_broken:
		amount *= 1.4
		print("Damage received %d (+ 40% from break)" % amount)
		
	# 1 - Evasion Check
	var evasion_rating = stat_block.get_stat("evasion_rating")
	var dodge_chance = clamp(evasion_rating / (evasion_rating + 100), 0, .95)
	if randf() < dodge_chance:
		print("[Enemy have dodge]")
		return
		
	# 2 - Block Chance
	var block_chance = stat_block.get_stat("block_chance_percent")
	if block_chance > 0:
		var roll = randf() * 100
		if roll < block_chance:
			print("[Enemy have block the attack]")
			return
	
	# 3 - Armour
	var armour  = stat_block.get_stat("armour")
	if armour > 0:
		var reduction = armour / (armour + 5 * amount)
		var reduced_amount = int(amount * (1.0 - reduction))
		print("Armour reduces damage by %.1f%%" % (reduction * 100))
		print("Damage received %d" % reduced_amount)
		amount = reduced_amount
	
	# 4 - Energy Shield
	if energy_shield > 0:
		var energy_absorb = min(amount, energy_shield)
		print("Energy shield have block %d damage" % energy_absorb)
		amount -= energy_absorb
		energy_shield -= energy_absorb
		
	print("Final damage received %d" % amount)
	life = clamp(life - amount, 0, stat_block.get_stat("life_max"))
	life_bar.value = life
	
	_add_break(amount)
	
	if life <= 0:
		die()
		
func _add_break(amount: int) -> void:
	if is_broken:
		return
	break_value = clamp(break_value + amount, 0, break_max)
	if break_value >= break_max:
		_trigger_break()
		
func _trigger_break() -> void:
	is_broken = true
	break_value = break_max
	print("[Enemy] is broken !")
	timer_breeak_cooldown.start()

func _on_break_cooldown_timeout() -> void:
	is_broken = false
	break_value = 0
	print("[Enemy] has not more broken")

func die():
	is_dead = true
	# TODO Drop loot
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
	]

	stat_block.set_source("base", base_mods)
	
	var rolled_mods: Array = EnemyModDb.roll_for_enemy(level, rarity)
	var raw_modifiers: Array = EnemyModDb._to_stat_modifiers(rolled_mods)
	print(raw_modifiers)
	
	var modifiers: Array = []
	for raw in raw_modifiers:
		modifiers.append(stat_block.create_modifier(raw.stat, raw.form, raw.value))

	stat_block.set_source("mods", modifiers)
