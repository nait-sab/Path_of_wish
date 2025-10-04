class_name SupportResource extends Resource

@export_category("Informations")
@export var id: String
## Can be active or support
@export var type: String = "support"
@export var applies_to_tags: Array[String] = []
@export var drop_level: int = 1

@export_category("Levels")
@export var levels: Array[SkillLevelResource] = []
