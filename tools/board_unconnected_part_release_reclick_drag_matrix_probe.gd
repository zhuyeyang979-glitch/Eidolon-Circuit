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


func _part_is_board_volume(main: Node, role_key: String, slot_key: String, part_index: int) -> bool:
	var part: Dictionary = main._selected_component(role_key, slot_key, part_index)
	if slot_key == "muscle" and main._component_is_torso(part):
		return false
	return true


func _visible_distal_point(main: Node, role_key: String, unit_bp: Dictionary, node_index: int) -> Vector2:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var polygon: PackedVector2Array = main._topology_node_visible_hit_polygon(role_key, unit_bp, nodes, edges, node_index)
	if polygon.size() < 3:
		_fail("Visible polygon missing for loose node %d." % node_index)
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


func _check_part(main: Node, role_key: String, slot_key: String, part_index: int) -> int:
	main.editor_role_index = MainScene.ROLE_ORDER.find(role_key)
	main.editor_board_tool = "layout"
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, slot_key, part_index)
	var place_pos := Vector2(304.0, 242.0)
	main._handle_editor_board_input(_mouse_button(place_pos, true))
	var node_index := int(main.editor_dragging_node_index)
	if node_index < 0:
		var place_part: Dictionary = main._selected_component(role_key, slot_key, part_index)
		_fail("%s %s[%d] %s did not enter drag state during placement." % [role_key, slot_key, part_index, String(place_part.get("name", ""))])
	main._handle_editor_board_input(_mouse_button(place_pos, false))
	if int(main.editor_dragging_node_index) != -1:
		_fail("%s %s[%d] drag state did not clear after placement release." % [role_key, slot_key, part_index])
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	if main._topology_node_edge_count(edges, node_index) != 0:
		_fail("%s %s[%d] unexpectedly linked during single-node placement." % [role_key, slot_key, part_index])
	var click_pos := _visible_distal_point(main, role_key, unit_bp, node_index)
	var before: Vector2 = main._topology_node_position(nodes[node_index])
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	if int(main.editor_dragging_node_index) != node_index:
		var part: Dictionary = main._selected_component(role_key, slot_key, part_index)
		_fail("%s %s[%d] %s did not start re-click drag from visible body; reject=%s hit=%s." % [role_key, slot_key, part_index, String(part.get("name", "")), String(main.last_layout_drag_reject_reason), String(main.last_layout_drag_hit_reason)])
	var drag_pos := click_pos + Vector2(52.0, -31.0)
	main._handle_editor_board_input(_mouse_motion(drag_pos))
	main._handle_editor_board_input(_mouse_button(drag_pos, false))
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var after: Vector2 = main._topology_node_position(nodes[node_index])
	if after.distance_to(before) <= 0.001:
		var failed_part: Dictionary = main._selected_component(role_key, slot_key, part_index)
		_fail("%s %s[%d] %s did not move after release/re-click drag." % [role_key, slot_key, part_index, String(failed_part.get("name", ""))])
	return 1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	var checked := 0
	for role in MainScene.ROLE_ORDER:
		var role_key := String(role)
		for slot_key in ["limb_muscle", "muscle"]:
			for i in range(main._catalog_for(role_key, slot_key).size()):
				if not _part_is_board_volume(main, role_key, slot_key, i):
					continue
				checked += _check_part(main, role_key, slot_key, i)
	print("BOARD_UNCONNECTED_PART_RELEASE_RECLICK_DRAG_MATRIX_PROBE ok checked=%d" % checked)
	quit()
