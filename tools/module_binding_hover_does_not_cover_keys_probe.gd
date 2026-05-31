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


func _global_click(main, pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pos
	main._input(event)


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
	main.editor_open_torso_node_index = 0
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	main._refresh_torso_detail_view()
	var view = main.editor_torso_detail_view
	if view == null or not view.visible or not view.binding_mode:
		_fail("Torso detail binding panel did not open.")
	var hover_part: Dictionary = main._selected_component("hero", "module", module_index)
	main._show_editor_part_hover("module", module_index, hover_part)
	if main.editor_hover_popup_view != null and main.editor_hover_popup_view.visible:
		_fail("Catalog hover popup is visible during binding mode and can cover attack keys.")
	var selected := -1
	for i in range(view.binding_candidates.size()):
		if bool(Dictionary(view.binding_candidates[i]).get("valid", false)):
			selected = i
			break
	if selected < 0:
		_fail("No valid binding candidate.")
	_global_click(main, view.get_global_rect().position + view._binding_candidate_rect(selected).get_center())
	if not view.binding_key_ready:
		_fail("Key grid did not activate.")
	main._show_editor_part_hover("module", module_index, hover_part)
	if main.editor_hover_popup_view != null and main.editor_hover_popup_view.visible:
		_fail("Catalog hover popup reappeared over active attack-key grid.")
	_global_click(main, view.get_global_rect().position + view._binding_key_rect(1).get_center())
	if Array(unit_bp.get("module_bindings", [])).is_empty():
		_fail("Attack-key click did not finalize binding.")
	print("MODULE_BINDING_HOVER_DOES_NOT_COVER_KEYS_PROBE ok")
	quit()
