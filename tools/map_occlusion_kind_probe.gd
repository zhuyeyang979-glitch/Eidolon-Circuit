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
		"radius": 0.16,
		"teamedit_runtime_topology": false,
	}
	for key in stats_extra.keys():
		stats[key] = stats_extra[key]
	var unit = main._create_unit(owner, role_key, stats, name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _base_event() -> Dictionary:
	return {
		"projectile": true,
		"gun_activation": true,
		"module_action_profile": "missile_lock_activate",
		"projectile_style": "missile",
		"projectile_behavior": "explosive",
		"travel_path": "homing",
		"direction": Vector2.RIGHT,
		"range": 3.4,
		"lane_range": 0.11,
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var attacker = _spawn_unit(main, 1, "hero", "OCCLUSION ATTACKER", 5.0, 0.0)
	var target = _spawn_unit(main, 2, "hero", "OCCLUSION TARGET", 7.0, 0.0)
	_spawn_unit(main, 2, "barrier", "CAGE WALL", 6.0, 0.0, {"is_cage_wall": true, "material_class": "barrier_wall", "radius": 0.18})
	var kind := main._map_occlusion_kind_between(attacker, target, _base_event())
	if kind != MainScene.MAP_OCCLUSION_CAGE:
		_fail("Expected cage occlusion, got %s." % kind)

	main._clear_all_units()
	var ally_attacker = _spawn_unit(main, 1, "hero", "ALLY SHOOTER", 5.0, 0.0)
	var enemy_target = _spawn_unit(main, 2, "hero", "ENEMY TARGET", 7.0, 0.0)
	_spawn_unit(main, 1, "barrier", "ALLY SCREEN", 6.0, 0.0, {"is_one_way_shield": true, "material_class": "one_way_shield", "shield_pass_mode": "ally", "radius": 0.18})
	kind = main._map_occlusion_kind_between(ally_attacker, enemy_target, _base_event())
	if kind != MainScene.MAP_OCCLUSION_NONE:
		_fail("Ally one-way screen should pass allied fire, got %s." % kind)

	main._clear_all_units()
	var enemy_attacker = _spawn_unit(main, 2, "hero", "ENEMY SHOOTER", 5.0, 0.0)
	var ally_target = _spawn_unit(main, 1, "hero", "ALLY TARGET", 7.0, 0.0)
	_spawn_unit(main, 1, "barrier", "ALLY SCREEN", 6.0, 0.0, {"is_one_way_shield": true, "material_class": "one_way_shield", "shield_pass_mode": "ally", "radius": 0.18})
	kind = main._map_occlusion_kind_between(enemy_attacker, ally_target, _base_event())
	if kind != MainScene.MAP_OCCLUSION_ONE_WAY:
		_fail("Enemy fire through ally one-way screen should be blocked, got %s." % kind)
	print("MAP_OCCLUSION_KIND_PROBE ok")
	quit()
