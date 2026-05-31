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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_board_tool = "pose"
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso(main)
	var terminal_part := _first_terminal(main)
	if torso_part < 0 or terminal_part < 0:
		_fail("Missing torso or terminal part.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.45, 0.5), torso_part)
	var limb_a := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT, [0])
	var limb_b := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.UP, [1])
	var terminal := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_b, "TIP", "muscle", terminal_part, Vector2.UP)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var torso_pos: Vector2 = main._topology_node_position(nodes[torso])
	var a_pos: Vector2 = main._topology_node_position(nodes[limb_a])
	var b_pos: Vector2 = main._topology_node_position(nodes[limb_b])
	var a_axis: Vector2 = main._topology_endpoint_axis_for_node(limb_a, nodes, edges)
	var b_axis: Vector2 = main._topology_endpoint_axis_for_node(limb_b, nodes, edges)
	var terminal_pos: Vector2 = main._topology_node_position(nodes[terminal])
	var click_root := main._pose_root_for_click("hero", unit_bp, nodes, edges, terminal)
	if click_root != terminal:
		_fail("Clicking a terminal weapon should use the terminal itself as pose root.")
	var pivot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, terminal, "root_joint")
	var start_local := main._topology_position_to_board_local(pivot + Vector2.UP * 0.1)
	var end_local := main._topology_position_to_board_local(pivot + Vector2.LEFT * 0.1)
	if not main._start_editor_pose_drag(unit_bp, terminal, start_local, [terminal]):
		_fail("Could not start pose drag for terminal weapon.")
	main._update_editor_pose_drag(unit_bp, end_local)
	main._finish_editor_pose_drag(unit_bp)
	var moved_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	if main._topology_node_position(moved_nodes[torso]).distance_to(torso_pos) > 0.00001:
		_fail("Terminal pose drag moved the torso.")
	if main._topology_node_position(moved_nodes[limb_a]).distance_to(a_pos) > 0.00001:
		_fail("Terminal pose drag moved the first limb.")
	if main._topology_node_position(moved_nodes[limb_b]).distance_to(b_pos) > 0.00001:
		_fail("Terminal pose drag moved the second limb.")
	if main._topology_endpoint_axis_for_node(limb_a, moved_nodes, edges).distance_to(a_axis) > 0.00001:
		_fail("Terminal pose drag rotated the first limb.")
	if main._topology_endpoint_axis_for_node(limb_b, moved_nodes, edges).distance_to(b_axis) > 0.00001:
		_fail("Terminal pose drag rotated the second limb.")
	if main._topology_node_position(moved_nodes[terminal]).distance_to(terminal_pos) <= 0.00001:
		_fail("Terminal pose drag did not rotate the terminal weapon.")
	var gap := main._topology_max_socket_gap("hero", unit_bp, moved_nodes, edges)
	if gap > 0.00001:
		_fail("Terminal pose drag created socket gap %.6f." % gap)
	print("POSE_TERMINAL_INDEPENDENT_PROBE ok")
	quit()
