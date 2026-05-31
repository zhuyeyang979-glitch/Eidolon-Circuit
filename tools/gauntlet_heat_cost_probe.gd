extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const ProbeLib := preload("res://tools/gauntlet_runtime_probe_lib.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp := ProbeLib.build_unit(main)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	stats["heat_capacity"] = 200.0
	var bindings: Array = stats.get("runtime_module_bindings", [])
	if bindings.is_empty():
		_fail("Gauntlet runtime binding missing.")
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"owner_id": 1, "role": "hero", "unit_name": "GauntletHeat", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var normal_event: Dictionary = fighter.begin_runtime_module_action("normal", Dictionary(bindings[0]), Vector2.RIGHT)
	if normal_event.is_empty():
		_fail("Normal gauntlet action did not start: %s" % String(fighter.get_meta("last_module_gate_reason", "")))
	if absf(float(fighter.heat)) > 0.001:
		_fail("Normal gauntlet action should not consume heat.")
	fighter.runtime_module_actions.clear()
	fighter.action_cooldown = 0.0
	var armor_event: Dictionary = fighter.begin_runtime_module_action("armor", Dictionary(bindings[0]), Vector2.RIGHT)
	if armor_event.is_empty():
		_fail("Armor gauntlet action did not start.")
	var expected := 20.0
	if absf(float(fighter.heat) - expected) > 0.01:
		_fail("Armor gauntlet heat cost should be 10%% of heat capacity: got %.2f expected %.2f" % [float(fighter.heat), expected])
	print("GAUNTLET_HEAT_COST_PROBE ok heat=%.2f" % float(fighter.heat))
	quit()
