extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main._gun_aim_input_mode_for_data({"module_action_profile": "gun_activate"}) != "turn_keys":
		_fail("Gun activation profiles should default to turn-key aim.")
	if main._gun_aim_input_mode_for_data({"turn_keys_steer_joint": true}) != "turn_keys":
		_fail("Legacy turn_keys_steer_joint modules should keep turn-key aim.")
	if main._gun_aim_input_mode_for_data({"gun_aim_input_mode": "direction_keys", "module_action_profile": "gun_activate"}) != "direction_keys":
		_fail("Explicit direction-key aim should override gun activation defaults.")
	if main._gun_aim_input_mode_for_data({"aim_mode": "manual", "projectile": true}) != "direction_keys":
		_fail("Manual projectile modules without turn-key ownership should remain direction-key aim.")
	var found_rifle := false
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == "rifle_burst_activate":
			found_rifle = true
			if String(part.get("gun_aim_input_mode", "")) != "turn_keys" or not bool(part.get("turn_keys_steer_joint", false)):
				_fail("Catalog rifle burst activation should advertise turn-key gun aim.")
			if String(part.get("summary", "")).find("移动键仍控制移动") < 0 and String(part.get("summary", "")).find("movement keys still move") < 0:
				_fail("Catalog rifle burst activation should explain that movement keys still move.")
			break
	if not found_rifle:
		_fail("Missing rifle burst activation module.")
	print("DIRECTION_KEY_AIM_POLICY_PROBE ok")
	quit()
