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
	main._drop_catalog_part_on_board("muscle", scythe_part, Vector2(310.0, 250.0))
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var node_index := int(main.editor_pending_orientation_node_index)
	if node_index < 0:
		node_index = nodes.size() - 1
	if node_index < 0 or node_index >= nodes.size():
		_fail("Placed scythe node was not found.")
	var visible_point: Vector2 = _far_visible_point(main, unit_bp, node_index)
	var center: Vector2 = main._topology_position_to_board_local(main._topology_node_position(nodes[node_index]))
	var old_pick_radius := main._topology_node_pick_radius("hero", unit_bp, nodes[node_index])
	if visible_point.distance_to(center) <= old_pick_radius + 4.0:
		_fail("Probe could not find a scythe blade point outside the old center-pick radius.")
	var picked := main._nearest_custom_node_index("hero", unit_bp, nodes, visible_point)
	if picked != node_index:
		_fail("Visible scythe blade did not hit its node; picked=%d expected=%d." % [picked, node_index])
	var before_pos: Vector2 = main._topology_node_position(nodes[node_index])
	main._handle_editor_board_input(_mouse_button(visible_point, true))
	main._handle_editor_board_input(_mouse_motion(visible_point + Vector2(80.0, 36.0)))
	main._handle_editor_board_input(_mouse_button(visible_point + Vector2(80.0, 36.0), false))
	unit_bp = main._editor_current_blueprint()
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var after_pos: Vector2 = main._topology_node_position(nodes[node_index])
	if after_pos.distance_to(before_pos) <= 0.01:
		_fail("Dragging from the visible scythe blade did not move the unconnected node.")
	if int(main.editor_dragging_node_index) != -1:
		_fail("Scythe drag state did not clear on release.")
	print("SCYTHE_VISIBLE_POLYGON_DRAG_PROBE ok node=%d delta=%.3f" % [node_index, after_pos.distance_to(before_pos)])
	quit()
