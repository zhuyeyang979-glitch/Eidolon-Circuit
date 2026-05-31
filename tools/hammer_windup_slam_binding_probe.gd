extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const ProbeLib := preload("res://tools/blunt_terminal_probe_lib.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_index := ProbeLib.first_module(main, "blunt_hammer_windup_slam")
	if module_index < 0:
		_fail("Hammer Windup-Slam module missing.")
	var hammer_index := ProbeLib.first_part(main, func(part): return bool(part.get("blunt_hammer", false)))
	var shield_index := ProbeLib.first_part(main, func(part): return bool(part.get("blunt_shield", false)))
	if hammer_index < 0 or shield_index < 0:
		_fail("Hammer or shield catalog target missing.")
	var legal := ProbeLib.build_unit(main, hammer_index, module_index, "hammer_terminal", "HAMMER")
	var legal_stats: Dictionary = main._compute_unit_stats(1, "hero", -1, legal)
	var legal_bindings: Array = legal_stats.get("runtime_module_bindings", [])
	if legal_bindings.size() != 1 or not bool(Dictionary(legal_bindings[0]).get("runtime_valid", false)):
		_fail("Hammer terminal should bind Hammer Windup-Slam.")
	var invalid := ProbeLib.build_unit(main, shield_index, module_index, "hammer_terminal", "SHIELD")
	var invalid_stats: Dictionary = main._compute_unit_stats(1, "hero", -1, invalid)
	var invalid_bindings: Array = invalid_stats.get("runtime_module_bindings", [])
	if invalid_bindings.is_empty() or bool(Dictionary(invalid_bindings[0]).get("runtime_valid", true)):
		_fail("Shield terminal must not bind Hammer Windup-Slam.")
	print("HAMMER_WINDUP_SLAM_BINDING_PROBE ok")
	quit()
