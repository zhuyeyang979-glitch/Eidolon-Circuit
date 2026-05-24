extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _send_enter_to_input_map(main) -> void:
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	Input.parse_input_event(enter)
	main._input(enter)
	main._process(0.016)
	var release := InputEventKey.new()
	release.keycode = KEY_ENTER
	release.physical_keycode = KEY_ENTER
	release.pressed = false
	Input.parse_input_event(release)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Editor did not open before Enter test.")
	if main.engine_momentum_allocation_view != null:
		main._close_engine_momentum_allocation_panel()
	_send_enter_to_input_map(main)
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Enter in Unit Edit navigated away: %s" % String(main.game_state))
	if main.engine_momentum_allocation_view != null and main.engine_momentum_allocation_view.visible:
		_fail("Enter in Unit Edit unexpectedly opened the power allocation panel.")
	print("UNIT_EDITOR_ENTER_NO_NAVIGATION_PROBE ok")
	quit()
