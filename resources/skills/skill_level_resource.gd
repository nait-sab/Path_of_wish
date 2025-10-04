class_name SkillLevelResource extends Resource

@export_category("Level")
@export var level: int = 1
@export var xp_to_next: int = 0

@export_category("Requirements")
@export var min_level: int = 1
@export var min_strength: int = 0
@export var min_dexterity: int = 0
@export var min_intelligence: int = 0

@export_category("Cost / Speed")
@export var mana_cost: int = 0
@export var cast_speed_scalar: float = 0
@export var attack_speed_scalar: float = 0

@export_category("Damage")
@export var weapon_physical_percent: float = 0.0
@export var effectiveness_of_added_damage: float = 1.0
@export var damage_base: Dictionary = {}
@export var crit_chance_percent: float = 0
@export var radius: int = 0
@export var projectile_speed: int = 0

@export_category("Support Effects")
@export var effects: Dictionary = {}
