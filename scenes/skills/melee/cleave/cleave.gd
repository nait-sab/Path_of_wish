class_name CleaveSkill extends SkillNode

@export_category("Data")
@export var melee_radius := 200
@export var arc_degrees := 180
@export var vfx_thickness := 70
@export var vfx_duration := .18

const ArcSweepScene := preload("res://assets/vfx/arc_sweep/arc_sweep.tscn")

func _on_cast_started() -> void:
	var origin := source.global_position
	var enemies := _get_enemies_in_arc(origin, target_world, melee_radius, arc_degrees, 64)
	for enemy: Enemy in enemies:
		apply_hit(enemy)
	_spawn_vfx(origin, target_world)
	queue_free()

func _get_enemies_in_arc(origin: Vector2, aim_point: Vector2, max_range: float, arc_deg: float, pad: float = 64.0) -> Array[Enemy]:
	var hits: Array[Enemy] = []
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

func _spawn_vfx(origin: Vector2, aim: Vector2) -> void:
	var vfx: ArcSweep = ArcSweepScene.instantiate()
	vfx.global_position = origin
	# Rotation toward cursor
	vfx.rotation = (aim - origin).angle()
	vfx.radius = melee_radius
	vfx.thickness = arc_degrees
	vfx.duration = vfx_duration
	
	var parent := World.get_any().projectiles_node
	parent.add_child(vfx)
