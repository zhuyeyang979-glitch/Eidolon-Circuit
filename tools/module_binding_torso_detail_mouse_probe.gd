extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


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


func _click(control: Control, pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pos
	control._gui_input(event)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
		quit(1)
		return
	var unit_bp := _build_unit(main, module_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"
	main.editor_open_torso_node_index = 0
	main._refresh_torso_detail_view()
	var view = main.editor_torso_detail_view
	if view == null or not view.visible:
		_fail("Torso detail did not open.")
		quit(1)
		return

	var rebind_rect: Rect2 = view._rebind_rect_for_slot(view._slot_rect("software", 0))
	_click(view, rebind_rect.get_center())
	if main.editor_pending_module_binding.is_empty() or not view.binding_mode:
		_fail("Clicking the rebind button did not enter binding mode.")
	if view.binding_candidates.is_empty():
		_fail("Binding mode did not expose target candidates.")
	if not view.binding_candidates.is_empty() and not bool(Dictionary(view.binding_candidates[0]).get("valid", false)):
		_fail("First visible binding candidate should be legal after sorting.")
	if not failed:
		_click(view, view._binding_candidate_rect(0).get_center())
		if not bool(main.editor_pending_module_binding.get("target_selected", false)):
			_fail("Clicking the first candidate did not select the target.")
		if not view.binding_key_ready:
			_fail("Clicking a legal candidate did not activate the key row.")
	if not failed:
		_click(view, view._binding_key_rect(1).get_center())
		var bindings: Array = Array(unit_bp.get("module_bindings", []))
		if bindings.size() != 1 or int(Dictionary(bindings[0]).get("attack_key", 0)) != 1:
			_fail("Clicking key 1U did not write the binding.")
		if not main.editor_pending_module_binding.is_empty():
			_fail("Pending binding was not cleared after clicking key 1U.")
	if failed:
		quit(1)
		return
	print("MODULE_BINDING_TORSO_DETAIL_MOUSE_PROBE ok")
	quit()
