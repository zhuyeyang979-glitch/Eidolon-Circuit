extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drain_loading(main: Node, expected_state: String, max_ticks: int = 160) -> void:
	if main.game_state != MainScene.STATE_LOADING:
		_fail("Expected loading state before %s, got %s." % [expected_state, String(main.game_state)])
	for _i in range(max_ticks):
		main.tick_loading_tasks(0.016, 6000)
		if main.game_state != MainScene.STATE_LOADING:
			break
	if main.game_state != expected_state:
		_fail("Loading target mismatch. expected=%s actual=%s" % [expected_state, String(main.game_state)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = true
	if main.game_state == MainScene.STATE_LOADING:
		_drain_loading(main, MainScene.STATE_MENU)
	main._show_editor()
	_drain_loading(main, MainScene.STATE_EDITOR)
	main._show_saved_units_library("", "editor")
	var begin_snapshot: Dictionary = main.navigation_service.snapshot()
	var pending: Dictionary = begin_snapshot.get("pending_transition", {})
	if String(pending.get("from_page", "")) != MainScene.STATE_EDITOR:
		_fail("Loading pending transition should remember editor as from_page.")
	if String(pending.get("to_page", "")) != MainScene.STATE_SAVED_UNITS:
		_fail("Loading pending transition should target saved units.")
	if String(pending.get("return_target", "")) != MainScene.STATE_EDITOR:
		_fail("Loading pending transition should carry explicit return target.")
	_drain_loading(main, MainScene.STATE_SAVED_UNITS)
	var snapshot: Dictionary = main.navigation_service.snapshot()
	if String(snapshot.get("current_page", "")) != MainScene.STATE_SAVED_UNITS:
		_fail("Navigation should commit loaded target page.")
	if String(snapshot.get("return_target", "")) != MainScene.STATE_EDITOR:
		_fail("Navigation should keep loaded return target.")
	print("LOADING_NAVIGATION_CONTRACT_PROBE ok")
	quit(0)
