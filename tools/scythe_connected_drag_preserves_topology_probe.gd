extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_limb(main: Node) -> int:
	return 0 if main._catalog_for("hero", "limb_muscle").size() > 0 else -1


func _scythe_index(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._blade_weapon_family_for_part(part) == "scythe" and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


func _mouse_button(pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = pos
	event.pressed = pressed
	return event


func _mouse_motion(pos: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = pos
	return event


func _far_visible_point(main: Node, unit_bp: Dictionary, node_index: int) -> Vector2:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var polygon: PackedVector2Array = main._topology_node_visible_hit_polygon("hero", unit_bp, nodes, edges, node_index)
	if polygon.size() < 3:
		_fail("Scythe visual polygon was not available.")
	var center: Vector2 = main._topology_position_to_board_local(main._topology_node_position(nodes[node_index]))
	var best := Vector2(polygon[0])
	var best_distance := -1.0
	for point in polygon:
		var candidate := Vector2(point)
		var distance := candidate.distance_to(center)
		if distance > best_distance:
			best_distance = distance
			best = candidate
	return best


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_board_tool = "layout"
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso(main)
	var limb_part := _first_limb(main)
	var scythe_part := _scythe_index(main)
	if torso_part < 0 or limb_part < 0 or scythe_part < 0:
		_fail("Missing torso, limb, or scythe catalog part.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_part)
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "HANDLE", "limb_muscle", limb_part, Vector2.RIGHT, [0])
	var scythe := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "SCYTHE", "muscle", scythe_part, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["blank_canvas"] = false
	var before_positions: Array = []
	for node in nodes:
		before_positions.append(main._topology_node_position(node))
	var before_edge_count := edges.size()
	var click_pos: Vector2 = _far_visible_point(main, unit_bp, scythe)
	if main._nearest_custom_node_index("hero", unit_bp, nodes, click_pos) != scythe:
		_fail("Connected scythe visible blade did not select the scythe node.")
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	main._handle_editor_board_input(_mouse_motion(click_pos + Vector2(94.0, 38.0)))
	main._handle_editor_board_input(_mouse_button(click_pos + Vector2(94.0, 38.0), false))
	unit_bp = main._editor_current_blueprint()
	var after_topology: Dictionary = unit_bp.get("custom_topology", {})
	var after_nodes: Array = after_topology.get("nodes", [])
	var after_edges: Array = after_topology.get("edges", [])
	if after_edges.size() != before_edge_count:
		_fail("Dragging a connected scythe changed edge count from %d to %d." % [before_edge_count, after_edges.size()])
	var moved_count := 0
	for i in range(after_nodes.size()):
		var delta: Vector2 = main._topology_node_position(after_nodes[i]) - Vector2(before_positions[i])
		if delta.length() > 0.001:
			moved_count += 1
	if moved_count != 0:
		_fail("Connected scythe layout drag should be topology-protected, moved=%d nodes." % moved_count)
	var gap := main._topology_max_socket_gap("hero", unit_bp, after_nodes, after_edges)
	if gap > 0.00001:
		_fail("Blocked connected scythe drag created socket gap %.6f." % gap)
	print("SCYTHE_CONNECTED_DRAG_PRESERVES_TOPOLOGY_PROBE ok scythe=%d edges=%d" % [scythe, after_edges.size()])
	quit()
