extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


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


func _first_torso(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_limb(main: Node) -> int:
	return 0 if main._catalog_for("hero", "limb_muscle").size() > 0 else -1


func _visible_point(main: Node, unit_bp: Dictionary, node_index: int) -> Vector2:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var polygon: PackedVector2Array = main._topology_node_visible_hit_polygon("hero", unit_bp, nodes, edges, node_index)
	if polygon.size() < 3:
		_fail("Visible polygon missing for connected node %d." % node_index)
	var center: Vector2 = main._topology_position_to_board_local(main._topology_node_position(nodes[node_index]))
	var best := Vector2(polygon[0])
	var best_distance := -1.0
	for raw_point in polygon:
		var point := Vector2(raw_point)
		var distance := point.distance_to(center)
		if distance > best_distance:
			best_distance = distance
			best = point
	return center.lerp(best, 0.72)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_board_tool = "layout"
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var torso_part := _first_torso(main)
	var limb_part := _first_limb(main)
	if torso_part < 0 or limb_part < 0:
		_fail("Missing torso or limb catalog part.")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.50), torso_part)
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LIMB", "limb_muscle", limb_part, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["blank_canvas"] = false
	main._topology_update_local_pose_fields("hero", unit_bp)
	var before_positions: Array = []
	for node in nodes:
		before_positions.append(main._topology_node_position(node))
	var before_edge_count := edges.size()
	var click_pos := _visible_point(main, unit_bp, limb)
	if int(main._nearest_custom_node_index("hero", unit_bp, nodes, click_pos)) != limb:
		_fail("Connected limb visible body did not select the limb node.")
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	if int(main.editor_dragging_node_index) != -1 or bool(main.editor_dragging_selected_nodes):
		_fail("Connected non-torso node started a layout drag; reject=%s." % String(main.last_layout_drag_reject_reason))
	main._handle_editor_board_input(_mouse_motion(click_pos + Vector2(80.0, 42.0)))
	main._handle_editor_board_input(_mouse_button(click_pos + Vector2(80.0, 42.0), false))
	var after_topology: Dictionary = unit_bp.get("custom_topology", {})
	var after_nodes: Array = after_topology.get("nodes", [])
	var after_edges: Array = after_topology.get("edges", [])
	if after_edges.size() != before_edge_count:
		_fail("Connected layout protection changed edge count from %d to %d." % [before_edge_count, after_edges.size()])
	for i in range(after_nodes.size()):
		var delta: Vector2 = main._topology_node_position(after_nodes[i]) - Vector2(before_positions[i])
		if delta.length() > 0.001:
			_fail("Connected layout protection moved node %d by %s." % [i, str(delta)])
	print("BOARD_CONNECTED_PART_LAYOUT_PROTECTION_PROBE ok edges=%d" % after_edges.size())
	quit()
