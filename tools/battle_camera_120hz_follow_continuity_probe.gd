extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_main():
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_PVP
	main.ai_battle_seat = 0
	main.mobius_enabled = true
	main.camera_mobius_s = MainScene.RING_LENGTH - 0.25
	main.camera_center = fposmod(main.camera_mobius_s, MainScene.RING_LENGTH)
	main.camera_lane_center = 0.0
	main.player_camera_centers[1] = main.camera_mobius_s
	main.player_camera_lanes[1] = 0.0
	return main


func _make_unit(player_id: int, s: float, lane: float):
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({"owner_id": player_id, "role": "hero", "stats": {"health": 100.0, "mass": 12.0}})
	unit.deploy(fposmod(s, MainScene.RING_LENGTH), lane)
	unit.mobius_s = s
	unit.mobius_v = lane
	unit.ring_pos = fposmod(s, MainScene.RING_LENGTH)
	unit.lane = lane
	return unit


func _init() -> void:
	var main = _make_main()
	var hero = _make_unit(1, MainScene.RING_LENGTH + 1.0, 0.65)
	var enemy = _make_unit(2, MainScene.RING_LENGTH + 8.0, -0.35)
	main.active_units[1]["hero"] = hero
	main.active_units[2]["hero"] = enemy
	main.all_units = [hero, enemy]
	var previous_s: float = float(main.camera_mobius_s)
	var previous_lane: float = float(main.camera_lane_center)
	var max_s_step := 0.0
	var max_lane_step := 0.0
	for i in range(120):
		hero.mobius_s += 0.018
		hero.mobius_v = clampf(hero.mobius_v + 0.002, -MainScene.BATTLE_HALF_HEIGHT, MainScene.BATTLE_HALF_HEIGHT)
		hero.ring_pos = fposmod(hero.mobius_s, MainScene.RING_LENGTH)
		hero.lane = hero.mobius_v
		main._update_camera_center(MainScene.BATTLE_SIMULATION_DELTA)
		var s_step := absf(main.camera_mobius_s - previous_s)
		var lane_step := absf(main.camera_lane_center - previous_lane)
		max_s_step = maxf(max_s_step, s_step)
		max_lane_step = maxf(max_lane_step, lane_step)
		if main.camera_mobius_s + 0.001 < previous_s:
			_fail("Camera s should follow unwrapped Mobius coordinate without snapping backward at step %d." % i)
			return
		previous_s = main.camera_mobius_s
		previous_lane = main.camera_lane_center
	if max_s_step > 0.12:
		_fail("Camera follow step too coarse for 120Hz: %.4f." % max_s_step)
		return
	if max_lane_step > 0.08:
		_fail("Camera lane follow step too coarse for 120Hz: %.4f." % max_lane_step)
		return
	if absf(main.camera_mobius_s - MainScene.RING_LENGTH) < 0.01:
		_fail("Camera did not move toward the controlled unit.")
		return
	print("BATTLE_CAMERA_120HZ_FOLLOW_CONTINUITY_PROBE ok max_s=%.4f max_lane=%.4f" % [max_s_step, max_lane_step])
	quit(0)
