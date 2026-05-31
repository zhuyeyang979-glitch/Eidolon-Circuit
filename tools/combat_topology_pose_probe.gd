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
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso_index(main))
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LINK", "limb_muscle", 0, Vector2.RIGHT, [0])
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "TIP", "muscle", _first_terminal_index(main), Vector2.RIGHT)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	if not bool(stats.get("teamedit_runtime_topology", false)):
		_fail("TeamEdit blueprint did not produce runtime topology.")
	if not Array(stats.get("attack_groups", [])).is_empty():
		_fail("TeamEdit runtime still generated legacy attack_groups.")
	var blueprint_segments: Array = stats.get("runtime_topology_segments", [])
	if blueprint_segments.size() != nodes.size():
		_fail("Runtime segment count should match topology nodes: %d vs %d." % [blueprint_segments.size(), nodes.size()])
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Combat Topology Pose", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(3.0, 0.0)
	var world_segments: Array = fighter._runtime_topology_world_segments(true, false)
	if world_segments.size() != blueprint_segments.size():
		_fail("Combat world segment count differs from saved blueprint: %d vs %d." % [world_segments.size(), blueprint_segments.size()])
	for i in range(blueprint_segments.size()):
		var source: Dictionary = blueprint_segments[i]
		var world: Dictionary = world_segments[i]
		for key in ["node_index", "part_kind", "slot"]:
			if str(source.get(key, "")) != str(world.get(key, "")):
				_fail("Runtime segment %d changed %s: %s vs %s." % [i, key, str(world.get(key, "")), str(source.get(key, ""))])
		var local_len := Vector2(source.get("a_local", Vector2.ZERO)).distance_to(Vector2(source.get("b_local", Vector2.ZERO)))
		var world_len := Vector2(world.get("a", Vector2.ZERO)).distance_to(Vector2(world.get("b", Vector2.ZERO)))
		if absf(local_len - world_len) > 0.01:
			_fail("Runtime segment %d length changed: %.4f vs %.4f." % [i, world_len, local_len])
	print("COMBAT_TOPOLOGY_POSE_PROBE runtime_segments=%d attack_groups=0" % world_segments.size())
	quit()
