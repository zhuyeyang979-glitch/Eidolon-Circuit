extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_root_link(main: Node, unit_bp: Dictionary, scythe: int, expected_parent: int, expected_parent_socket_prefix: String) -> void:
	var edge := Helpers.scythe_edge(main, unit_bp, scythe)
	if edge.is_empty():
		_fail("Scythe link edge missing.")
		return
	var own_socket: String = main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, scythe))
	var parent: int = main._topology_edge_other_node(edge, scythe)
	var parent_socket: String = main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, parent))
	if parent != expected_parent:
		_fail("Unexpected scythe parent %d, expected %d." % [parent, expected_parent])
		return
	if own_socket != "root_joint":
		_fail("Scythe must connect through root_joint/handle, got %s." % own_socket)
		return
	if expected_parent_socket_prefix == "torso_port:":
		if not parent_socket.begins_with("torso_port:"):
			_fail("Scythe direct torso link should use a torso port, got %s." % parent_socket)
			return
	elif parent_socket != expected_parent_socket_prefix:
		_fail("Scythe parent socket should be %s, got %s." % [expected_parent_socket_prefix, parent_socket])
		return


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
	_assert_root_link(main, unit_bp, scythe, limb, "distal")

	main = Helpers.setup_main(self)
	unit_bp = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := Helpers.first_torso(main)
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_part)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["blank_canvas"] = false
	scythe = Helpers.append_loose_scythe_near_limb(main, unit_bp, torso)
	main._link_topology_nodes(unit_bp, scythe, torso)
	_assert_root_link(main, unit_bp, scythe, torso, "torso_port:")
	print("SCYTHE_LINK_ROOT_SOCKET_PROBE ok")
	quit(0)
