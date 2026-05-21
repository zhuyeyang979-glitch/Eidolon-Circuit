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
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso(main)
	if torso_part < 0:
		_fail("No torso part was found.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ROOT", "limb_muscle", 0, Vector2.RIGHT, [0])
	var torso_pos: Vector2 = main._topology_node_position(nodes[torso])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._snap_all_topology_edges("hero", unit_bp)
	var snapped_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	if main._topology_node_position(snapped_nodes[torso]).distance_to(torso_pos) > 0.00001:
		_fail("snap_all moved the torso root.")
	var desired_torso := torso_pos + Vector2(0.2, 0.15)
	var snap_result: Vector2 = main._snap_position_to_fixed_connection("hero", unit_bp, snapped_nodes, edges, torso, desired_torso)
	if snap_result.distance_to(torso_pos) > 0.00001:
		_fail("Connected torso snap returned a moved position.")
	var limb_before_group_drag: Vector2 = main._topology_node_position(snapped_nodes[limb])
	main.editor_group_drag_original_positions = [
		{"index": torso, "pos": main._topology_node_position(snapped_nodes[torso])},
		{"index": limb, "pos": limb_before_group_drag},
	]
	unit_bp["custom_topology"] = {"nodes": snapped_nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._move_selected_topology_nodes_by_delta(unit_bp, Vector2(80.0, 20.0))
	var moved_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var torso_delta: Vector2 = main._topology_node_position(moved_nodes[torso]) - torso_pos
	var limb_delta: Vector2 = main._topology_node_position(moved_nodes[limb]) - limb_before_group_drag
	if torso_delta.length() <= 0.00001:
		_fail("Rigid group drag should move the torso when the torso is part of the selected connected island.")
	if torso_delta.distance_to(limb_delta) > 0.00001:
		_fail("Rigid group drag moved torso and limb by different deltas.")
	print("TORSO_IMMUTABLE_SNAP_PROBE ok child-snap-stable rigid-drag-delta=%s" % str(torso_delta))
	quit()
