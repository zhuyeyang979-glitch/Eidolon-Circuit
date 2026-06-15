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
	main.loading_auto_transitions_enabled = false
	main._show_settings(true)
	if not main.settings_category_buttons.has("input"):
		_fail("Settings has no input category button.")
	else:
		(main.settings_category_buttons["input"] as Button).pressed.emit()
	if main.settings_scroll_container == null:
		_fail("Settings page has no scroll container.")
	var required_actions := [
		"p1_up", "p1_down", "p1_left", "p1_right",
		"p1_face_left", "p1_face_right",
		"p1_cool", "p1_portal",
		"p1_attack_1", "p1_attack_2", "p1_attack_3", "p1_attack_4", "p1_attack_5", "p1_attack_6",
		"p2_cool", "p2_portal",
	]
	for action_name in required_actions:
		if not InputMap.has_action(action_name):
			_fail("%s missing from InputMap." % action_name)
		if not main.battle_input_buttons.has(action_name):
			_fail("%s missing from battle input settings list." % action_name)
	var expected := [KEY_U, KEY_I, KEY_O, KEY_J, KEY_K, KEY_L]
	for i in range(expected.size()):
		if not _has_key("p1_attack_%d" % (i + 1), int(expected[i])):
			_fail("P1 attack %d lost default UIOJKL binding." % (i + 1))
	if not _has_key("p1_cool", KEY_G):
		_fail("P1 manual cooling lost default G binding.")
	if not _has_key("p1_portal", KEY_TAB):
		_fail("P1 tactical portal lost default Tab binding.")
	if failed:
		quit(1)
		return
	print("BATTLE_INPUT_SETTINGS_UI_PROBE ok")
	quit()
