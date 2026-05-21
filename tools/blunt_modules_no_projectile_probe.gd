extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const ProbeLib := preload("res://tools/blunt_terminal_probe_lib.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _check(main, profile: String, flag: String, target_kind: String) -> void:
	var module_index := ProbeLib.first_module(main, profile)
	var terminal_index := ProbeLib.first_part(main, func(part): return bool(part.get(flag, false)))
	if module_index < 0 or terminal_index < 0:
		_fail("%s setup missing." % profile)
	var unit_bp := ProbeLib.build_unit(main, terminal_index, module_index, target_kind)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var bindings: Array = stats.get("runtime_module_bindings", [])
	if bindings.is_empty():
		_fail("%s runtime binding missing." % profile)
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"owner_id": 1, "role": "hero", "unit_name": profile, "stats": stats})
	fighter.deploy(0.0, 0.0)
	var event: Dictionary = fighter.begin_runtime_module_action("active", Dictionary(bindings[0]), Vector2.RIGHT)
	if event.is_empty():
		_fail("%s did not start." % profile)
	if bool(event.get("projectile", false)) or String(event.get("projectile_style", "")) != "" or String(event.get("travel_path", "")) != "":
		_fail("%s must remain explicit non-projectile melee runtime action." % profile)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	_check(main, "blunt_shield_guard_bash", "blunt_shield", "shield_terminal")
	_check(main, "blunt_hammer_windup_slam", "blunt_hammer", "hammer_terminal")
	print("BLUNT_MODULES_NO_PROJECTILE_PROBE ok")
	quit()
