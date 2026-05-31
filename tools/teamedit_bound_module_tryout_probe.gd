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


func _build_bound_unit(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	var by_node := {}
	by_node[str(limb_a)] = 12.0
	by_node[str(limb_b)] = 12.0
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
		"joint_drive_allocation_by_node": by_node,
		"joint_drive_allocation_total": 24.0,
		"joint_drive_demand": 24.0,
		"joint_output_momentum": 24.0,
		"command_window_profile": String(module_part.get("command_window_profile", "")),
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
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
	var unit_bp := _build_bound_unit(main, module_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	if not main._tryout_editor_bound_module(1):
		_fail("Tryout did not consume bound attack key.")
	if main.editor_bound_module_tryout.is_empty():
		_fail("Tryout preview state was not created.")
	if String(main.editor_bound_module_tryout.get("preview_kind", "")) != "melee":
		_fail("Two-Link tryout should be melee preview.")
	if bool(main.editor_bound_module_tryout.get("projectile", false)):
		_fail("Melee tryout must not expose projectile.")
	print("TEAMEDIT_BOUND_MODULE_TRYOUT_PROBE ok profile=%s" % String(main.editor_bound_module_tryout.get("profile", "")))
	quit()
