extends SceneTree

const MainScene := preload("res://scripts/main.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			return i
	return 0


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var board_point := Vector2(690.0, 390.0)
	var topo_point: Vector2 = main._board_position_to_topology(board_point)
	var roundtrip: Vector2 = main._topology_position_to_board(topo_point)
	if roundtrip.distance_to(board_point) > 2.0:
		_fail("Canvas roundtrip drifted %.2f px, input and display mapping are not unified." % roundtrip.distance_to(board_point))
	main._set_pending_canvas_part(unit_bp, "muscle", _first_torso(main))
	var torso_index: int = main._add_topology_node_at(Vector2(310.0, 250.0))
	if torso_index != 0:
		_fail("Expected first placed torso to be index 0, got %d." % torso_index)
	main._set_pending_canvas_part(unit_bp, "limb_muscle", 0)
	var muscle_index: int = main._add_topology_node_at(Vector2(362.0, 250.0))
	if muscle_index != 1:
		_fail("Expected second placed node to be index 1, got %d." % muscle_index)
	if not main._try_magnetic_link_for_node(unit_bp, muscle_index):
		_fail("Magnetic link did not snap nearby joint/muscle nodes.")
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	if edges.size() != 1:
		_fail("Expected exactly one magnetic edge, got %d." % edges.size())
	var edge = edges[0]
	var a := main._topology_edge_node_a(edge)
	var b := main._topology_edge_node_b(edge)
	if not main._topology_edge_can_connect(nodes[a], nodes[b]):
		_fail("Magnetic edge violated hard direct muscle rule.")
	var edge_points: Dictionary = main._topology_edge_socket_board_points("hero", unit_bp, nodes, edges, a, b)
	var socket_a: Vector2 = edge_points.get("a", Vector2.ZERO)
	var socket_b: Vector2 = edge_points.get("b", Vector2.ZERO)
	var socket_gap_units := socket_a.distance_to(socket_b) / maxf(1.0, main._topology_board_uniform_scale()) * MainScene.TOPOLOGY_BOARD_PHYSICAL_UNITS
	if socket_gap_units > MainScene.TOPOLOGY_EDGE_TOLERANCE:
		_fail("Magnetic edge sockets are not overlapping: gap %.4f." % socket_gap_units)
	var muscle_node: Dictionary = nodes[muscle_index]
	var muscle_part: Dictionary = main._topology_node_part("hero", muscle_node, unit_bp)
	var rotation_radius := main._topology_joint_max_rotation_radius_units("hero", unit_bp, nodes, edges, muscle_index)
	var expected_rotation_radius := float(muscle_part.get("length", 0.0))
	if absf(rotation_radius - expected_rotation_radius) > 0.001:
		_fail("Embedded joint preview radius should include full downstream muscle length: got %.4f expected %.4f." % [rotation_radius, expected_rotation_radius])
	print("EDITOR_CANVAS_PROBE roundtrip=%.2f nodes=%d edges=%d fixed=%.3f" % [
		roundtrip.distance_to(board_point),
		nodes.size(),
		edges.size(),
		socket_gap_units,
	])
	quit()
