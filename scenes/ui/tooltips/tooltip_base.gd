class_name TooltipBase extends PanelContainer

enum Placement {
	FOLLOW_MOUSE,
	ABOVE_CENTERED,
	BELOW_CENTERED,
	RIGHT_CENTERED,
	LEFT_CENTERED,
}

@export var margin_from_origin: float = 6.0
@export var screen_padding: float = 10.0

var _origin_owner: Control
var _pending_hide: SceneTreeTimer
var _placement: Placement

func _ready() -> void:
	resized.connect(_move_position)

func show_for(owner: Control, placement: Placement = Placement.FOLLOW_MOUSE) -> void:
	_origin_owner = owner
	_pending_hide = null
	_placement = placement
	visible = true
	_on_show_started()
	call_deferred("_move_position")

func request_hide(request_control: Control) -> void:
	if request_control != _origin_owner:
		return
	if _pending_hide != null:
		return
	_pending_hide = get_tree().create_timer(0.0)
	_pending_hide.timeout.connect(func():
		_pending_hide = null
		if request_control != _origin_owner:
			return
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered != null and (hovered == request_control or request_control.is_ancestor_of(hovered)):
			return
		hide_now()
	)

func _move_position() -> void:
	if not visible:
		return
	
	var viewport := get_viewport()
	var viewport_rect := viewport.get_visible_rect()
	var pos := Vector2.ZERO
	
	if _placement == Placement.FOLLOW_MOUSE or _origin_owner == null or not is_instance_valid(_origin_owner):
		pos = viewport.get_mouse_position()
	else:
		var relative = _origin_owner.get_global_rect()
		match _placement:
			Placement.ABOVE_CENTERED:
				pos.x = relative.position.x + (relative.size.x - size.x) * .5
				pos.y = relative.position.y - size.y - margin_from_origin
			Placement.BELOW_CENTERED:
				pos.x = relative.position.x + (relative.size.x - size.x) * .5
				pos.y = relative.end.y + margin_from_origin
			Placement.RIGHT_CENTERED:
				pos.x = relative.end.x + margin_from_origin
				pos.y = relative.position.y + (relative.size.y - size.y) * .5
			Placement.LEFT_CENTERED:
				pos.x = relative.position.x - size.x - margin_from_origin
				pos.y = relative.position.y + (relative.size.y - size.y) * .5
			_:
				pos = viewport.get_mouse_position()
	
	pos.x = clamp(pos.x, screen_padding, viewport_rect.size.x - size.x - screen_padding)
	pos.y = clamp(pos.y, screen_padding, viewport_rect.size.y - size.y - screen_padding)
	position = pos

func hide_now():
	visible = false
	_origin_owner = null
	_on_hide_done()

func _process(_delta: float) -> void:
	if not visible:
		return
	_move_position()

func _on_show_started():
	pass

func _on_hide_done():
	pass
