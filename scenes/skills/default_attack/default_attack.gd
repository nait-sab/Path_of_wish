class_name DefaultAttack extends SkillNode

@export_category("Melee")
@export var radius: float = 140
@export var arc_degrees: float = 60
@export var cast_time: float = 1

enum _STYLE {UNARMED, MELEE, RANGED, MAGIC}
var _style: _STYLE

func _on_cast_started():
	_style = _define_style()
	
	# 1. Initial position
	global_position = source.global_position
	
	# 2. Cast time - Used later
	var scalar := float(instance.final.get("cast_speed_scalar", 1.0))
	var time: float = max(0.001, cast_time / scalar)
	
	# 3. Use the correct attack based on the main hand
	match _style:
		_STYLE.UNARMED:
			_do_melee(true)
		_STYLE.MELEE:
			_do_melee(false)
		_STYLE.RANGED:
			_do_ranged_projectile()
		_STYLE.MAGIC:
			_do_magic_projectile()
	
	queue_free()

func _define_style() -> _STYLE:
	var weapon = Inventory.get_any().get_main_weapon()
	if weapon == null:
		return _STYLE.UNARMED
	
	var tags = weapon.tags
	if tags.has(Item.Tag.BOW):
		return _STYLE.RANGED
	if tags.has(Item.Tag.SCEPTRE) or tags.has(Item.Tag.WAND):
		return _STYLE.MAGIC
	return _STYLE.MELEE

func _do_melee(unarmed: bool) -> void:
	var origin := source.global_position
	var enemy = _find_enemy_near_cursor(origin, target_world, radius, arc_degrees)
	
	if enemy == null:
		return
	
	if not unarmed:
		apply_hit(enemy)
	else:
		var damage := randi_range(
			instance.final.get("unarmed_min", 2),
			instance.final.get("unarmed_max", 6)
		)
		
		var packet := SkillMath.build_packet(instance, Callable(StatEngine, "get_stat"), null)
		packet.physical = damage
		enemy.receive_hit(packet)

func _find_enemy_near_cursor(origin: Vector2, cursor: Vector2, max_range: float, arc_deg: float) -> Enemy:
	var near: Enemy = null
	var near_distance := INF
	
	var to_aim := cursor - origin
	if to_aim.length_squared() < 1e-6:
		to_aim = Vector2.RIGHT
	var facing := to_aim.normalized()
	var cos_half := cos(deg_to_rad(arc_deg * .5))
	var max_distance := max_range * max_range
	
	for enemy: Enemy in get_tree().get_nodes_in_group("Enemy"):
		var to_enemy := enemy.global_position - origin
		var distance := to_enemy.length()
		if distance > max_distance:
			continue
		var dir: Vector2 = to_enemy / max(1e-6, distance)
		if facing.dot(dir) < cos_half:
			continue
		
		var distance_to_cursor := (enemy.global_position - cursor).length_squared()
		if distance_to_cursor < near_distance:
			near_distance = distance_to_cursor
			near = enemy
	return near

func _do_ranged_projectile() -> void:
	pass

func _do_magic_projectile() -> void:
	pass
