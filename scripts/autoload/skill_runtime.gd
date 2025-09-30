extends Node

const SKILLS := {
	"default_attack": preload("res://scenes/skills/default_attack/default_attack.tscn"),
	"fireball": preload("res://scenes/skills/projectiles/fireball/fireball.tscn"),
	"cleave": preload("res://scenes/skills/melee/cleave/cleave.tscn")
}

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
	
	var id := str(instance.final.get("id", ""))
	var scene: PackedScene = SKILLS.get(id, null)
	
	if scene == null:
		push_error("[SkillRuntime] No scene found for skill id : %s" % id)
		ActionBus.cast_rejected.emit("no_scene", instance, source)
		return
	
	ActionBus.cast_started.emit(instance, source)
	
	var node := scene.instantiate()
	var parent := World.get_any().projectiles_node
	parent.add_child(node)
	node.cast(instance, source, world_pos)
	
	ActionBus.cast_finished.emit(instance, source)

func _screen_to_world(screen_pos: Vector2, from: Node) -> Vector2:
	var viewport := from.get_viewport()
	if viewport == null:
		return screen_pos
	return viewport.get_canvas_transform().affine_inverse() * screen_pos
