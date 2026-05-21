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
	var expected := [KEY_U, KEY_I, KEY_O, KEY_J, KEY_K, KEY_L]
	var old_keys := [KEY_F, KEY_R, KEY_T, KEY_C, KEY_V, KEY_B]
	for i in range(expected.size()):
		var action_name := "p1_attack_%d" % (i + 1)
		if not _has_key(action_name, int(expected[i])):
			_fail("%s is not bound to the expected UIOJKL key." % action_name)
		for old_key in old_keys:
			if _has_key(action_name, int(old_key)):
				_fail("%s still contains an old keyboard attack binding." % action_name)
	if failed:
		quit(1)
		return
	print("KEYBOARD_ATTACK_MAPPING_PROBE ok")
	quit()
