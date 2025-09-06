class_name HeldItem extends Control

@export var texture_rect: TextureRect
@export var skill_icon: SkillIcon
@export var amount_label: Label

var texture: Texture2D = null
var item: Item = null
var default_texture = preload("res://assets/textures/icon.svg")

func _ready() -> void:
	add_to_group("HeldItem")
	visible = false
	texture_rect.visible = true
	skill_icon.visible = false
	amount_label.visible = false
	
static func get_any() -> HeldItem:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("HeldItem") as HeldItem

func set_item(data: Item):
	item = data
	
	amount_label.text = str(item.stack_current)
	amount_label.visible = item.stack_max > 1
	
	var texture_size := Vector2(
		item.size.x * InventorySlot.SLOT_SIZE,
		item.size.y * InventorySlot.SLOT_SIZE
	)
	
	if item is Gem:
		texture_rect.visible = false
		skill_icon.visible = true
		skill_icon.setupByTexture(item.get_icon_texture())
		skill_icon.custom_minimum_size = texture_size
		skill_icon.size = texture_size
	else:
		texture_rect.visible = true
		skill_icon.visible = false
		texture_rect.texture = default_texture
		texture_rect.custom_minimum_size = texture_size
		texture_rect.size = texture_size
	
	visible = true
	
func clear_item():
	item = null
	texture_rect.texture = null
	texture_rect.visible = true
	skill_icon.visible = false
	amount_label.text = ""
	amount_label.visible = false
	visible = false
	
func _process(_delta: float) -> void:
	position = get_viewport().get_mouse_position()
