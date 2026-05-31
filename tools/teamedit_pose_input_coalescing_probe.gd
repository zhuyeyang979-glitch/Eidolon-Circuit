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
	var pivot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, limb, "root_joint")
	var start_local := main._topology_position_to_board_local(pivot + Vector2.RIGHT * 0.12)
	if not main._start_editor_pose_drag(unit_bp, limb, start_local, [limb]):
		_fail("Could not start pose drag.")
	for i in range(10):
		var angle := 0.2 + float(i) * 0.05
		main._update_editor_pose_drag(unit_bp, main._topology_position_to_board_local(pivot + Vector2(cos(angle), sin(angle)) * 0.14))
	if int(main.editor_pose_drag_apply_count) != 0:
		_fail("Pose update applied immediately instead of coalescing.")
	main._tick_editor_visuals(1.0 / 60.0)
	if int(main.editor_pose_drag_apply_count) != 1:
		_fail("Expected exactly one coalesced pose apply, got %d." % int(main.editor_pose_drag_apply_count))
	if int(main.editor_pose_drag_coalesced_count) < 10:
		_fail("Expected motion events to be recorded as coalesced.")
	print("TEAMEDIT_POSE_INPUT_COALESCING_PROBE ok updates=%d apply=%d" % [
		int(main.editor_pose_drag_coalesced_count),
		int(main.editor_pose_drag_apply_count),
	])
	quit(0)
