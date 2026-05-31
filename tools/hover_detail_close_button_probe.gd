extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_index(main, profile: String) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == profile:
			return i
	return -1


func _left_click(local_pos: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = local_pos
	return event


func _right_click(global_pos: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	event.position = global_pos
	return event


func _show_detail(main, module_index: int, source: String) -> void:
	var module: Dictionary = main._selected_component("hero", "module", module_index)
	main._show_editor_part_hover("module", module_index, module, true, {"source": source})
	if main.editor_hover_popup_view == null or not main.editor_hover_popup_view.visible or not main.editor_hover_pinned:
		_fail("Pinned detail did not open for %s." % source)
	if main.editor_hover_popup_view.mouse_filter != Control.MOUSE_FILTER_STOP:
		_fail("Pinned detail should stop mouse events.")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.ui_language = "en"
	var module_index := _module_index(main, "gun_activate")
	if module_index < 0:
		_fail("Missing gun_activate module.")
	_show_detail(main, module_index, "close_button")
	main.editor_hover_popup_view._gui_input(_left_click(main.editor_hover_popup_view._close_rect().get_center()))
	if main.editor_hover_popup_view.visible:
		_fail("Close button did not hide pinned detail.")
	main._show_editor_part_hover("module", module_index, main._selected_component("hero", "module", module_index), true, {"source": "close_button"})
	if main.editor_hover_popup_view.visible:
		_fail("Pinned detail reopened immediately despite suppress token.")
	main.editor_hover_suppress_until_msec = 0
	_show_detail(main, module_index, "esc")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	main._input(esc)
	if main.editor_hover_popup_view.visible:
		_fail("Esc did not close pinned detail.")
	main.editor_hover_suppress_until_msec = 0
	_show_detail(main, module_index, "right_click")
	main._input(_right_click(main.editor_hover_popup_view.get_global_rect().get_center()))
	if main.editor_hover_popup_view.visible:
		_fail("Right click did not close pinned detail.")
	print("HOVER_DETAIL_CLOSE_BUTTON_PROBE ok")
	quit()
