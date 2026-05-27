extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


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
	main.editor_panel_mode = "load"
	main.editor_load_mode = "team"
	main._update_editor_ui()
	main._show_editor_empty_slot_hover(0, true)
	if main.editor_unit_hover_view == null or not main.editor_unit_hover_view.visible:
		_fail("Pinned unit detail did not open.")
		return
	if not bool(main.editor_unit_detail_pinned):
		_fail("Unit detail did not enter pinned state.")
		return
	var token := String(main.editor_unit_detail_token)
	var handled := main._route_unit_editor_priority_input(_global_close_click(main.editor_unit_hover_view))
	if not handled:
		_fail("Global close click was not consumed by the priority input route.")
		return
	if main.editor_unit_hover_view.visible:
		_fail("Global close click did not hide pinned unit detail.")
		return
	if bool(main.editor_unit_detail_pinned):
		_fail("Global close click did not clear pinned unit detail state.")
		return
	if String(main.editor_unit_detail_suppress_token) != token:
		_fail("Global close click did not preserve the suppress token.")
		return
	main._show_editor_empty_slot_hover(0, false)
	if main.editor_unit_hover_view.visible:
		_fail("Closed unit detail immediately reopened for the same suppressed token.")
		return
	print("EDITOR_UNIT_DETAIL_GLOBAL_CLOSE_BUTTON_PROBE ok token=%s" % token)
	quit()
