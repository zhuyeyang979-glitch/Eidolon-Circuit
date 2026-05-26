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
	main.editor_pending_module_binding["side_mount_action_required"] = true
	main.editor_pending_module_binding["side_mount_action_side"] = ""
	main.editor_pending_module_binding["side_mount_action_default_side"] = "right"
	main._refresh_torso_detail_view()
	var left_button: Button = main.editor_action_buttons["bind_side_left"]
	var right_button: Button = main.editor_action_buttons["bind_side_right"]
	if not left_button.visible or not right_button.visible or left_button.disabled or right_button.disabled:
		_fail("Action-side buttons should be visible and enabled before key selection.")
	if left_button.z_index <= main.editor_torso_detail_view.z_index or right_button.z_index <= main.editor_torso_detail_view.z_index:
		_fail("Action-side buttons are not above the torso detail binding panel.")
	for key_value in range(1, MainScene.ATTACK_GROUP_COUNT + 1):
		if bool(main.editor_action_buttons["bind_key_%d" % key_value].visible):
			_fail("Attack key %d should remain hidden until a side action is chosen." % key_value)
	left_button.pressed.emit()
	if String(main.editor_pending_module_binding.get("side_mount_action_side", "")) != "left":
		_fail("Left action-side button did not write side state.")
	for key_value in range(1, MainScene.ATTACK_GROUP_COUNT + 1):
		var key_button: Button = main.editor_action_buttons["bind_key_%d" % key_value]
		if not key_button.visible or key_button.disabled:
			_fail("Attack key %d should be available after choosing action side." % key_value)
	main.editor_action_buttons["bind_key_2"].pressed.emit()
	var bindings: Array = Array(unit_bp.get("module_bindings", []))
	if bindings.size() != 1:
		_fail("Side action + key flow did not finalize binding.")
	var binding: Dictionary = Dictionary(bindings[0])
	if String(binding.get("side_mount_action_side", "")) != "left":
		_fail("Final binding did not preserve selected side action.")
	if int(binding.get("attack_key", 0)) != 2:
		_fail("Final binding did not preserve selected attack key.")
	print("MODULE_BINDING_SIDE_ACTION_TOP_LAYER_PROBE ok")
	quit()
