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
		"radius": 0.14,
		"teamedit_runtime_topology": false,
	}, name, ring, lane)
	main._assign_unit_role(unit, "hero")
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var attacker = _spawn_unit(main, 1, "Sniper", 1.0, 0.0)
	var target = _spawn_unit(main, 2, "Target", 1.7, 0.0)
	var before: int = main.effects_root.get_child_count()
	main._resolve_attack(attacker, {
		"projectile": true,
		"gun_activation": true,
		"module_action_profile": "gun_activate",
		"true_bullet_ready": true,
		"aim_locked": true,
		"locked_target": target,
		"ammo_consumed": true,
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"travel_path": "instant_line",
		"damage_type": "bullet",
		"projectile_damage_type": "bullet",
		"projectile_momentum": 32.0,
		"projectile_damage_coeff": 4.0,
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
	})
	var after: int = main.effects_root.get_child_count()
	if after <= before:
		_fail("Sniper hit should spawn a hit VFX on the target.")
		return
	var effect = main.effects_root.get_child(after - 1)
	var expected: Vector2 = main._screen_from_ring(target.ring_pos, target.lane)["position"]
	if effect.position.distance_to(expected) > 90.0:
		_fail("Sniper hit VFX should be near target contact point. effect=%s expected=%s" % [str(effect.position), str(expected)])
		return
	print("SNIPER_HIT_VFX_ON_TARGET_PROBE ok effects=%d" % (after - before))
	quit()
