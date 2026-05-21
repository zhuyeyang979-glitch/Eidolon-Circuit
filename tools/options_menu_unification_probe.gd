extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _button_text(main: Node, layer: CanvasLayer, button_name: String) -> String:
	var button := main._find_control_by_name(layer, button_name) as Button
	if button == null:
		_fail("Missing button: %s" % button_name)
	return button.text


func _assert_options_button(main: Node, layer: CanvasLayer, button_name: String) -> void:
	var text := _button_text(main, layer, button_name)
	if text != "选项" and text != "OPTIONS":
		_fail("%s should be unified options button, got '%s'" % [button_name, text])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_saved_units_library()
	_assert_options_button(main, main.saved_units_layer, "SavedUnitsBackButton")
	main._show_page_options("saved_units")
	if main.page_options_layer == null or not main.page_options_layer.visible:
		_fail("Saved units options menu did not open.")
	for key in ["back", "main_menu", "settings", "help", "close"]:
		if not main.page_options_buttons.has(key):
			_fail("Options menu missing action: %s" % key)
	main._page_options_action("settings")
	if main.game_state != MainScene.STATE_SETTINGS:
		_fail("Options/settings should open settings page.")
	main._show_settings_category("input")
	main._show_page_options("settings")
	main._page_options_action("back")
	if main.game_state != MainScene.STATE_SETTINGS or main.settings_category != "root":
		_fail("Options/back from settings subpage should return to settings root.")
	main._show_editor()
	_assert_options_button(main, main.editor_layer, "EditorBackButton")
	main._show_training_config(true)
	_assert_options_button(main, main.scout_layer, "ScoutMenuButton")
	main._show_settings()
	_assert_options_button(main, main.settings_layer, "SettingsBackButton")
	main._show_page_options("settings")
	main._page_options_action("main_menu")
	if main.game_state != MainScene.STATE_MENU:
		_fail("Options/main menu should return to main menu.")
	print("OPTIONS_MENU_UNIFICATION_PROBE ok")
	quit()
