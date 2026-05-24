extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, role_key: String, name: String, ring: float, lane: float, stats_extra: Dictionary = {}):
	var stats := {
		"health": 120,
		"max_health": 120,
		"mass": 20.0,
		"radius": 0.14,
		"teamedit_runtime_topology": false,
	}
	for key in stats_extra.keys():
		stats[key] = stats_extra[key]
	var unit = main._create_unit(owner, role_key, stats, name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _projectile_source() -> Dictionary:
	return {
		"projectile": true,
		"projectile_only": true,
		"material_class": "gun",
		"shape": "rifle",
		"gun_kind": "sniper",
		"ammo_kind": "bullet",
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var attacker = _spawn_unit(main, 1, "hero", "PROJECTILE USER", 5.0, 0.0, {"ammo_capacity": {"bullet": 10, "laser": 7, "explosive": 3}})
	var target = _spawn_unit(main, 2, "hero", "COVERED HERO", 7.0, 0.0)
	var wall = _spawn_unit(main, 2, "barrier", "COVER WALL", 6.0, 0.0, {"is_cage_wall": true, "material_class": "barrier_wall", "radius": 0.18})
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": target, "barrier": wall, "puppet": []}}

	var missile_event := {
		"projectile": true,
		"gun_activation": true,
		"module_action_profile": "missile_lock_activate",
		"gun_kind": "missile_launcher",
		"ammo_kind": "explosive",
		"projectile_style": "missile",
		"projectile_behavior": "explosive",
		"travel_path": "homing",
		"direction": Vector2.RIGHT,
		"range": 3.4,
		"lane_range": 0.11,
		"missile_lock_range": 3.4,
		"missile_lock_cone_degrees": 52.0,
		"missile_lock_target_classes": ["hero"],
	}
	if main._acquire_missile_lock_target(attacker, missile_event) != null:
		_fail("Missile lock should not acquire a hero hidden behind map occlusion.")

	var sniper_event := {
		"projectile": true,
		"true_bullet_ready": true,
		"aim_locked": true,
		"locked_target": target,
		"module_action_profile": "gun_activate",
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"travel_path": "instant_line",
		"damage_type": "bullet",
		"projectile_damage_type": "bullet",
		"direction": Vector2.RIGHT,
		"range": 3.4,
		"lane_range": 0.1,
		"collision_group": _projectile_source(),
		"muscle_node": 0,
	}
	if not main._true_bullet_target_blocked(attacker, target, sniper_event):
		_fail("Sniper line should be blocked by the same map occlusion helper.")

	var laser_event := {
		"projectile": true,
		"gun_activation": true,
		"module_action_profile": "laser_beam_activate",
		"projectile_behavior": "laser",
		"projectile_style": "beam",
		"travel_path": "instant_line",
		"damage_type": "laser",
		"projectile_damage_type": "laser",
		"direction": Vector2.RIGHT,
		"range": 4.2,
		"lane_range": 0.09,
		"collision_group": _projectile_source(),
		"muscle_node": 0,
	}
	if not main._attack_part_hit(attacker, target, laser_event).is_empty():
		_fail("Laser beam should not hit a target behind map occlusion.")
	if String(laser_event.get("map_occlusion_kind", "")) != MainScene.MAP_OCCLUSION_CAGE:
		_fail("Laser blocked event should record cage occlusion.")
	print("MAP_OCCLUSION_PROJECTILE_INTEGRATION_PROBE ok")
	quit()
