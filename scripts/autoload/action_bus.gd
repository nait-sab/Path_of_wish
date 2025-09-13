extends Node

signal cast_requested(instance: SkillInstance, source: Node, target_pos: Vector2)

# Not used for now
signal cast_started(instance: SkillInstance, source: Node)
signal cast_finished(instance: SkillInstance, source: Node)
signal cast_rejected(instance: SkillInstance, source: Node)

func request_cast(instance: SkillInstance, source: Node, target_pos: Vector2) -> void:
	if instance == null or source == null:
		emit_signal("cast_rejected", "invalid_args", instance, source)
		return
	
	if get_tree().paused:
		emit_signal("cast_rejected", "paused", instance, source)
		return
	
	cast_requested.emit(instance, source, target_pos)
