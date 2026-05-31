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


func _make_unit(main, torso: int, engine_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var node_torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "engine", "engine": engine_index, "torso_node": node_torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	return unit_bp


func _engine_slot_index(view) -> int:
	for i in range(view.plugin_entries.size()):
		if view.plugin_entries[i] is Dictionary and String(Dictionary(view.plugin_entries[i]).get("kind", "")) == "engine":
			return i
	return -1


func _click(view, pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pos
	view._gui_input(event)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var torso_index := _first_torso(main)
	var engine_index := _first_engine(main)
	if torso_index < 0 or engine_index < 0:
		_fail("Required torso or engine missing.")
	var unit_bp := _make_unit(main, torso_index, engine_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = 0
	main._refresh_torso_detail_view()
	var view = main.editor_torso_detail_view
	var allocation_count := [0]
	view.engine_allocation_requested.connect(func(_payload_index: int): allocation_count[0] = int(allocation_count[0]) + 1)
	var slot_index := _engine_slot_index(view)
	if slot_index < 0:
		_fail("Engine payload is not visible in plugin slots.")
	var slot_rect: Rect2 = view._slot_rect("plugin", slot_index)
	var body_pos := slot_rect.position + Vector2(72.0, slot_rect.size.y * 0.5)
	if String(view._slot_hit(body_pos).get("action", "")) != "engine_allocation":
		_fail("Engine slot body should resolve to engine_allocation action.")
	_click(view, body_pos)
	if int(allocation_count[0]) != 1:
		_fail("Engine slot body click should open allocation exactly once.")
	var unit_bp_delete := _make_unit(main, torso_index, engine_index)
	main.editor_working_blueprint = unit_bp_delete
	main.editor_open_torso_node_index = 0
	main._refresh_torso_detail_view()
	view = main.editor_torso_detail_view
	var allocation_count_after_delete := [0]
	view.engine_allocation_requested.connect(func(_payload_index: int): allocation_count_after_delete[0] = int(allocation_count_after_delete[0]) + 1)
	slot_index = _engine_slot_index(view)
	var delete_pos: Vector2 = view._remove_rect_for_slot(view._slot_rect("plugin", slot_index)).get_center()
	if String(view._slot_hit(delete_pos).get("action", "")) != "delete":
		_fail("Engine delete hot zone should resolve to delete action.")
	_click(view, delete_pos)
	if int(allocation_count_after_delete[0]) != 0:
		_fail("Engine delete hot zone incorrectly opened allocation.")
	if not Array(unit_bp_delete.get("slot_payloads", [])).is_empty():
		_fail("Engine delete hot zone did not delete the payload.")
	print("ENGINE_SLOT_ALLOCATION_CLICK_PROBE ok")
	quit()
