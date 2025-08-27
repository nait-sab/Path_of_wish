class_name ItemLoot extends Node2D

signal pickup_requested(node: ItemLoot)

@export var name_label: Label
@export var area: Area2D
@export var collision: CollisionShape2D

var item: Item

func setup(_item: Item) -> void:
	item = _item
	var txt := item.name
	if item.tags.has(Item.Tag.CURRENCY) and item.stack_max > 1:
		txt += "x%d" % int(item.stack_current)
	name_label.text = txt
	name_label.add_theme_color_override("font_color", rarity_color(item.rarity))
		
func rarity_color(rarity: Item.Rarity) -> Color:
	match rarity:
		Item.Rarity.NORMAL: return Color.WHITE
		Item.Rarity.MAGIC: return Color(.3, .5, 1)
		Item.Rarity.RARE: return Color(1, 1, .3)
		Item.Rarity.UNIQUE: return Color(1, .5, .1)
		_: return Color.WHITE

func _on_area_2d_mouse_entered() -> void:
	var tooltip = get_tree().get_first_node_in_group("ItemTooltip") as ItemTooltip
	tooltip.show_item(item)

func _on_area_2d_mouse_exited() -> void:
	var tooltip = get_tree().get_first_node_in_group("ItemTooltip") as ItemTooltip
	tooltip.hide_item()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("pickup_requested", self)
