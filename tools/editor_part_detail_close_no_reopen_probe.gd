extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_limb(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if not part.is_empty():
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var limb_index := _first_limb(main)
	if limb_index < 0:
		return {}
	var nodes: Array = [
		main._topology_component_node(0, "TEST LIMB", Vector2(0.64, 0.50), "limb_muscle", limb_index),
	]
	unit["blank_canvas"] = false
	unit["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _mouse_button(global_pos: Vector2, pressed: bool, button_index: int = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = pressed
	event.position = global_pos
	event.global_position = global_pos
	return event


func _mouse_motion(global_pos: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = global_pos
	event.global_position = global_pos
	return event


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.ui_language = "en"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	if main.editor_working_blueprint.is_empty():
		_fail("Could not build test unit.")
		return
	main._update_editor_ui()
	var node_board_pos := main._topology_position_to_board_local(Vector2(0.64, 0.50))
	main._show_editor_topology_node_detail(0, "board", {"position": Vector2(520.0, 86.0)})
	if main.editor_hover_popup_view == null or not main.editor_hover_popup_view.visible or not main.editor_hover_pinned:
		_fail("Board part detail did not open.")
		return
	var close_pos: Vector2 = main.editor_hover_popup_view.get_global_transform() * main.editor_hover_popup_view._close_rect().get_center()
	main.editor_dragging_node_index = 0
	main.editor_dragging_selected_nodes = false
	main.editor_node_click_candidate_index = 0
	main.editor_node_click_start_position = close_pos
	main.editor_node_click_moved = false
	if not main._route_unit_editor_priority_input(_mouse_button(close_pos, true)):
		_fail("Close click was not consumed.")
		return
	main._handle_editor_board_input(_mouse_button(close_pos, false))
	main._refresh_editor_visual_views()
	main.flush_editor_dirty(2400)
	main._handle_editor_board_input(_mouse_motion(node_board_pos))
	if main.editor_hover_popup_view.visible:
		_fail("Pinned part detail reopened after close + release/refresh/motion.")
		return
	if main.editor_hover_pinned:
		_fail("Pinned part detail state was restored after close.")
		return
	if main.editor_node_click_candidate_index != -1:
		_fail("Board click candidate was restored after close.")
		return
	print("EDITOR_PART_DETAIL_CLOSE_NO_REOPEN_PROBE ok")
	quit()
