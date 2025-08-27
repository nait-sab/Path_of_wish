class_name Player extends CharacterBody2D

const DAMAGE_PACKET = preload("res://scripts/combat/damage_packet.gd")
const DAMAGE_RESOLVER = preload("res://scripts/combat/damage_resolver.gd")

signal stats_changed(stats)

@export_category("Data")
@export var base_speed: float = 200
@export var melee_range: float
@export var melee_damage: float = 10
@export var mana_cost: int = 3

@export_category("Components")
@export var sprite: Sprite2D
@export var melee_zone: CollisionShape2D

# Caracteristics
var level: int = 1
var strength: int = 0
var dexterity: int = 0
var intelligence: int = 0
var gold: int = 0

# Dynamic variables
var life: float = 0
var last_life: float = 0
var mana: float = 0
var last_mana: float = 0

# Combat
var attack_cooldown: float = .35
var _cd: float = 0

# Loot
var pickup_target: ItemLoot = null
const PICKUP_RADIUS := 24.0

func _ready():
	add_to_group("Player")
	melee_zone.shape.radius = melee_range
	load_current()
	emit_signal("stats_changed", self)
	
func _process(delta: float) -> void:
	var updated = false
	
	# Get StatEngine infos
	var life_max = StatEngine.get_stat("life_max")
	var mana_max = StatEngine.get_stat("mana_max")
	var life_regen_percent = StatEngine.get_stat("life_regen_percent")
	var mana_regen_percent = StatEngine.get_stat("mana_regen_percent")
	
	if life < life_max and life_regen_percent > 0:
		var regen_amount = (life_max * (life_regen_percent / 100.0)) * delta
		life = min(life + regen_amount, life_max)
		updated = true

	if mana < mana_max and mana_regen_percent > 0:
		var regen_amount = (mana_max * (mana_regen_percent / 100.0)) * delta
		mana = min(mana + regen_amount, mana_max)
		updated = true
		
	if updated and (life != last_life or mana != last_mana):
		emit_signal("stats_changed", self)
		last_life = life
		last_mana = mana
		
func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if pickup_target and is_instance_valid(pickup_target):
		var distance := (pickup_target.global_position - global_position)
		if distance.length() > PICKUP_RADIUS:
			direction = distance.normalized()
		else:
			_try_pickup_item(pickup_target)
			pickup_target = null
	
	var movespeed_percent = StatEngine.get_stat("move_speed_percent")
	var speed = base_speed * (1.0 + movespeed_percent / 100.0)
	velocity = direction * speed
	
	if direction != Vector2.ZERO:
		rotation = direction.angle()
	
	move_and_slide()
	
	_cd = max(0, _cd - delta)
	
	if Input.is_action_pressed("attack") and _cd == 0:
		_try_attack()
		
func _try_attack():	
	if mana < mana_cost:
		return
		
	var target: CharacterBody2D = _find_enemy_under_mouse()
	
	if target == null:
		return

	if target.global_position.distance_to(global_position) > melee_range:
		return
		
	var packet := DAMAGE_PACKET.melee_physical(melee_damage)
	packet.can_crit = false
	packet.crit_chance = 0.0
	packet.crit_multiplier = 0.0
	
	if "receive_hit" in target:
		target.receive_hit(packet)

	#target.apply_damage(melee_damage)
	mana = clamp(mana - mana_cost, 0, StatEngine.get_stat("mana_max"))
	emit_signal("stats_changed", self)
	_cd = attack_cooldown
	
func receive_hit(packet: DamagePacket) -> DamageReport:
	var defender_get := Callable(StatEngine, "get_stat")
	var defender_state := {
		"life": life,
		"energy_shield": StatEngine.get_stat("energy_shield_max")
	}
	
	var report := DamageResolver.resolve(defender_get, defender_state, packet, {})
	if report.applied_to_life > 0.0:
		life = clamp(life - report.applied_to_life, 0.0, StatEngine.get_stat("life_max"))
		emit_signal("stats_changed", self)
		
	return report
	
func request_pickup(target: ItemLoot) -> void:
	pickup_target = target
	
func _try_pickup_item(node: ItemLoot) -> void:
	if not node or not is_instance_valid(node):
		return
	var inventory = get_tree().get_first_node_in_group("Inventory") as Inventory
	if inventory and inventory.try_insert_item(node.item):
		node.queue_free()
	else:
		# TODO - Sound of full inventory
		pass
	
func _find_enemy_under_mouse():
	var mouse := get_global_mouse_position()
	
	var best
	var best_d: float = 60 # Range around cursor allowed
	
	for enemy: CharacterBody2D in get_tree().get_nodes_in_group("Enemy"):
		if enemy.is_dead:
			continue
			
		var distance := enemy.global_position.distance_to(mouse)
		if distance < best_d:
			best_d = distance
			best = enemy
			
	return best
	
func load_current():
	var stats: Dictionary = Game.current_char["stats"]
	
	level = stats["level"]
	strength = stats["strength"]
	dexterity = stats["dexterity"]
	intelligence = stats["intelligence"]
	gold = stats["gold"]
	
	life = stats["life"]
	last_life = life
	mana = stats["mana"]
	last_mana = mana
	
	# Send base data to StatEngine
	var base_mods = [
		# Life /  Mana
		StatEngineClass.create_modifier("life_max", StatEngineClass.ModifierForm.FLAT, stats.get("life_max")),
		StatEngineClass.create_modifier("mana_max", StatEngineClass.ModifierForm.FLAT, stats.get("mana_max")),
		StatEngineClass.create_modifier("life_regen_percent", StatEngineClass.ModifierForm.FLAT, 10), #0),
		StatEngineClass.create_modifier("mana_regen_percent", StatEngineClass.ModifierForm.FLAT, 10), #1.8),
	
		# Resistances
		StatEngineClass.create_modifier("resistance_fire", StatEngineClass.ModifierForm.FLAT, stats.get("resistance_fire", 0)),
		StatEngineClass.create_modifier("resistance_fire_max", StatEngineClass.ModifierForm.FLAT, stats.get("resistance_fire_max", 75)),
		StatEngineClass.create_modifier("resistance_cold", StatEngineClass.ModifierForm.FLAT, stats.get("resistance_cold", 0)),
		StatEngineClass.create_modifier("resistance_cold_max", StatEngineClass.ModifierForm.FLAT, stats.get("resistance_cold_max", 75)),
		StatEngineClass.create_modifier("resistance_lightning", StatEngineClass.ModifierForm.FLAT, stats.get("resistance_lightning", 0)),
		StatEngineClass.create_modifier("resistance_lightning_max", StatEngineClass.ModifierForm.FLAT, stats.get("resistance_lightning_max", 75)),
		StatEngineClass.create_modifier("resistance_chaos", StatEngineClass.ModifierForm.FLAT, stats.get("resistance_chaos", 0)),
		StatEngineClass.create_modifier("resistance_chaos_max", StatEngineClass.ModifierForm.FLAT, stats.get("resistance_chaos_max", 75)),
	]
	StatEngine.set_source("base_char", base_mods)
	
	if Game.current_char.has("position"):
		var player_position = Game.current_char["position"]
		
		if typeof(player_position) == TYPE_ARRAY and player_position.size() == 2:
			global_position = Vector2(player_position[0], player_position[1])
		elif typeof(player_position) == TYPE_VECTOR2:
			global_position = player_position

func save_current():
	var stats: Dictionary = Game.current_char["stats"]
	
	stats["level"] = level
	stats["strength"] = strength
	stats["dexterity"] = dexterity
	stats["intelligence"] = intelligence
	stats["gold"] = gold
	
	stats["life"] = life
	stats["life_max"] = StatEngine.get_stat("life_max")
	stats["mana"] = mana
	stats["mana_max"] = StatEngine.get_stat("mana_max")
	
	Game.current_char["stats"] = stats
