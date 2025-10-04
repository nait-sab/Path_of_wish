class_name SkillTooltip extends TooltipBase

@export var skill_icon: SkillIcon
@export var skill_name: Label
@export var skill_cost: Label
@export var skill_cooldown_type: Label
@export var skill_cooldown: Label
@export var skill_description: Label

func _ready() -> void:
	add_to_group("SkillTooltip")
	visible = false
	
static func get_any() -> SkillTooltip:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("SkillTooltip") as SkillTooltip

func show_skill(skill: SkillInstance, origin_owner: Control = null) -> void:
	show_for(origin_owner, TooltipBase.Placement.ABOVE_CENTERED)
	if skill.origin_gem:
		skill_name.text = skill.origin_gem.name
		skill_description.text = skill.origin_gem.description
		skill_icon.setupByTexture(skill.origin_gem.get_icon_texture(), SkillIcon.IconMode.SQUARE)
	else:
		skill_name.text = skill.name
		skill_description.text = ""
		skill_icon.setupById(skill.icon, SkillIcon.IconMode.SQUARE)
	skill_cost.text = "%d Mana" % skill.mana_cost
	
	var cooldown: float = 0.0
	if skill.attack_speed_scalar != 0.0:
		skill_cooldown_type.text = "Temps d'attaque"
		cooldown = skill.attack_speed_scalar
	elif skill.cast_speed_scalar != 0.0:
		skill_cooldown_type.text = "Temps d'utilisation"
		cooldown = skill.cast_speed_scalar
	
	skill_cooldown.text = "%s Sec" % String(ToolTipHelper.convert_comma_decimal(cooldown))
	reset_size()
	
func hide_item():
	hide_now()
