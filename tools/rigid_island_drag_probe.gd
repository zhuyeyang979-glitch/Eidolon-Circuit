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
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso(main)
	var terminal_part := _first_terminal(main)
	if torso_part < 0 or terminal_part < 0:
		_fail("Missing torso or terminal catalog part.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LIMB", "limb_muscle", 0, Vector2.RIGHT, [0])
	var terminal := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "TIP", "muscle", terminal_part, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var before_torso: Vector2 = main._topology_node_position(nodes[torso])
	var before_limb: Vector2 = main._topology_node_position(nodes[limb])
	var before_terminal: Vector2 = main._topology_node_position(nodes[terminal])
	main._start_topology_group_drag(unit_bp, Vector2.ZERO, [torso], true)
	main._move_selected_topology_nodes_by_delta(unit_bp, Vector2(80.0, 20.0))
	var moved_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var delta_torso: Vector2 = main._topology_node_position(moved_nodes[torso]) - before_torso
	var delta_limb: Vector2 = main._topology_node_position(moved_nodes[limb]) - before_limb
	var delta_terminal: Vector2 = main._topology_node_position(moved_nodes[terminal]) - before_terminal
	if delta_torso.length() <= 0.00001:
		_fail("Dragging a connected limb did not move the torso in the same rigid island.")
	if delta_torso.distance_to(delta_limb) > 0.00001 or delta_torso.distance_to(delta_terminal) > 0.00001:
		_fail("Connected island nodes did not move by the same delta.")
	var gap := main._topology_max_socket_gap("hero", unit_bp, moved_nodes, edges)
	if gap > 0.00001:
		_fail("Rigid island drag created socket gap %.6f." % gap)
	print("RIGID_ISLAND_DRAG_PROBE ok delta=%s gap=%.6f" % [str(delta_torso), gap])
	quit()
