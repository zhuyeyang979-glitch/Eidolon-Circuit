extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var probe_failed := false


func _fail(message: String) -> void:
	push_error(message)
	probe_failed = true


func _expected_center() -> Vector2:
	return Vector2(
		(MainScene.ARENA_LEFT + MainScene.ARENA_RIGHT) * 0.5,
		(MainScene.ARENA_TOP + MainScene.ARENA_BOTTOM) * 0.5
	)


func _assert_controlled_unit_centered(main, label: String) -> void:
	var player_id := 2 if int(main.ai_battle_seat) == 2 else 1
	var hero = main.active_units[player_id]["hero"]
	if not main._is_live_unit(hero):
		_fail("%s did not spawn a controlled hero for P%d." % [label, player_id])
	var screen_error: float = Vector2(hero.position).distance_to(_expected_center())
	var ring_error: float = absf(float(main._ring_delta(float(main.camera_center), float(hero.ring_pos))))
	var lane_error: float = absf(float(main.camera_lane_center) - float(hero.lane))
	if screen_error > 0.75:
		_fail("%s controlled unit was not centered on the first battle frame; screen_error=%.3f ring_error=%.5f lane_error=%.5f." % [label, screen_error, ring_error, lane_error])
		return
	if ring_error > 0.001:
		_fail("%s camera ring did not lock to controlled unit on battle begin; ring_error=%.5f." % [label, ring_error])
		return
	if lane_error > 0.001:
		_fail("%s camera lane did not lock to controlled unit on battle begin; lane_error=%.5f." % [label, lane_error])
		return


func _begin_training_for_seat(seat: int):
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(seat)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Training seat %d did not enter battle state." % seat)
	return main


func _init() -> void:
	var p1_main = _begin_training_for_seat(1)
	_assert_controlled_unit_centered(p1_main, "P1 training")
	p1_main.queue_free()

	var p2_main = _begin_training_for_seat(2)
	_assert_controlled_unit_centered(p2_main, "P2 training")
	p2_main.queue_free()

	if probe_failed:
		quit(1)
		return
	print("BATTLE_CONTROLLED_UNIT_CENTER_ON_BEGIN_PROBE ok")
	quit()
