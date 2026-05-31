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
	if torso_part < 0:
		_fail("No torso catalog part.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LIMB", "limb_muscle", 0, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var torso_pos: Vector2 = main._topology_node_position(nodes[torso])
	var torso_axis: Vector2 = main._topology_node_axis(nodes[torso])
	var pivot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, limb, "root_joint")
	var start_local := main._topology_position_to_board_local(pivot + Vector2.RIGHT * 0.1)
	var end_local := main._topology_position_to_board_local(pivot + Vector2.UP * 0.1)
	if not main._start_editor_pose_drag(unit_bp, limb, start_local, [limb]):
		_fail("Could not start pose drag for limb.")
	main._update_editor_pose_drag(unit_bp, end_local)
	main._finish_editor_pose_drag(unit_bp)
	var moved_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	if main._topology_node_position(moved_nodes[torso]).distance_to(torso_pos) > 0.00001:
		_fail("Pose drag moved the torso position.")
	if main._topology_node_axis(moved_nodes[torso]).distance_to(torso_axis) > 0.00001:
		_fail("Pose drag rotated the torso axis.")
	print("POSE_MODE_KEEPS_TORSO_ANCHOR_PROBE ok")
	quit()
