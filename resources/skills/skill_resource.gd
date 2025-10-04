class_name SkillResource extends Resource

@export_category("Informations")
@export var id: String
## Can be active or support
@export var type: String = "active"
@export var tags: Array[String] = []
@export var drop_level: int = 1
@export var uses_weapon: bool = false

@export_category("Levels")
@export var levels: Array[SkillLevelResource] = []
