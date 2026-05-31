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


func _first_torso(main: Node, role_key: String) -> int:
	for i in range(main._catalog_for(role_key, "muscle").size()):
		if main._component_is_torso(main._selected_component(role_key, "muscle", i)):
			return i
	return -1


func _first_limb(main: Node, role_key: String) -> int:
	return 0 if main._catalog_for(role_key, "limb_muscle").size() > 0 else -1


func _visible_distal_point(main: Node, role_key: String, unit_bp: Dictionary, node_index: int) -> Vector2:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var polygon: PackedVector2Array = main._topology_node_visible_hit_polygon(role_key, unit_bp, nodes, edges, node_index)
	if polygon.size() < 3:
		_fail("%s node %d visible polygon missing." % [role_key, node_index])
	var center: Vector2 = main._topology_position_to_board_local(main._topology_node_position(nodes[node_index]))
	var parent_info: Dictionary = main._topology_parent_edge_info(role_key, unit_bp, nodes, edges, node_index)
	if not parent_info.is_empty():
		var parent_index := int(parent_info.get("parent", -1))
		if parent_index >= 0 and parent_index < nodes.size():
			var parent_center: Vector2 = main._topology_position_to_board_local(main._topology_node_position(nodes[parent_index]))
			var axis := center - parent_center
			if axis.length() > 0.01:
				axis = axis.normalized()
				var distal := Vector2(polygon[0])
				var distal_score := -INF
				for raw_point in polygon:
					var point := Vector2(raw_point)
					var score := (point - center).dot(axis)
					if score > distal_score:
						distal_score = score
						distal = point
				return center.lerp(distal, 0.88)
	var best := Vector2(polygon[0])
	var best_distance := -1.0
	for raw_point in polygon:
		var point := Vector2(raw_point)
		var distance := point.distance_to(center)
		if distance > best_distance:
			best_distance = distance
			best = point
	return center.lerp(best, 0.88)


func _check_part(main: Node, role_key: String, slot_key: String, part_index: int) -> int:
	main.editor_role_index = MainScene.ROLE_ORDER.find(role_key)
	main.editor_board_tool = "layout"
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso(main, role_key)
	var limb_part := _first_limb(main, role_key)
	if torso_part < 0 or limb_part < 0:
		_fail("%s missing torso or limb catalog part." % role_key)
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.38, 0.50), torso_part)
	var target := -1
	if slot_key == "limb_muscle":
		target = main._append_directed_component_node(role_key, unit_bp, nodes, edges, torso, "TARGET", "limb_muscle", part_index, Vector2.RIGHT, [0])
	else:
		var limb: int = main._append_directed_component_node(role_key, unit_bp, nodes, edges, torso, "HANDLE", "limb_muscle", limb_part, Vector2.RIGHT, [0])
		target = main._append_directed_component_node(role_key, unit_bp, nodes, edges, limb, "TARGET", "muscle", part_index, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["blank_canvas"] = false
	main._topology_update_local_pose_fields(role_key, unit_bp)
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	edges = Dictionary(unit_bp.get("custom_topology", {})).get("edges", [])
	var before_positions: Array = []
	for node in nodes:
		before_positions.append(main._topology_node_position(node))
	var before_edges := edges.size()
	var before_gap: float = main._topology_max_socket_gap(role_key, unit_bp, nodes, edges)
	var click_pos: Vector2 = _visible_distal_point(main, role_key, unit_bp, target)
	var drag_pos := click_pos + Vector2(66.0, -32.0)
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	if not bool(main.editor_dragging_selected_nodes) or int(main.editor_dragging_node_index) < 0:
		var no_drag_part: Dictionary = main._selected_component(role_key, slot_key, part_index)
		_fail("%s %s[%d] %s connected visible click did not start island drag." % [role_key, slot_key, part_index, String(no_drag_part.get("name", ""))])
	main._handle_editor_board_input(_mouse_motion(drag_pos))
	main._handle_editor_board_input(_mouse_button(drag_pos, false))
	unit_bp = main._editor_current_blueprint()
	var after_topology: Dictionary = unit_bp.get("custom_topology", {})
	var after_nodes: Array = after_topology.get("nodes", [])
	var after_edges: Array = after_topology.get("edges", [])
	if after_edges.size() != before_edges:
		_fail("%s %s[%d] connected island drag changed edge count." % [role_key, slot_key, part_index])
	var moved_count := 0
	var first_delta := Vector2.ZERO
	for i in range(after_nodes.size()):
		var delta: Vector2 = main._topology_node_position(after_nodes[i]) - Vector2(before_positions[i])
		if delta.length() > 0.001:
			moved_count += 1
			if moved_count == 1:
				first_delta = delta
			elif delta.distance_to(first_delta) > 0.0001:
				_fail("%s %s[%d] island drag was not rigid at node %d." % [role_key, slot_key, part_index, i])
	if moved_count != after_nodes.size():
		var failed_part: Dictionary = main._selected_component(role_key, slot_key, part_index)
		_fail("%s %s[%d] %s did not move the whole connected island, moved=%d nodes=%d." % [role_key, slot_key, part_index, String(failed_part.get("name", "")), moved_count, after_nodes.size()])
	var gap: float = main._topology_max_socket_gap(role_key, unit_bp, after_nodes, after_edges)
	if gap > before_gap + 0.00001:
		_fail("%s %s[%d] island drag increased socket gap from %.6f to %.6f." % [role_key, slot_key, part_index, before_gap, gap])
	return 1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	var checked := 0
	for role in MainScene.ROLE_ORDER:
		var role_key := String(role)
		for i in range(main._catalog_for(role_key, "limb_muscle").size()):
			checked += _check_part(main, role_key, "limb_muscle", i)
		for i in range(main._catalog_for(role_key, "muscle").size()):
			var part: Dictionary = main._selected_component(role_key, "muscle", i)
			if main._component_is_torso(part):
				continue
			checked += _check_part(main, role_key, "muscle", i)
	print("BOARD_CONNECTED_VOLUMETRIC_ISLAND_DRAG_MATRIX_PROBE ok checked=%d" % checked)
	quit()
