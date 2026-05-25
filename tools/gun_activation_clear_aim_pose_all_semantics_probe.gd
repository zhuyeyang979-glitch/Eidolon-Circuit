extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _axis_for_node(fighter, node_index: int, dynamic := true) -> Vector2:
	var segment: Dictionary = fighter.runtime_world_segment_for_node(node_index, dynamic)
	var axis: Vector2 = Vector2(segment.get("b", Vector2.ZERO)) - Vector2(segment.get("a", Vector2.ZERO))
	return axis.normalized() if axis.length() > 0.001 else Vector2.ZERO


func _fighter_for_case(gun_kind: String, ammo_kind: String):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Gun Semantic %s" % gun_kind,
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 24.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{
				"node_index": 2,
				"part_index": 2,
				"part_kind": "terminal",
				"terminal_weapon_kind": "ranged",
				"projectile": true,
				"projectile_only": true,
				"material_class": "gun",
				"gun_kind": gun_kind,
				"ammo_kind": ammo_kind,
				"a_local": Vector2.ZERO,
				"b_local": Vector2.RIGHT,
				"axis_local": Vector2.RIGHT,
				"radius": 0.04,
				"projectile_momentum": 20.0,
				"gun_projectile_damage_mult": 1.0,
				"momentum_min": 10.0,
				"momentum_max": 30.0,
				"allocated_limb_momentum": 20.0,
			}],
		},
	})
	fighter.deploy(0.0, 0.0)
	return fighter


func _binding() -> Dictionary:
	return {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [2],
		"module_action_profile": "gun_activate",
		"module_part": {
			"module_action_profile": "gun_activate",
			"module_target_kind": "gun_terminal",
			"gun_activation": "gun_activate",
			"hold_to_activate": true,
		},
		"joint_drive_allocation_by_node": {"2": 20.0},
		"allocated_limb_momentum_by_node": {"2": 20.0},
	}


func _run_case(main, gun_kind: String, ammo_kind: String) -> void:
	var fighter = _fighter_for_case(gun_kind, ammo_kind)
	main.active_units[1]["hero"] = fighter
	main.active_units[2]["hero"] = null
	main.all_units = [fighter]
	main._start_runtime_gun_activation(1, "p1", 0, "probe_fire", _binding())
	if not main._runtime_gun_activation_active(1):
		_fail("Gun activation did not start for %s/%s." % [gun_kind, ammo_kind])
		return
	var state: Dictionary = main.gun_activation_state[1]
	state["aim_direction"] = Vector2.UP
	main.gun_activation_state[1] = state
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	if event.is_empty():
		_fail("Gun activation event empty for %s/%s." % [gun_kind, ammo_kind])
		return
	if _axis_for_node(fighter, 2, true).dot(Vector2.UP) < 0.95:
		_fail("Gun did not enter aim pose for %s/%s." % [gun_kind, ammo_kind])
		return
	main._release_runtime_gun_activation(1)
	for i in range(4):
		main._update_true_bullet_locks(0.5)
	if int(fighter.aim_pose_part_index) != -1:
		_fail("Aim pose was not cleared for %s/%s." % [gun_kind, ammo_kind])
		return
	if _axis_for_node(fighter, 2, true).dot(Vector2.RIGHT) < 0.98:
		_fail("Gun did not restore entry pose for %s/%s." % [gun_kind, ammo_kind])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var cases := [
		["sniper", "bullet"],
		["sprayer", "chemical"],
		["rifle", "bullet"],
		["laser_gun", "laser"],
		["grenade_launcher", "explosive"],
		["missile_launcher", "explosive"],
		["web_gun", "web"],
	]
	for case in cases:
		_run_case(main, String(case[0]), String(case[1]))
	print("GUN_ACTIVATION_CLEAR_AIM_POSE_ALL_SEMANTICS_PROBE ok cases=%d" % cases.size())
	quit()
