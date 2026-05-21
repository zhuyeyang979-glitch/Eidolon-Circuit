extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


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


func _build_unit(main) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso_index(main)
	var limb_part := _part_index_by_name(main, "limb_muscle", "RAZOR FLEX")
	var katana_part := _part_index_by_name(main, "muscle", "KATANA")
	var module_index := _module_index_by_profile(main, "blade_arc_return")
	if min(limb_part, katana_part, module_index) < 0:
		_fail("Missing blade runtime test parts.")
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_part)
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ARM", "limb_muscle", limb_part, Vector2.RIGHT)
	var terminal: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "KATANA", "muscle", katana_part, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": [limb, terminal],
		"target_torso_node": torso,
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp := _build_unit(main)
	var runtime_segments: Array = main._runtime_topology_segments_for_blueprint("hero", unit_bp)
	var runtime_bindings: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	if runtime_segments.size() < 3:
		_fail("Runtime topology did not include blade limb segments.")
	if runtime_bindings.is_empty() or not bool(Dictionary(runtime_bindings[0]).get("runtime_valid", false)):
		_fail("Blade runtime binding is not valid.")
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"unit_name": "Blade Probe",
		"stats": {
			"health": 120.0,
			"mass": 80.0,
			"runtime_topology_segments": runtime_segments,
			"runtime_module_bindings": runtime_bindings,
			"teamedit_runtime_topology": true,
		},
	})
	fighter.deploy(0.0, 0.0)
	var binding: Dictionary = Dictionary(runtime_bindings[0]).duplicate(true)
	binding["runtime_command_variant"] = "armor_forward_cut"
	var event: Dictionary = fighter.begin_runtime_module_action("armor", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Blade runtime action did not start: %s" % String(fighter.get_meta("last_module_gate_reason", "")))
	if fighter.runtime_module_actions.is_empty():
		_fail("Blade runtime action was not registered.")
	var overrides: Dictionary = fighter._runtime_module_segment_overrides(1.0, 1.0)
	if overrides.is_empty():
		_fail("Blade runtime action produced no segment overrides.")
	fighter._tick_runtime_module_actions(float(fighter.runtime_module_actions[0].get("duration", 0.4)) + 0.01)
	if not fighter.runtime_module_actions.is_empty():
		_fail("Blade runtime action did not complete.")
	print("BLADE_RUNTIME_ACTION_PROBE ok")
	quit()
