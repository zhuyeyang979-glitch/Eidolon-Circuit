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


func _first_limb(main: Node) -> int:
	return 0 if main._catalog_for("hero", "limb_muscle").size() > 0 else -1


func _visible_body_point(main: Node, unit_bp: Dictionary, node_index: int) -> Vector2:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var polygon: PackedVector2Array = main._topology_node_visible_hit_polygon("hero", unit_bp, nodes, edges, node_index)
	if polygon.size() < 3:
		_fail("Visible polygon missing for loose limb.")
	var center: Vector2 = main._topology_position_to_board_local(main._topology_node_position(nodes[node_index]))
	var best := Vector2(polygon[0])
	var best_distance := -1.0
	for raw_point in polygon:
		var point := Vector2(raw_point)
		var distance := point.distance_to(center)
		if distance > best_distance:
			best_distance = distance
			best = point
	return center.lerp(best, 0.80)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var limb_index := _first_limb(main)
	if limb_index < 0:
		_fail("Missing hero limb_muscle catalog part.")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, "limb_muscle", limb_index)
	var place_pos := Vector2(314.0, 246.0)
	main._handle_editor_board_input(_mouse_button(place_pos, true))
	var node_index := int(main.editor_dragging_node_index)
	main._handle_editor_board_input(_mouse_button(place_pos, false))
	if node_index < 0:
		_fail("Loose limb placement did not create a node.")
	main.editor_board_tool = "pose"
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var before: Vector2 = main._topology_node_position(nodes[node_index])
	var click_pos := _visible_body_point(main, unit_bp, node_index)
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	if bool(main.editor_pose_dragging):
		_fail("Loose limb in pose mode started pose rotation instead of temporary movement.")
	if int(main.editor_dragging_node_index) != node_index:
		_fail("Loose limb in pose mode did not enter temporary move drag; reject=%s hit=%s." % [String(main.last_layout_drag_reject_reason), String(main.last_layout_drag_hit_reason)])
	var drag_pos := click_pos + Vector2(-46.0, 37.0)
	main._handle_editor_board_input(_mouse_motion(drag_pos))
	main._handle_editor_board_input(_mouse_button(drag_pos, false))
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var after: Vector2 = main._topology_node_position(nodes[node_index])
	if after.distance_to(before) <= 0.001:
		_fail("Loose limb in pose mode did not move.")
	print("BOARD_UNCONNECTED_LIMB_POSE_MODE_MOVES_PROBE ok node=%d" % node_index)
	quit()
