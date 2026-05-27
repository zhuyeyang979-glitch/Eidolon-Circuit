extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = Helpers.setup_main(self)
	var setup := Helpers.build_torso_limb(main)
	if setup.is_empty():
		_fail("Missing torso or limb catalog part.")
		return
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	var limb := int(setup.get("limb", -1))
	var scythe := Helpers.append_loose_scythe_near_limb(main, unit_bp, limb)
	if scythe < 0:
		_fail("Scythe terminal missing.")
		return
	main._link_topology_nodes(unit_bp, scythe, limb)
	unit_bp = main._editor_current_blueprint()
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var edge := Helpers.scythe_edge(main, unit_bp, scythe)
	if edge.is_empty():
		_fail("Scythe link edge missing.")
		return
	var own_socket: String = main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, scythe))
	var parent: int = main._topology_edge_other_node(edge, scythe)
	var parent_socket: String = main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, parent))
	if own_socket != "root_joint" or parent != limb or parent_socket != "distal":
		_fail("Scythe should link root_joint to limb distal, got %s -> node %d %s." % [own_socket, parent, parent_socket])
		return
	var scythe_root: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, scythe, own_socket, parent)
	var parent_slot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, parent, parent_socket, scythe)
	if scythe_root.distance_to(parent_slot) > 0.00001:
		_fail("Scythe root_joint is not flush with parent slot: %.8f." % scythe_root.distance_to(parent_slot))
		return
	var parent_axis: Vector2 = main._topology_endpoint_axis_for_node(limb, nodes, edges).normalized()
	var scythe_axis: Vector2 = main._topology_endpoint_axis_for_node(scythe, nodes, edges).normalized()
	if parent_axis.length() < 0.001 or scythe_axis.length() < 0.001 or scythe_axis.dot(parent_axis) < 0.999:
		_fail("Scythe handle axis should equal parent limb axis: scythe=%s parent=%s." % [str(scythe_axis), str(parent_axis)])
		return
	var root_extent: float = main._topology_node_visual_edge_extent_units("hero", Dictionary(nodes[scythe]), unit_bp, "root_joint") / MainScene.TOPOLOGY_BOARD_PHYSICAL_UNITS
	var expected_center := parent_slot + parent_axis * root_extent
	var center: Vector2 = main._topology_node_position(Dictionary(nodes[scythe]))
	if center.distance_to(expected_center) > 0.00001:
		_fail("Scythe center does not match joint-slot formula: got %s expected %s." % [str(center), str(expected_center)])
		return
	print("SCYTHE_LINK_JOINT_SLOT_FLUSH_PROBE ok scythe=%d parent=%d" % [scythe, parent])
	quit(0)
