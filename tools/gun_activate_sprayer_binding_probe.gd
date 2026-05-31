extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _module_index(main) -> int:
	var catalog: Array = main._catalog_for("hero", "module")
	for i in range(catalog.size()):
		if String(Dictionary(catalog[i]).get("module_action_profile", "")) == "gun_activate":
			return i
	return -1


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _standard_sprayer(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("name", "")) == MainScene.STANDARD_CHEMICAL_SPRAYER_NAME:
			return i
	return -1


func _build_sprayer_unit(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ARM", "limb_muscle", 0, Vector2.RIGHT)
	var gun: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "SPRAYER", "muscle", _standard_sprayer(main), Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "software_slot_index": 0}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	unit_bp["_probe_gun_node"] = gun
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_index := _module_index(main)
	var sprayer_index := _standard_sprayer(main)
	if module_index < 0:
		_fail("Gun Activate module missing.")
	if sprayer_index < 0:
		_fail("Standard chemical sprayer missing.")
	if failed:
		quit(1)
		return
	var module_part := main._selected_component("hero", "module", module_index)
	var unit_bp := _build_sprayer_unit(main, module_index)
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"
	main._start_editor_module_binding_flow(0, module_part)
	var gun_node := int(unit_bp.get("_probe_gun_node", -1))
	main._complete_pending_module_binding_with_selection(unit_bp, [gun_node])
	if not bool(main.editor_pending_module_binding.get("target_selected", false)):
		_fail("Gun Activate should accept the standard chemical sprayer.")
	main._set_pending_module_attack_key(3)
	var bindings: Array = Array(unit_bp.get("module_bindings", []))
	if bindings.size() != 1:
		_fail("Sprayer Gun Activate binding should save exactly one binding.")
	else:
		var binding: Dictionary = bindings[0]
		if int(binding.get("attack_key", 0)) != 3:
			_fail("Sprayer binding did not save the selected attack key.")
		if Array(binding.get("target_nodes", [])) != [gun_node]:
			_fail("Sprayer binding should target the selected sprayer node.")
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var runtime_bindings: Array = Array(stats.get("runtime_module_bindings", []))
	if runtime_bindings.is_empty() or String(Dictionary(runtime_bindings[0]).get("module_action_profile", "")) != "gun_activate":
		_fail("Runtime stats should expose the sprayer Gun Activate binding.")
	if failed:
		quit(1)
		return
	print("GUN_ACTIVATE_SPRAYER_BINDING_PROBE ok")
	quit()
