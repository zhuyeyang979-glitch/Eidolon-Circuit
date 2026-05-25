extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part(main, category: String, predicate: Callable) -> Dictionary:
	for i in range(main._catalog_for("hero", category).size()):
		var part: Dictionary = main._selected_component("hero", category, i)
		if predicate.call(part):
			return part
	return {}


func _make_fixture(main) -> Dictionary:
	var module_part := _part(main, "module", func(part): return String(part.get("module_action_profile", "")) == "gun_activate")
	var gun_part := _part(main, "muscle", func(part): return main._component_is_gun_muscle(part, "muscle") and not main._part_is_catalog_frozen("muscle", part))
	if module_part.is_empty() or gun_part.is_empty():
		_fail("Missing gun module or live gun part.")
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [1, 2],
		"module_action_profile": "gun_activate",
		"module_part": module_part.duplicate(true),
		"joint_drive_allocation_by_node": {"2": 80.0},
		"allocated_limb_momentum_by_node": {"2": 80.0},
	}
	var gun_segment := gun_part.duplicate(true)
	gun_segment.merge({
		"node_index": 2,
		"part_index": 2,
		"part_kind": "terminal",
		"a_local": Vector2(0.68, 0.08),
		"b_local": Vector2(1.34, 0.08),
		"axis_local": Vector2.RIGHT,
		"radius": maxf(0.02, float(gun_part.get("radius", 0.05))),
		"terminal_weapon_kind": "ranged",
		"projectile": true,
		"projectile_only": true,
		"joint_output_momentum_base": 80.0,
		"joint_drive_allocation": 80.0,
		"allocated_limb_momentum": 80.0,
	}, true)
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Complex Muzzle Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 32.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_index": 0, "part_kind": "torso", "a_local": Vector2(-0.35, 0.0), "b_local": Vector2(0.0, 0.0), "radius": 0.22},
				{"node_index": 1, "part_index": 1, "part_kind": "limb", "a_local": Vector2(0.0, 0.0), "b_local": Vector2(0.68, 0.08), "radius": 0.07},
				gun_segment,
			],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(4.0, 0.55)
	return {"fighter": fighter, "binding": binding}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.mobius_enabled = true
	main.camera_mobius_s = 4.0
	main.camera_center = 4.0
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {"twist_phase": 0.42, "twist_amplitude": 0.18, "pivot": Vector2(12.0, 0.0)}
	main._sync_camera_mobius_from_compat()
	var fixture: Dictionary = _make_fixture(main)
	var fighter = fixture["fighter"]
	var binding: Dictionary = fixture["binding"]
	main.active_units[1]["hero"] = fighter
	main.all_units = [fighter]
	main._start_runtime_gun_activation(1, "p1_", 0, "probe_fire", binding)
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	if event.is_empty():
		_fail("Runtime gun event was empty.")
	var muzzle: Vector2 = event.get("muzzle_combat_position", Vector2.INF)
	var expected_start: Vector2 = main._screen_from_ring(wrapf(muzzle.x, 0.0, MainScene.RING_LENGTH), clampf(muzzle.y, -MainScene.BATTLE_HALF_HEIGHT, MainScene.BATTLE_HALF_HEIGHT)).get("position", Vector2.ZERO)
	var segment := main._projected_projectile_screen_segment(fighter, event, 0.0)
	if segment.is_empty():
		_fail("Projected segment should exist for complex runtime gun event.")
	var start: Vector2 = segment.get("start", Vector2.ZERO)
	if start.distance_to(expected_start) > 0.01:
		_fail("Complex runtime projectile should start at projected muzzle; expected %s got %s." % [str(expected_start), str(start)])
	main._spawn_projectile_trace(fighter, event)
	var trace = main.effects_root.get_child(main.effects_root.get_child_count() - 1)
	var trace_start: Vector2 = trace.get("start_point")
	if trace_start.distance_to(expected_start) > 0.01:
		_fail("Complex runtime trace should start at projected muzzle; expected %s got %s." % [str(expected_start), str(trace_start)])
	print("PROJECTILE_MUZZLE_COMPLEX_UNIT_REAL_SCREEN_PROBE ok start=%s" % str(trace_start))
	quit()
