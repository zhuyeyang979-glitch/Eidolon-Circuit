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
		if not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


func _edge_count(unit_bp: Dictionary) -> int:
	return Array(Dictionary(unit_bp.get("custom_topology", {})).get("edges", [])).size()


func _right_click(main, unit_bp: Dictionary, local_position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.position = local_position
	event.pressed = true
	main._handle_custom_topology_click(event, unit_bp)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var torso_index := _first_torso(main)
	var terminal_index := _first_terminal(main)
	if torso_index < 0 or terminal_index < 0:
		_fail("Missing torso or terminal part.")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_index)
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LINK", "limb_muscle", 0, Vector2.RIGHT, [0])
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "TIP", "muscle", terminal_index, Vector2.RIGHT)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	if _edge_count(unit_bp) != 2:
		_fail("Expected two direct links before right-click unlink, got %d." % _edge_count(unit_bp))
	var points := main._topology_edge_socket_board_points("hero", unit_bp, nodes, edges, torso, limb)
	var midpoint: Vector2 = (Vector2(points.get("a", Vector2.ZERO)) + Vector2(points.get("b", Vector2.ZERO))) * 0.5
	_right_click(main, unit_bp, midpoint)
	unit_bp = main._editor_current_blueprint()
	if _edge_count(unit_bp) != 1:
		_fail("Right-click on edge should unlink one connection, got %d links." % _edge_count(unit_bp))
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	nodes = topology.get("nodes", [])
	var limb_pos := main._topology_position_to_board_local(main._topology_node_position(nodes[limb]))
	_right_click(main, unit_bp, limb_pos)
	unit_bp = main._editor_current_blueprint()
	if _edge_count(unit_bp) != 0:
		_fail("Right-click on component should unlink remaining direct-muscle connections, got %d links." % _edge_count(unit_bp))
	print("EDITOR_RIGHT_CLICK_UNLINK_PROBE ok")
	quit()
