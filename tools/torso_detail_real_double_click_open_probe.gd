extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			return i
	return -1


func _mouse_button(position: Vector2, pressed: bool, double_click: bool = false) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.double_click = double_click
	return event


func _build_unit(main) -> Dictionary:
	var torso_index := _first_torso(main)
	if torso_index < 0:
		_fail("No torso part found.")
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	unit["blank_canvas"] = false
	unit["custom_topology"] = {
		"nodes": [
			main._topology_component_node(0, "TEST TORSO", Vector2(0.50, 0.50), "muscle", torso_index),
		],
		"edges": [],
		"edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION,
	}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _run_mode(main, mode: String) -> void:
	main.editor_working_blueprint = _build_unit(main)
	main.editor_panel_mode = "parts"
	main.editor_board_tool = mode
	main._close_editor_torso_detail()
	main._clear_editor_hover_card(true)
	main._clear_editor_detail_reopen_candidates()
	main._update_editor_ui()
	var local_pos: Vector2 = main._topology_position_to_board_local(Vector2(0.50, 0.50))
	var global_pos: Vector2 = main.assembly_board_view.get_global_transform() * local_pos
	main._handle_editor_board_input(_mouse_button(local_pos, true))
	main._handle_editor_board_input(_mouse_button(local_pos, false))
	if main.editor_hover_popup_view != null and main.editor_hover_popup_view.visible and main.editor_hover_pinned:
		_fail("Single torso click in %s mode opened the generic pinned part card." % mode)
	var handled: bool = main._route_unit_editor_priority_input(_mouse_button(global_pos, true, true))
	if not handled:
		_fail("Torso double-click in %s mode was not consumed by priority route." % mode)
	if main.editor_torso_detail_view == null or not main.editor_torso_detail_view.visible:
		_fail("Torso double-click in %s mode did not open torso detail." % mode)
	if main.editor_open_torso_node_index != 0:
		_fail("Torso detail opened wrong node in %s mode: %d." % [mode, main.editor_open_torso_node_index])
	if main.editor_hover_popup_view != null and main.editor_hover_popup_view.visible and main.editor_hover_pinned:
		_fail("Torso double-click in %s mode left a generic pinned part card visible." % mode)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.ui_language = "zh"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	_run_mode(main, "layout")
	_run_mode(main, "pose")
	print("TORSO_DETAIL_REAL_DOUBLE_CLICK_OPEN_PROBE ok")
	quit()
