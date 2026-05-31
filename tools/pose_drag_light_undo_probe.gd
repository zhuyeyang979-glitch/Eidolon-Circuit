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
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.50), _first_torso(main))
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var before_pos: Vector2 = main._topology_node_position(nodes[limb])
	var before_entry: Dictionary = Dictionary(unit_bp.get("entry_pose", {})).duplicate(true)
	var before_full := int(main.editor_undo_full_snapshot_count)
	var pivot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, limb, "root_joint")
	var start_local := main._topology_position_to_board_local(pivot + Vector2.RIGHT * 0.12)
	var end_local := main._topology_position_to_board_local(pivot + Vector2.UP * 0.12)
	if not main._start_editor_pose_drag(unit_bp, limb, start_local, [limb]):
		_fail("Could not start pose drag.")
	main._update_editor_pose_drag(unit_bp, end_local)
	main._finish_editor_pose_drag(unit_bp)
	if int(main.editor_undo_full_snapshot_count) != before_full:
		_fail("Pose drag used full undo snapshot.")
	main._restore_editor_undo_state()
	var restored_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	if main._topology_node_position(restored_nodes[limb]).distance_to(before_pos) > 0.00001:
		_fail("Light pose undo did not restore limb position.")
	if Dictionary(unit_bp.get("entry_pose", {})) != before_entry:
		_fail("Light pose undo did not restore entry_pose.")
	print("POSE_DRAG_LIGHT_UNDO_PROBE ok full_undo_delta=0")
	quit(0)
