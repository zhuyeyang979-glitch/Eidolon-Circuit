extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _root_gap(main: Node, unit_bp: Dictionary, scythe: int) -> float:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var edge := Helpers.scythe_edge(main, unit_bp, scythe)
	if edge.is_empty():
		return 999.0
	var parent: int = main._topology_edge_other_node(edge, scythe)
	var own_socket: String = main._topology_edge_socket_for_node(edge, scythe)
	var parent_socket: String = main._topology_edge_socket_for_node(edge, parent)
	var own_pos: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, scythe, own_socket, parent)
	var parent_pos: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, parent, parent_socket, scythe)
	return own_pos.distance_to(parent_pos)


func _assert_parent_axis(main: Node, unit_bp: Dictionary, limb: int, scythe: int, label: String) -> void:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var expected_axis: Vector2 = main._topology_endpoint_axis_for_node(limb, nodes, edges).normalized()
	var enriched: Dictionary = main._editor_fast_enriched_board_node("hero", unit_bp, nodes, edges, scythe)
	var mount_axis: Vector2 = enriched.get("mount_parent_axis_local", Vector2.ZERO)
	if mount_axis.length() < 0.001 or absf(mount_axis.normalized().dot(expected_axis)) < 0.99:
		_fail("%s scythe mount axis should follow parent limb axis, got %s expected %s." % [label, str(mount_axis), str(expected_axis)])
		return
	var handle_axis: Vector2 = main._topology_endpoint_axis_for_node(scythe, nodes, edges).normalized()
	if handle_axis.length() < 0.001 or handle_axis.dot(expected_axis) < 0.999:
		_fail("%s scythe handle axis should be the parent joint-slot axis, got %s expected %s." % [label, str(handle_axis), str(expected_axis)])


func _init() -> void:
	var main = Helpers.setup_main(self)
	var setup := Helpers.build_torso_limb(main)
	if setup.is_empty():
		_fail("Missing torso or limb catalog part.")
		return
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	var limb := int(setup.get("limb", -1))
	var scythe := Helpers.append_loose_scythe_near_limb(main, unit_bp, limb)
	main._link_topology_nodes(unit_bp, scythe, limb)
	if int(main.editor_pending_orientation_node_index) != scythe:
		_fail("Scythe link did not leave orientation choice active.")
		return
	_assert_parent_axis(main, unit_bp, limb, scythe, "linked")
	if _root_gap(main, unit_bp, scythe) > 0.00001:
		_fail("Linked scythe root socket is not flush before side choice.")
		return
	main._editor_action("set_handedness_left")
	unit_bp = main._editor_current_blueprint()
	_assert_parent_axis(main, unit_bp, limb, scythe, "left")
	if _root_gap(main, unit_bp, scythe) > 0.00001:
		_fail("Left side choice changed scythe root socket fit.")
		return
	main._editor_action("flip_handedness")
	unit_bp = main._editor_current_blueprint()
	_assert_parent_axis(main, unit_bp, limb, scythe, "right")
	if _root_gap(main, unit_bp, scythe) > 0.00001:
		_fail("Right side flip changed scythe root socket fit.")
		return
	print("SCYTHE_LINK_VISUAL_PARENT_AXIS_PROBE ok scythe=%d" % scythe)
	quit(0)
