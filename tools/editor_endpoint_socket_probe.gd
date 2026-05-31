extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_terminal(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle"):
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
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso(main))
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LINK", "limb_muscle", 0, Vector2.RIGHT, [0])
	var terminal := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "TIP", "muscle", _first_terminal(main), Vector2.RIGHT)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	if edges.size() != 2:
		_fail("Expected two direct edges, got %d." % edges.size())
	var root_sockets := main._topology_socket_ids_for_node("hero", nodes[torso], unit_bp)
	var limb_sockets := main._topology_socket_ids_for_node("hero", nodes[limb], unit_bp)
	var terminal_sockets := main._topology_socket_ids_for_node("hero", nodes[terminal], unit_bp)
	if root_sockets.is_empty() or not String(root_sockets[0]).begins_with("torso_port:"):
		_fail("Torso should expose real torso_port sockets.")
	if not (limb_sockets.has("root_joint") and limb_sockets.has("distal")):
		_fail("Connector muscle must expose root_joint and distal sockets, got %s." % str(limb_sockets))
	if terminal_sockets != ["root_joint"]:
		_fail("Terminal muscle should expose only root_joint, got %s." % str(terminal_sockets))
	for edge in edges:
		var a := main._topology_edge_node_a(edge)
		var b := main._topology_edge_node_b(edge)
		var a_socket := main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, a))
		var b_socket := main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, b))
		if not main._topology_socket_pair_can_connect("hero", unit_bp, nodes, a, a_socket, b, b_socket):
			_fail("Illegal direct socket pair %s <-> %s." % [a_socket, b_socket])
		var points := main._topology_edge_socket_board_points("hero", unit_bp, nodes, edges, a, b)
		if Vector2(points.get("a", Vector2.ZERO)).distance_to(Vector2(points.get("b", Vector2.ZERO))) > 1.5:
			_fail("Linked sockets should overlap on board.")
	var duplicate_edges := edges.duplicate(true)
	duplicate_edges.append(main._topology_make_socket_edge(terminal, "root_joint", limb, "distal"))
	var conflict := main._topology_endpoint_conflicts("hero", unit_bp, nodes, duplicate_edges)
	if not conflict.has("note"):
		_fail("Duplicate terminal root_joint/direct distal occupancy should be rejected.")
	print("EDITOR_ENDPOINT_SOCKET_PROBE nodes=%d edges=%d sockets=%d/%d/%d" % [nodes.size(), edges.size(), root_sockets.size(), limb_sockets.size(), terminal_sockets.size()])
	quit()
