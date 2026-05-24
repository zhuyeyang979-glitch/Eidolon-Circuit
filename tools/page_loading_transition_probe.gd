extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drain_loading(main, expected_state: String, max_ticks: int = 140) -> void:
	if String(main.game_state) != MainScene.STATE_LOADING:
		_fail("Expected loading before %s, got %s." % [expected_state, String(main.game_state)])
		return
	for _i in range(max_ticks):
		main.tick_loading_tasks(0.016, 6000)
		if String(main.game_state) != MainScene.STATE_LOADING:
			break
	if String(main.game_state) != expected_state:
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
	main._show_saved_units_library()
	_drain_loading(main, MainScene.STATE_SAVED_UNITS)
	main._show_settings()
	_drain_loading(main, MainScene.STATE_SETTINGS)
	main._show_scout(MainScene.MODE_AI)
	_drain_loading(main, MainScene.STATE_SCOUT)
	if int(main.loading_transition_count) < 4:
		_fail("Expected at least four page loading transitions.")
		return
	print("PAGE_LOADING_TRANSITION_PROBE ok transitions=%d completed=%d" % [int(main.loading_transition_count), int(main.loading_completed_count)])
	quit(0)
