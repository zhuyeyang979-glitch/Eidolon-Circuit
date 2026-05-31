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


func _outside_popup_board_pos(main) -> Vector2:
	var board_rect: Rect2 = main.assembly_board_view.get_global_rect() if main.assembly_board_view != null else Rect2(Vector2.ZERO, Vector2(600.0, 420.0))
	var popup_rect: Rect2 = main.editor_hover_popup_view.get_global_rect()
	var candidates := [
		board_rect.position + Vector2(28.0, 28.0),
		board_rect.position + Vector2(board_rect.size.x - 28.0, 28.0),
		board_rect.position + Vector2(28.0, board_rect.size.y - 28.0),
		board_rect.position + board_rect.size * 0.5,
	]
	for candidate in candidates:
		if board_rect.has_point(candidate) and not popup_rect.has_point(candidate):
			return candidate
	return popup_rect.position - Vector2(18.0, 18.0)


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
	main._show_editor_topology_node_detail(0, "board", {"position": Vector2(520.0, 86.0)})
	if main.editor_hover_popup_view == null or not main.editor_hover_popup_view.visible or not main.editor_hover_pinned:
		_fail("Board part detail did not open.")
		return
	var outside_pos := _outside_popup_board_pos(main)
	var handled := main._route_unit_editor_priority_input(_mouse_button(outside_pos, true))
	if not handled:
		_fail("Outside click was not consumed by pinned part detail close.")
		return
	if main.editor_hover_popup_view.visible:
		_fail("Outside click did not close pinned part detail.")
		return
	main._handle_editor_board_input(_mouse_button(outside_pos, false))
	if main.editor_hover_popup_view.visible:
		_fail("Outside close reopened pinned part detail on release.")
		return
	print("EDITOR_PART_DETAIL_CLICK_OUTSIDE_CLOSE_PROBE ok")
	quit()
