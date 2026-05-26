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


func _any_binding_overlay_button_visible(main) -> bool:
	for key_value in range(1, MainScene.ATTACK_GROUP_COUNT + 1):
		var button: Button = main.editor_action_buttons["bind_key_%d" % key_value]
		if button.visible and button.z_index >= MainScene.MODULE_BINDING_OVERLAY_Z_INDEX:
			return true
	for side_key in ["left", "right"]:
		if main.editor_action_buttons.has("bind_side_%s" % side_key) and bool(main.editor_action_buttons["bind_side_%s" % side_key].visible):
			return true
	return false


func _start_and_select(main, module_index: int) -> void:
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	_select_first_valid_candidate(main)
	if not _any_binding_overlay_button_visible(main):
		_fail("Binding overlay buttons did not become visible after selecting target.")


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
	_start_and_select(main, module_index)
	main._cancel_editor_module_binding(false)
	if _any_binding_overlay_button_visible(main):
		_fail("Binding overlay buttons should hide after cancel.")
	_start_and_select(main, module_index)
	main.editor_action_buttons["bind_key_1"].pressed.emit()
	if _any_binding_overlay_button_visible(main):
		_fail("Binding overlay buttons should hide after final key selection.")
	_start_and_select(main, module_index)
	main._close_editor_torso_detail()
	main._refresh_editor_module_binding_buttons()
	if _any_binding_overlay_button_visible(main):
		_fail("Binding overlay buttons should hide after closing torso detail.")
	print("MODULE_BINDING_OVERLAY_CLEARS_PROBE ok")
	quit()
