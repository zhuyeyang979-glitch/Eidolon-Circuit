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
	main.ui_language = MainScene.UI_LANGUAGE_ZH
	main._apply_language_to_existing_ui()
	if not String((main.menu_buttons[0] as Button).text).contains("开始训练"):
		_fail("Chinese main menu text should come from menu table.")
	if String((main.page_options_buttons["settings"] as Button).text) != "设置":
		_fail("Chinese page options text should come from menu table.")
	main.battle_mode = MainScene.MODE_TRAINING
	main._update_battle_runtime_menu_ui()
	if not String((main.battle_runtime_menu_buttons["training_config"] as Button).text).contains("训练"):
		_fail("Chinese runtime options text should come from menu table.")
	main.ui_language = MainScene.UI_LANGUAGE_EN
	main._apply_language_to_existing_ui()
	if not String((main.menu_buttons[0] as Button).text).contains("TRAINING"):
		_fail("English main menu text should come from menu table.")
	if String((main.page_options_buttons["settings"] as Button).text) != "SETTINGS":
		_fail("English page options text should come from menu table.")
	main._update_battle_runtime_menu_ui()
	if String((main.battle_runtime_menu_buttons["training_config"] as Button).text) != "TRAINING CFG":
		_fail("English runtime options text should come from menu table.")
	print("MENU_LANGUAGE_TABLE_PROBE ok")
	quit(0)
