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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	var candidate := main._pending_module_binding_candidate_for_node(unit_bp, limb_b)
	if candidate.is_empty() or not bool(candidate.get("valid", false)):
		_fail("Clicking a highlighted downstream Two-Link node did not resolve a legal grouped candidate.")
	main._complete_pending_module_binding_with_selection(unit_bp, Array(candidate.get("selection", [])))
	main._set_pending_module_attack_key(1)
	var runtime_bindings: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	if runtime_bindings.size() != 1:
		_fail("Two-Link UI binding did not create one runtime binding.")
	var binding: Dictionary = Dictionary(runtime_bindings[0])
	if not bool(binding.get("runtime_valid", false)):
		_fail("Two-Link runtime binding invalid: %s" % String(binding.get("binding_valid_note", "")))
	if Array(binding.get("target_nodes", [])).size() != 2:
		_fail("Two-Link runtime binding lost its two target nodes.")
	print("TWO_LINK_BINDING_REAL_UI_PROBE ok")
	quit()
