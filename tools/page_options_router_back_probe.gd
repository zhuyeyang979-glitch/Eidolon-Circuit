extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor()
	main._show_saved_units_library("", "editor")
	main._show_page_options("saved_units")
	main._page_options_action("back")
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Saved units back should be routed to editor.")
	main._show_settings()
	main._show_settings_category("input")
	main._show_page_options("settings")
	main._page_options_action("back")
	if main.game_state != MainScene.STATE_SETTINGS or main.settings_category != "root":
		_fail("Settings subroute back should return to settings root.")
	main._show_page_options("settings")
	main._page_options_action("back")
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Settings root back should return to navigation return target.")
	main._show_scout(MainScene.MODE_AI)
	main._show_page_options("scout")
	main._page_options_action("back")
	if main.game_state != MainScene.STATE_MENU:
		_fail("Scout back should route to menu by default.")
	print("PAGE_OPTIONS_ROUTER_BACK_PROBE ok")
	quit(0)
