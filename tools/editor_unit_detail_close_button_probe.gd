extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


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
	var local_event := InputEventMouseButton.new()
	local_event.button_index = MOUSE_BUTTON_LEFT
	local_event.pressed = true
	local_event.position = main.editor_unit_hover_view._close_rect().get_center()
	main.editor_unit_hover_view._gui_input(local_event)
	if main.editor_unit_hover_view.visible:
		_fail("Close button did not hide pinned unit detail.")
		return
	if bool(main.editor_unit_detail_pinned):
		_fail("Close button did not clear pinned unit detail state.")
		return
	print("EDITOR_UNIT_DETAIL_CLOSE_BUTTON_PROBE ok")
	quit()
