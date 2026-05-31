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


func _tap_escape_for_battle(main: Node) -> void:
	Input.action_press("battle_pause")
	main._handle_battle_input(0.016)
	Input.action_release("battle_pause")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._commit_page_state(MainScene.STATE_BATTLE, "keyboard_escape_battle_pause_probe")
	main._set_visible_layer(main.hud_layer)
	if main.battle_runtime_menu_panel == null:
		_fail("Battle runtime menu panel missing.")
	if main.battle_runtime_menu_panel.visible:
		main._hide_battle_runtime_menu()
	_tap_escape_for_battle(main)
	if not main.battle_runtime_menu_panel.visible:
		_fail("Escape did not open the battle runtime menu.")
	_tap_escape_for_battle(main)
	if main.battle_runtime_menu_panel.visible:
		_fail("Escape did not close the battle runtime menu.")
	print("KEYBOARD_ESCAPE_BATTLE_PAUSE_PROBE ok")
	quit()
