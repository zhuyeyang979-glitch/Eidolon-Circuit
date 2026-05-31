extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if source.is_empty():
		_fail("Unable to read TeamEdit source.")
		return
	var board_input := _function_block(source, "func _handle_editor_board_input")
	var slider_view := _function_block(source, "func _emit_slider_change")
	if board_input.is_empty() or slider_view.is_empty():
		_fail("Unable to inspect TeamEdit input paths.")
		return
	var mouse_motion_pos := board_input.find("if event is InputEventMouseMotion:")
	var mouse_button_pos := board_input.find("if not (event is InputEventMouseButton):")
	var motion_block := board_input.substr(mouse_motion_pos, mouse_button_pos - mouse_motion_pos) if mouse_motion_pos >= 0 and mouse_button_pos > mouse_motion_pos else ""
	if motion_block.contains("_update_editor_ui("):
		_fail("Board mouse motion still directly calls full _update_editor_ui().")
		return
	if slider_view.contains("_update_editor_ui("):
		_fail("Dashboard slider drag still directly calls full _update_editor_ui().")
		return
	print("EDITOR_INPUT_NO_DIRECT_FULL_REFRESH_PROBE ok")
	quit(0)
