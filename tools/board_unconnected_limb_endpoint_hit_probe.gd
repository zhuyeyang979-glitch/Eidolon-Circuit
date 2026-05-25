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
	var best := -1
	var best_length := -1.0
	var catalog: Array = main._catalog_for("hero", "limb_muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		var length := float(part.get("length", part.get("component_length", 0.0)))
		if length > best_length:
			best_length = length
			best = i
	return best


func _endpoint_point(main: Node, unit_bp: Dictionary, node_index: int, sign: float) -> Vector2:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var visual_nodes: Array = main._topology_visual_hit_nodes("hero", unit_bp, nodes, edges)
	var node: Dictionary = visual_nodes[node_index]
	var center: Vector2 = main._topology_position_to_board_local(main._topology_node_position(node))
	var axis: Vector2 = main._topology_visual_hit_node_axis(node_index, visual_nodes, edges)
	if axis.length() <= 0.01:
		axis = Vector2.RIGHT
	axis = axis.normalized()
	var radius: float = main._topology_visual_hit_node_radius(node)
	var visual_length: float = main._topology_visual_hit_node_length_px(node, radius)
	return center + axis * visual_length * 0.5 * sign


func _place_loose_limb(main: Node, limb_index: int, place_pos: Vector2) -> Dictionary:
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, "limb_muscle", limb_index)
	main._handle_editor_board_input(_mouse_button(place_pos, true))
	var node_index := int(main.editor_dragging_node_index)
	main._handle_editor_board_input(_mouse_button(place_pos, false))
	if node_index < 0:
		_fail("Loose limb placement did not create a node.")
	return {"unit_bp": unit_bp, "node_index": node_index}


func _check_endpoint(main: Node, limb_index: int, sign: float) -> void:
	var placed := _place_loose_limb(main, limb_index, Vector2(314.0, 246.0))
	var unit_bp: Dictionary = placed.get("unit_bp", {})
	var node_index := int(placed.get("node_index", -1))
	var click_pos := _endpoint_point(main, unit_bp, node_index, sign)
	if int(main._nearest_custom_node_index("hero", unit_bp, Dictionary(unit_bp.get("custom_topology", {})).get("nodes", []), click_pos)) != node_index:
		_fail("Loose limb endpoint %.1f did not hit its node." % sign)
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	if int(main.editor_dragging_node_index) != node_index:
		_fail("Loose limb endpoint %.1f did not start drag; reject=%s hit=%s." % [sign, String(main.last_layout_drag_reject_reason), String(main.last_layout_drag_hit_reason)])
	var drag_pos := click_pos + Vector2(24.0 * sign, 22.0)
	main._handle_editor_board_input(_mouse_motion(drag_pos))
	main._handle_editor_board_input(_mouse_button(drag_pos, false))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_board_tool = "layout"
	var limb_index := _first_limb(main)
	if limb_index < 0:
		_fail("Missing hero limb_muscle catalog part.")
	_check_endpoint(main, limb_index, -1.0)
	_check_endpoint(main, limb_index, 1.0)
	print("BOARD_UNCONNECTED_LIMB_ENDPOINT_HIT_PROBE ok limb=%d" % limb_index)
	quit()
