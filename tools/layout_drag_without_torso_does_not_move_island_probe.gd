extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_terminal(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._part_counts_as_terminal_weapon(part, "muscle"):
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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_board_tool = "layout"
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso(main)
	var terminal_part := _first_terminal(main)
	if torso_part < 0 or terminal_part < 0:
		_fail("Missing torso or terminal catalog part.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LIMB", "limb_muscle", 0, Vector2.RIGHT, [0])
	var terminal := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "TIP", "muscle", terminal_part, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var before_torso: Vector2 = main._topology_node_position(nodes[torso])
	var before_limb: Vector2 = main._topology_node_position(nodes[limb])
	var before_terminal: Vector2 = main._topology_node_position(nodes[terminal])
	var limb_local := main._topology_position_to_board_local(before_limb)
	main._handle_custom_topology_click(_mouse_button(limb_local, true), unit_bp)
	main._handle_editor_board_input(_mouse_motion(limb_local + Vector2(110.0, 30.0)))
	main._handle_editor_board_input(_mouse_button(limb_local + Vector2(110.0, 30.0), false))
	var moved_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	if main._topology_node_position(moved_nodes[torso]).distance_to(before_torso) > 0.00001:
		_fail("Layout dragging a connected limb without torso moved the torso.")
	if main._topology_node_position(moved_nodes[limb]).distance_to(before_limb) > 0.00001:
		_fail("Layout dragging a connected limb without torso moved the limb instead of requiring pose mode.")
	if main._topology_node_position(moved_nodes[terminal]).distance_to(before_terminal) > 0.00001:
		_fail("Layout dragging a connected limb without torso moved downstream parts.")
	var gap := main._topology_max_socket_gap("hero", unit_bp, moved_nodes, edges)
	if gap > 0.00001:
		_fail("Blocked layout limb drag created socket gap %.6f." % gap)
	print("LAYOUT_DRAG_WITHOUT_TORSO_DOES_NOT_MOVE_ISLAND_PROBE ok")
	quit()
