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


func _first_booster(main) -> int:
	for i in range(main._catalog_for("hero", "booster").size()):
		if main._thruster_drive_demand_for_part(main._selected_component("hero", "booster", i)) > 0.0:
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	unit["blank_canvas"] = false
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": _first_engine(main), "torso_node": torso},
		{"kind": "booster", "booster": _first_booster(main), "torso_node": torso},
	]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _click(local_pos: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = local_pos
	return event


func _entry_index(view, prefix: String) -> int:
	for i in range(view.entries.size()):
		if view.entries[i] is Dictionary and String(Dictionary(view.entries[i]).get("id", "")).begins_with(prefix):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.ui_language = "en"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main._update_editor_ui()
	main._set_engine_allocation_context_for_torso(main._editor_current_blueprint(), 0, false, 0)
	main._toggle_engine_momentum_allocation_for_active_target()
	var view = main.engine_momentum_allocation_view
	if view == null or not view.visible:
		_fail("Allocation detail panel did not open.")
	var booster_row := _entry_index(view, "booster_drive:")
	if booster_row < 0:
		_fail("Missing booster drive row.")
	view._gui_input(_click(view._entry_row_rect(booster_row).position + Vector2(18.0, 18.0)))
	if main.editor_hover_popup_view == null or not main.editor_hover_popup_view.visible or not main.editor_hover_pinned:
		_fail("Clicking allocation row did not open pinned part detail.")
	if main.editor_hover_slot_key != "booster":
		_fail("Allocation row should open booster detail, got %s." % main.editor_hover_slot_key)
	main._close_editor_hover_detail("probe")
	main.editor_hover_suppress_until_msec = 0
	if view.segments.is_empty():
		_fail("Allocation panel has no silhouette segments.")
	var segment: Dictionary = view.segments[0]
	var segment_center: Vector2 = view._segment_screen_rect(segment).get_center()
	view._gui_input(_click(segment_center))
	if main.editor_hover_popup_view == null or not main.editor_hover_popup_view.visible or not main.editor_hover_pinned:
		_fail("Clicking allocation silhouette segment did not open pinned part detail.")
	print("POWER_ALLOCATION_CLICK_PART_HOVER_PROBE ok")
	quit()
