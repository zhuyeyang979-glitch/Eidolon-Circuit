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
	var torso_part := _first_torso_with_ports(main, 2)
	if torso_part < 0:
		_fail("No torso with two ports found.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	var first := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ROOT A", "limb_muscle", 0, Vector2.RIGHT, [0])
	var second := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ROOT B", "limb_muscle", 0, Vector2.UP, [1])
	if edges.size() != 2:
		_fail("Expected two root limb connections.")
	var first_socket := main._topology_edge_socket_for_node(edges[0], torso)
	var second_socket := main._topology_edge_socket_for_node(edges[1], torso)
	if first_socket == second_socket:
		_fail("Setup failed: two limbs used the same torso socket.")
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var before_edges := edges.duplicate(true)
	var second_socket_pos: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, torso, second_socket, second)
	main._move_custom_node_to(unit_bp, first, main._topology_position_to_board_local(second_socket_pos))
	var moved_topology: Dictionary = unit_bp.get("custom_topology", {})
	var moved_edges: Array = moved_topology.get("edges", [])
	if moved_edges.size() != before_edges.size():
		_fail("Dragging a connected limb changed edge count.")
	for i in range(before_edges.size()):
		if Dictionary(moved_edges[i]) != Dictionary(before_edges[i]):
			_fail("Dragging a connected limb rewired or replaced an edge.")
	var occupancy := main._topology_socket_occupancy("hero", unit_bp, moved_topology.get("nodes", []), moved_edges)
	var torso_occ: Dictionary = occupancy.get(torso, {})
	for socket_id in torso_occ.keys():
		if Array(torso_occ[socket_id]).size() != 1:
			_fail("Dragging connected limb created duplicate occupancy on %s." % String(socket_id))
	print("DRAG_CONNECTED_NO_RESNAP_PROBE ok sockets=%s,%s" % [first_socket, second_socket])
	quit()
