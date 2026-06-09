extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	_release_actions()
	failures.append(message)


func _release_actions() -> void:
	for action in ["p1_up", "p1_down", "p1_left", "p1_right"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _make_main():
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main.mobius_enabled = true
	main.camera_mobius_s = 3.0
	main.camera_center = 3.0
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {"twist_phase": 0.18, "twist_amplitude": 0.16, "pivot": Vector2(12.0, 0.0)}
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
			"move_acceleration": 30.0,
			"movement_profile": "vector",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	return unit


func _input_cases() -> Array:
	return [
		{"action": "p1_up", "raw": Vector2.UP},
		{"action": "p1_down", "raw": Vector2.DOWN},
		{"action": "p1_left", "raw": Vector2.LEFT},
		{"action": "p1_right", "raw": Vector2.RIGHT},
	]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = _make_main()
	var unit = _make_unit()
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit
	for test in _input_cases():
		unit.deploy(3.2, 0.45)
		unit.velocity = Vector2.ZERO
		_release_actions()
		Input.action_press(String(test["action"]))
		await process_frame
		var expected: Vector2 = main._battle_movement_vector_for_unit(unit, test["raw"]).get("actual", Vector2.ZERO)
		main._handle_player_battle_input(1, 0.12, "p1")
		var actual: Vector2 = unit.get_meta("actual_move_input_vector", Vector2.ZERO)
		if actual.distance_to(expected) > 0.015:
			_fail("%s actual vector mismatch expected=%s got=%s." % [String(test["action"]), str(expected), str(actual)])
		if unit.velocity.length() <= 0.001 or unit.velocity.normalized().distance_to(expected.normalized()) > 0.10:
			_fail("%s velocity did not follow actual battle vector; velocity=%s expected=%s." % [String(test["action"]), str(unit.velocity), str(expected)])
		_release_actions()
	if not failures.is_empty():
		print("BATTLE_REAL_TRAINING_MOVEMENT_SCREEN_DIRECTION_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BATTLE_REAL_TRAINING_MOVEMENT_SCREEN_DIRECTION_PROBE ok")
	quit(0)
