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
	var bindings: Array = stats.get("runtime_module_bindings", [])
	if bindings.is_empty():
		_fail("Gauntlet runtime binding missing.")
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"owner_id": 1, "role": "hero", "unit_name": "GauntletMomentum", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var event: Dictionary = fighter.begin_runtime_module_action("normal", Dictionary(bindings[0]), Vector2.RIGHT)
	if event.is_empty():
		_fail("Gauntlet action did not start.")
	if absf(float(event.get("terminal_momentum_mult", 0.0)) - MainScene.STANDARD_GAUNTLET_MOMENTUM_MULT) > 0.001:
		_fail("Gauntlet event should carry 1.5 terminal momentum multiplier.")
	if float(event.get("runtime_contact_speed", 0.0)) <= 0.0:
		_fail("Gauntlet runtime contact speed should be positive.")
	print("GAUNTLET_MOMENTUM_COEFF_PROBE ok mult=%.2f speed=%.2f" % [float(event.get("terminal_momentum_mult", 0.0)), float(event.get("runtime_contact_speed", 0.0))])
	quit()
