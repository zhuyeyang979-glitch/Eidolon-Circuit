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
	var hero = FighterScene.new()
	root.add_child(hero)
	hero.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "edge_camera_probe",
		"stats": {"health": 100, "mass": 12.0, "move_speed": 4.0, "teamedit_runtime_topology": false},
	})
	hero.deploy(9.0, MainScene.BATTLE_HALF_HEIGHT - 0.01)
	main.all_units = [hero]
	main.active_units[1]["hero"] = hero
	main.player_camera_centers[1] = 0.0
	main.player_camera_lanes[1] = 0.0
	main._update_camera_center()
	var expected_lane := MainScene.BATTLE_HALF_HEIGHT - MainScene.VIEW_HEIGHT * 0.5
	if absf(main.camera_lane_center - expected_lane) > 0.001:
		_fail("Camera y should clamp to %.3f near map edge, got %.3f." % [expected_lane, main.camera_lane_center])
		return
	if absf(main._ring_delta(main.camera_center, hero.ring_pos)) > 0.001:
		_fail("Camera x should still follow the controlled unit at the y edge.")
		return
	var projected := main._screen_from_ring(hero.ring_pos, hero.lane)
	var pos: Vector2 = projected.get("position", Vector2.ZERO)
	if absf(pos.x - (MainScene.ARENA_LEFT + MainScene.ARENA_RIGHT) * 0.5) > 0.75:
		_fail("Controlled unit should remain x-centered near the y edge.")
		return
	if absf(pos.y - (MainScene.ARENA_TOP + MainScene.ARENA_BOTTOM) * 0.5) < 24.0:
		_fail("Controlled unit should not stay y-centered when camera is clamped at the edge.")
		return
	print("BATTLE_CAMERA_Y_EDGE_CLAMP_PROBE ok camera_lane=%.3f unit_y=%.3f" % [main.camera_lane_center, pos.y])
	quit()
