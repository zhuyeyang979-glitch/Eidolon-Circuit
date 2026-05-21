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
		_fail("No torso catalog part.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.86, 0.5), torso_part)
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LIMB", "limb_muscle", 0, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._start_topology_group_drag(unit_bp, Vector2.ZERO, [torso], true)
	main._move_selected_topology_nodes_by_delta(unit_bp, Vector2(5000.0, 0.0))
	var moved_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var gap := main._topology_max_socket_gap("hero", unit_bp, moved_nodes, edges)
	if gap > 0.00001:
		_fail("Boundary-clamped rigid drag left socket gap %.6f." % gap)
	if main._topology_node_position(moved_nodes[torso]).x > 1.00001 or main._topology_node_position(moved_nodes[limb]).x > 1.00001:
		_fail("Rigid island drag moved nodes outside the topology board.")
	print("SOCKET_ZERO_GAP_AFTER_DRAG_PROBE ok gap=%.6f" % gap)
	quit()
