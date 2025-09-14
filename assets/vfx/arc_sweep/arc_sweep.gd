class_name ArcSweep extends Node2D

@export_category("Data")
@export var radius: float = 200
@export var thickness: float = 60
@export var arc_degrees: float = 180
@export var duration: float = 0.2
@export var color_fill: Color = Color(1, .25, .1, .45)
@export var color_rim: Color = Color(1, .65, .25, .85)
@export var segments: int = 48

@export_category("Components")
@export var fill: Polygon2D
@export var rim: Line2D

func _ready() -> void:
	_build_geometry()
	_play_anim()

func _build_geometry() -> void:
	var start_angle := -deg_to_rad(arc_degrees) * .5
	var end_angle := deg_to_rad(arc_degrees) * .5
	var inner_radius: float = max(0, radius - thickness)
	var outer_radius := radius
	
	# Ring
	var poly: PackedVector2Array = []
	for index in range(segments + 1):
		var weight := float(index) / float(segments)
		var angle: float = lerp(start_angle, end_angle, weight)
		poly.append(Vector2(cos(angle), sin(angle)) * outer_radius)
	for index in range(segments, -1, -1):
		var weight2 := float(index) / float(segments)
		var angle2: float = lerp(start_angle, end_angle, weight2)
		poly.append(Vector2(cos(angle2), sin(angle2)) * inner_radius)
	
	fill.polygon = poly
	fill.color = color_fill
	
	# Glow edge
	var rim_points: PackedVector2Array = []
	for index in range(segments + 1):
		var weight := float(index) / float(segments)
		var angle: float = lerp(start_angle, end_angle, weight)
		rim_points.append(Vector2(cos(angle), sin(angle)) * outer_radius)
	
	rim.points = rim_points
	rim.width = 10
	rim.default_color = color_rim

func _play_anim() -> void:
	modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1, .05).from(0)
	tween.tween_property(self, "modulate:a", 0, max(.01, duration - .05))
	tween.finished.connect(queue_free)
