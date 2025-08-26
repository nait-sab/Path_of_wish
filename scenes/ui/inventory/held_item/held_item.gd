class_name HeldItem extends Control

@export var texture_rect: TextureRect
@export var amount_label: Label

var texture: Texture2D = null
var item: Item = null
var default_texture = preload("res://assets/textures/icon.svg")

func _ready() -> void:
	visible = false

func set_item(data: Item):
	item = data
	texture_rect.texture = default_texture
	amount_label.text = str(item.stack_current)
	amount_label.visible = item.stack_max > 1
	texture_rect.size = Vector2(
		item.size.x * InventorySlot.SLOT_SIZE,
		item.size.y * InventorySlot.SLOT_SIZE
	)
	visible = true
	
func clear_item():
	texture_rect.texture = null
	item = null
	amount_label.text = ""
	visible = false
	
func _process(_delta: float) -> void:
	position = get_viewport().get_mouse_position()
