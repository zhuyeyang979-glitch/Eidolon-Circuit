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
	main._update_editor_ui()
	for key in ["save_canvas", "training_import", "open_saved_units"]:
		if not main.editor_action_buttons.has(key):
			_fail("Missing core board action: %s" % key)
		var button: Button = main.editor_action_buttons[key]
		if not button.visible or button.disabled:
			_fail("Core board action is not usable: %s" % key)
	var summary_lines: PackedStringArray = main.editor_summary_label.text.split("\n")
	if summary_lines.size() > 2:
		_fail("Editor summary still uses long explanatory copy.")
	if main.editor_unit_label.text.find("悬停") >= 0 or main.editor_unit_label.text.find("Hover") >= 0:
		_fail("Unit label still contains hover instruction copy.")
	print("TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=%d" % summary_lines.size())
	quit()
