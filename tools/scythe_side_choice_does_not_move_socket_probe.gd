extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _socket_state(main: Node, unit_bp: Dictionary, scythe: int) -> Dictionary:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var edge := Helpers.scythe_edge(main, unit_bp, scythe)
	if edge.is_empty():
		return {}
	var parent: int = main._topology_edge_other_node(edge, scythe)
	var parent_socket: String = main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, parent))
	var root_world: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, scythe, "root_joint", parent)
	var parent_world: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, parent, parent_socket, scythe)
	return {
		"root": root_world,
		"parent": parent_world,
		"gap": root_world.distance_to(parent_world),
		"center": main._topology_node_position(Dictionary(nodes[scythe])),
		"axis": main._topology_endpoint_axis_for_node(scythe, nodes, edges).normalized(),
	}


func _assert_same(before: Dictionary, after: Dictionary, label: String) -> void:
	if before.is_empty() or after.is_empty():
		_fail("%s state missing." % label)
		return
	if float(after.get("gap", 999.0)) > 0.00001:
		_fail("%s changed root socket fit: %.8f." % [label, float(after.get("gap", 999.0))])
		return
	if Vector2(before.get("root", Vector2.ZERO)).distance_to(Vector2(after.get("root", Vector2.ZERO))) > 0.00001:
		_fail("%s moved root socket point." % label)
		return
	if Vector2(before.get("center", Vector2.ZERO)).distance_to(Vector2(after.get("center", Vector2.ZERO))) > 0.00001:
		_fail("%s moved scythe center." % label)
		return
	if Vector2(before.get("axis", Vector2.RIGHT)).distance_to(Vector2(after.get("axis", Vector2.RIGHT))) > 0.00001:
		_fail("%s changed scythe handle axis." % label)
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
	unit_bp = main._editor_current_blueprint()
	var before := _socket_state(main, unit_bp, scythe)
	main._editor_action("set_handedness_left")
	unit_bp = main._editor_current_blueprint()
	var after_left := _socket_state(main, unit_bp, scythe)
	_assert_same(before, after_left, "left side choice")
	main.editor_topology_node_index = scythe
	main.editor_selected_topology_nodes = [scythe]
	main._editor_action("flip_handedness")
	unit_bp = main._editor_current_blueprint()
	var after_right := _socket_state(main, unit_bp, scythe)
	_assert_same(before, after_right, "right side flip")
	print("SCYTHE_SIDE_CHOICE_DOES_NOT_MOVE_SOCKET_PROBE ok scythe=%d" % scythe)
	quit(0)
