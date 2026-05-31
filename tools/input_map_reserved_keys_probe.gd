extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _action_has_key(action_name: String, keycode: int) -> bool:
	if not InputMap.has_action(action_name):
		return false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			if code == keycode:
				return true
	return false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if _action_has_key("menu_confirm", KEY_ENTER) or _action_has_key("menu_confirm", KEY_KP_ENTER):
		_fail("menu_confirm must not contain Enter/KP Enter.")
	if _action_has_key("menu_back", KEY_ESCAPE):
		_fail("menu_back must not contain Escape.")
	if not _action_has_key("ui_numeric_submit", KEY_ENTER) or not _action_has_key("ui_numeric_submit", KEY_KP_ENTER):
		_fail("ui_numeric_submit must contain Enter and KP Enter.")
	if not _action_has_key("ui_detail_close", KEY_ESCAPE):
		_fail("ui_detail_close must contain Escape.")
	if not _action_has_key("battle_pause", KEY_ESCAPE):
		_fail("battle_pause must contain Escape.")
	print("INPUT_MAP_RESERVED_KEYS_PROBE ok")
	quit()
