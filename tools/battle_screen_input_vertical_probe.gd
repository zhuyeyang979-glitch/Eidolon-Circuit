extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
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
			"health": 20,
			"mass": 12.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
			"move_speed": 4.0,
			"body_move_speed": 4.0,
			"move_acceleration": 20.0,
			"thruster_acceleration": 20.0,
		},
	})
	unit.deploy(3.0, 0.0)
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit
	var up := main._mobius_surface_input_for_unit(unit, Vector2.UP)
	var down := main._mobius_surface_input_for_unit(unit, Vector2.DOWN)
	if up.distance_to(Vector2.UP) > 0.001:
		_fail("Screen-up input should stay screen-up for battle movement, got %s." % str(up))
	if down.distance_to(Vector2.DOWN) > 0.001:
		_fail("Screen-down input should stay screen-down for battle movement, got %s." % str(down))
	unit.move_by(down, 0.2, MainScene.RING_LENGTH)
	unit.tick(0.2, MainScene.RING_LENGTH)
	main._update_camera_center()
	if unit.lane <= 0.01:
		_fail("Screen-down input should advance unit lane downward/positive.")
	if absf(main.camera_lane_center - unit.lane) > 0.001:
		_fail("Camera lane should follow controlled unit lane; camera %.3f unit %.3f." % [main.camera_lane_center, unit.lane])
	unit.deploy(3.0, MainScene.BATTLE_HALF_HEIGHT - 0.02)
	main.camera_lane_center = 0.0
	main.player_camera_lanes[1] = 0.0
	main._update_camera_center()
	var expected_limit := MainScene.BATTLE_HALF_HEIGHT - MainScene.VIEW_HEIGHT * 0.5
	if absf(main.camera_lane_center - expected_limit) > 0.001:
		_fail("Camera lane should clamp at view-center edge %.3f, got %.3f." % [expected_limit, main.camera_lane_center])
	print("BATTLE_SCREEN_INPUT_VERTICAL_PROBE ok lane=%.3f camera_lane=%.3f edge=%.3f" % [unit.lane, main.camera_lane_center, expected_limit])
	quit()
