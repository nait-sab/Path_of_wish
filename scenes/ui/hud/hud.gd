extends CanvasLayer

@export var life_orb: TextureProgressBar
@export var mana_orb: TextureProgressBar

var player: CharacterBody2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
	if player:
		player.connect("stats_changed", Callable(self, "_on_stats_changed"))
		_on_stats_changed(player)
		
func _on_stats_changed(target: Player) -> void:
	life_orb.max_value = StatEngine.get_stat("life_max")
	life_orb.value = target.life
	mana_orb.max_value = StatEngine.get_stat("mana_max")
	mana_orb.value = target.mana
