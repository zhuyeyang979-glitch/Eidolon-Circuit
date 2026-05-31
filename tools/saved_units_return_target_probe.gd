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
	var unit_bp: Dictionary = main._editor_current_blueprint()
	unit_bp["navigation_probe_marker"] = "preserve-me"
	main._show_saved_units_library("", "editor")
	if main.saved_units_return_context != MainScene.STATE_EDITOR:
		_fail("Saved units explicit return target should be editor.")
	if String(main.navigation_service.return_target()) != MainScene.STATE_EDITOR:
		_fail("Navigation return target should be editor.")
	main._page_options_back("saved_units")
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Saved units back should return to editor.")
	if String(main._editor_current_blueprint().get("navigation_probe_marker", "")) != "preserve-me":
		_fail("Editor canvas should be preserved when returning from saved units.")
	main._show_menu()
	main._show_saved_units_library("", "menu")
	if String(main.navigation_service.return_target()) != MainScene.STATE_MENU:
		_fail("Saved units opened from menu should carry menu return target.")
	main._page_options_back("saved_units")
	if main.game_state != MainScene.STATE_MENU:
		_fail("Saved units back should return to menu.")
	print("SAVED_UNITS_RETURN_TARGET_PROBE ok")
	quit(0)
