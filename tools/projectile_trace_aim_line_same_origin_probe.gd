extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _catalog_part(main, category: String, key: String, value: String) -> Dictionary:
	for i in range(main._catalog_for("hero", category).size()):
		var part: Dictionary = main._selected_component("hero", category, i)
		if String(part.get(key, "")) == value:
			return part
	return {}


func _first_gun(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_gun_muscle(part, "muscle") and not main._part_is_catalog_frozen("muscle", part):
			return part
	return {}


func _make_fixture(main) -> Dictionary:
	var module_part := _catalog_part(main, "module", "module_action_profile", "gun_activate")
	var gun_part := _first_gun(main)
	if module_part.is_empty() or gun_part.is_empty():
		_fail("Missing generic gun module or gun part.")
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
		"a_local": Vector2(0.6, -0.12),
		"b_local": Vector2(1.26, -0.12),
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
		"unit_name": "Aim Trace Origin Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 32.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_index": 0, "part_kind": "torso", "a_local": Vector2(-0.35, 0.0), "b_local": Vector2(0.0, 0.0), "radius": 0.22},
				{"node_index": 1, "part_index": 1, "part_kind": "limb", "a_local": Vector2(0.0, 0.0), "b_local": Vector2(0.6, -0.12), "radius": 0.07},
				gun_segment,
			],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(4.0, -0.35)
	return {"fighter": fighter, "binding": binding}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.mobius_enabled = true
	main.camera_mobius_s = 4.0
	main.camera_center = 4.0
	main.camera_lane_center = 0.0
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
	main._update_aim_lines(0.016)
	var line: Line2D = main.aim_lines[1]
	if not line.visible or line.points.size() < 2:
		_fail("Runtime gun aim line should be visible.")
	var aim_start: Vector2 = line.points[0]
	main._spawn_projectile_trace(fighter, event)
	if main.effects_root == null or main.effects_root.get_child_count() <= 0:
		_fail("Projectile trace was not spawned.")
	var trace = main.effects_root.get_child(main.effects_root.get_child_count() - 1)
	var trace_start: Vector2 = trace.get("start_point")
	if trace_start.distance_to(aim_start) > 0.01:
		_fail("Aim line and projectile trace should share muzzle origin; aim=%s trace=%s." % [str(aim_start), str(trace_start)])
	print("PROJECTILE_TRACE_AIM_LINE_SAME_ORIGIN_PROBE ok origin=%s" % str(aim_start))
	quit()
