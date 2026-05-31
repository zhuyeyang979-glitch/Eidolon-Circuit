extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _marker(markers: Array, node_index: int, socket_id: String) -> Dictionary:
	for raw_marker in markers:
		if not (raw_marker is Dictionary):
			continue
		var marker: Dictionary = raw_marker
		if int(marker.get("node", -1)) == node_index and String(marker.get("id", "")) == socket_id:
			return marker
	return {}


func _init() -> void:
	var main = Helpers.setup_main(self)
	var setup := Helpers.build_torso_limb(main)
	if setup.is_empty():
		_fail("Missing torso or limb catalog part.")
		return
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	var limb := int(setup.get("limb", -1))
	var scythe := Helpers.append_loose_scythe_near_limb(main, unit_bp, limb)
	if not main._try_magnetic_link_for_node(unit_bp, scythe):
		_fail("Magnetic scythe link did not succeed.")
		return
	unit_bp = main._editor_current_blueprint()
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var edge := Helpers.scythe_edge(main, unit_bp, scythe)
	if edge.is_empty():
		_fail("Scythe link edge missing.")
		return
	var parent: int = main._topology_edge_other_node(edge, scythe)
	var parent_socket: String = main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, parent))
	var markers: Array = main._topology_socket_markers_for_board("hero", unit_bp, nodes, edges)
	var scythe_root_marker := _marker(markers, scythe, "root_joint")
	var parent_marker := _marker(markers, parent, parent_socket)
	if scythe_root_marker.is_empty():
		_fail("Scythe root socket marker missing.")
		return
	if parent_marker.is_empty():
		_fail("Parent socket marker missing.")
		return
	var scythe_pos = scythe_root_marker.get("pos", Vector2.INF)
	var parent_pos = parent_marker.get("pos", Vector2.INF)
	if not (scythe_pos is Vector2) or not (parent_pos is Vector2):
		_fail("Socket marker positions are not Vector2.")
		return
	var marker_gap := Vector2(scythe_pos).distance_to(Vector2(parent_pos))
	if marker_gap > 0.001:
		_fail("Scythe root marker floats away from parent slot marker: %.6f px." % marker_gap)
		return
	var root_world: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, scythe, "root_joint", parent)
	var parent_world: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, parent, parent_socket, scythe)
	if root_world.distance_to(parent_world) > 0.00001:
		_fail("Scythe root socket world point floats away from parent slot: %.8f." % root_world.distance_to(parent_world))
		return
	print("SCYTHE_NO_FLOATING_RING_AFTER_LINK_PROBE ok marker_gap=%.6f" % marker_gap)
	quit(0)
