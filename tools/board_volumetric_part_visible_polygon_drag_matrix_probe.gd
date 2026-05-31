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


func _visible_distal_point(main: Node, unit_bp: Dictionary, node_index: int) -> Vector2:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var polygon: PackedVector2Array = main._topology_node_visible_hit_polygon("hero", unit_bp, nodes, edges, node_index)
	if polygon.size() < 3:
		_fail("Visible polygon missing for node %d." % node_index)
	var center: Vector2 = main._topology_position_to_board_local(main._topology_node_position(nodes[node_index]))
	var best := Vector2(polygon[0])
	var best_distance := -1.0
	for raw_point in polygon:
		var point := Vector2(raw_point)
		var distance := point.distance_to(center)
		if distance > best_distance:
			best_distance = distance
			best = point
	return center.lerp(best, 0.88)


func _check_part(main: Node, slot_key: String, part_index: int) -> int:
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var node: Dictionary = main._topology_component_node(0, "TARGET", Vector2(0.48, 0.50), slot_key, part_index)
	unit_bp["custom_topology"] = {"nodes": [node], "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["blank_canvas"] = false
	main.editor_board_tool = "layout"
	main._topology_update_local_pose_fields("hero", unit_bp)
	var nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var click_pos: Vector2 = _visible_distal_point(main, unit_bp, 0)
	var drag_pos := click_pos + Vector2(42.0, -24.0)
	var before: Vector2 = main._topology_node_position(nodes[0])
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	if int(main.editor_dragging_node_index) != 0:
		var part: Dictionary = main._selected_component("hero", slot_key, part_index)
		_fail("%s[%d] %s did not start layout drag from visible polygon." % [slot_key, part_index, String(part.get("name", ""))])
	main._handle_editor_board_input(_mouse_motion(drag_pos))
	main._handle_editor_board_input(_mouse_button(drag_pos, false))
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var after: Vector2 = main._topology_node_position(nodes[0])
	if after.distance_to(before) <= 0.001:
		var failed_part: Dictionary = main._selected_component("hero", slot_key, part_index)
		_fail("%s[%d] %s did not move during layout drag." % [slot_key, part_index, String(failed_part.get("name", ""))])
	return 1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var checked := 0
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		checked += _check_part(main, "limb_muscle", i)
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			continue
		checked += _check_part(main, "muscle", i)
	print("BOARD_VOLUMETRIC_PART_VISIBLE_POLYGON_DRAG_MATRIX_PROBE ok checked=%d" % checked)
	quit()
