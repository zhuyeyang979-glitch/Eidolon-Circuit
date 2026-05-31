extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _entry_exists(main: Node, path: String) -> bool:
	for raw_entry in main._unit_library_entries():
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("path", "")) == path:
			return true
	return false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)
	var unit_name := "Real UI Save Probe %d" % int(Time.get_ticks_msec())
	var bp: Dictionary = main._editor_current_blueprint()
	bp["custom_topology"] = main._default_free_canvas_topology("hero")
	bp["blank_canvas"] = false
	bp["unit_name"] = unit_name
	if not main.editor_action_buttons.has("save_canvas"):
		_fail("Save Unit button missing.")
		return
	var save_canvas_button: Button = main.editor_action_buttons["save_canvas"]
	save_canvas_button.pressed.emit()
	if main.editor_save_unit_name_panel == null or not main.editor_save_unit_name_panel.visible:
		_fail("Save name panel did not open.")
		return
	for role_key in MainScene.ROLE_ORDER:
		var role_button = main.editor_save_unit_role_buttons.get(role_key, null)
		if not (role_button is Button):
			_fail("Save dialog missing role confirmation button for %s." % role_key)
			return
		var button: Button = role_button
		var should_be_current: bool = String(role_key) == "hero"
		if button.disabled == should_be_current:
			_fail("Save dialog role button enabled/disabled state mismatch for %s." % role_key)
			return
	main.editor_save_unit_name_edit.text = unit_name
	var raw_save_button: Node = main.editor_save_unit_name_panel.get_node_or_null("save_name_stay")
	if not (raw_save_button is Button):
		_fail("Save confirm button missing.")
		return
	var save_button: Button = raw_save_button
	save_button.pressed.emit()
	var saved_path := String(main.editor_source_saved_unit_path)
	if saved_path == "" or not FileAccess.file_exists(saved_path):
		_fail("Save confirm did not create a saved-unit file: %s." % saved_path)
		return
	var payload = JSON.parse_string(FileAccess.get_file_as_string(saved_path))
	if not (payload is Dictionary):
		_fail("Saved unit payload is damaged JSON.")
		return
	if String(Dictionary(payload).get("unit_role", "")) != "hero" or String(Dictionary(payload).get("save_kind", "")) != MainScene.SAVE_KIND_SINGLE_UNIT:
		_fail("Saved unit payload should confirm current hero single-unit type: %s." % str(payload))
		return
	if main.editor_save_unit_feedback_label == null or String(main.editor_save_unit_feedback_label.text).find(unit_name) < 0:
		_fail("Save feedback did not mention the saved unit.")
		return
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Saving should keep the player on Unit Edit.")
		return
	if not main.editor_action_buttons.has("open_saved_units"):
		_fail("Open Saved Units button missing.")
		return
	var open_button: Button = main.editor_action_buttons["open_saved_units"]
	open_button.pressed.emit()
	if main.game_state != MainScene.STATE_SAVED_UNITS:
		_fail("Saved Units button did not open the library.")
		return
	if not _entry_exists(main, saved_path):
		_fail("Saved unit was not visible immediately after opening Saved Units.")
		return
	if main.saved_unit_selected_index < 0:
		_fail("Saved unit should be focused in the library.")
		return
	if not main._load_saved_unit_into_unit_editor(saved_path):
		_fail("Saved unit could not be loaded back into Unit Edit.")
		return
	var loaded: Dictionary = main._editor_current_blueprint()
	if String(loaded.get("unit_name", "")) != unit_name:
		_fail("Loaded unit name mismatch.")
		return
	if FileAccess.file_exists(saved_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(saved_path))
	print("TEAMEDIT_SAVE_UNIT_REAL_UI_PROBE ok path=%s" % saved_path)
	quit(0)
