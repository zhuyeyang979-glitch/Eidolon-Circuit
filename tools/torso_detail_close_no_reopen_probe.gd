extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			return i
	return -1


func _mouse_button(pos: Vector2, pressed: bool, double_click: bool = false) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.double_click = double_click
	event.position = pos
	event.global_position = pos
	return event


func _global_close_pos(view) -> Vector2:
	return view.get_global_transform() * view._close_rect().get_center()


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var torso_part := _find_torso(main)
	if torso_part < 0:
		_fail("No torso part found.")
		return
	main._set_pending_canvas_part(unit_bp, "muscle", torso_part)
	var torso_pos := Vector2(500.0, 302.0)
	var torso_node: int = main._add_topology_node_at(torso_pos)
	if torso_node < 0:
		_fail("Could not place torso.")
		return
	main._handle_editor_board_input(_mouse_button(torso_pos, true, true))
	if main.editor_torso_detail_view == null or not main.editor_torso_detail_view.visible:
		_fail("Double-click did not open torso detail.")
		return
	var close_pos := _global_close_pos(main.editor_torso_detail_view)
	if not main._route_unit_editor_priority_input(_mouse_button(close_pos, true)):
		_fail("Close click was not consumed.")
		return
	main._handle_editor_board_input(_mouse_button(close_pos, false))
	main._refresh_torso_detail_view()
	main.flush_editor_dirty(2400)
	var motion := InputEventMouseMotion.new()
	motion.position = torso_pos
	motion.global_position = torso_pos
	main._handle_editor_board_input(motion)
	if main.editor_torso_detail_view.visible:
		_fail("Torso detail reopened after close + release/refresh/motion.")
		return
	if main.editor_open_torso_node_index != -1:
		_fail("Torso detail open index was restored after close.")
		return
	print("TORSO_DETAIL_CLOSE_NO_REOPEN_PROBE ok torso=%d" % torso_node)
	quit()
