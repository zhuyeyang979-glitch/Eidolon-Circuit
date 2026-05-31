extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const MENU_VIEW_PATH := "res://scripts/views/menu_view.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _require_signal(object: Object, signal_name: String) -> void:
	if not object.has_signal(signal_name):
		_fail("MenuView missing signal: %s" % signal_name)


func _init() -> void:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MENU_VIEW_PATH))
	if source.is_empty():
		_fail("Could not read MenuView source.")
	for forbidden in ["_hover_menu_item", "_activate_menu_item", "_show_page_options", "_battle_runtime_menu_action", "_start_ai_battle_from_menu", "main_ref._add_ui_rect", "main_ref._make_label", "main_ref._set_named_label"]:
		if source.find(forbidden) >= 0:
			_fail("MenuView should emit intent signals instead of calling main private helper: %s" % forbidden)
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	var view = main.menu_view
	if view == null:
		_fail("Main scene did not create MenuView.")
	for signal_name in ["main_menu_hovered", "main_menu_pressed", "main_menu_gui_input", "ai_seat_pressed", "page_option_pressed", "battle_runtime_pressed"]:
		_require_signal(view, signal_name)
	var seen := {"main": false, "page": false, "runtime": false, "seat": false}
	view.main_menu_pressed.connect(func(_index: int) -> void: seen["main"] = true)
	view.page_option_pressed.connect(func(_key: String) -> void: seen["page"] = true)
	view.battle_runtime_pressed.connect(func(_key: String) -> void: seen["runtime"] = true)
	view.ai_seat_pressed.connect(func(_seat: int) -> void: seen["seat"] = true)
	if main.menu_buttons.is_empty() or main.page_options_buttons.is_empty() or main.battle_runtime_menu_buttons.is_empty() or main.menu_ai_seat_buttons.is_empty():
		_fail("MenuView should expose legacy button collections.")
	var main_button := main.menu_buttons[0] as Button
	var page_button := main.page_options_buttons["close"] as Button
	var runtime_button := main.battle_runtime_menu_buttons["continue"] as Button
	var seat_button := main.menu_ai_seat_buttons[0] as Button
	if main_button == null or page_button == null or runtime_button == null or seat_button == null:
		_fail("Legacy menu collections should contain Button controls.")
	main_button.pressed.emit()
	page_button.pressed.emit()
	runtime_button.pressed.emit()
	seat_button.pressed.emit()
	for key in seen.keys():
		if not bool(seen[key]):
			_fail("MenuView signal was not emitted for %s button path." % key)
	print("MENU_VIEW_SIGNAL_CONTRACT_PROBE ok")
	quit(0)
