extends Node

# Generic settings
const DEFAULT_PROJECTILE_SPEED := 900.0
const DEFAULT_PROJECTILE_RADIUS := 10.0
const DEFAULT_PROJECTILE_LIFETIME := 2.0
const DEFAULT_MELEE_RADIUS := 200.0
const ARC_DEGREES := 180.0

func _ready() -> void:
	ActionBus.cast_requested.connect(_on_cast_requested)

func _on_cast_requested(instance: SkillInstance, source: Node, target_pos: Vector2) -> void:
	if instance == null or source == null:
		ActionBus.cast_rejected.emit("invalid_args", instance, source)
		return
	
	var world_pos := _screen_to_world(target_pos, source)
	
	if world_pos == null:
		ActionBus.cast_rejected.emit("no_camera", instance, source)
		return
	
	ActionBus.cast_started.emit(instance, source)
	
	var id := str(instance.final.get("id", ""))
	match id:
		"fireball":
			_cast_fireball(instance, source, world_pos)
		"cleave":
			_cast_cleave(instance, source, world_pos)
		"_":
			printerr("[SKILL_RUNTIME] Skill not handled : %s" % id)
	
	ActionBus.cast_finished.emit(instance, source)

func _cast_fireball(instance: SkillInstance, source: Node, target_world: Vector2) -> void:
	var origin := _get_global_position(source)
	var dir := (target_world - origin).normalized()
	var speed := float(instance.final.get("projectile_speed", DEFAULT_PROJECTILE_SPEED))
	var radius := float(instance.final.get("projectile_radius", DEFAULT_PROJECTILE_RADIUS))
	var life := float(instance.final.get("projectile_lifetime", DEFAULT_PROJECTILE_LIFETIME))
	
	var projectile := _spawn_fireball_node(radius)
	if projectile == null:
		return
	
	projectile.global_position = origin
	projectile.rotation = dir.angle()
	projectile.set("velocity", dir * speed)
	projectile.set("lifetime", life)
	projectile.set("owner_source", source)
	projectile.set("skill_instance", instance)
	World.get_any().projectiles_node.add_child(projectile)

func _spawn_fireball_node(radius: float) -> Node2D:
	var root := Node2D.new()
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	area.add_child(shape)
	root.add_child(area)
	
	var sprite := ColorRect.new()
	sprite.color = Color(1, .4, .1, .6)
	sprite.size = Vector2(radius * 2, radius * 2)
	sprite.position = Vector2(-radius, -radius)
	root.add_child(sprite)
	
	var script := GDScript.new()
	script.source_code = _FIREBALL_BEHAVIOR()
	script.reload()
	root.set_script(script)
	
	area.body_entered.connect(func(body):
		if body is Enemy:
			print("Enemy touched")
			_send_hit(root.get("skill_instance"), body)
			root.queue_free()
	)
	return root

func _FIREBALL_BEHAVIOR() -> String:
	return '''
extends Node2D
var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 2.0
var owner_source: Node
var skill_instance

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
'''

func _cast_cleave(instance: SkillInstance, source: Node, target_world: Vector2) -> void:
	var origin := _get_global_position(source)
	var radius := float(instance.final.get("melee_radius", DEFAULT_MELEE_RADIUS))
	var arc_deg := float(instance.final.get("arc_degrees", ARC_DEGREES))
	
	var enemies := _get_enemies_in_arc(origin, target_world, radius, arc_deg, 64)
	print("enemies in range : %d" % enemies.size())
	for enemy: Enemy in enemies:
		print("Enemy touched")
		_send_hit(instance, enemy)

func _screen_to_world(screen_pos: Vector2, from: Node) -> Vector2:
	var viewport := from.get_viewport()
	if viewport == null:
		return screen_pos
	return viewport.get_canvas_transform().affine_inverse() * screen_pos

func _get_global_position(node: Node) -> Vector2:
	if node is Node2D:
		return (node as Node2D).global_position
	if node is Control:
		return (node as Control).get_global_rect().get_center()
	return Vector2.ZERO

func _get_enemies_in_arc(origin: Vector2, aim_point: Vector2, max_range: float, arc_deg: float, pad: float = 64.0) -> Array:
	var hits: Array = []
	var to_aim := (aim_point - origin)
	if to_aim.length_squared() < 1e-6:
		to_aim = Vector2.RIGHT
	var facing := to_aim.normalized()
	var cos_half := cos(deg_to_rad(arc_deg * .5))
	var max_dist := max_range + pad
	
	for enemy: Enemy in get_tree().get_nodes_in_group("Enemy"):
		var to_enemy := enemy.global_position - origin
		var dist := to_enemy.length()
		if dist > max_dist:
			continue
		var dir: Vector2 = to_enemy / max(1e-6, dist)
		if facing.dot(dir) >= cos_half:
			hits.append(enemy)
	return hits

func _send_hit(instance: SkillInstance, enemy: Enemy) -> void:
	var weapon = Inventory.get_any().get_main_weapon()
	var packet: DamagePacket = SkillMath.build_packet(
		instance, 
		Callable(StatEngine, "get_stat"), 
		weapon
	)
	print(packet.debug_string())
	enemy.receive_hit(packet)
