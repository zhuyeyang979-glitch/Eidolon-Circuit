extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const Fighter := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expected_center() -> Vector2:
	return Vector2(
		(MainScene.ARENA_LEFT + MainScene.ARENA_RIGHT) * 0.5,
		(MainScene.ARENA_TOP + MainScene.ARENA_BOTTOM) * 0.5
	)


func _spawn_controlled_hero(main, player_id: int, ring: float, lane: float):
	var hero := Fighter.new()
	root.add_child(hero)
	hero.setup_unit({
		"owner_id": player_id,
		"role": "hero",
		"unit_name": "camera_center_probe",
		"stats": {
			"health": 100,
			"mass": 12.0,
			"runtime_visual_scale": 1.0,
			"teamedit_runtime_topology": false,
		},
	})
	hero.deploy(ring, lane)
	main.all_units.append(hero)
	main.active_units[player_id]["hero"] = hero
	return hero


func _assert_centered(seat: int, controlled_player_id: int) -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = seat
	main.camera_center = 0.0
	main.camera_lane_center = 0.0
	main.player_camera_centers[1] = 0.0
	main.player_camera_centers[2] = 0.0
	main.player_camera_lanes[1] = 0.0
	main.player_camera_lanes[2] = 0.0
	var hero = _spawn_controlled_hero(main, controlled_player_id, 8.5 + float(seat), 1.2)
	main._update_camera_center()
	main._refresh_unit_screen_positions()
	var screen_error: float = Vector2(hero.position).distance_to(_expected_center())
	var ring_error: float = absf(float(main._ring_delta(float(main.camera_center), float(hero.ring_pos))))
	var lane_error: float = absf(float(main.camera_lane_center) - float(hero.lane))
	if screen_error > 0.75:
		_fail("Seat %d controlled unit was not centered; screen_error=%.3f." % [seat, screen_error])
	if ring_error > 0.001:
		_fail("Seat %d camera ring did not lock to controlled unit; ring_error=%.5f." % [seat, ring_error])
	if lane_error > 0.001:
		_fail("Seat %d camera lane did not lock to controlled unit; lane_error=%.5f." % [seat, lane_error])
	main.queue_free()


func _init() -> void:
	_assert_centered(1, 1)
	_assert_centered(2, 2)
	print("BATTLE_CONTROLLED_UNIT_CENTER_ON_BEGIN_PROBE ok seats=2")
	quit()
