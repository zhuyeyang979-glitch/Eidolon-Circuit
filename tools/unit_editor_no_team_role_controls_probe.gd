extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_panel_mode = "parts"
	main._update_editor_ui(true)
	for role_key in MainScene.ROLE_ORDER:
		if main.editor_role_buttons.has(role_key) and main.editor_role_buttons[role_key].visible:
			_fail("Role button should be hidden in Unit Edit: %s" % role_key)
	for action_key in ["edit_side", "load_team", "add_to_team", "import_team", "export_team", "clear_team", "toggle_match_format", "copy_ai", "initial", "sortie_toggle", "sortie_up", "sortie_down"]:
		if main.editor_action_buttons.has(action_key) and main.editor_action_buttons[action_key].visible:
			_fail("Team-only action should be hidden in Unit Edit: %s" % action_key)
	print("UNIT_EDITOR_NO_TEAM_ROLE_CONTROLS_PROBE ok")
	quit()
