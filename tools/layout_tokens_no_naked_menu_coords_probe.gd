extends SceneTree

const MENU_VIEW_PATH := "res://scripts/views/menu_view.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string(MENU_VIEW_PATH)
	if source.is_empty():
		_fail("Could not read MenuView source.")
	var forbidden := [
		"Vector2(",
		"Rect2(",
		".position =",
		".size =",
		"_make_label(",
		"_add_ui_rect(",
	]
	var allowed_lines := {
		"control.position = screen_rect.position": true,
		"control.size = screen_rect.size": true,
		"control.position = local_rect.position": true,
		"control.size = local_rect.size": true,
		"viewport_size = main_ref._ui_viewport_size()": true,
	}
	var lines := source.split("\n")
	for i in range(lines.size()):
		var stripped := String(lines[i]).strip_edges()
		if allowed_lines.has(stripped):
			continue
		for token in forbidden:
			if stripped.contains(token):
				_fail("MenuView should not use naked layout token '%s' at line %d: %s" % [token, i + 1, stripped])
	print("LAYOUT_TOKENS_NO_NAKED_MENU_COORDS_PROBE ok")
	quit(0)
