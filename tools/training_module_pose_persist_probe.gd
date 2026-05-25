extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _find_part(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		var part: Dictionary = main._selected_component("hero", slot, i)
		if bool(predicate.call(part)):
			return i
	return -1


func _build_training_unit(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := _first_torso(main)
	var engine := _find_part(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 100.0)
	var booster := _find_part(main, "booster", func(part: Dictionary) -> bool: return main._thruster_drive_demand_for_part(part) > 0.0)
	if torso < 0 or engine < 0 or booster < 0:
		return {}
	var torso_node: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso)
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso_node, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [
		{"kind": "engine", "engine": engine, "torso_node": torso_node},
		{"kind": "booster", "booster": booster, "torso_node": torso_node},
		{"kind": "module", "module": module_index, "torso_node": torso_node},
	]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 2,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso_node,
		"binding_valid_note": "OK",
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
		return
	var role_key := "hero"
	var unit_bp := _build_training_unit(main, module_index)
	if unit_bp.is_empty():
		_fail("Could not build probe training unit.")
		return
	main.training_import_units = [{"role": role_key, "blueprint": unit_bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = unit_bp.duplicate(true)
	main.ai_battle_seat = 1
	main.training_seat_confirmed = true
	if not main._prepare_training_battle_loadouts():
		_fail("Probe training loadout was rejected: %s" % String(main.training_import_error_note))
		return
	if not main._configure_training_sides_for_seat():
		_fail("Probe training sides could not be configured: %s" % String(main.training_import_error_note))
		return
	main._begin_battle(MainScene.MODE_TRAINING, true)
	var hero = Dictionary(main.active_units.get(1, {})).get("hero", null)
	if hero == null:
		_fail("Unit 2 did not spawn a controllable training hero.")
		return
	var bindings: Array = Array(hero.stats.get("runtime_module_bindings", []))
	if bindings.is_empty():
		_fail("Unit 2 has no runtime module bindings.")
		return
	var binding: Dictionary = Dictionary(bindings[0])
	var first_node := int(Array(binding.get("target_nodes", []))[0])
	var before: Dictionary = hero._runtime_segment_source_by_node(first_node)
	var before_b: Vector2 = hero._runtime_local_vector(before.get("b_local", Vector2.ZERO))
	var event: Dictionary = hero.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Training module action did not start: %s" % String(hero.get_meta("last_module_gate_reason", "")))
		return
	hero._tick_runtime_module_actions(10.0)
	var after: Dictionary = hero._runtime_segment_source_by_node(first_node)
	var after_b: Vector2 = hero._runtime_local_vector(after.get("b_local", Vector2.ZERO))
	if after_b.distance_to(before_b) > 0.01:
		_fail("Training module action did not restore its entry default pose.")
		return
	print("TRAINING_MODULE_POSE_PERSIST_PROBE generated_unit=true")
	quit()
