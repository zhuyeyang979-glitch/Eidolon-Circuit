extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _generic_gun_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "gun_activate":
			return i
	return -1


func _first_gun(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_gun_muscle(part, "muscle") and not main._part_is_catalog_frozen("muscle", part):
			return i
	return -1


func _axis_for_node(fighter, node_index: int, dynamic := true) -> Vector2:
	var segment: Dictionary = fighter.runtime_world_segment_for_node(node_index, dynamic)
	var axis: Vector2 = Vector2(segment.get("b", Vector2.ZERO)) - Vector2(segment.get("a", Vector2.ZERO))
	return axis.normalized() if axis.length() > 0.001 else Vector2.ZERO


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_index := _generic_gun_module(main)
	var gun_index := _first_gun(main)
	if module_index < 0 or gun_index < 0:
		_fail("Missing generic gun module or gun terminal.")
		return
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var gun_node := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "GUN", "muscle", gun_index, Vector2.UP)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "gun",
		"target_nodes": [gun_node],
		"target_torso_node": torso,
		"binding_valid_note": "OK",
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var bindings: Array = Array(stats.get("runtime_module_bindings", []))
	if bindings.is_empty():
		_fail("Runtime gun binding missing.")
		return
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Gun Return", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	if _axis_for_node(fighter, gun_node, false).dot(Vector2.RIGHT) < 0.98:
		_fail("Runtime gun entry pose should be normalized parallel to torso normal.")
	main.active_units[1]["hero"] = fighter
	main.all_units = [fighter]
	main._start_runtime_gun_activation(1, "p1", 0, "probe_fire", Dictionary(bindings[0]))
	if not main._runtime_gun_activation_active(1):
		_fail("Gun activation did not start.")
	var state: Dictionary = main.gun_activation_state[1]
	state["aim_direction"] = Vector2.UP
	main.gun_activation_state[1] = state
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	if event.is_empty():
		_fail("Gun activation event was empty.")
	if _axis_for_node(fighter, gun_node, true).dot(Vector2.UP) < 0.96:
		_fail("Gun did not align to aim direction before release.")
	main._release_runtime_gun_activation(1)
	if int(fighter.aim_pose_part_index) != -1:
		_fail("Gun aim pose should be cleared after release.")
	if _axis_for_node(fighter, gun_node, true).dot(Vector2.RIGHT) < 0.98:
		_fail("Gun should return parallel to torso normal after shooting/release.")
	print("GUN_ACTIVATION_RETURN_TO_TORSO_NORMAL_PROBE ok node=%d" % gun_node)
	quit()
