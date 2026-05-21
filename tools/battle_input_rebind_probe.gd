extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _has_key(action_name: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_settings()
	main._begin_battle_input_rebind("p1_attack_6")
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.physical_keycode = KEY_P
	if not main._handle_battle_input_rebind_event(key_event):
		_fail("Rebind event was not consumed.")
	if not _has_key("p1_attack_6", KEY_P):
		_fail("P1 attack 6 was not rebound to P.")
	if not FileAccess.file_exists(MainScene.BATTLE_INPUT_BINDINGS_PATH):
		_fail("Battle input binding file was not written.")
	main._reset_battle_input_bindings_to_default()
	if not _has_key("p1_attack_6", KEY_L):
		_fail("Reset did not restore P1 attack 6 to L.")
	if FileAccess.file_exists(MainScene.BATTLE_INPUT_BINDINGS_PATH):
		_fail("Reset did not remove battle input binding file.")
	if failed:
		quit(1)
		return
	print("BATTLE_INPUT_REBIND_PROBE ok")
	quit()
