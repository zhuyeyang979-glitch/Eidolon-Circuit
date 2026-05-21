extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_terminal_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	main.editor_board_tool = "pose"
	var unit_bp: Dictionary = main._editor_current_blueprint()
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.48, 0.5), _first_torso_index(main))
	var limb_a := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT, [0])
	var limb_b := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.UP)
	var terminal := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_b, "TIP", "muscle", _first_terminal_index(main), Vector2.UP)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var original_torso_pos: Vector2 = main._topology_node_position(nodes[torso])
	var original_a: Vector2 = main._topology_node_position(nodes[limb_a])
	var original_b: Vector2 = main._topology_node_position(nodes[limb_b])
	var original_tip: Vector2 = main._topology_node_position(nodes[terminal])
	var pivot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, limb_a, "root_joint")
	var start_local := main._topology_position_to_board_local(pivot + Vector2.RIGHT * 0.1)
	var end_local := main._topology_position_to_board_local(pivot + Vector2.UP * 0.1)
	if not main._start_editor_pose_drag(unit_bp, limb_a, start_local, [limb_a, limb_b, terminal]):
		_fail("Could not start pose drag for proximal limb.")
	main._update_editor_pose_drag(unit_bp, end_local)
	main._finish_editor_pose_drag(unit_bp)
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var rotated_nodes: Array = topology.get("nodes", [])
	var rotated_torso: Vector2 = main._topology_node_position(rotated_nodes[torso])
	if rotated_torso.distance_to(original_torso_pos) > 0.0001:
		_fail("Torso moved during pose subtree rotation.")
	var rotated_a: Vector2 = main._topology_node_position(rotated_nodes[limb_a])
	var rotated_b: Vector2 = main._topology_node_position(rotated_nodes[limb_b])
	var rotated_tip: Vector2 = main._topology_node_position(rotated_nodes[terminal])
	var expected_delta := -PI * 0.5
	var expected_a := pivot + (original_a - pivot).rotated(expected_delta)
	var expected_b := pivot + (original_b - pivot).rotated(expected_delta)
	var expected_tip := pivot + (original_tip - pivot).rotated(expected_delta)
	if rotated_a.distance_to(expected_a) > 0.002:
		_fail("Proximal limb did not rotate around its root pivot.")
	if rotated_b.distance_to(expected_b) > 0.002 or rotated_tip.distance_to(expected_tip) > 0.002:
		_fail("Downstream chain did not rigidly follow proximal pose rotation.")
	if absf(rotated_b.distance_to(rotated_a) - original_b.distance_to(original_a)) > 0.001:
		_fail("Internal limb distance changed during pose rotation.")
	if not unit_bp.has("entry_pose"):
		_fail("Pose edit did not store entry_pose on the unit blueprint.")
	print("EDITOR_POSE_SUBTREE_ROTATION_PROBE ok")
	quit()
