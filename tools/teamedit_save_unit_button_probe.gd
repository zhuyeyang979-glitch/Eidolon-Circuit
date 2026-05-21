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
	if not main.editor_action_buttons.has("save_canvas"):
		_fail("TeamEdit should have a fixed Save Unit action.")
	var save_button: Button = main.editor_action_buttons["save_canvas"]
	if not save_button.visible:
		_fail("Save Unit action should be visible in TeamEdit.")
	var bp: Dictionary = main._editor_current_blueprint()
	bp["custom_topology"] = main._default_free_canvas_topology("hero")
	bp["blank_canvas"] = false
	bp["unit_name"] = "Probe Saved Units Jump"
	var path := "user://saved_units/probe_saved_units_jump.json"
	var saved_path := main._save_editor_current_unit_to_library(path)
	if saved_path != path:
		_fail("Save Unit should write the requested unit path.")
	main._show_saved_units_library(path)
	if main.game_state != MainScene.STATE_SAVED_UNITS:
		_fail("Saved unit jump should open the Saved Units page.")
	if main.saved_unit_selected_index < 0:
		_fail("Saved unit jump should focus the newly saved unit.")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("TEAMEDIT_SAVE_UNIT_BUTTON_PROBE ok path=%s" % path)
	quit()
