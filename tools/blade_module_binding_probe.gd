extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part_index_by_name(main, slot_key: String, name_fragment: String) -> int:
	for i in range(main._catalog_for("hero", slot_key).size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		if String(part.get("name", "")).findn(name_fragment) >= 0:
			return i
	return -1


func _module_index_by_profile(main, profile: String) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == profile:
			return i
	return -1


func _first_torso_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			return i
	return 0


func _build_unit(main, terminal_index: int, module_index: int, target_nodes: Array) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _part_index_by_name(main, "muscle", "COINRUN SKATE")
	if torso_part < 0:
		torso_part = _first_torso_index(main)
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_part)
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ARM", "limb_muscle", _part_index_by_name(main, "limb_muscle", "FOREARM"), Vector2.RIGHT)
	var terminal: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "BLADE", "muscle", terminal_index, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": target_nodes if not target_nodes.is_empty() else [terminal],
		"target_torso_node": torso,
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _invalid_reason(main, unit_bp: Dictionary) -> String:
	var payload: Dictionary = unit_bp["slot_payloads"][0]
	var module_index := int(payload["module"])
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	var binding: Dictionary = unit_bp["module_bindings"][0]
	return main._module_binding_invalid_reason(unit_bp, 0, payload, module_part, binding)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var katana_idx := _part_index_by_name(main, "muscle", "KATANA")
	var scythe_idx := _part_index_by_name(main, "muscle", "SCYTHE")
	var katana_module := _module_index_by_profile(main, "katana_quickdraw")
	var triple_module := _module_index_by_profile(main, "triple_limb_cross_cut")
	if min(katana_idx, scythe_idx, katana_module, triple_module) < 0:
		_fail("Missing blade parts or modules for binding probe.")
	var valid_unit := _build_unit(main, katana_idx, katana_module, [])
	var reason := _invalid_reason(main, valid_unit)
	if reason != "":
		_fail("Katana module should bind katana terminal, got: %s" % reason)
	var invalid_unit := _build_unit(main, scythe_idx, katana_module, [])
	reason = _invalid_reason(main, invalid_unit)
	if reason.findn("katana") < 0:
		_fail("Katana module should reject scythe terminal, got: %s" % reason)
	var triple_invalid := _build_unit(main, katana_idx, triple_module, [2])
	reason = _invalid_reason(main, triple_invalid)
	if reason.find("at least") < 0:
		_fail("Triple module should require at least three bound segments, got: %s" % reason)
	print("BLADE_MODULE_BINDING_PROBE ok")
	quit()
