extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var dummy = main._create_unit(2, "hero", {
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"brake_power": 30.0,
		"boost_duration": 0.2,
		"turn_speed": 2.0,
		"teamedit_runtime_topology": false,
	}, "Brake Dummy", 2.0, 0.0)
	main._assign_unit_role(dummy, "hero")
	dummy.velocity = Vector2(1.2, 0.0)
	dummy.angular_velocity = 1.0
	var start_ring: float = dummy.ring_pos
	for i in range(12):
		dummy.tick(0.1, MainScene.RING_LENGTH)
		main._apply_training_dummy_auto_brake(dummy, 0.1)
	if absf(main._ring_delta(start_ring, dummy.ring_pos)) <= 0.001:
		_fail("Training dummy should move from received impulse before braking.")
	if dummy.velocity.length() > 0.02:
		_fail("Training dummy auto brake should stop velocity, got %.3f" % dummy.velocity.length())
	if absf(dummy.angular_velocity) > 0.05:
		_fail("Training dummy auto brake should stop angular velocity, got %.3f" % dummy.angular_velocity)
	print("TRAINING_DUMMY_AUTO_BRAKE_PROBE ok moved=%.3f" % absf(main._ring_delta(start_ring, dummy.ring_pos)))
	quit()
