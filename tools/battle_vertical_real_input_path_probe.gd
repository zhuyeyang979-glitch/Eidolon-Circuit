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
	main.camera_center = 4.0
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
			"move_acceleration": 24.0,
			"thruster_acceleration": 24.0,
			"movement_profile": "vector",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(4.0, 0.0)
	return unit


func _install_unit(main, unit) -> void:
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = _make_main()
	var unit = _make_unit()
	_install_unit(main, unit)

	_release_actions()
	Input.action_press("p1_down")
	await process_frame
	main._handle_player_battle_input(1, 0.18, "p1")
	if unit.velocity.y <= 0.001:
		_fail("Real p1_down input path should create positive vertical velocity, got %.4f." % unit.velocity.y)
	unit.tick(0.18, MainScene.RING_LENGTH)
	if unit.mobius_v <= 0.001 or unit.lane <= 0.001:
		_fail("Real p1_down input path should advance mobius_v/lane downward.")

	_release_actions()
	unit.deploy(4.0, 0.0)
	unit.velocity = Vector2.ZERO
	Input.action_press("p1_up")
	await process_frame
	main._handle_player_battle_input(1, 0.18, "p1")
	if unit.velocity.y >= -0.001:
		_fail("Real p1_up input path should create negative vertical velocity, got %.4f." % unit.velocity.y)
	unit.tick(0.18, MainScene.RING_LENGTH)
	if unit.mobius_v >= -0.001 or unit.lane >= -0.001:
		_fail("Real p1_up input path should advance mobius_v/lane upward.")

	_release_actions()
	print("BATTLE_VERTICAL_REAL_INPUT_PATH_PROBE ok up=%.3f lane=%.3f" % [unit.velocity.y, unit.lane])
	quit()
