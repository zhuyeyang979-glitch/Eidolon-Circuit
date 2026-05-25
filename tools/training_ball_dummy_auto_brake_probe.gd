extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._set_training_ball_dummy_radius(0.6)
	main._show_training_config(true)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	var dummy = main.active_units[2]["hero"]
	if not main._is_live_unit(dummy):
		_fail("Training ball dummy did not spawn.")
	dummy.velocity = Vector2(2.0, 0.0)
	dummy.angular_velocity = 1.0
	var start_ring: float = dummy.ring_pos
	for i in range(24):
		dummy.tick(0.1, MainScene.RING_LENGTH)
		main._apply_training_dummy_auto_brake(dummy, 0.1)
	if absf(main._ring_delta(start_ring, dummy.ring_pos)) <= 0.001:
		_fail("Ball dummy should move from received impulse before braking.")
	if dummy.velocity.length() > 0.03:
		_fail("Ball dummy auto brake should stop velocity, got %.3f" % dummy.velocity.length())
	if absf(dummy.angular_velocity) > 0.05:
		_fail("Ball dummy auto brake should stop angular velocity, got %.3f" % dummy.angular_velocity)
	print("TRAINING_BALL_DUMMY_AUTO_BRAKE_PROBE ok moved=%.3f" % absf(main._ring_delta(start_ring, dummy.ring_pos)))
	quit()
