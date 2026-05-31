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
	main._topology_update_local_pose_fields("hero", unit_bp)
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	nodes = topology.get("nodes", [])
	var a_local := float(Dictionary(nodes[limb_a]).get("local_angle", 999.0))
	var b_local := float(Dictionary(nodes[limb_b]).get("local_angle", 999.0))
	var tip_local := float(Dictionary(nodes[terminal]).get("local_angle", 999.0))
	var pivot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, limb_a, "root_joint")
	var start_local := main._topology_position_to_board_local(pivot + Vector2.RIGHT * 0.1)
	var end_local := main._topology_position_to_board_local(pivot + Vector2.UP * 0.1)
	if not main._start_editor_pose_drag(unit_bp, limb_a, start_local, [limb_a, limb_b, terminal]):
		_fail("Could not start local FK pose drag.")
	main._update_editor_pose_drag(unit_bp, end_local)
	main._finish_editor_pose_drag(unit_bp)
	topology = unit_bp.get("custom_topology", {})
	nodes = topology.get("nodes", [])
	var a_after := float(Dictionary(nodes[limb_a]).get("local_angle", 999.0))
	var b_after := float(Dictionary(nodes[limb_b]).get("local_angle", 999.0))
	var tip_after := float(Dictionary(nodes[terminal]).get("local_angle", 999.0))
	if absf(wrapf(a_after - a_local, -PI, PI)) < 0.5:
		_fail("Root limb local angle did not change during pose edit.")
	if absf(wrapf(b_after - b_local, -PI, PI)) > 0.001:
		_fail("Downstream limb local angle changed; rigid follow should preserve it.")
	if absf(wrapf(tip_after - tip_local, -PI, PI)) > 0.001:
		_fail("Terminal local angle changed; rigid follow should preserve it.")
	print("ENTRY_POSE_LOCAL_FK_PROBE ok")
	quit()
