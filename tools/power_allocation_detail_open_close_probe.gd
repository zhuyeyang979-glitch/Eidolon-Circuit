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
		if main._thruster_allocated_momentum_for_part(main._selected_component("hero", "booster", i)) > 0.0:
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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main.editor_panel_mode = "parts"
	main._update_editor_ui()
	main._set_engine_allocation_context_for_torso(main._editor_current_blueprint(), 0, false, 0)
	if main.engine_momentum_allocation_view != null and main.engine_momentum_allocation_view.visible:
		_fail("Non-explicit context refresh opened detail panel.")
	if main.editor_power_dock_view == null or not main.editor_power_dock_view.visible:
		_fail("Power dock should remain visible.")
	main._toggle_engine_momentum_allocation_for_active_target()
	if main.engine_momentum_allocation_view == null or not main.engine_momentum_allocation_view.visible:
		_fail("Explicit dock/detail toggle did not open allocation detail panel.")
	var close_click := InputEventMouseButton.new()
	close_click.button_index = MOUSE_BUTTON_LEFT
	close_click.pressed = true
	var close_local: Vector2 = main.engine_momentum_allocation_view._close_rect().get_center()
	close_click.position = main.engine_momentum_allocation_view.get_global_transform() * close_local
	main._input(close_click)
	if main.engine_momentum_allocation_view.visible:
		_fail("Global close button click did not hide allocation detail panel.")
	main._toggle_engine_momentum_allocation_for_active_target()
	if not main.engine_momentum_allocation_view.visible:
		_fail("Reopen after global close button click failed.")
	main._close_engine_momentum_allocation_panel()
	if main.engine_momentum_allocation_view.visible:
		_fail("Close helper did not hide allocation detail panel.")
	main._refresh_engine_momentum_allocation_view()
	if main.engine_momentum_allocation_view.visible:
		_fail("Dirty refresh reopened allocation detail panel after close.")
	main._toggle_engine_momentum_allocation_for_active_target()
	if not main.engine_momentum_allocation_view.visible:
		_fail("Second explicit toggle did not reopen allocation detail panel.")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	main._input(esc)
	if main.engine_momentum_allocation_view.visible:
		_fail("Esc did not hide allocation detail panel.")
	main._toggle_engine_momentum_allocation_for_active_target()
	if not main.engine_momentum_allocation_view.visible:
		_fail("Reopen after Esc close failed.")
	main._toggle_engine_momentum_allocation_for_active_target()
	if main.engine_momentum_allocation_view.visible:
		_fail("Explicit toggle did not close allocation detail panel.")
	print("POWER_ALLOCATION_DETAIL_OPEN_CLOSE_PROBE ok")
	quit()
