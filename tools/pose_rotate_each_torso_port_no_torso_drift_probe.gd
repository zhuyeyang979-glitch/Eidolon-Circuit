extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_with_ports(main, min_ports: int) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part) and main._torso_external_joint_ports(part) >= min_ports:
			return i
	return -1


func _first_limb(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if int(part.get("connection_ends", 2)) >= 2:
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
	var torso_part := _first_torso_with_ports(main, 4)
	var limb_part := _first_limb(main)
	if torso_part < 0 or limb_part < 0:
		_fail("Missing a 4-port torso or connector limb.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	var limbs: Array = []
	for dir in [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]:
		var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "L%d" % limbs.size(), "limb_muscle", limb_part, dir)
		limbs.append(limb)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	nodes = topology.get("nodes", [])
	edges = topology.get("edges", [])
	var torso_pos: Vector2 = main._topology_node_position(nodes[torso])
	var torso_axis := main._topology_endpoint_axis_for_node(torso, nodes, edges)
	if torso_axis.distance_to(Vector2.RIGHT) > 0.0001:
		_fail("Torso axis should not be inferred from attached limbs before pose drag.")
	for raw_limb in limbs:
		var limb_index := int(raw_limb)
		var before_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
		var before_torso_pos: Vector2 = main._topology_node_position(before_nodes[torso])
		var before_torso_axis := main._topology_endpoint_axis_for_node(torso, before_nodes, edges)
		var pivot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, before_nodes, edges, limb_index, "root_joint")
		var start_local := main._topology_position_to_board_local(pivot + Vector2.RIGHT * 0.08)
		var end_local := main._topology_position_to_board_local(pivot + Vector2.DOWN * 0.08)
		if not main._start_editor_pose_drag(unit_bp, limb_index, start_local, [limb_index]):
			_fail("Could not start pose drag for limb %d." % limb_index)
		main._update_editor_pose_drag(unit_bp, end_local)
		main._finish_editor_pose_drag(unit_bp)
		var moved_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
		var moved_edges: Array = Dictionary(unit_bp.get("custom_topology", {})).get("edges", [])
		if main._topology_node_position(moved_nodes[torso]).distance_to(before_torso_pos) > 0.00001:
			_fail("Pose drag of limb %d moved the torso." % limb_index)
		var moved_axis := main._topology_endpoint_axis_for_node(torso, moved_nodes, moved_edges)
		if moved_axis.distance_to(before_torso_axis) > 0.00001:
			_fail("Pose drag of limb %d rotated the torso axis." % limb_index)
		var gap := main._topology_max_socket_gap("hero", unit_bp, moved_nodes, moved_edges)
		if gap > 0.00001:
			_fail("Pose drag of limb %d created socket gap %.6f." % [limb_index, gap])
	if main._topology_node_position(Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])[torso]).distance_to(torso_pos) > 0.00001:
		_fail("Torso drifted after rotating multiple ports.")
	print("POSE_ROTATE_EACH_TORSO_PORT_NO_TORSO_DRIFT_PROBE ok")
	quit()
