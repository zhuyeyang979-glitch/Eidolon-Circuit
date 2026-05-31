extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_nav(main: Node, expected_page: String, expected_reason: String, expected_return: String = "") -> void:
	if main.navigation_service == null:
		_fail("Navigation service was not initialized.")
	var snapshot: Dictionary = main.navigation_service.snapshot()
	if String(snapshot.get("current_page", "")) != expected_page:
		_fail("Navigation current page mismatch. expected=%s actual=%s" % [expected_page, String(snapshot.get("current_page", ""))])
	var last: Dictionary = snapshot.get("last_transition", {})
	if String(last.get("to_page", "")) != expected_page:
		_fail("Navigation last to_page mismatch. expected=%s actual=%s" % [expected_page, String(last.get("to_page", ""))])
	if String(last.get("reason", "")) != expected_reason:
		_fail("Navigation reason mismatch. expected=%s actual=%s" % [expected_reason, String(last.get("reason", ""))])
	if expected_return != "" and String(snapshot.get("return_target", "")) != expected_return:
		_fail("Navigation return target mismatch. expected=%s actual=%s" % [expected_return, String(snapshot.get("return_target", ""))])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor()
	_assert_nav(main, MainScene.STATE_EDITOR, "teamedit")
	main._show_saved_units_library("", "editor")
	_assert_nav(main, MainScene.STATE_SAVED_UNITS, "saved_units", MainScene.STATE_EDITOR)
	main._page_options_back("saved_units")
	_assert_nav(main, MainScene.STATE_EDITOR, "teamedit_preserve")
	main._show_settings()
	_assert_nav(main, MainScene.STATE_SETTINGS, "settings", MainScene.STATE_EDITOR)
	main._show_scout(MainScene.MODE_AI)
	_assert_nav(main, MainScene.STATE_SCOUT, "scout:%s" % MainScene.MODE_AI)
	main._begin_battle(MainScene.MODE_AI, true)
	_assert_nav(main, MainScene.STATE_BATTLE, "battle:%s" % MainScene.MODE_AI)
	print("NAVIGATION_SERVICE_CONTRACT_PROBE ok")
	quit(0)
