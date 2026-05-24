extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	_release_actions()
	quit(1)


func _release_actions() -> void:
	for action in ["p1_up", "p1_down", "p1_left", "p1_right", "p1_attack_1"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _make_main():
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.mobius_enabled = true
	main.camera_center = 5.0
	main.camera_lane_center = 0.0
	main._sync_camera_mobius_from_compat()
	return main


func _make_unit():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 12.0,
			"move_speed": 4.0,
			"body_move_speed": 4.0,
			"move_acceleration": 30.0,
			"thruster_acceleration": 30.0,
			"movement_profile": "car",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(5.0, 0.0)
	return unit


func _install_unit(main, unit) -> void:
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit


func _assert_vertical_move(main, unit, action_name: String, expected_sign: float, label: String) -> void:
	_release_actions()
	Input.action_press(action_name)
	await process_frame
	main._handle_player_battle_input(1, 0.16, "p1")
	if signf(unit.velocity.y) != expected_sign:
		_fail("%s should not block vertical movement; velocity.y=%.4f." % [label, unit.velocity.y])
	unit.tick(0.16, MainScene.RING_LENGTH)
	if signf(unit.mobius_v) != expected_sign or signf(unit.lane) != expected_sign:
		_fail("%s should advance mobius_v/lane; mobius_v=%.4f lane=%.4f." % [label, unit.mobius_v, unit.lane])


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = _make_main()
	var unit = _make_unit()
	_install_unit(main, unit)

	main.attack_command_windows[1] = {
		"0": {
			"attack_index": 0,
			"attack_key": 1,
			"prefix": "p1",
			"binding": {},
			"timer": 10.0,
			"hold_time": 0.0,
		},
	}
	await _assert_vertical_move(main, unit, "p1_down", 1.0, "Attack command window")

	unit.deploy(5.0, 0.0)
	unit.velocity = Vector2.ZERO
	main.attack_command_windows[1] = {}
	main.gun_activation_state[1] = {
		"action_name": "p1_attack_1",
		"activation_semantic": "release_web",
		"aim_direction": Vector2.RIGHT,
		"binding": {},
		"hold_time": 0.0,
	}
	_release_actions()
	Input.action_press("p1_attack_1")
	Input.action_press("p1_up")
	await process_frame
	main._handle_player_battle_input(1, 0.16, "p1")
	if signf(unit.velocity.y) != -1.0:
		_fail("Runtime gun activation should not block vertical movement; velocity.y=%.4f." % unit.velocity.y)
	unit.tick(0.16, MainScene.RING_LENGTH)
	if signf(unit.mobius_v) != -1.0 or signf(unit.lane) != -1.0:
		_fail("Runtime gun activation should advance mobius_v/lane; mobius_v=%.4f lane=%.4f." % [unit.mobius_v, unit.lane])

	_release_actions()
	print("BATTLE_VERTICAL_INPUT_DURING_ACTIVATION_PROBE ok")
	quit()
