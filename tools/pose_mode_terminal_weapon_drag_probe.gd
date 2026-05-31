extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const Renderer := preload("res://scripts/assembly_board_renderer.gd")


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
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _terminal_for_family(main: Node, family_key: String) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			continue
		var component := Renderer.part_to_component_node("muscle", part)
		var family := Renderer.terminal_shape_family(component)
		if family_key == "gun" and String(part.get("material_class", "")).to_lower() in ["gun", "missile_launcher", "web_gun"]:
			return i
		if family == family_key:
			return i
	return -1


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


func _drag_target_around_pivot(main: Node, unit_bp: Dictionary, node_index: int, click_pos: Vector2, radians: float) -> Vector2:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var pivot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, node_index, "root_joint")
	var start_topology: Vector2 = main._board_position_to_topology(click_pos)
	var vec := start_topology - pivot
	if vec.length() < 0.01:
		vec = Vector2.RIGHT * 0.16
	return main._topology_position_to_board_local(pivot + vec.rotated(radians))


func _run_case(family_key: String) -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_board_tool = "pose"
	main._start_blank_topology()
	var terminal_part := _terminal_for_family(main, family_key)
	if terminal_part < 0:
		_fail("Missing terminal family %s." % family_key)
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "HANDLE", "limb_muscle", 0, Vector2.RIGHT, [0])
	var terminal := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, family_key.to_upper(), "muscle", terminal_part, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["blank_canvas"] = false
	main._topology_update_local_pose_fields("hero", unit_bp)
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var before_limb: Vector2 = main._topology_node_position(nodes[limb])
	var before_terminal: Vector2 = main._topology_node_position(nodes[terminal])
	var click_pos := _visible_point_far_from_center(main, unit_bp, terminal)
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	if not bool(main.editor_pose_dragging) or int(main.editor_pose_root_node) != terminal:
		_fail("%s terminal did not start terminal pose drag: %s" % [family_key, String(main.last_pose_drag_reject_reason)])
	var drag_pos := _drag_target_around_pivot(main, unit_bp, terminal, click_pos, -0.58)
	main._handle_editor_board_input(_mouse_motion(drag_pos))
	main._tick_editor_visuals(1.0 / 60.0)
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	if main._topology_node_position(nodes[limb]).distance_to(before_limb) > 0.00001:
		_fail("%s terminal pose drag moved its parent limb." % family_key)
	if main._topology_node_position(nodes[terminal]).distance_to(before_terminal) <= 0.001:
		_fail("%s terminal pose drag did not rotate the terminal." % family_key)
	main._handle_editor_board_input(_mouse_button(drag_pos, false))
	main.queue_free()


func _init() -> void:
	for family in ["scythe", "shield", "drill", "gauntlet", "gun"]:
		_run_case(String(family))
	print("POSE_MODE_TERMINAL_WEAPON_DRAG_PROBE ok")
	quit()
