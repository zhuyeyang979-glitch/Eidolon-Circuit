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
	var source_nodes: Array = Array(Dictionary(unit.get("custom_topology", {})).get("nodes", []))
	var source_edges: Array = Array(Dictionary(unit.get("custom_topology", {})).get("edges", []))
	var original_limb_pos: Vector2 = main._topology_node_position(source_nodes[limb])
	var visual_nodes: Array = main._board_nodes_with_art_visual_positions("hero", unit, source_nodes, source_edges)
	var visual_limb_pos: Vector2 = Dictionary(visual_nodes[limb]).get("visual_pos", original_limb_pos)
	var source_limb_pos_after: Vector2 = main._topology_node_position(source_nodes[limb])
	if source_limb_pos_after.distance_to(original_limb_pos) > 0.0001:
		_fail("Art-aware visual layout must not mutate saved topology positions.")
	if visual_limb_pos.distance_to(original_limb_pos) < 0.0001:
		_fail("Expected display visual_pos to differ from raw topology pos after art-anchor layout.")
	print("BOARD_VISUAL_POS_ART_SCALE_PROBE ok raw=%s visual=%s" % [str(original_limb_pos), str(visual_limb_pos)])
	quit()
