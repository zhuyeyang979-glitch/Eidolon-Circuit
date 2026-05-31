extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_with_ports(main, min_ports: int) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part) and main._torso_external_joint_ports(part) >= min_ports:
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso_with_ports(main, 3)
	if torso_part < 0:
		_fail("No torso with at least three external ports was found.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	var torso_pos: Vector2 = main._topology_node_position(nodes[torso])
	var directions := [Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for i in range(directions.size()):
		var before_edges := edges.size()
		main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ROOT LIMB %d" % (i + 1), "limb_muscle", 0, directions[i], [i])
		if edges.size() != before_edges + 1:
			_fail("Root limb %d did not create exactly one edge." % (i + 1))
		if not main._topology_node_is_torso("hero", nodes[torso], unit_bp):
			_fail("Torso node degraded after adding limb %d." % (i + 1))
		if main._topology_node_position(nodes[torso]).distance_to(torso_pos) > 0.00001:
			_fail("Torso moved while adding limb %d." % (i + 1))
	var occupied := main._topology_socket_occupancy("hero", unit_bp, nodes, edges)
	var torso_occ: Dictionary = occupied.get(torso, {})
	if torso_occ.size() != 3:
		_fail("Expected three occupied torso ports, got %d." % torso_occ.size())
	for socket_id in torso_occ.keys():
		if Array(torso_occ[socket_id]).size() != 1:
			_fail("Torso socket %s was occupied by %d edges." % [String(socket_id), Array(torso_occ[socket_id]).size()])
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		var label := String(node.get("label", ""))
		if label == "" or label == str(i + 1):
			_fail("Node %d visible label degraded to '%s'." % [i + 1, label])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._refresh_editor_visual_views()
	var snapshot: Dictionary = main.assembly_board_view.board_snapshot
	if bool(snapshot.get("show_node_numbers", false)):
		_fail("Board snapshot enables debug node numbers by default.")
	print("THREE_ROOT_LIMB_ATTACH_PROBE ok nodes=%d edges=%d ports=%d" % [nodes.size(), edges.size(), torso_occ.size()])
	quit()
