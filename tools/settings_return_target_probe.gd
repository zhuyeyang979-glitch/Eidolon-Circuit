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
	main._show_settings()
	if String(main.navigation_service.return_target()) != MainScene.STATE_EDITOR:
		_fail("Settings opened from editor should remember editor return target.")
	main._page_options_back("settings")
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Back from settings should return to editor.")
	main._begin_battle(MainScene.MODE_TRAINING, true)
	main._show_settings()
	if String(main.navigation_service.return_target()) != MainScene.STATE_BATTLE:
		_fail("Settings opened from battle should remember battle return target.")
	main._page_options_back("settings")
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Back from settings should return to battle without resetting.")
	print("SETTINGS_RETURN_TARGET_PROBE ok")
	quit(0)
