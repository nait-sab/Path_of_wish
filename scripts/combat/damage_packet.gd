# Helper script to handle a hit with damages
class_name DamagePacket extends RefCounted

# Tags ("attack", "melee", "projectile", "spell")
# Structure -> tags = {"attack": true, "melee": true, "projectile": false, "spell": false}
var tags: Dictionary = {}

# Damage structure
var physical: float = 0.0
var fire: float = 0.0
var cold: float = 0.0
var lightning: float = 0.0
var chaos: float = 0.0

# Crit
var can_crit: bool = true
var crit_chance: float = 0.0			# 0.30 -> +30%
var crit_multiplier: float = 1.50	# 1.50 -> +50%

func total() -> float:
	return physical + fire + cold + lightning + chaos
	
static func melee_physical(amount: float) -> DamagePacket:
	var hit = DamagePacket.new()
	hit.tags = { "attack": true, "melee": true, "hit": true }
	hit.physical = max(amount, 0.0)
	return hit
