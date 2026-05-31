extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const UILayoutTokens := preload("res://scripts/ui_layout_tokens.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_global_rect(control: Control, expected: Rect2, label: String) -> void:
	var actual := control.get_global_rect()
	if actual.position.distance_to(expected.position) > 0.01 or actual.size.distance_to(expected.size) > 0.01:
		_fail("%s global rect mismatch: expected=%s actual=%s" % [label, str(expected), str(actual)])


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	await process_frame
	main._show_menu(true)
	await process_frame
	_assert_global_rect(main.menu_buttons[0], UILayoutTokens.main_menu_button_rect(0), "main menu first button")
	_assert_global_rect(main.menu_buttons[6], UILayoutTokens.main_menu_button_rect(6), "main menu last button")
	main._show_page_options("menu")
	await process_frame
	if main.page_options_layer == null or not main.page_options_layer.visible:
		_fail("Page options should be visible after explicit open.")
	_assert_global_rect(main.page_options_panel, UILayoutTokens.page_options_rect(), "page options panel")
	_assert_global_rect(main.page_options_buttons["close"], Rect2(UILayoutTokens.page_options_rect().position + UILayoutTokens.page_options_button_rect(4).position, UILayoutTokens.page_options_button_rect(4).size), "page options close")
	main._hide_page_options()
	main.battle_mode = MainScene.MODE_TRAINING
	main._toggle_battle_runtime_menu()
	await process_frame
	if main.battle_runtime_menu_panel == null or not main.battle_runtime_menu_panel.visible:
		_fail("Runtime menu should be visible after explicit toggle.")
	_assert_global_rect(main.battle_runtime_menu_panel, UILayoutTokens.battle_runtime_options_rect(), "runtime panel")
	_assert_global_rect(main.battle_runtime_menu_buttons["main_menu"], Rect2(UILayoutTokens.battle_runtime_options_rect().position + UILayoutTokens.battle_runtime_button_rect(7).position, UILayoutTokens.battle_runtime_button_rect(7).size), "runtime main menu")
	print("MENU_LAYOUT_REGRESSION_PROBE ok")
	quit(0)
