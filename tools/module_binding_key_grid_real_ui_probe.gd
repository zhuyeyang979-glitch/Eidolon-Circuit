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


func _first_engine(main) -> int:
	for i in range(main._catalog_for("hero", "engine").size()):
		if main._engine_momentum_output_for_part(main._selected_component("hero", "engine", i)) > 0.0:
			return i
	return -1


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _build_unit(main, module_index: int, engine_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _click(view: Control, pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pos
	view._gui_input(event)


func _global_click(main, pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pos
	main._input(event)


func _click_button(button: Button) -> void:
	button.pressed.emit()


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	var engine_index := _first_engine(main)
	if module_index < 0 or engine_index < 0:
		_fail("Missing two-link module or engine.")
	var unit_bp := _build_unit(main, module_index, engine_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = 0
	main._start_editor_module_binding_flow(1, main._selected_component("hero", "module", module_index))
	main._refresh_torso_detail_view()
	var view = main.editor_torso_detail_view
	if not view.binding_mode:
		_fail("Torso detail did not enter binding mode.")

	var panel_rect: Rect2 = view._binding_panel_rect()
	var list_rect: Rect2 = view._binding_list_rect()
	var seen_rows := {}
	for key_value in range(1, 7):
		var rect: Rect2 = view._binding_key_rect(key_value)
		if not panel_rect.encloses(rect):
			_fail("Binding key %d is outside the binding panel: %s panel=%s" % [key_value, str(rect), str(panel_rect)])
		if rect.intersects(list_rect):
			_fail("Binding key %d overlaps the candidate list." % key_value)
		for other_key in range(1, key_value):
			if rect.intersects(view._binding_key_rect(other_key)):
				_fail("Binding key %d overlaps key %d." % [key_value, other_key])
		seen_rows[int(round(rect.position.y))] = true
	if seen_rows.size() != 2:
		_fail("Binding attack keys are not arranged in two visible rows.")
	for key_value in range(1, MainScene.ATTACK_GROUP_COUNT + 1):
		var button_key := "bind_key_%d" % key_value
		if main.editor_action_buttons.has(button_key) and main.editor_action_buttons[button_key].visible:
			_fail("Global bind key button %d is visible during pending binding; it can overlap the board/catalog." % key_value)

	var selected := -1
	for i in range(view.binding_candidates.size()):
		if bool(Dictionary(view.binding_candidates[i]).get("valid", false)):
			selected = i
			break
	if selected < 0:
		_fail("No legal binding candidate in panel.")
	_global_click(main, view.get_global_rect().position + view._binding_candidate_rect(selected).get_center())
	if not bool(main.editor_pending_module_binding.get("target_selected", false)):
		_fail("Global candidate-row click did not select a binding target.")
	if not view.binding_key_ready:
		_fail("Binding key row did not become active after selecting a target.")
	for key_value in range(1, MainScene.ATTACK_GROUP_COUNT + 1):
		var button_key := "bind_key_%d" % key_value
		if not main.editor_action_buttons.has(button_key):
			_fail("Missing real bind key button %d." % key_value)
		var button: Button = main.editor_action_buttons[button_key]
		if not button.visible or button.disabled:
			_fail("Real bind key button %d should be visible and enabled after target selection." % key_value)
		if button.mouse_filter != Control.MOUSE_FILTER_STOP:
			_fail("Real bind key button %d must stop mouse input." % key_value)
		var expected_rect: Rect2 = Rect2(view.get_global_rect().position + view._binding_key_rect(key_value).position, view._binding_key_rect(key_value).size)
		var actual_rect: Rect2 = button.get_global_rect()
		if actual_rect.position.distance_to(expected_rect.position) > 1.5 or absf(actual_rect.size.x - expected_rect.size.x) > 1.5 or actual_rect.size.y < expected_rect.size.y:
			_fail("Real bind key button %d is not aligned with the torso detail key grid. actual=%s expected=%s" % [key_value, str(actual_rect), str(expected_rect)])

	_click_button(main.editor_action_buttons["bind_key_3"])
	var bindings: Array = Array(unit_bp.get("module_bindings", []))
	if bindings.size() != 1:
		_fail("Global key click did not finalize a module binding.")
	var binding: Dictionary = Dictionary(bindings[0])
	if int(binding.get("attack_key", 0)) != 3:
		_fail("Binding key was not written from real key click.")
	if Array(binding.get("target_nodes", [])).size() != 2:
		_fail("Two-Link binding did not preserve the two target nodes.")
	main._refresh_unit_editor_power_allocation_dock()
	var limb_entries := 0
	for raw_entry in Array(main.editor_power_dock_view.entries):
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == "limb":
			limb_entries += 1
	if limb_entries < 2:
		_fail("Bound limb entries did not appear in power allocation dock.")
	print("MODULE_BINDING_KEY_GRID_REAL_UI_PROBE ok rows=%d limbs=%d" % [seen_rows.size(), limb_entries])
	quit()
