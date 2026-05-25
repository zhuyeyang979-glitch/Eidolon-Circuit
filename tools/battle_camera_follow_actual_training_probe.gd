extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	if Input.is_action_pressed("p1_down"):
		Input.action_release("p1_down")
	quit(1)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main.mobius_enabled = true
	main.camera_center = 3.0
	main.camera_lane_center = 0.0
	main._sync_camera_mobius_from_compat()
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 12.0,
			"move_speed": 5.0,
			"body_move_speed": 5.0,
			"move_acceleration": 35.0,
			"thruster_acceleration": 35.0,
			"movement_profile": "vector",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(3.0, 0.0)
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit
	Input.action_press("p1_down")
	for i in range(4):
		await process_frame
		main._handle_player_battle_input(1, 0.10, "p1")
		unit.tick(0.10, MainScene.RING_LENGTH)
		main._update_camera_center()
	Input.action_release("p1_down")
	if unit.lane <= 0.05:
		_fail("Controlled unit should move vertically in actual training input path.")
	var clamp_limit := MainScene.BATTLE_HALF_HEIGHT - MainScene.VIEW_HEIGHT * 0.5
	var expected_lane: float = clampf(unit.lane, -clamp_limit, clamp_limit)
	if absf(main.camera_lane_center - expected_lane) > 0.02:
		_fail("Camera lane should follow controlled unit within clamp, expected %.3f got %.3f." % [expected_lane, main.camera_lane_center])
	print("BATTLE_CAMERA_FOLLOW_ACTUAL_TRAINING_PROBE ok lane=%.3f camera=%.3f" % [unit.lane, main.camera_lane_center])
	quit()
