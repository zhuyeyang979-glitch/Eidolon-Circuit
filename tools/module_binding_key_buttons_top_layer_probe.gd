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


func _select_first_valid_candidate(main) -> void:
	var view = main.editor_torso_detail_view
	for i in range(view.binding_candidates.size()):
		if bool(Dictionary(view.binding_candidates[i]).get("valid", false)):
			main._select_torso_detail_binding_candidate(i)
			return
	_fail("No valid module binding candidate.")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Missing two-link module.")
	var unit_bp := _build_unit(main, module_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	_select_first_valid_candidate(main)
	main._refresh_editor_module_binding_buttons()
	var detail_z: int = main.editor_torso_detail_view.z_index if main.editor_torso_detail_view != null else 0
	var power_z: int = main.engine_momentum_allocation_view.z_index if main.engine_momentum_allocation_view != null else 0
	var hover_z: int = main.editor_hover_popup_view.z_index if main.editor_hover_popup_view != null else 0
	var orient_z: int = main.editor_orientation_popup_panel.z_index if main.editor_orientation_popup_panel != null else 0
	for key_value in range(1, MainScene.ATTACK_GROUP_COUNT + 1):
		var button: Button = main.editor_action_buttons["bind_key_%d" % key_value]
		if not button.visible or button.disabled:
			_fail("Bind key %d should be visible and enabled in binding key-select mode." % key_value)
		if button.mouse_filter != Control.MOUSE_FILTER_STOP:
			_fail("Bind key %d should stop mouse input." % key_value)
		if button.z_index <= max(max(detail_z, power_z), max(hover_z, orient_z)):
			_fail("Bind key %d is not above editor overlays: key=%d detail=%d power=%d hover=%d orient=%d" % [key_value, button.z_index, detail_z, power_z, hover_z, orient_z])
		var expected: Rect2 = Rect2(main.editor_torso_detail_view.get_global_rect().position + main.editor_torso_detail_view._binding_key_rect(key_value).position, main.editor_torso_detail_view._binding_key_rect(key_value).size)
		var actual: Rect2 = button.get_global_rect()
		if actual.position.distance_to(expected.position) > 1.5 or absf(actual.size.x - expected.size.x) > 1.5 or actual.size.y < expected.size.y:
			_fail("Bind key %d is not aligned with detail key rect. actual=%s expected=%s" % [key_value, str(actual), str(expected)])
	print("MODULE_BINDING_KEY_BUTTONS_TOP_LAYER_PROBE ok")
	quit()
