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


func _open_panel(main) -> void:
	main._open_dashboard_engine_allocation()
	if main.engine_momentum_allocation_view == null or not main.engine_momentum_allocation_view.visible:
		_fail("Power allocation panel did not open from explicit dashboard action.")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var torso_index := _first_torso(main)
	var engine_index := _first_engine(main)
	if torso_index < 0 or engine_index < 0:
		_fail("Missing torso or engine.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "engine", "engine": engine_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._activate_engine_allocation_target_for_torso(unit_bp, torso)

	_open_panel(main)
	var close_click := InputEventMouseButton.new()
	close_click.button_index = MOUSE_BUTTON_LEFT
	close_click.pressed = true
	close_click.position = main.engine_momentum_allocation_view._close_rect().get_center()
	main.engine_momentum_allocation_view._gui_input(close_click)
	if main.engine_momentum_allocation_view.visible:
		_fail("Close button did not close the power allocation panel.")
	main._refresh_unit_editor_power_allocation_dock()
	main._refresh_engine_momentum_allocation_view()
	if main.engine_momentum_allocation_view.visible:
		_fail("Dashboard/topbar refresh reopened the panel after close button.")
	if main.editor_power_dock_view != null and main.editor_power_dock_view.visible:
		_fail("The old power allocation dock is still visible after close; it has no close affordance.")

	_open_panel(main)
	var escape_event := InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.physical_keycode = KEY_ESCAPE
	escape_event.pressed = true
	main._input(escape_event)
	if main.engine_momentum_allocation_view.visible:
		_fail("Esc did not close the power allocation panel.")
	main._refresh_unit_editor_power_allocation_dock()
	main._refresh_engine_momentum_allocation_view()
	if main.engine_momentum_allocation_view.visible:
		_fail("Dashboard/topbar refresh reopened the panel after Esc close.")

	_open_panel(main)
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	right_click.position = Vector2(240.0, 180.0)
	main._input(right_click)
	if main.engine_momentum_allocation_view.visible:
		_fail("Right click did not close the power allocation panel.")
	main._refresh_unit_editor_power_allocation_dock()
	main._refresh_engine_momentum_allocation_view()
	if main.engine_momentum_allocation_view.visible:
		_fail("Dashboard/topbar refresh reopened the panel after right-click close.")

	print("POWER_ALLOCATION_PANEL_CLOSE_PROBE ok")
	quit()
