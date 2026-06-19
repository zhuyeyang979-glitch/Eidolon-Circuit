extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const AssemblyTemplateOverlayRenderer := preload("res://scripts/views/editor/assembly_template_overlay_renderer.gd")

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))


func _init() -> void:
	var renderer := AssemblyTemplateOverlayRenderer.new()
	if not renderer.has_method("toggle_button_rect"):
		_fail("Assembly template renderer should expose toggle_button_rect for fold interaction.")
	if not renderer.has_method("overlay_panel_rect"):
		_fail("Assembly template renderer should expose overlay_panel_rect.")
	if not renderer.has_method("collapsed_panel_rect"):
		_fail("Assembly template renderer should expose collapsed_panel_rect for the compact strip.")
	if renderer.has_method("overlay_panel_rect") and renderer.has_method("collapsed_panel_rect"):
		var expanded: Rect2 = renderer.overlay_panel_rect(Vector2(908.0, 548.0))
		var collapsed: Rect2 = renderer.collapsed_panel_rect(Vector2(908.0, 548.0))
		if collapsed.size.y > 48.0:
			_fail("Collapsed assembly template should be a compact strip, got height %.1f." % collapsed.size.y)
		if collapsed.get_area() > expanded.get_area() * 0.32:
			_fail("Collapsed assembly template should free most image space, got area %.1f vs %.1f." % [collapsed.get_area(), expanded.get_area()])
		if renderer.has_method("toggle_button_rect"):
			var expanded_toggle: Rect2 = renderer.toggle_button_rect(Vector2(908.0, 548.0), false)
			var collapsed_toggle: Rect2 = renderer.toggle_button_rect(Vector2(908.0, 548.0), true)
			if not expanded.encloses(expanded_toggle):
				_fail("Expanded toggle button should live inside expanded template panel.")
			if not collapsed.encloses(collapsed_toggle):
				_fail("Collapsed toggle button should live inside collapsed template strip.")
	var main_source := _source("res://scripts/main.gd")
	if main_source.find("editor_assembly_template_collapsed") < 0:
		_fail("Main editor should keep a local editor_assembly_template_collapsed UI state.")
	if main_source.find("_try_toggle_editor_assembly_template") < 0:
		_fail("Main editor should intercept clicks on the assembly template fold button.")
	if failed:
		quit(1)
		return
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var model := {
		"title": "组装模板",
		"status": "warn",
		"signature": "fold-probe",
		"slots": [],
		"warnings": [],
		"warning_count": 0,
	}
	var snapshot := {
		"nodes": [],
		"edges": [],
		"assembly_template_model": model,
		"assembly_template_signature": "fold-probe",
		"revision_key": "fold-probe",
	}
	main.set("editor_assembly_template_collapsed", false)
	main.assembly_board_view.set_board(snapshot, "", {}, "", 0.0, "custom", "zh", 0.0, "fold-probe")
	var click_rect: Rect2 = renderer.toggle_button_rect(main.assembly_board_view.size, false)
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = click_rect.get_center()
	main._handle_editor_board_input(click_event)
	if not bool(main.get("editor_assembly_template_collapsed")):
		_fail("Clicking the fold button should toggle editor_assembly_template_collapsed.")
	var updated_model = main.assembly_board_view.board_snapshot.get("assembly_template_model", {})
	if not (updated_model is Dictionary) or not bool(Dictionary(updated_model).get("collapsed", false)):
		_fail("Fold click should update the current board snapshot template model.")
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_ASSEMBLY_TEMPLATE_FOLD_PROBE ok")
	quit(0)
