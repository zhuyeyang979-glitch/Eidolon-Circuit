extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, role_key: String, name: String, ring: float, lane: float):
	var stats := {
		"health": 120,
		"max_health": 120,
		"mass": 20.0,
		"radius": 0.12,
		"teamedit_runtime_topology": false,
	}
	var unit = main._create_unit(owner, role_key, stats, name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var attacker = _spawn_unit(main, 1, "hero", "Sniper", 1.0, 0.0)
	var blocker = _spawn_unit(main, 2, "puppet", "Blocker", 1.42, 0.0)
	var locked = _spawn_unit(main, 2, "hero", "Locked", 1.82, 0.0)
	var event := {
		"projectile": true,
		"true_bullet_ready": true,
		"aim_locked": true,
		"locked_target": locked,
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"travel_path": "instant_line",
		"damage_type": "bullet",
		"projectile_damage_type": "bullet",
		"projectile_momentum": 88.0,
		"direction": Vector2.RIGHT,
		"range": 2.0,
		"lane_range": 0.22,
		"muscle_node": 0,
		"collision_group": {
			"projectile": true,
			"projectile_only": true,
			"material_class": "gun",
			"shape": "rifle",
			"gun_kind": "sniper",
			"ammo_kind": "bullet",
		},
	}
	var impact := main._first_projectile_impact(attacker, event)
	if impact.is_empty():
		_fail("Sniper true bullet should find the first obstruction.")
		return
	if impact.get("target", null) != blocker:
		_fail("Sniper true bullet should hit the first obstruction before the locked target.")
		return
	print("SNIPER_FIRST_OBSTRUCTION_PROBE ok target=%s" % String(impact.get("target").unit_name))
	quit()
