extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _open_pinned_detail(main: Node, slot_index: int) -> void:
	main._show_editor_empty_slot_hover(slot_index, true)
	if main.editor_unit_hover_view == null or not main.editor_unit_hover_view.visible:
		_fail("Pinned unit detail did not open.")
	if not bool(main.editor_unit_detail_pinned):
		_fail("Unit detail did not enter pinned state.")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_panel_mode = "load"
	main.editor_load_mode = "team"
	main._update_editor_ui()
	var before_state := String(main.game_state)
	_open_pinned_detail(main, 0)
	var esc_event := InputEventKey.new()
	esc_event.keycode = KEY_ESCAPE
	esc_event.physical_keycode = KEY_ESCAPE
	esc_event.pressed = true
	if not main._route_unit_editor_priority_input(esc_event):
		_fail("Esc was not consumed by pinned unit detail.")
		return
	if main.editor_unit_hover_view.visible or bool(main.editor_unit_detail_pinned):
		_fail("Esc did not close pinned unit detail.")
		return
	if String(main.game_state) != before_state:
		_fail("Esc changed page state while closing unit detail.")
		return
	_open_pinned_detail(main, 1)
	var right_event := InputEventMouseButton.new()
	right_event.button_index = MOUSE_BUTTON_RIGHT
	right_event.pressed = true
	right_event.position = main.editor_unit_hover_view.get_global_rect().get_center()
	if not main._route_unit_editor_priority_input(right_event):
		_fail("Right click was not consumed by pinned unit detail.")
		return
	if main.editor_unit_hover_view.visible or bool(main.editor_unit_detail_pinned):
		_fail("Right click did not close pinned unit detail.")
		return
	if String(main.game_state) != before_state:
		_fail("Right click changed page state while closing unit detail.")
		return
	print("EDITOR_UNIT_DETAIL_ESC_RIGHT_CLICK_PROBE ok")
	quit()
