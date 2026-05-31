extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const Fighter := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main.camera_center = 100.0
	main.camera_lane_center = 0.0
	main.player_camera_centers[1] = 100.0
	main.player_camera_lanes[1] = 0.0

	var hero := Fighter.new()
	root.add_child(hero)
	hero.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "camera_lag_probe",
		"stats": {
			"health": 100,
			"mass": 12.0,
			"speedometer_max_speed": 999.0,
			"runtime_visual_scale": 1.0,
			"teamedit_runtime_topology": false,
		},
	})
	hero.deploy(100.0, 0.0)
	hero.velocity = Vector2(12.0, 0.0)
	main.all_units = [hero]
	main.active_units[1]["hero"] = hero

	var delta := MainScene.BATTLE_FRAME_DELTA
	var old_camera: float = float(main.camera_center)
	main._update_units(delta, false)
	var moved_ring := hero.ring_pos
	main._update_camera_center()
	main._refresh_unit_screen_positions()

	var expected_center := Vector2(
		(MainScene.ARENA_LEFT + MainScene.ARENA_RIGHT) * 0.5,
		(MainScene.ARENA_TOP + MainScene.ARENA_BOTTOM) * 0.5
	)
	var center_error := hero.position.distance_to(expected_center)
	if center_error > 0.75:
		_fail("Moving controlled unit was projected with stale camera center; screen error %.3f px." % center_error)
	var lag_px := absf(main._ring_delta(old_camera, moved_ring) * main._battle_world_to_screen_scale())
	if lag_px < 1.0:
		_fail("Probe velocity did not create a measurable old-order camera lag.")
	if absf(main.camera_center - hero.ring_pos) > 0.001:
		_fail("Camera center did not update to the controlled unit after physics tick.")
	print("BATTLE_MOVEMENT_CAMERA_NO_LAG_PROBE ok old_order_lag_px=%.3f center_error=%.3f" % [lag_px, center_error])
	quit()
