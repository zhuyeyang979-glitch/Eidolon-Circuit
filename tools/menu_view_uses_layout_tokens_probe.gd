extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const UILayoutTokens := preload("res://scripts/ui_layout_tokens.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_rect(control: Control, expected: Rect2, label: String) -> void:
	var actual := Rect2(control.position, control.size)
	if actual.position.distance_to(expected.position) > 0.01 or actual.size.distance_to(expected.size) > 0.01:
		_fail("%s rect mismatch: expected=%s actual=%s" % [label, str(expected), str(actual)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	if main.menu_view == null:
		_fail("MenuView should be initialized.")
	if main.menu_buttons.size() < 2:
		_fail("Main menu buttons should be generated.")
	_assert_rect(main.menu_buttons[0], UILayoutTokens.main_menu_button_rect(0), "main menu button 0")
	_assert_rect(main.menu_buttons[1], UILayoutTokens.main_menu_button_rect(1), "main menu button 1")
	if main.menu_ai_seat_buttons.size() != 3:
		_fail("AI seat buttons should be generated.")
	_assert_rect(main.menu_ai_seat_buttons[2], UILayoutTokens.main_menu_ai_seat_button_rect(2), "AI seat button 2")
	_assert_rect(main.page_options_panel, UILayoutTokens.page_options_rect(), "page options panel")
	_assert_rect(main.page_options_buttons["settings"], UILayoutTokens.page_options_button_rect(2), "page options settings button")
	_assert_rect(main.battle_runtime_menu_panel, UILayoutTokens.battle_runtime_options_rect(), "runtime options panel")
	_assert_rect(main.battle_runtime_menu_buttons["dummy_state"], UILayoutTokens.battle_runtime_button_rect(3), "runtime dummy button")
	var title := main.menu_layer.find_child("GameTitle", true, false) as Control
	if title == null:
		_fail("GameTitle should exist.")
	_assert_rect(title, UILayoutTokens.main_menu_title_rect(), "main menu title")
	print("MENU_VIEW_USES_LAYOUT_TOKENS_PROBE ok")
	quit(0)
