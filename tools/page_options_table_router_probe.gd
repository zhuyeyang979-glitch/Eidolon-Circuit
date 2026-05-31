extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MenuControllerScript := preload("res://scripts/controllers/menu_controller.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	if main.page_options_buttons.size() != MenuControllerScript.PAGE_OPTION_SPECS.size():
		_fail("Page options should be generated from controller specs.")
	main._show_editor()
	main._show_settings()
	main._show_settings_category("input")
	main._show_page_options("settings")
	main._page_options_action("back")
	if main.game_state != MainScene.STATE_SETTINGS or main.settings_category != "root":
		_fail("Settings subroute back should be routed through table action to settings root.")
	main._show_page_options("settings")
	main._page_options_action("back")
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Settings root back should use navigation return target.")
	main._show_page_options("editor")
	main._page_options_action("close")
	if main.page_options_layer.visible:
		_fail("Close option should hide page options.")
	print("PAGE_OPTIONS_TABLE_ROUTER_PROBE ok")
	quit(0)
