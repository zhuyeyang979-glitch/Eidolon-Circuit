extends SceneTree

const MainScene := preload("res://scenes/main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	var failures: Array = []
	for language in ["zh", "en"]:
		main.ui_language = language
		main._apply_language_to_existing_ui()
		var views := [
			["menu", Callable(main, "_show_menu")],
			["saved_units", Callable(main, "_show_saved_units_library")],
			["editor_parts", Callable(self, "_show_editor_panel").bind(main, "parts", "unit")],
			["editor_load_team", Callable(self, "_show_editor_panel").bind(main, "load", "team")],
			["editor_load_unit", Callable(self, "_show_editor_panel").bind(main, "load", "unit")],
			["editor_shop", Callable(self, "_show_editor_panel").bind(main, "shop", "unit")],
			["editor_stats", Callable(self, "_show_editor_panel").bind(main, "stats", "unit")],
			["settings", Callable(main, "_show_settings")],
			["scout", Callable(main, "_show_scout").bind(main.MODE_AI)],
		]
		for view in views:
			view[1].call()
			await process_frame
			var bad := []
			_collect_overflow(main, "%s/%s" % [language, String(view[0])], bad)
			print("TEXT_OVERFLOW %s/%s count=%d" % [language, String(view[0]), bad.size()])
			failures.append_array(bad)
	for i in range(mini(12, failures.size())):
		print("TEXT_OVERFLOW_BAD %s" % String(failures[i]))
	quit(1 if failures.size() > 0 else 0)


func _show_editor_panel(main, panel_mode: String, load_mode: String = "unit") -> void:
	main._show_editor()
	main.editor_panel_mode = panel_mode
	main.editor_load_mode = load_mode
	main._update_editor_ui()


func _collect_overflow(node: Node, view_name: String, bad: Array) -> void:
	if node is Label or node is Button:
		var control := node as Control
		if control.visible and control.is_visible_in_tree() and not _inside_scroll(control):
			var text := _control_text(control).strip_edges()
			if text != "" and _control_text_overflows(control, text):
				bad.append("%s %s size=%s text=%s" % [view_name, String(control.name), str(control.size), text.substr(0, 96)])
	for child in node.get_children():
		_collect_overflow(child, view_name, bad)


func _inside_scroll(control: Control) -> bool:
	var current := control.get_parent()
	while current != null:
		if current is ScrollContainer:
			return true
		current = current.get_parent()
	return false


func _control_text(control: Control) -> String:
	if control is Label:
		return (control as Label).text
	if control is Button:
		return (control as Button).text
	return ""


func _control_font_size(control: Control) -> float:
	var font_size := 12.0
	if control is Label:
		font_size = float((control as Label).get_theme_font_size("font_size"))
	elif control is Button:
		font_size = float((control as Button).get_theme_font_size("font_size"))
	return clampf(font_size, 9.0, 42.0)


func _control_text_overflows(control: Control, text: String) -> bool:
	var font_size := _control_font_size(control)
	var char_width := maxf(5.6, font_size * 0.56)
	var line_height := font_size + 5.0
	var available_w := maxf(8.0, control.size.x - 8.0)
	var available_h := maxf(8.0, control.size.y - 5.0)
	var visual_lines := 0
	var max_line_width := 0.0
	for raw_line in text.split("\n"):
		var line := String(raw_line)
		var estimated_w := float(line.length()) * char_width
		max_line_width = maxf(max_line_width, estimated_w)
		var wraps := 1
		if control is Label and (control as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
			wraps = maxi(1, int(ceilf(estimated_w / available_w)))
		visual_lines += wraps
	var estimated_h := float(maxi(1, visual_lines)) * line_height
	if estimated_h > available_h + 3.0:
		return true
	if control is Button:
		return max_line_width > available_w + 3.0
	if control is Label and (control as Label).autowrap_mode == TextServer.AUTOWRAP_OFF:
		return max_line_width > available_w + 3.0
	return false
