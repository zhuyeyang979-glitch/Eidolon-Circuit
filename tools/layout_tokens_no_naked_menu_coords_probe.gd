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
		"control.position = rect.position": true,
		"control.size = rect.size": true,
		"return main_ref._make_label(parent, node_name, text, rect.position, rect.size, font_size, color, align)": true,
		"return main_ref._add_ui_rect(parent, node_name, rect.position, rect.size, color)": true,
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
