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


func _tap_escape(main: Node) -> void:
	var press := _key_event(KEY_ESCAPE, true)
	Input.parse_input_event(press)
	main._input(press)
	main._process(0.016)
	var release := _key_event(KEY_ESCAPE, false)
	Input.parse_input_event(release)


func _assert_state(main: Node, expected: String, label: String) -> void:
	if String(main.game_state) != expected:
		_fail("Escape navigated %s page from %s to %s." % [label, expected, String(main.game_state)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_saved_units_library("", "", false, true)
	_tap_escape(main)
	_assert_state(main, MainScene.STATE_SAVED_UNITS, "saved units")
	main._show_editor(true)
	_tap_escape(main)
	_assert_state(main, MainScene.STATE_EDITOR, "unit editor")
	main._show_scout(MainScene.MODE_TRAINING, true)
	_tap_escape(main)
	_assert_state(main, MainScene.STATE_SCOUT, "scout")
	main._show_settings(true)
	main._show_settings_category("video")
	_tap_escape(main)
	_assert_state(main, MainScene.STATE_SETTINGS, "settings")
	if String(main.settings_category) != "video":
		_fail("Escape changed settings category to %s." % String(main.settings_category))
	main._show_editor(true)
	main._show_page_options("editor")
	if main.page_options_layer == null or not main.page_options_layer.visible:
		_fail("Page Options did not open for Escape probe.")
	_tap_escape(main)
	_assert_state(main, MainScene.STATE_EDITOR, "page options")
	if main.page_options_layer == null or not main.page_options_layer.visible:
		_fail("Escape should not close Page Options; use the visible Close button.")
	print("KEYBOARD_ESCAPE_RESERVED_ALL_PAGES_PROBE ok")
	quit()
