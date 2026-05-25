extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _segment(node_index: int, a: Vector2, b: Vector2, kind := "limb") -> Dictionary:
	return {
		"node_index": node_index,
		"part_index": node_index,
		"part_kind": "terminal" if kind == "terminal" else "limb",
		"terminal_weapon_kind": "melee" if kind == "terminal" else "",
		"a_local": a,
		"b_local": b,
		"axis_local": (b - a).normalized(),
		"radius": 0.06,
		"mass": 1.0,
		"joint_output_momentum_base": 40.0,
		"joint_drive_allocation": 40.0,
		"allocated_limb_momentum": 40.0,
	}


func _pose(fighter, node_index: int) -> Dictionary:
	var source: Dictionary = fighter._runtime_segment_source_by_node(node_index)
	return {
		"a": fighter._runtime_local_vector(source.get("a_local", Vector2.ZERO)),
		"b": fighter._runtime_local_vector(source.get("b_local", Vector2.ZERO)),
		"axis": fighter._runtime_local_vector(source.get("axis_local", Vector2.RIGHT)).normalized(),
	}


func _pose_matches(a: Dictionary, b: Dictionary) -> bool:
	return Vector2(a["a"]).distance_to(Vector2(b["a"])) <= 0.01 and Vector2(a["b"]).distance_to(Vector2(b["b"])) <= 0.01 and Vector2(a["axis"]).distance_to(Vector2(b["axis"])) <= 0.02


func _run_case(name: String, profile: String, target_nodes: Array, segments: Array, module_part: Dictionary = {}) -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": name,
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 24.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": segments,
		},
	})
	fighter.deploy(0.0, 0.0)
	var before := {}
	for raw_node in target_nodes:
		before[int(raw_node)] = _pose(fighter, int(raw_node))
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": target_nodes.duplicate(true),
		"module_action_profile": profile,
		"module_part": module_part.duplicate(true),
	}
	binding["module_part"]["module_action_profile"] = profile
	var event: Dictionary = fighter.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("%s did not start: %s" % [name, String(fighter.get_meta("last_module_gate_reason", ""))])
		return
	fighter._tick_runtime_module_actions(10.0)
	if not fighter.runtime_module_actions.is_empty():
		_fail("%s did not finish." % name)
		return
	for raw_node in target_nodes:
		var node_index := int(raw_node)
		if not _pose_matches(Dictionary(before[node_index]), _pose(fighter, node_index)):
			_fail("%s node %d did not restore entry pose." % [name, node_index])
			return


func _init() -> void:
	_run_case("two_link", "two_link_forward_snap", [1, 2], [
		_segment(1, Vector2.ZERO, Vector2(0.6, 0.18)),
		_segment(2, Vector2(0.6, 0.18), Vector2(1.1, -0.08)),
	])
	_run_case("generic_swing", "swing_180", [1], [_segment(1, Vector2.ZERO, Vector2(0.7, 0.2))], {"swing_arc_degrees": 180.0})
	_run_case("gauntlet", "blunt_gauntlet_extend_swing", [1], [_segment(1, Vector2.ZERO, Vector2(0.65, -0.12), "terminal")], {"module_extension_m": 1.0, "swing_arc_degrees": 70.0})
	_run_case("shield", "blunt_shield_guard_bash", [1], [_segment(1, Vector2.ZERO, Vector2(0.5, 0.18), "terminal")], {"swing_arc_degrees": 82.0})
	_run_case("hammer", "blunt_hammer_windup_slam", [1], [_segment(1, Vector2.ZERO, Vector2(0.62, -0.2), "terminal")], {"swing_arc_degrees": 150.0})
	_run_case("blade", "katana_quickdraw", [1], [_segment(1, Vector2.ZERO, Vector2(0.72, 0.14), "terminal")], {"swing_arc_degrees": 180.0})
	print("RUNTIME_MODULE_ENTRY_POSE_RESTORE_PROBE ok")
	quit()
