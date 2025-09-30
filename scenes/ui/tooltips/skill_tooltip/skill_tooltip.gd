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
	if skill.gem:
		skill_name.text = skill.gem.name
		skill_description.text = skill.gem.description
		skill_icon.setupByTexture(skill.gem.get_icon_texture(), SkillIcon.IconMode.SQUARE)
	else:
		skill_name.text = skill.final.get("name", "")
		skill_description.text = ""
		skill_icon.setupById(skill.final.get("icon", ""), SkillIcon.IconMode.SQUARE)
	skill_cost.text = "%d Mana" % skill.final.get("mana_cost", 0)
	
	var cooldown: float = 0.0
	if skill.final.get("attack_speed_scalar", -1.0) != -1.0:
		skill_cooldown_type.text = "Temps d'attaque"
		cooldown = skill.final.get("attack_speed_scalar")
	elif skill.final.get("cast_speed_scalar", -1.0) != -1.0:
		skill_cooldown_type.text = "Temps d'utilisation"
		cooldown = skill.final.get("cast_speed_scalar")
	
	skill_cooldown.text = "%s Sec" % String(ToolTipHelper.convert_comma_decimal(cooldown))
	reset_size()
	
func hide_item():
	hide_now()
