class_name FireballSkill extends SkillNode

@export_category("Data")
@export var speed := 900.0
@export var lifetime := 2.0

@export_category("Components")
@export var collision_shape: CollisionShape2D
@export var lifetime_timer: Timer

var _velocity := Vector2.ZERO

func _on_cast_started():
	# 1. Initial position
	global_position = source.global_position
	
	# 2. Direction
	_velocity = (target_world - global_position).normalized() * speed
	rotation = _velocity.angle()
	
	# 3. Timer
	lifetime_timer.wait_time = lifetime
	lifetime_timer.start()

func _physics_process(delta: float) -> void:
	position += _velocity * delta

func _on_lifetime_timeout() -> void:
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Enemy:
		apply_hit(body)
		queue_free()
