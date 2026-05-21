extends SceneTree

const PartArt := preload("res://scripts/part_art.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() <= 0.000001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return point.distance_to(a + ab * t)


func _init() -> void:
	var length := 2.0
	var front_width := 0.72
	var rear_width := 1.56
	var points := PartArt.torso_saddle_local_points(length, front_width, rear_width)
	var edges := [
		[points[0], points[1]],
		[points[0], points[3]],
		[points[1], points[2]],
		[points[2], points[3]],
	]
	for count in range(1, 7):
		var offsets: Array = PartArt.torso_saddle_port_local_offsets(count, length, front_width, rear_width)
		if offsets.size() != count:
			_fail("Port count %d returned %d offsets." % [count, offsets.size()])
		for offset in offsets:
			var p: Vector2 = offset
			var best := 999.0
			for edge in edges:
				best = minf(best, _distance_to_segment(p, edge[0], edge[1]))
			if best > 0.002:
				_fail("Torso port for count %d is not on the saddle edge: %s distance %.4f" % [count, str(p), best])
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var torso_index := -1
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			torso_index = i
			break
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_index)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._refresh_editor_visual_views()
	var snapshot: Dictionary = main.assembly_board_view.board_snapshot
	var drawn_nodes: Array = snapshot.get("nodes", [])
	if drawn_nodes.is_empty():
		_fail("No drawn torso node in board snapshot.")
	var drawn: Dictionary = drawn_nodes[torso]
	var center: Vector2 = main.assembly_board_view._custom_node_pos(drawn)
	var radius: float = main.assembly_board_view._node_visual_radius(drawn)
	var edge_px: float = main.assembly_board_view._node_edge_extent_px(drawn, radius)
	var r := maxf(edge_px / 0.97, 8.0)
	var axis := Vector2(drawn.get("axis", Vector2.RIGHT))
	var screen_length := r * 1.94
	var screen_front := r * 0.72
	var screen_rear := r * 1.58
	var screen_points: PackedVector2Array = main.assembly_board_view._saddle_world_polygon(center, axis, screen_length, screen_front, screen_rear)
	var screen_edges := [
		[screen_points[0], screen_points[1]],
		[screen_points[0], screen_points[3]],
		[screen_points[1], screen_points[2]],
		[screen_points[2], screen_points[3]],
	]
	var markers: Array = snapshot.get("socket_markers", [])
	var checked := 0
	for marker in markers:
		if not (marker is Dictionary):
			continue
		if int(Dictionary(marker).get("node", -1)) != torso:
			continue
		var marker_pos: Vector2 = Dictionary(marker).get("pos", Vector2.ZERO)
		var screen_best := 9999.0
		for edge in screen_edges:
			screen_best = minf(screen_best, _distance_to_segment(marker_pos, edge[0], edge[1]))
		if screen_best > 1.75:
			_fail("Drawn torso socket is not on visual hull edge: %s distance %.3f" % [str(marker_pos), screen_best])
		checked += 1
	if checked <= 0:
		_fail("No torso socket markers found in board snapshot.")
	print("TORSO_EDGE_PORT_PROBE ok")
	quit()
