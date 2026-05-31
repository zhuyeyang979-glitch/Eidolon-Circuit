extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _segment_for_node(stats: Dictionary, node_index: int) -> Dictionary:
	for raw_segment in Array(stats.get("runtime_topology_segments", [])):
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -9999)) == node_index:
			return Dictionary(raw_segment)
	return {}


func _axis_for(stats: Dictionary, node_index: int) -> Vector2:
	var segment := _segment_for_node(stats, node_index)
	if segment.is_empty():
		return Vector2.ZERO
	return Vector2(segment.get("axis_local", Vector2.ZERO)).normalized()


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
	return {"unit_bp": unit_bp, "torso": torso, "limb_a": limb_a, "limb_b": limb_b, "scythe": scythe}


func _init() -> void:
	var main := Helpers.setup_main(self)
	var left_setup := _build_group_unit(main, "left")
	var right_setup := _build_group_unit(main, "right")
	var left_stats: Dictionary = main._compute_unit_stats(1, "hero", -1, Dictionary(left_setup.get("unit_bp", {})))
	var right_stats: Dictionary = main._compute_unit_stats(1, "hero", -1, Dictionary(right_setup.get("unit_bp", {})))
	var left_runtime: Array = Array(left_stats.get("runtime_module_bindings", []))
	var right_runtime: Array = Array(right_stats.get("runtime_module_bindings", []))
	if left_runtime.is_empty() or not bool(Dictionary(left_runtime[0]).get("runtime_valid", false)):
		_fail("Left runtime scythe group binding should be valid: %s" % (String(Dictionary(left_runtime[0]).get("binding_valid_note", "")) if not left_runtime.is_empty() else "missing"))
		return
	if right_runtime.is_empty() or not bool(Dictionary(right_runtime[0]).get("runtime_valid", false)):
		_fail("Right runtime scythe group binding should be valid: %s" % (String(Dictionary(right_runtime[0]).get("binding_valid_note", "")) if not right_runtime.is_empty() else "missing"))
		return
	var left_limb_a := int(left_setup.get("limb_a", -1))
	var left_limb_b := int(left_setup.get("limb_b", -1))
	var left_scythe := int(left_setup.get("scythe", -1))
	var right_limb_a := int(right_setup.get("limb_a", -1))
	var right_limb_b := int(right_setup.get("limb_b", -1))
	var right_scythe := int(right_setup.get("scythe", -1))
	var left_a_axis := _axis_for(left_stats, left_limb_a)
	var left_b_axis := _axis_for(left_stats, left_limb_b)
	var left_scythe_axis := _axis_for(left_stats, left_scythe)
	var right_a_axis := _axis_for(right_stats, right_limb_a)
	var right_b_axis := _axis_for(right_stats, right_limb_b)
	var right_scythe_axis := _axis_for(right_stats, right_scythe)
	if left_a_axis.dot(right_a_axis) < 0.995:
		_fail("First ordinary limb changed with side-mount action side: left=%s right=%s." % [str(left_a_axis), str(right_a_axis)])
		return
	if left_b_axis.dot(right_b_axis) < 0.995:
		_fail("Second ordinary limb changed with side-mount action side: left=%s right=%s." % [str(left_b_axis), str(right_b_axis)])
		return
	var expected_left_scythe := left_b_axis.rotated(-PI * 0.5).normalized()
	var expected_right_scythe := right_b_axis.rotated(PI * 0.5).normalized()
	if left_scythe_axis.dot(expected_left_scythe) < 0.99:
		_fail("Left scythe terminal did not receive terminal-only 90deg offset: got %s expected %s." % [str(left_scythe_axis), str(expected_left_scythe)])
		return
	if right_scythe_axis.dot(expected_right_scythe) < 0.99:
		_fail("Right scythe terminal did not receive terminal-only 90deg offset: got %s expected %s." % [str(right_scythe_axis), str(expected_right_scythe)])
		return
	if left_scythe_axis.dot(right_scythe_axis) > -0.92:
		_fail("Left/right side should mirror only scythe terminal: left=%s right=%s." % [str(left_scythe_axis), str(right_scythe_axis)])
		return
	var runtime_binding: Dictionary = Dictionary(left_runtime[0])
	if int(runtime_binding.get("side_mount_action_node", -1)) != left_scythe:
		_fail("Runtime binding side_mount_action_node should point to scythe terminal only.")
		return
	print("SCYTHE_SIDE_MOUNT_OFFSET_TERMINAL_ONLY_PROBE ok")
	quit(0)
