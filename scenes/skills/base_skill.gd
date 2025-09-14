class_name SkillNode extends Node2D

var instance: SkillInstance
var source: Node2D
var target_world: Vector2

func cast(_instance: SkillInstance, _source: Node, _target_world: Vector2) -> void:
	instance = _instance
	source = _source
	target_world = _target_world
	_on_cast_started()

# Method to override inside skill scenes
func _on_cast_started() -> void:
	pass

# --- Helpers
func apply_hit(enemy: Enemy) -> void:
	var weapon = Inventory.get_any().get_main_weapon()
	var packet: DamagePacket = SkillMath.build_packet(
		instance,
		Callable(StatEngine, "get_stat"),
		weapon
	)
	enemy.receive_hit(packet)
