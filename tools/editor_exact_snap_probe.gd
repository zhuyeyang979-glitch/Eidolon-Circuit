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
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var torso_index := _first_torso_index(main)
	var terminal_index := _first_terminal_index(main)
	if torso_index < 0 or terminal_index < 0:
		_fail("Missing torso or terminal component.")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_index)
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LINK", "limb_muscle", 0, Vector2.RIGHT, [0])
	var terminal := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "TIP", "muscle", terminal_index, Vector2.RIGHT)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	if edges.size() != 2:
		_fail("Expected two direct socket edges, got %d." % edges.size())
	for edge in edges:
		var a := main._topology_edge_node_a(edge)
		var b := main._topology_edge_node_b(edge)
		var points: Dictionary = main._topology_edge_socket_board_points("hero", unit_bp, nodes, edges, a, b)
		var pa: Vector2 = points.get("a", Vector2.ZERO)
		var pb: Vector2 = points.get("b", Vector2.ZERO)
		if pa.distance_to(pb) > 0.75:
			_fail("Direct edge %d-%d sockets did not overlap: %.3f px." % [a, b, pa.distance_to(pb)])
	var terminal_sockets := main._topology_socket_ids_for_node("hero", nodes[terminal], unit_bp)
	if terminal_sockets != ["root_joint"]:
		_fail("Terminal weapon should expose only root_joint, got %s." % str(terminal_sockets))
	var limb_sockets := main._topology_socket_ids_for_node("hero", nodes[limb], unit_bp)
	if not (limb_sockets.has("root_joint") and limb_sockets.has("distal")):
		_fail("Connector muscle should expose root_joint and distal sockets, got %s." % str(limb_sockets))
	print("EDITOR_EXACT_SNAP_PROBE nodes=%d edges=%d" % [nodes.size(), edges.size()])
	quit()
