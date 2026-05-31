extends SceneTree

const MainScene := preload("res://scripts/main.gd")


var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_limb(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if not bool(part.get("is_torso", false)):
			return i
	return 0


func _first_gauntlet(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("name", "")) == MainScene.STANDARD_GAUNTLET_NAME:
			return i
	return -1


func _first_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == "blunt_gauntlet_extend_swing":
			return i
	return -1


func _first_invalid_terminal(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._part_counts_as_terminal_weapon(part, "muscle") and String(part.get("name", "")) != MainScene.STANDARD_GAUNTLET_NAME:
			return i
	return -1


func _build_unit(main, terminal_index: int, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ARM", "limb_muscle", _first_limb(main), Vector2.RIGHT)
	var terminal: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "TIP", "muscle", terminal_index, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "gauntlet_terminal",
		"target_nodes": [terminal],
		"target_torso_node": torso,
		"binding_valid_note": "OK",
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _first_module(main)
	var gauntlet_index := _first_gauntlet(main)
	if module_index < 0:
		_fail("Gauntlet Extend-Swing module missing.")
	if gauntlet_index < 0:
		_fail("Standard Momentum Gauntlet missing.")
	if failed:
		quit(1)
		return
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	if not String(module_part.get("name", "")).contains("GAUNTLET EXTEND-SWING"):
		_fail("HAMMER ANCHOR slot was not converted to Gauntlet Extend-Swing.")
	if String(module_part.get("module_target_kind", "")) != "blunt_hybrid_gauntlet":
		_fail("Gauntlet module target kind is wrong.")
	var legal := _build_unit(main, gauntlet_index, module_index)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, legal)
	var bindings: Array = stats.get("runtime_module_bindings", [])
	if bindings.size() != 1:
		_fail("Legal gauntlet unit did not generate one runtime binding.")
	elif not bool(Dictionary(bindings[0]).get("runtime_valid", false)):
		_fail("Legal gauntlet runtime binding invalid: %s" % String(Dictionary(bindings[0]).get("binding_valid_note", "")))
	var invalid_terminal := _first_invalid_terminal(main)
	if invalid_terminal >= 0:
		var invalid_unit := _build_unit(main, invalid_terminal, module_index)
		var invalid_stats: Dictionary = main._compute_unit_stats(1, "hero", -1, invalid_unit)
		var invalid_bindings: Array = invalid_stats.get("runtime_module_bindings", [])
		if invalid_bindings.is_empty() or bool(Dictionary(invalid_bindings[0]).get("runtime_valid", true)):
			_fail("Non-gauntlet terminal should not bind Gauntlet Extend-Swing.")
	if failed:
		quit(1)
		return
	print("GAUNTLET_MODULE_BINDING_PROBE ok module=%d gauntlet=%d" % [module_index, gauntlet_index])
	quit()
