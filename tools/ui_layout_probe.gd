extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const DESIGN_RECT := Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	var reports: Array = []
	for language in ["zh", "en"]:
		main.ui_language = language
		main._apply_language_to_existing_ui()
		var views := [
			["menu", Callable(main, "_show_menu")],
			["saved_units", Callable(main, "_show_saved_units_library")],
			["editor", Callable(self, "_show_editor_panel").bind(main, "parts")],
			["editor_shop", Callable(self, "_show_editor_panel").bind(main, "shop")],
			["editor_stats", Callable(self, "_show_editor_panel").bind(main, "stats")],
			["settings", Callable(main, "_show_settings")],
			["scout", Callable(main, "_show_scout").bind(main.MODE_AI)],
		]
		for view in views:
			view[1].call()
			await process_frame
			reports.append(_scan_view(main, "%s/%s" % [language, String(view[0])]))
	var hard_failures := 0
	for report in reports:
		hard_failures += int(report.get("hard", 0))
		print("UI_LAYOUT %s controls=%d overlap=%d out=%d hard=%d" % [
			String(report.get("view", "")),
			int(report.get("controls", 0)),
			int(report.get("overlap", 0)),
			int(report.get("out", 0)),
			int(report.get("hard", 0)),
		])
	quit(1 if hard_failures > 0 else 0)


func _show_editor_panel(main, panel_mode: String) -> void:
	main._show_editor()
	main.editor_panel_mode = panel_mode
	main._update_editor_ui()


func _scan_view(root_node: Node, view_name: String) -> Dictionary:
	var controls := _collect_controls(root_node)
	var out_count := 0
	var hard := 0
	for item in controls:
		var rect: Rect2 = item.get("rect", Rect2())
		if rect.size.x <= 2.0 or rect.size.y <= 2.0:
			continue
		if bool(item.get("inside_scroll", false)):
			continue
		if not DESIGN_RECT.encloses(rect.grow(-1.0)):
			out_count += 1
			if item.get("kind", "") == "Button":
				hard += 1
	var overlap_count := 0
	var hard_examples: Array = []
	var soft_examples: Array = []
	for i in range(controls.size()):
		for j in range(i + 1, controls.size()):
			var a: Dictionary = controls[i]
			var b: Dictionary = controls[j]
			if a.get("layer", "") != b.get("layer", ""):
				continue
			if bool(a.get("inside_scroll", false)) or bool(b.get("inside_scroll", false)):
				continue
			if a.get("parent", null) == b.get("node", null) or b.get("parent", null) == a.get("node", null):
				continue
			var rect_a: Rect2 = a.get("rect", Rect2())
			var rect_b: Rect2 = b.get("rect", Rect2())
			var overlap := rect_a.intersection(rect_b)
			if overlap.size.x * overlap.size.y > 120.0:
				overlap_count += 1
				if a.get("kind", "") == "Button" and b.get("kind", "") == "Button":
					hard += 1
					if hard_examples.size() < 8:
						hard_examples.append("%s %s <-> %s %s" % [String((a.get("node", null) as Node).name), str(a.get("rect", Rect2())), String((b.get("node", null) as Node).name), str(b.get("rect", Rect2()))])
				elif soft_examples.size() < 8:
					soft_examples.append("%s %s <-> %s %s" % [String((a.get("node", null) as Node).name), str(a.get("rect", Rect2())), String((b.get("node", null) as Node).name), str(b.get("rect", Rect2()))])
	if hard_examples.size() > 0:
		print("UI_LAYOUT_HARD %s %s" % [view_name, " | ".join(hard_examples)])
	if soft_examples.size() > 0:
		print("UI_LAYOUT_SOFT %s %s" % [view_name, " | ".join(soft_examples)])
	return {"view": view_name, "controls": controls.size(), "overlap": overlap_count, "out": out_count, "hard": hard}


func _collect_controls(node: Node, layer_name: String = "") -> Array:
	var result: Array = []
	var current_layer := layer_name
	if node is CanvasLayer:
		current_layer = node.name
	if node is Button or node is Label:
		var control := node as Control
		if control.visible and control.is_visible_in_tree():
			result.append({
				"node": control,
				"parent": control.get_parent(),
				"kind": control.get_class(),
				"layer": current_layer,
				"rect": control.get_global_rect(),
				"inside_scroll": _is_inside_scroll_container(control),
			})
	for child in node.get_children():
		result.append_array(_collect_controls(child, current_layer))
	return result


func _is_inside_scroll_container(control: Control) -> bool:
	var node := control.get_parent()
	while node != null:
		if node is ScrollContainer:
			return true
		node = node.get_parent()
	return false
