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


func _first_torso(main: Node) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_limb(main: Node) -> int:
	return 0 if main._catalog_for("hero", "limb_muscle").size() > 0 else -1


func _visible_point_far_from_center(main: Node, unit_bp: Dictionary, node_index: int) -> Vector2:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var polygon: PackedVector2Array = main._topology_node_visible_hit_polygon("hero", unit_bp, nodes, edges, node_index)
	if polygon.size() < 3:
		_fail("Visible polygon missing for node %d." % node_index)
	var center: Vector2 = main._topology_position_to_board_local(main._topology_node_position(nodes[node_index]))
	var parent_info: Dictionary = main._topology_parent_edge_info("hero", unit_bp, nodes, edges, node_index)
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
	return best


func _check_part(main: Node, slot_key: String, part_index: int) -> int:
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.38, 0.5), _first_torso(main))
	var target := -1
	if slot_key == "limb_muscle":
		target = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "TARGET", "limb_muscle", part_index, Vector2.RIGHT, [0])
	else:
		var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "HANDLE", "limb_muscle", _first_limb(main), Vector2.RIGHT, [0])
		target = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "TARGET", "muscle", part_index, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["blank_canvas"] = false
	main._topology_update_local_pose_fields("hero", unit_bp)
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	edges = Dictionary(unit_bp.get("custom_topology", {})).get("edges", [])
	var click_pos := _visible_point_far_from_center(main, unit_bp, target)
	var candidate: Dictionary = main._pose_drag_candidate_for_point("hero", unit_bp, nodes, edges, click_pos)
	if not bool(candidate.get("valid", false)) or int(candidate.get("root_index", -1)) != target:
		var part: Dictionary = main._selected_component("hero", slot_key, part_index)
		_fail("%s[%d] %s did not produce a valid pose candidate: %s" % [slot_key, part_index, String(part.get("name", "")), JSON.stringify(candidate)])
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	if not bool(main.editor_pose_dragging) or int(main.editor_pose_root_node) != target:
		var failed_part: Dictionary = main._selected_component("hero", slot_key, part_index)
		_fail("%s[%d] %s did not start pose drag: %s" % [slot_key, part_index, String(failed_part.get("name", "")), String(main.last_pose_drag_reject_reason)])
	main._handle_editor_board_input(_mouse_button(click_pos, false))
	return 1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_board_tool = "pose"
	main._start_blank_topology()
	var checked := 0
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		checked += _check_part(main, "limb_muscle", i)
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			continue
		checked += _check_part(main, "muscle", i)
	print("POSE_MODE_VISIBLE_POLYGON_DRAG_MATRIX_PROBE ok checked=%d" % checked)
	quit()
