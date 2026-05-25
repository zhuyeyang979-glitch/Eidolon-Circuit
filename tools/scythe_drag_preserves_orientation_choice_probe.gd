extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


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
	main._start_blank_topology()
	var scythe_part := _scythe_index(main)
	if scythe_part < 0:
		_fail("Scythe terminal missing.")
	main._drop_catalog_part_on_board("muscle", scythe_part, Vector2(324.0, 254.0))
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var node_index := int(main.editor_pending_orientation_node_index)
	if node_index < 0:
		_fail("Scythe placement did not start orientation choice.")
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var before_side := String(Dictionary(nodes[node_index]).get("visual_mount_side", ""))
	var click_pos: Vector2 = _far_visible_point(main, unit_bp, node_index)
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	main._handle_editor_board_input(_mouse_motion(click_pos + Vector2(62.0, -34.0)))
	main._handle_editor_board_input(_mouse_button(click_pos + Vector2(62.0, -34.0), false))
	unit_bp = main._editor_current_blueprint()
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var after_side := String(Dictionary(nodes[node_index]).get("visual_mount_side", ""))
	if int(main.editor_pending_orientation_node_index) != node_index:
		_fail("Dragging an unconnected scythe cleared the pending orientation choice.")
	if after_side != before_side:
		_fail("Dragging changed visual_mount_side from %s to %s." % [before_side, after_side])
	if not main.editor_action_buttons.has("set_handedness_left") or not bool(main.editor_action_buttons["set_handedness_left"].visible):
		_fail("Left orientation button disappeared after scythe drag.")
	if not main.editor_action_buttons.has("set_handedness_right") or not bool(main.editor_action_buttons["set_handedness_right"].visible):
		_fail("Right orientation button disappeared after scythe drag.")
	print("SCYTHE_DRAG_PRESERVES_ORIENTATION_CHOICE_PROBE ok node=%d side=%s" % [node_index, after_side])
	quit()
