extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_limb_index(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		return i
	return 0


func _first_ranged_terminal_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle") and bool(part.get("projectile", false)):
			return i
	return -1


func _gun_event(gun_node: int, muzzle: Vector2) -> Dictionary:
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
		"range": 3.0,
		"lane_range": 0.12,
		"muscle_node": gun_node,
		"source_gun_node": gun_node,
		"source_node_index": gun_node,
		"runtime_target_nodes": [gun_node],
		"muzzle_combat_position": muzzle,
		"muzzle_direction": Vector2.RIGHT,
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
	var ranged_index := _first_ranged_terminal_index(main)
	if ranged_index < 0:
		_fail("No ranged terminal weapon found in hero catalog.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso_index(main))
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LINK", "limb_muscle", _first_limb_index(main), Vector2.RIGHT, [0])
	var gun_node: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "GUN", "muscle", ranged_index, Vector2.RIGHT)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	if not bool(stats.get("teamedit_runtime_topology", false)):
		_fail("Ranged topology did not enter runtime topology.")
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Muzzle Screen Alignment", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(3.0, 0.55)
	main.mobius_enabled = true
	main.camera_mobius_s = 3.0
	main.camera_center = 3.0
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {"twist_phase": 0.32, "twist_amplitude": 0.18, "pivot": Vector2(12.0, 0.0)}
	main._sync_camera_mobius_from_compat()
	main.all_units = [fighter]
	main.active_units[1]["hero"] = fighter
	var gun_segment: Dictionary = fighter.runtime_world_segment_for_node(gun_node, true)
	var muzzle_combat: Vector2 = gun_segment.get("b", fighter.muzzle_position_for_part(0))
	var event := _gun_event(gun_node, muzzle_combat)
	var expected_start: Vector2 = main._screen_from_ring(wrapf(muzzle_combat.x, 0.0, MainScene.RING_LENGTH), clampf(muzzle_combat.y, -MainScene.BATTLE_HALF_HEIGHT, MainScene.BATTLE_HALF_HEIGHT)).get("position", Vector2.ZERO)
	var segment := main._projected_projectile_screen_segment(fighter, event, 0.0)
	if segment.is_empty():
		_fail("Projected projectile screen segment should exist.")
	var start: Vector2 = segment.get("start", Vector2.ZERO)
	if start.distance_to(expected_start) > 0.01:
		_fail("Projected projectile start should attach to muzzle screen position, expected %s got %s." % [str(expected_start), str(start)])
	main._spawn_projectile_trace(fighter, event)
	if main.effects_root == null or main.effects_root.get_child_count() <= 0:
		_fail("Projectile trace should spawn for muzzle alignment.")
	var trace = main.effects_root.get_child(main.effects_root.get_child_count() - 1)
	var trace_start: Vector2 = trace.get("start_point")
	if trace_start.distance_to(expected_start) > 0.01:
		_fail("Spawned projectile trace should start at projected muzzle, expected %s got %s." % [str(expected_start), str(trace_start)])
	print("PROJECTILE_MUZZLE_SCREEN_ALIGNMENT_PROBE ok muzzle=%s screen=%s" % [str(muzzle_combat), str(trace_start)])
	quit()
