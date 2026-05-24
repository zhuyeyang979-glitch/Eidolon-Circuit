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


func _setup_unit(main) -> Dictionary:
	var module_index := _two_link_module(main)
	var torso_index := _first_torso(main)
	if module_index < 0 or torso_index < 0:
		_fail("Required torso or Two-Link module missing.")
		return {}
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	main._refresh_editor_visual_views()
	return {
		"unit": unit_bp,
		"limb_a": limb_a,
		"limb_b": limb_b,
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var setup := _setup_unit(main)
	if setup.is_empty():
		return
	var unit_bp: Dictionary = setup["unit"]
	var board = main.assembly_board_view
	if board == null:
		_fail("Assembly board missing.")
		return
	if Dictionary(board.board_snapshot.get("binding_highlights", {})).is_empty():
		_fail("Pending binding did not create board binding highlights.")
		return
	if board.retained_binding_group_items.is_empty():
		_fail("Pending binding did not create retained binding groups.")
		return
	if not main._complete_pending_module_binding_with_selection(unit_bp, [int(setup["limb_a"]), int(setup["limb_b"])]):
		_fail("Selecting a two-link binding target failed.")
		return
	if main.editor_pending_module_binding.is_empty():
		_fail("Pending binding was cleared before attack key selection.")
		return
	main._set_pending_module_attack_key(1)
	if not main.editor_pending_module_binding.is_empty():
		_fail("Pending binding remained after finalization.")
		return
	if not main.editor_bound_module_tryout.is_empty():
		_fail("Tryout preview remained after binding finalization.")
		return
	if not main.editor_selected_topology_nodes.is_empty():
		_fail("Bound target nodes remained selected as persistent highlight.")
		return
	board = main.assembly_board_view
	var highlights: Dictionary = Dictionary(board.board_snapshot.get("binding_highlights", {}))
	if not highlights.is_empty():
		_fail("Board binding highlights remained after binding finalization: %s." % str(highlights.keys()))
		return
	if not board.retained_binding_group_items.is_empty():
		_fail("Retained binding group items remained after finalization.")
		return
	if Array(unit_bp.get("module_bindings", [])).is_empty():
		_fail("Binding data was not saved to the unit blueprint.")
		return
	print("MODULE_BINDING_HIGHLIGHT_CLEARS_AFTER_SUCCESS_PROBE ok bindings=%d" % Array(unit_bp.get("module_bindings", [])).size())
	quit()
