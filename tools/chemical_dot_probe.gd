extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, name: String):
	var stats := {
		"health": 160,
		"max_health": 160,
		"mass": 40.0,
		"radius": 0.18,
		"teamedit_runtime_topology": false,
	}
	var unit = main._create_unit(owner, "hero", stats, name, 1.0 + owner, 0.0)
	main._assign_unit_role(unit, "hero")
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var attacker = _spawn_unit(main, 1, "Sprayer")
	var target = _spawn_unit(main, 2, "Target")
	var event := {
		"projectile": true,
		"damage_type": "chemical",
		"projectile_damage_type": "chemical",
		"chemical_dot_duration": MainScene.STANDARD_CHEMICAL_SPRAYER_DOT_SECONDS,
		"chemical_dot_no_stack": true,
	}
	main._apply_chemical_dot_status(attacker, target, event, 24)
	var first_dps := float(target.get_meta("chemical_dot_dps", 0.0))
	main._apply_chemical_dot_status(attacker, target, event, 24)
	var second_dps := float(target.get_meta("chemical_dot_dps", 0.0))
	if absf(second_dps - first_dps) > 0.001:
		_fail("No-stack sprayer DoT should refresh/keep strongest DPS instead of adding.")
	var before_hp := int(target.health)
	for i in range(12):
		main._update_chemical_dot_status(target, 0.1)
	if int(target.health) >= before_hp:
		_fail("Chemical DoT should tick HP damage over time.")
	print("CHEMICAL_DOT_PROBE ok dps=%.2f hp=%d->%d" % [second_dps, before_hp, int(target.health)])
	quit()
