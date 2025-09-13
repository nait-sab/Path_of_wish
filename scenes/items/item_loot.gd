class_name ItemLoot extends Area2D

signal pickup_requested(node: ItemLoot)

@export var name_label: Label
@export var margin: MarginContainer
@export var box: PanelContainer
@export var collision: CollisionShape2D

var item: Item

func _ready() -> void:
	name_label.minimum_size_changed.connect(_resize_box_to_fit)

func setup(_item: Item) -> void:
	item = _item
	
	var txt := item.name
	if item.tags.has(Item.Tag.CURRENCY) and item.stack_max > 1:
		txt += " x%d" % int(item.stack_current)
		
	name_label.text = txt
	name_label.add_theme_color_override("font_color", rarity_color(item.rarity))
	
	_resize_box_to_fit()
		
func rarity_color(rarity: Item.Rarity) -> Color:
	match rarity:
		Item.Rarity.NORMAL: return Color.WHITE
		Item.Rarity.MAGIC: return Color(.3, .5, 1)
		Item.Rarity.RARE: return Color(1, 1, .3)
		Item.Rarity.UNIQUE: return Color(1, .5, .1)
		_: return Color.WHITE
		
func _resize_box_to_fit() -> void:
	var label_size := name_label.get_minimum_size()
	var padding := Vector2.ZERO
	padding.x = float(margin.get_theme_constant("margin_left")) + float(margin.get_theme_constant("margin_right"))
	padding.y = float(margin.get_theme_constant("margin_top")) + float(margin.get_theme_constant("margin_bottom"))
	var size = label_size + padding
	
	box.custom_minimum_size = Vector2(100, 0)
	box.size = size
	_update_shape()

func _update_shape() -> void:
	var size := box.size
	if size.x <= 0.0 or size.y <= 0.0:
		return
		
	var shape := RectangleShape2D.new()
	shape.extents = size * .5
	collision.shape = shape
	
	collision.position = box.position + size * .5

func _on_area_2d_mouse_entered() -> void:
	var tooltip = get_tree().get_first_node_in_group("ItemTooltip") as ItemTooltip
	tooltip.show_item(item)

func _on_area_2d_mouse_exited() -> void:
	var tooltip = get_tree().get_first_node_in_group("ItemTooltip") as ItemTooltip
	tooltip.hide_item()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo() and not event.double_click:
			emit_signal("pickup_requested", self)
