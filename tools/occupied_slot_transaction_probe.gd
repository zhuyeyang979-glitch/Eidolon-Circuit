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


func _first_terminal(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._part_counts_as_terminal_weapon(part, "muscle"):
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
	var terminal_part := _first_terminal(main)
	if torso_part < 0 or terminal_part < 0:
		_fail("No torso with at least two ports or terminal weapon found.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	var port_positions: Array = main._topology_torso_port_positions("hero", nodes[torso], unit_bp)
	var torso_pos: Vector2 = main._topology_node_position(nodes[torso])
	for port_index in range(port_positions.size()):
		var direction: Vector2 = Vector2(port_positions[port_index]) - torso_pos
		var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ROOT %d" % port_index, "limb_muscle", 0, direction, [0])
		main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "TIP %d" % port_index, "muscle", terminal_part, direction)
	if edges.size() != port_positions.size() * 2:
		_fail("Setup failed: expected every torso port and limb distal to be occupied.")
	var used_socket := main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edges[0], torso))
	var new_index := nodes.size()
	var start_pos: Vector2 = main._topology_node_position(nodes[torso]) + Vector2(0.02, 0.02)
	nodes.append(main._topology_component_node(new_index, "EXTRA", start_pos, "limb_muscle", 0, 0, [0]))
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges.duplicate(true), "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var before_edges: Array = Array(Dictionary(unit_bp["custom_topology"]).get("edges", [])).duplicate(true)
	var before_pos: Vector2 = main._topology_node_position(nodes[new_index])
	var linked := main._try_magnetic_link_for_node(unit_bp, new_index)
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var after_nodes: Array = topology.get("nodes", [])
	var after_edges: Array = topology.get("edges", [])
	if linked:
		_fail("Magnetic link accepted an already occupied torso slot.")
	if after_edges.size() != before_edges.size():
		_fail("Rejected magnetic link changed edge count.")
	for i in range(before_edges.size()):
		if Dictionary(after_edges[i]) != Dictionary(before_edges[i]):
			_fail("Rejected magnetic link replaced an existing edge.")
	if main._topology_node_position(after_nodes[new_index]).distance_to(before_pos) > 0.00001:
		_fail("Rejected magnetic link moved the new limb.")
	var occupancy := main._topology_socket_occupancy("hero", unit_bp, after_nodes, after_edges)
	var torso_occ: Dictionary = occupancy.get(torso, {})
	for socket_id in torso_occ.keys():
		if Array(torso_occ[socket_id]).size() != 1:
			_fail("Torso socket %s has duplicate occupancy after rejected link." % String(socket_id))
	print("OCCUPIED_SLOT_TRANSACTION_PROBE ok rejected_socket=%s edges=%d" % [used_socket, after_edges.size()])
	quit()
