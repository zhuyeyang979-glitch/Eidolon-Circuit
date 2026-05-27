extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _segment_for_node(segments: Array, node_index: int) -> Dictionary:
	for raw_segment in segments:
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -9999)) == node_index:
			return Dictionary(raw_segment)
	return {}


func _axis_for(segments: Array, node_index: int) -> Vector2:
	var segment := _segment_for_node(segments, node_index)
	if segment.is_empty():
		return Vector2.ZERO
	return Vector2(segment.get("axis", Vector2.ZERO)).normalized()


func _part_index_by_name(main: Node, slot_key: String, name_fragment: String) -> int:
	for i in range(main._catalog_for("hero", slot_key).size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		if String(part.get("name", "")).findn(name_fragment) >= 0:
			return i
	return -1


func _build_group_unit(main: Node, side: String) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso_part := Helpers.first_torso(main)
	var limb_part := _part_index_by_name(main, "limb_muscle", "RAZOR FLEX")
	if limb_part < 0:
		limb_part = Helpers.first_limb(main)
	var scythe_part := Helpers.scythe_index(main)
	var module_index := Helpers.scythe_module_index(main)
	if min(torso_part, limb_part, scythe_part, module_index) < 0:
		_fail("Missing torso/limb/scythe/module catalog entry.")
		return {}
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_part)
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", limb_part, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", limb_part, Vector2.RIGHT)
	var scythe: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_b, "SCYTHE", "muscle", scythe_part, Vector2.RIGHT)
	var scythe_node: Dictionary = Dictionary(nodes[scythe]).duplicate(true)
	scythe_node["visual_mount_side"] = "right"
	scythe_node["visual_handedness"] = "right"
	scythe_node["orientation_category"] = "orthogonal_side_mount"
	scythe_node["orientation_basis"] = "parent_normal"
	nodes[scythe] = scythe_node
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	if side != "":
		unit_bp["module_bindings"] = [{
			"software_slot_index": 0,
			"module_index": module_index,
			"attack_key": 1,
			"target_kind": "limb",
			"root_index": limb_a,
			"target_nodes": [limb_a, limb_b, scythe],
			"target_torso_node": torso,
			"side_mount_action_side": side,
			"side_mount_action_node": scythe,
			"side_mount_action_angle_offset": -PI * 0.5 if side == "left" else PI * 0.5,
		}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return {"unit_bp": unit_bp, "limb_a": limb_a, "limb_b": limb_b, "scythe": scythe, "module": module_index, "torso": torso, "side": side}


func _binding_for_setup(main: Node, setup: Dictionary) -> Dictionary:
	var side := String(setup.get("side", ""))
	var module_index := int(setup.get("module", -1))
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	var binding := {
		"software_slot_index": 0,
		"module_index": module_index,
		"module_part": module_part.duplicate(true),
		"module_action_profile": String(module_part.get("module_action_profile", "")),
		"command_window_profile": String(module_part.get("command_window_profile", "")),
		"attack_key": 1,
		"target_kind": "limb",
		"root_index": int(setup.get("limb_a", -1)),
		"target_nodes": [int(setup.get("limb_a", -1)), int(setup.get("limb_b", -1)), int(setup.get("scythe", -1))],
		"target_torso_node": int(setup.get("torso", -1)),
	}
	if side != "":
		binding["side_mount_action_side"] = side
		binding["side_mount_action_node"] = int(setup.get("scythe", -1))
		binding["side_mount_action_angle_offset"] = -PI * 0.5 if side == "left" else PI * 0.5
	return binding


func _action_axes(main: Node, setup: Dictionary) -> Dictionary:
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var runtime_bindings: Array = Array(stats.get("runtime_module_bindings", []))
	var runtime_binding := _binding_for_setup(main, setup)
	if not runtime_bindings.is_empty():
		if not bool(Dictionary(runtime_bindings[0]).get("runtime_valid", false)):
			_fail("Runtime scythe group binding should be valid.")
			return {}
		runtime_binding = Dictionary(runtime_bindings[0])
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Scythe Chain Side", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var event: Dictionary = fighter.begin_runtime_module_action("normal", runtime_binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Scythe group action did not start: %s." % String(fighter.get_meta("last_module_gate_reason", "")))
		return {}
	fighter._tick_runtime_module_actions(0.16)
	var segments: Array = fighter._runtime_topology_world_segments(true, true)
	var result := {
		"limb_a": _axis_for(segments, int(setup.get("limb_a", -1))),
		"limb_b": _axis_for(segments, int(setup.get("limb_b", -1))),
		"scythe": _axis_for(segments, int(setup.get("scythe", -1))),
	}
	fighter.queue_free()
	return result


func _init() -> void:
	var main := Helpers.setup_main(self)
	var baseline_setup := _build_group_unit(main, "")
	var left_setup := _build_group_unit(main, "left")
	var right_setup := _build_group_unit(main, "right")
	var baseline_axes := _action_axes(main, baseline_setup)
	var left_axes := _action_axes(main, left_setup)
	var right_axes := _action_axes(main, right_setup)
	for key in ["limb_a", "limb_b", "scythe"]:
		if Vector2(left_axes.get(key, Vector2.ZERO)).length() < 0.9 or Vector2(right_axes.get(key, Vector2.ZERO)).length() < 0.9:
			_fail("Missing action axis for %s." % key)
			return
	if Vector2(left_axes["limb_a"]).dot(Vector2(right_axes["limb_a"])) < 0.995:
		_fail("First ordinary limb changed with side-mount action side: left=%s right=%s." % [str(left_axes["limb_a"]), str(right_axes["limb_a"])])
		return
	if Vector2(left_axes["limb_b"]).dot(Vector2(right_axes["limb_b"])) < 0.995:
		_fail("Second ordinary limb changed with side-mount action side: left=%s right=%s." % [str(left_axes["limb_b"]), str(right_axes["limb_b"])])
		return
	if Vector2(baseline_axes["limb_a"]).dot(Vector2(left_axes["limb_a"])) < 0.995 or Vector2(baseline_axes["limb_a"]).dot(Vector2(right_axes["limb_a"])) < 0.995:
		_fail("First ordinary limb changed compared with straight baseline: base=%s left=%s right=%s." % [str(baseline_axes["limb_a"]), str(left_axes["limb_a"]), str(right_axes["limb_a"])])
		return
	if Vector2(baseline_axes["limb_b"]).dot(Vector2(left_axes["limb_b"])) < 0.995 or Vector2(baseline_axes["limb_b"]).dot(Vector2(right_axes["limb_b"])) < 0.995:
		_fail("Second ordinary limb changed compared with straight baseline: base=%s left=%s right=%s." % [str(baseline_axes["limb_b"]), str(left_axes["limb_b"]), str(right_axes["limb_b"])])
		return
	if Vector2(left_axes["scythe"]).dot(Vector2(right_axes["scythe"])) > -0.92:
		_fail("Scythe terminal should be the only segment mirrored by left/right action side: left=%s right=%s." % [str(left_axes["scythe"]), str(right_axes["scythe"])])
		return
	print("SCYTHE_ACTION_GROUP_LIMB_CHAIN_NOT_SIDE_ROTATED_PROBE ok")
	quit(0)
