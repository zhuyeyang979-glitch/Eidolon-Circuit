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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var limb_index := _find(main, "limb_muscle", func(part: Dictionary) -> bool: return not main._component_is_torso(part))
	if torso_index < 0 or limb_index < 0:
		_fail("Missing torso or limb part for anchor probe.")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.0, 0.0), torso_index)
	var limb: int = main._append_directed_component_node("hero", unit, nodes, edges, torso, "A", "limb_muscle", limb_index, Vector2.RIGHT)
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	nodes = Array(Dictionary(unit.get("custom_topology", {})).get("nodes", []))
	edges = Array(Dictionary(unit.get("custom_topology", {})).get("edges", []))
	var visual_nodes: Array = main._board_nodes_with_art_visual_positions("hero", unit, nodes, edges)
	var gap := main._topology_max_socket_gap("hero", unit, visual_nodes, edges)
	var gap_px := gap / maxf(0.001, MainScene.TOPOLOGY_BOARD_PHYSICAL_UNITS) * main._topology_board_uniform_scale()
	if gap_px > 1.0:
		_fail("Board art anchors should visually meet within 1px; gap=%.3fpx." % gap_px)
	var edge_points: Dictionary = main._topology_edge_socket_board_points("hero", unit, visual_nodes, edges, torso, limb)
	var board_gap := Vector2(edge_points.get("a", Vector2.ZERO)).distance_to(Vector2(edge_points.get("b", Vector2.ZERO)))
	if board_gap > 1.0:
		_fail("Board edge endpoints should be visually zero-gap; board gap=%.3fpx." % board_gap)
	print("BOARD_ART_ANCHOR_ZERO_GAP_PROBE ok gap_px=%.3f board_gap=%.3f" % [gap_px, board_gap])
	quit()
