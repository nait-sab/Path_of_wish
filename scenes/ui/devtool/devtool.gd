class_name Devtool extends CanvasLayer

@export var root: Panel

func ready():
	if not OS.is_debug_build():
		queue_free()
		return

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("toggle_devtool"):
		_toggle()

func _toggle() -> void:
	root.visible = not root.visible

func _on_exit_pressed() -> void:
	_toggle()

func _on_debug_button_1_pressed() -> void:
	# TODO : Move the enemy spawn action here
	pass

func _on_debug_button_2_pressed() -> void:
	var stats = StatEngine.get_final_stats()
	print("--- DEBUG Stats ---")
	for key in stats.keys():
		print("%s : %s" % [key, str(stats[key])])
	print("-------------------")

func _on_debug_button_3_pressed() -> void:
	var player: Player = get_tree().get_first_node_in_group("Player")
	if not player:
		print("[DevTools] Player not found")
		return
		
	print("\n=== Test Damage Packets ===")

	# Exemple 1 : Small physical hit
	var pkt1 = DamagePacket.melee_physical(10)
	var report1 = player.receive_hit(pkt1)
	print("[Test] Phys 10 →", report1.debug_string())
	_dump_layers("Physical+Cold", report1)

	# Exemple 2 : Big critical hit
	var pkt2 = DamagePacket.melee_physical(50)
	pkt2.can_crit = true
	pkt2.crit_chance = 1.0
	var report2 = player.receive_hit(pkt2)
	print("[Test] Phys 50 CRIT →", report2.debug_string())
	_dump_layers("Physical+Cold", report2)

	# Exemple 3 : Elemental fire hit
	var pkt3 = DamagePacket.new()
	pkt3.fire = 30
	pkt3.tags = {"spell": true, "hit": true}
	var report3 = player.receive_hit(pkt3)
	print("[Test] Fire 30 →", report3.debug_string())
	_dump_layers("Physical+Cold", report3)

	# Exemple 4 : mix Physical + Cold
	var pkt4 = DamagePacket.new()
	pkt4.physical = 20
	pkt4.cold = 15
	pkt4.tags = {"attack": true, "projectile": true}
	var report4 = player.receive_hit(pkt4)
	print("[Test] Physical+Cold →", report4.debug_string())
	_dump_layers("Physical+Cold", report4)
	
func _dump_layers(label: String, report: DamageReport) -> void:
	print("--- ", label, " ---")
	print("before            : ", report.before)
	print("after_block       : ", report.after_block)
	print("after_armour      : ", report.after_armour)
	print("after_resistances : ", report.after_resistances)
	print("applied ES=", report.applied_to_energy_shield, " life=", report.applied_to_life, " total=", report.final_total)

func _on_debug_button_4_pressed() -> void:
	var level := 10
	var enemy_rarity := Item.Rarity.MAGIC
	var drops := LootDb.roll_for_enemy(level, enemy_rarity)
	print("--- LOOT (lvl=%d, rarity=%s) ---" % [level, str(enemy_rarity)])
	for item: Item in drops:
		var stack := (item.stack_current if item.tags.has(Item.Tag.CURRENCY) else 1)
		print("• %s (%s) x%d" % [item.name, str(item.rarity), stack])
