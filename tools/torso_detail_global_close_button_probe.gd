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


func _global_close_click(view) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = view.get_global_transform() * view._close_rect().get_center()
	event.global_position = event.position
	return event


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
	var torso_node: int = main._add_topology_node_at(Vector2(500.0, 302.0))
	if torso_node < 0:
		_fail("Could not place torso.")
		return
	main._open_editor_torso_detail(torso_node)
	if main.editor_torso_detail_view == null or not main.editor_torso_detail_view.visible:
		_fail("Torso detail did not open.")
		return
	main.editor_node_click_candidate_index = torso_node
	main.editor_node_click_start_position = Vector2(500.0, 302.0)
	main.editor_node_click_moved = false
	var handled := main._route_unit_editor_priority_input(_global_close_click(main.editor_torso_detail_view))
	if not handled:
		_fail("Global torso close click was not consumed by priority input.")
		return
	if main.editor_torso_detail_view.visible:
		_fail("Global torso close click did not hide the torso detail panel.")
		return
	if main.editor_open_torso_node_index != -1:
		_fail("Global torso close click did not clear editor_open_torso_node_index.")
		return
	if main.editor_node_click_candidate_index != -1:
		_fail("Global torso close click did not clear the board reopen candidate.")
		return
	print("TORSO_DETAIL_GLOBAL_CLOSE_BUTTON_PROBE ok torso=%d" % torso_node)
	quit()
