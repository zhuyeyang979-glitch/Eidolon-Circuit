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


func _build_unit(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
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
	var unit_bp := _build_unit(main, module_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = 0
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	main._refresh_torso_detail_view()
	if not main.editor_torso_detail_view.binding_mode:
		_fail("Torso detail did not enter binding mode.")
	var selected := -1
	for i in range(main.editor_torso_detail_view.binding_candidates.size()):
		if bool(Dictionary(main.editor_torso_detail_view.binding_candidates[i]).get("valid", false)):
			selected = i
			break
	if selected < 0:
		_fail("No legal binding candidate in panel.")
	main._select_torso_detail_binding_candidate(selected)
	if not bool(main.editor_pending_module_binding.get("target_selected", false)):
		_fail("Panel candidate click did not select a target.")
	main._select_torso_detail_binding_key(3)
	var bindings: Array = Array(unit_bp.get("module_bindings", []))
	if bindings.size() != 1:
		_fail("Panel key click did not write a module binding.")
	var binding: Dictionary = Dictionary(bindings[0])
	if int(binding.get("attack_key", 0)) != 3:
		_fail("Binding key was not written from panel.")
	if Array(binding.get("target_nodes", [])).size() != 2:
		_fail("Two-Link panel binding did not preserve two target nodes.")
	print("MODULE_BINDING_PANEL_CLICK_PROBE ok key=%d" % int(binding.get("attack_key", 0)))
	quit()
