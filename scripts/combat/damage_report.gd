class_name DamageReport extends RefCounted

var evaded: bool = false
var blocked: bool = false
var crit: bool = false

# Data for debug
var before: Dictionary = {}
var after_block: Dictionary = {}
var after_armour: Dictionary = {}
var after_resistances: Dictionary = {}

# Final damages
var applied_to_energy_shield: float = 0.0
var applied_to_life: float = 0.0
var final_total: float = 0.0

func debug_string() -> String:
	return "crit=%s evade=%s blocked=%s final=%.1f [ES=%.1f / Life=%.1f]" % [
		str(crit), str(evaded), str(blocked), final_total, applied_to_energy_shield, applied_to_life
	]

func clone_layers() -> Dictionary:
	return {
		"before": before.duplicate(),
		"after_block": after_block.duplicate(),
		"after_armour": after_armour.duplicate(),
		"after_resistances": after_resistances.duplicate()
	}
