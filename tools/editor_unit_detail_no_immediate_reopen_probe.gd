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
	main._close_editor_unit_detail()
	if main.editor_unit_hover_view.visible:
		_fail("Pinned unit detail did not close.")
		return
	main._show_editor_empty_slot_hover(0, false)
	if main.editor_unit_hover_view.visible:
		_fail("Transient hover immediately reopened the just-closed unit detail.")
		return
	main._show_editor_empty_slot_hover(1, false)
	if main.editor_unit_hover_view == null or not main.editor_unit_hover_view.visible:
		_fail("Different unit detail token should still be allowed after suppressing the closed one.")
		return
	if bool(main.editor_unit_detail_pinned):
		_fail("Transient hover reopened as pinned detail.")
		return
	print("EDITOR_UNIT_DETAIL_NO_IMMEDIATE_REOPEN_PROBE ok")
	quit()
