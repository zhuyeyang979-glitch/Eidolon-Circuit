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
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.0, 0.0), torso_index)
	var limb: int = main._append_directed_component_node("hero", unit, nodes, edges, torso, "A", "limb_muscle", limb_index, Vector2.RIGHT)
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	nodes = Array(Dictionary(unit.get("custom_topology", {})).get("nodes", []))
	edges = Array(Dictionary(unit.get("custom_topology", {})).get("edges", []))
	var target_pos: Vector2 = main._topology_socket_position_by_id("hero", unit, nodes, edges, torso, "torso_port:0", limb)
	var aligned := main._topology_position_for_socket_alignment("hero", unit, nodes, edges, limb, "root_joint", target_pos, target_pos)
	var aligned_pos: Vector2 = aligned.get("pos", main._topology_node_position(nodes[limb]))
	var test_nodes: Array = nodes.duplicate(true)
	var moved: Dictionary = Dictionary(test_nodes[limb]).duplicate(true)
	moved["pos"] = aligned_pos
	test_nodes[limb] = moved
	var visual_nodes: Array = main._board_nodes_with_art_visual_positions("hero", unit, test_nodes, edges)
	var gap := main._topology_max_socket_gap("hero", unit, visual_nodes, edges)
	var gap_px := gap / maxf(0.001, MainScene.TOPOLOGY_BOARD_PHYSICAL_UNITS) * main._topology_board_uniform_scale()
	if gap_px > 1.0:
		_fail("Placement alignment must use art anchors; gap=%.3fpx." % gap_px)
	print("PLACEMENT_USES_ART_ANCHORS_PROBE ok gap_px=%.3f" % gap_px)
	quit()
