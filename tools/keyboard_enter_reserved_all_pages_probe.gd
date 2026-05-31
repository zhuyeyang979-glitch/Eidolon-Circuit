extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _key_event(keycode: int, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _tap_enter(main: Node) -> void:
	var press := _key_event(KEY_ENTER, true)
	Input.parse_input_event(press)
	main._input(press)
	main._process(0.016)
	var release := _key_event(KEY_ENTER, false)
	Input.parse_input_event(release)


func _assert_state(main: Node, expected: String, label: String) -> void:
	if String(main.game_state) != expected:
		_fail("Enter changed %s page from %s to %s." % [label, expected, String(main.game_state)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_menu(true)
	_tap_enter(main)
	_assert_state(main, MainScene.STATE_MENU, "main menu")
	main._show_saved_units_library("", "", false, true)
	_tap_enter(main)
	_assert_state(main, MainScene.STATE_SAVED_UNITS, "saved units")
	main._show_editor(true)
	if main.engine_momentum_allocation_view != null:
		main._close_engine_momentum_allocation_panel()
	_tap_enter(main)
	_assert_state(main, MainScene.STATE_EDITOR, "unit editor")
	if main.engine_momentum_allocation_view != null and main.engine_momentum_allocation_view.visible:
		_fail("Enter without numeric focus opened allocation panel.")
	main._show_scout(MainScene.MODE_TRAINING, true)
	_tap_enter(main)
	_assert_state(main, MainScene.STATE_SCOUT, "scout")
	main._show_settings(true)
	var before_category := String(main.settings_category)
	_tap_enter(main)
	_assert_state(main, MainScene.STATE_SETTINGS, "settings")
	if String(main.settings_category) != before_category:
		_fail("Enter activated a Settings row: %s -> %s." % [before_category, String(main.settings_category)])
	main._commit_page_state(MainScene.STATE_BATTLE, "keyboard_enter_probe")
	main.game_over = true
	_tap_enter(main)
	_assert_state(main, MainScene.STATE_BATTLE, "battle game-over")
	print("KEYBOARD_ENTER_RESERVED_ALL_PAGES_PROBE ok")
	quit()
