extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	quit(1)


func _part_index_by_name(main: Node, slot_key: String, name_fragment: String) -> int:
	for i in range(main._catalog_for("hero", slot_key).size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		if String(part.get("name", "")).findn(name_fragment) >= 0:
			return i
	return -1


func _build_unit(main: Node, side: String = "") -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso_part: int = Helpers.first_torso(main)
	var limb_part: int = _part_index_by_name(main, "limb_muscle", "RAZOR FLEX")
	if limb_part < 0:
		limb_part = Helpers.first_limb(main)
	var scythe_part: int = Helpers.scythe_index(main)
	var module_index: int = Helpers.scythe_module_index(main)
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
	return {"unit_bp": unit_bp, "torso": torso, "limb_a": limb_a, "limb_b": limb_b, "scythe": scythe, "module": module_index}


func _segment_for_node(segments: Array, node_index: int) -> Dictionary:
	for raw_segment in segments:
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -9999)) == node_index:
			return Dictionary(raw_segment)
	return {}


func _axis_for(segment: Dictionary) -> Vector2:
	if segment.is_empty():
		return Vector2.ZERO
	return Vector2(segment.get("axis", Vector2.ZERO)).normalized()


func _binding_for(main: Node, setup: Dictionary, side: String = "") -> Dictionary:
	var module_index: int = int(setup.get("module", -1))
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	var limb_a: int = int(setup.get("limb_a", -1))
	var limb_b: int = int(setup.get("limb_b", -1))
	var scythe: int = int(setup.get("scythe", -1))
	var binding := {
		"software_slot_index": 0,
		"module_index": module_index,
		"module_part": module_part.duplicate(true),
		"module_action_profile": String(module_part.get("module_action_profile", "")),
		"command_window_profile": String(module_part.get("command_window_profile", "")),
		"attack_key": 1,
		"target_kind": "limb",
		"root_index": limb_a,
		"target_nodes": [limb_a, limb_b, scythe],
		"target_torso_node": int(setup.get("torso", -1)),
	}
	if side != "":
		binding["side_mount_action_side"] = side
		binding["side_mount_action_node"] = scythe
		binding["side_mount_action_angle_offset"] = -PI * 0.5 if side == "left" else PI * 0.5
	return binding


func _action_segments(main: Node, setup: Dictionary, side: String, sample_time: float) -> Array:
	var unit_bp: Dictionary = Dictionary(setup.get("unit_bp", {}))
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Scythe Baseline Compare", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var event: Dictionary = fighter.begin_runtime_module_action("normal", _binding_for(main, setup, side), Vector2.RIGHT)
	if event.is_empty():
		_fail("Scythe action did not start for side '%s': %s." % [side, String(fighter.get_meta("last_module_gate_reason", ""))])
		return []
	if sample_time > 0.0:
		fighter._tick_runtime_module_actions(sample_time)
	var segments: Array = fighter._runtime_topology_world_segments(true, true)
	fighter.queue_free()
	return segments


func _assert_segment_matches(label: String, baseline: Dictionary, actual: Dictionary) -> void:
	if baseline.is_empty() or actual.is_empty():
		_fail("%s missing segment." % label)
		return
	var base_axis := _axis_for(baseline)
	var actual_axis := _axis_for(actual)
	if base_axis.length() < 0.9 or actual_axis.length() < 0.9:
		_fail("%s missing axis: baseline=%s actual=%s." % [label, str(base_axis), str(actual_axis)])
		return
	if base_axis.dot(actual_axis) < 0.995:
		_fail("%s axis changed: baseline=%s actual=%s." % [label, str(base_axis), str(actual_axis)])
		return
	var base_a: Vector2 = baseline.get("a", Vector2.ZERO)
	var base_b: Vector2 = baseline.get("b", Vector2.ZERO)
	var actual_a: Vector2 = actual.get("a", Vector2.ZERO)
	var actual_b: Vector2 = actual.get("b", Vector2.ZERO)
	if base_a.distance_to(actual_a) > 0.001 or base_b.distance_to(actual_b) > 0.001:
		_fail("%s endpoints changed: baseline=%s->%s actual=%s->%s." % [label, str(base_a), str(base_b), str(actual_a), str(actual_b)])
		return


func _assert_sample(main: Node, sample_time: float, side: String) -> void:
	var baseline_setup := _build_unit(main, "")
	var side_setup := _build_unit(main, side)
	var baseline_segments := _action_segments(main, baseline_setup, "", sample_time)
	var side_segments := _action_segments(main, side_setup, side, sample_time)
	for key in ["limb_a", "limb_b"]:
		var baseline_segment := _segment_for_node(baseline_segments, int(baseline_setup.get(key, -1)))
		var side_segment := _segment_for_node(side_segments, int(side_setup.get(key, -1)))
		_assert_segment_matches("%s %.2fs %s" % [side, sample_time, key], baseline_segment, side_segment)
	var baseline_terminal := _segment_for_node(baseline_segments, int(baseline_setup.get("scythe", -1)))
	var side_terminal := _segment_for_node(side_segments, int(side_setup.get("scythe", -1)))
	var baseline_axis := _axis_for(baseline_terminal)
	var side_axis := _axis_for(side_terminal)
	if baseline_axis.length() < 0.9 or side_axis.length() < 0.9:
		_fail("%s %.2fs missing terminal axis." % [side, sample_time])
		return
	if baseline_axis.dot(side_axis) > 0.92:
		_fail("%s %.2fs side-mounted terminal should differ from straight baseline: baseline=%s side=%s." % [side, sample_time, str(baseline_axis), str(side_axis)])
		return


func _init() -> void:
	var main := Helpers.setup_main(self)
	for sample_time in [0.0, 0.16, 0.36]:
		_assert_sample(main, float(sample_time), "left")
		if failed:
			return
		_assert_sample(main, float(sample_time), "right")
		if failed:
			return
	print("SCYTHE_ACTION_LIMB_MATCHES_STRAIGHT_WEAPON_PROBE ok")
	quit(0)
