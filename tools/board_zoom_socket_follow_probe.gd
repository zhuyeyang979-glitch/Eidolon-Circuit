extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		if bool(predicate.call(main._selected_component("hero", slot, i))):
			return i
	return -1


func _marker_by_key(markers: Array, node_index: int, socket_id: String) -> Dictionary:
	for raw_marker in markers:
		if not (raw_marker is Dictionary):
			continue
		var marker: Dictionary = raw_marker
		if int(marker.get("node", -1)) == node_index and String(marker.get("id", "")) == socket_id:
			return marker
	return {}


func _first_component_marker(markers: Array) -> Dictionary:
	for raw_marker in markers:
		if raw_marker is Dictionary and int(Dictionary(raw_marker).get("node", -1)) >= 0:
			return raw_marker
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var role_key: String = MainScene.ROLE_ORDER[main.editor_role_index]
	var unit: Dictionary = main._editor_current_blueprint()
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var limb_index := _find(main, "limb_muscle", func(part: Dictionary) -> bool: return not main._component_is_torso(part))
	if torso_index < 0 or limb_index < 0:
		_fail("Missing torso or limb part for zoom socket probe.")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.43), torso_index)
	var limb := main._append_directed_component_node(role_key, unit, nodes, edges, torso, "A", "limb_muscle", limb_index, Vector2.RIGHT)
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields(role_key, unit)
	main._refresh_editor_visual_views({}, false)
	var markers_1x: Array = main.assembly_board_view.board_snapshot.get("socket_markers", [])
	var first_marker := _first_component_marker(markers_1x)
	if first_marker.is_empty():
		_fail("Expected socket markers before zoom.")
	var marker_node := int(first_marker.get("node", -1))
	var marker_id := String(first_marker.get("id", ""))
	var marker_pos_1x: Vector2 = first_marker.get("pos", Vector2.ZERO)
	main._set_editor_board_zoom(1.8, Vector2(main.assembly_board_view.size.x * 0.5, main.assembly_board_view.size.y * 0.5))
	var snapshot: Dictionary = main.assembly_board_view.board_snapshot
	var markers_zoomed: Array = snapshot.get("socket_markers", [])
	var zoomed_marker := _marker_by_key(markers_zoomed, marker_node, marker_id)
	if zoomed_marker.is_empty():
		_fail("Zoomed board lost marker %d:%s." % [marker_node, marker_id])
	var zoomed_pos: Vector2 = zoomed_marker.get("pos", Vector2.ZERO)
	if zoomed_pos.distance_to(marker_pos_1x) < 1.0:
		_fail("Socket marker did not follow board zoom; delta=%.3fpx." % zoomed_pos.distance_to(marker_pos_1x))
	var topology: Dictionary = unit.get("custom_topology", {})
	var visual_nodes: Array = snapshot.get("nodes", [])
	var source_edges: Array = topology.get("edges", [])
	var expected_markers := main._topology_socket_markers_for_board(role_key, unit, visual_nodes, source_edges)
	var expected_marker := _marker_by_key(expected_markers, marker_node, marker_id)
	if expected_marker.is_empty():
		_fail("Expected dynamic marker missing for %d:%s." % [marker_node, marker_id])
	var expected_pos: Vector2 = expected_marker.get("pos", Vector2.ZERO)
	if zoomed_pos.distance_to(expected_pos) > 0.5:
		_fail("Zoomed socket marker is stale: actual=%s expected=%s delta=%.3fpx." % [str(zoomed_pos), str(expected_pos), zoomed_pos.distance_to(expected_pos)])
	print("BOARD_ZOOM_SOCKET_FOLLOW_PROBE ok marker=%d:%s delta=%.3fpx" % [marker_node, marker_id, zoomed_pos.distance_to(marker_pos_1x)])
	quit()
