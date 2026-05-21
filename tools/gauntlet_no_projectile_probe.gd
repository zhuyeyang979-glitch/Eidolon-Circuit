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
	fighter.setup_unit({"owner_id": 1, "role": "hero", "unit_name": "GauntletNoProjectile", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var event: Dictionary = fighter.begin_runtime_module_action("active", Dictionary(bindings[0]), Vector2.LEFT)
	if event.is_empty():
		_fail("Gauntlet action did not start.")
	if bool(event.get("projectile", false)) or String(event.get("projectile_behavior", "")) != "":
		_fail("Gauntlet action must not create projectile fields.")
	if String(event.get("module_action_profile", "")) != "blunt_gauntlet_extend_swing":
		_fail("Gauntlet event should remain a direct runtime module event.")
	print("GAUNTLET_NO_PROJECTILE_PROBE ok")
	quit()
