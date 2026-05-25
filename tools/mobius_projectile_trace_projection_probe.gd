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


func _event(impact: Vector2) -> Dictionary:
	return {
		"projectile": true,
		"gun_activation": true,
		"module_action_profile": "gun_activate",
		"projectile_behavior": "bullet_hell",
		"projectile_style": "bullet_hell",
		"travel_path": "straight",
		"damage_type": "bullet",
		"projectile_damage_type": "bullet",
		"direction": Vector2.RIGHT,
		"range": 5.2,
		"lane_range": 0.14,
		"muscle_node": 0,
		"projectile_impact_position": impact,
		"collision_group": {
			"projectile": true,
			"projectile_only": true,
			"material_class": "gun",
			"shape": "rifle",
			"gun_kind": "rifle",
		},
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.mobius_enabled = true
	main.camera_mobius_s = 2.0
	main.camera_center = 2.0
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {"twist_phase": 0.7, "twist_amplitude": 0.18, "pivot": Vector2(12.0, 0.0)}
	main._sync_camera_mobius_from_compat()
	var attacker = _spawn_unit(main, 1, "Trace Shooter", 1.0, 0.0)
	var impact := Vector2(2.1, 1.05)
	var event := _event(impact)
	var collider: Dictionary = main._attack_collider_for_event(attacker, event.duplicate(true))
	if collider.is_empty():
		_fail("Projectile event should produce a collider.")
	var start_combat: Vector2 = collider.get("a", Vector2(attacker.ring_pos, attacker.lane))
	var expected_start: Vector2 = main._screen_from_ring(wrapf(start_combat.x, 0.0, MainScene.RING_LENGTH), clampf(start_combat.y, -MainScene.BATTLE_HALF_HEIGHT, MainScene.BATTLE_HALF_HEIGHT)).get("position", Vector2.ZERO)
	var expected_end: Vector2 = main._screen_from_ring(wrapf(impact.x, 0.0, MainScene.RING_LENGTH), clampf(impact.y, -MainScene.BATTLE_HALF_HEIGHT, MainScene.BATTLE_HALF_HEIGHT)).get("position", Vector2.ZERO)
	main._spawn_projectile_trace(attacker, event)
	if main.effects_root == null or main.effects_root.get_child_count() <= 0:
		_fail("Projectile trace should spawn a VFX node.")
	var trace = main.effects_root.get_child(main.effects_root.get_child_count() - 1)
	var trace_start: Vector2 = trace.get("start_point")
	var trace_end: Vector2 = trace.get("end_point")
	if trace_start.distance_to(expected_start) > 0.01:
		_fail("Projectile trace start should use projected combat muzzle/start, expected %s got %s." % [str(expected_start), str(trace_start)])
	if trace_end.distance_to(expected_end) > 0.01:
		_fail("Projectile trace end should use projected combat impact, expected %s got %s." % [str(expected_end), str(trace_end)])
	var raw_screen_end := main._gameplay_ray_screen_end(expected_start, Vector2.RIGHT, 5.2, 92.0)
	if trace_end.distance_to(raw_screen_end) < 12.0:
		_fail("Projectile trace end still looks like raw screen-space ray extrapolation.")
	print("MOBIUS_PROJECTILE_TRACE_PROJECTION_PROBE ok start=%s end=%s" % [str(trace_start), str(trace_end)])
	quit()
