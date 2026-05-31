extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, name: String, ring: float, lane: float):
	var unit = main._create_unit(owner, "hero", {
		"health": 100,
		"max_health": 100,
		"mass": 20.0,
		"radius": 0.18,
		"teamedit_runtime_topology": false,
	}, name, ring, lane)
	main._assign_unit_role(unit, "hero")
	return unit


func _event() -> Dictionary:
	return {
		"projectile": true,
		"gun_activation": true,
		"module_action_profile": "gun_activate",
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"travel_path": "instant_line",
		"damage_type": "bullet",
		"projectile_damage_type": "bullet",
		"direction": Vector2.RIGHT,
		"range": 2.0,
		"lane_range": 0.14,
		"muscle_node": 0,
		"collision_group": {
			"projectile": true,
			"projectile_only": true,
			"material_class": "gun",
			"shape": "rifle",
			"gun_kind": "sniper",
		},
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.mobius_enabled = true
	var attacker = _spawn_unit(main, 1, "Shooter", 1.0, 0.0)
	var target = _spawn_unit(main, 2, "Target", 1.9, 0.0)
	main.mobius_rotation_state = {"angle": 0.0, "pivot": Vector2.ZERO}
	var hit_a: Dictionary = main._first_projectile_impact(attacker, _event())
	main.mobius_rotation_state = {"angle": 1.45, "pivot": Vector2(8.0, -2.0)}
	var hit_b: Dictionary = main._first_projectile_impact(attacker, _event())
	if hit_a.is_empty() or hit_b.is_empty():
		_fail("Projectile should hit target in both visual rotations.")
		return
	if hit_a.get("target", null) != target or hit_b.get("target", null) != target:
		_fail("Visual rotation must not change projectile target ordering.")
		return
	if absf(float(hit_a.get("distance", 0.0)) - float(hit_b.get("distance", 0.0))) > 0.001:
		_fail("Visual rotation must not bend projectile gameplay distance.")
		return
	print("PROJECTILE_PATH_NOT_BENT_BY_MOBIUS_PROBE ok distance=%.3f" % float(hit_a.get("distance", 0.0)))
	quit()
