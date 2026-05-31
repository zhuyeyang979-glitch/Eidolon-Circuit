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


func _first_ranged_terminal_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle") and bool(part.get("projectile", false)):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var ranged_index := _first_ranged_terminal_index(main)
	if ranged_index < 0:
		_fail("No ranged terminal weapon found in hero catalog.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso_index(main))
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LINK", "limb_muscle", _first_limb_index(main), Vector2.RIGHT, [0])
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "GUN", "muscle", ranged_index, Vector2.RIGHT)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	if not bool(stats.get("teamedit_runtime_topology", false)):
		_fail("Ranged topology did not enter runtime topology.")
	if not Array(stats.get("attack_groups", [])).is_empty():
		_fail("Ranged topology generated legacy attack_groups.")
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Muzzle Consistency", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(4.0, 0.0)
	var muzzle: Vector2 = fighter.muzzle_position_for_part(0)
	var terminal_tip := Vector2.INF
	for raw_segment in fighter._runtime_topology_world_segments(false, true):
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment
		if String(segment.get("part_kind", "")) == "terminal":
			terminal_tip = segment.get("b", Vector2.INF)
	if terminal_tip == Vector2.INF:
		_fail("No terminal segment found in runtime topology.")
	if muzzle.distance_to(terminal_tip) > 0.002:
		_fail("Projectile muzzle does not match runtime terminal tip: %.4f." % muzzle.distance_to(terminal_tip))
	print("PROJECTILE_MUZZLE_CONSISTENCY_PROBE distance=%.4f" % muzzle.distance_to(terminal_tip))
	quit()
