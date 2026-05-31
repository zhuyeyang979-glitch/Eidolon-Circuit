extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _segment_for_node(segments: Array, node_index: int) -> Dictionary:
	for raw_segment in segments:
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -9999)) == node_index:
			return Dictionary(raw_segment)
	return {}


func _init() -> void:
	var main := Helpers.setup_main(self)
	var setup: Dictionary = Helpers.build_torso_limb_scythe_module(main, "right")
	if setup.is_empty():
		_fail("Could not build scythe identity test unit.")
		return
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	if not Helpers.bind_scythe_action_side(main, unit_bp, int(setup.get("scythe", -1)), int(setup.get("module", -1)), "right", 1):
		_fail("Could not bind right-side scythe action.")
		return
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var segments: Array = Array(stats.get("runtime_topology_segments", []))
	var edges: Array = Array(Dictionary(unit_bp.get("custom_topology", {})).get("edges", []))
	var checked := 0
	for raw_edge in edges:
		if not (raw_edge is Dictionary):
			continue
		var edge: Dictionary = raw_edge
		var a := int(edge.get("a_node", edge.get("a", -1)))
		var b := int(edge.get("b_node", edge.get("b", -1)))
		for child in [a, b]:
			var child_socket := String(edge.get("a_socket" if child == a else "b_socket", ""))
			if child_socket != "root_joint":
				continue
			var segment := _segment_for_node(segments, child)
			if segment.is_empty():
				_fail("Runtime segment missing for child node %d." % child)
				return
			var gap := Vector2(segment.get("root_anchor_local", segment.get("a_local", Vector2.ZERO))).distance_to(Vector2(segment.get("parent_socket_anchor_local", segment.get("a_local", Vector2.ZERO))))
			if gap > 0.0005 or float(segment.get("socket_gap", 999.0)) > 0.0005:
				_fail("Board/runtime socket anchors diverged for node %d: %.6f / %.6f." % [child, gap, float(segment.get("socket_gap", 999.0))])
				return
			checked += 1
	if checked < 2:
		_fail("Expected at least two resolved child socket anchors, checked %d." % checked)
		return
	print("BOARD_BATTLE_TOPOLOGY_POSE_IDENTITY_PROBE ok checked=%d" % checked)
	quit(0)
