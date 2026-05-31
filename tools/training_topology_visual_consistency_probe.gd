extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_limb_index(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		return i
	return 0


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
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.44, 0.52), _first_torso_index(main))
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LINK", "limb_muscle", _first_limb_index(main), Vector2.RIGHT, [0])
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "TIP", "muscle", _first_terminal_index(main), Vector2.RIGHT)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var blueprint_segments: Array = stats.get("runtime_topology_segments", [])
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Visual Consistency", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(5.0, -0.25)
	var fighter_segments: Array = fighter._runtime_topology_world_segments(true, false)
	if fighter_segments.size() != blueprint_segments.size():
		_fail("Training/battle segment count differs from TeamEdit blueprint: %d vs %d." % [fighter_segments.size(), blueprint_segments.size()])
	for i in range(blueprint_segments.size()):
		var bp: Dictionary = blueprint_segments[i]
		var fs: Dictionary = fighter_segments[i]
		var local_a = bp.get("a_local", Vector2.ZERO)
		var local_b = bp.get("b_local", Vector2.ZERO)
		if not (local_a is Vector2):
			local_a = Vector2.ZERO
		if not (local_b is Vector2):
			local_b = Vector2.ZERO
		var expected_length: float = Vector2(local_a).distance_to(Vector2(local_b))
		var actual_length: float = Vector2(fs.get("a", Vector2.ZERO)).distance_to(Vector2(fs.get("b", Vector2.ZERO)))
		if absf(expected_length - actual_length) > 0.001:
			_fail("Segment %d length changed between TeamEdit and runtime: %.4f vs %.4f." % [i, expected_length, actual_length])
	print("TRAINING_TOPOLOGY_VISUAL_CONSISTENCY_PROBE segments=%d" % fighter_segments.size())
	quit()
