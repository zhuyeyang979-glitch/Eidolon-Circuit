extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_dummy(main):
	main._clear_all_units()
	main._show_training_config(true)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	return main.active_units[2]["hero"]


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	var dummy = _spawn_dummy(main)
	if not main._is_live_unit(dummy):
		_fail("Training ball dummy did not spawn.")
	main.training_dummy_state = "fixed"
	dummy.velocity = Vector2(1.0, 0.0)
	dummy.angular_velocity = 1.0
	main._update_training_dummy(0.1)
	if dummy.velocity.length() > 0.001 or absf(dummy.angular_velocity) > 0.001:
		_fail("Fixed dummy state should clear velocity.")
	main.training_dummy_state = "free_physics"
	dummy.velocity = Vector2(1.0, 0.0)
	main._update_training_dummy(0.1)
	if dummy.velocity.length() < 0.9:
		_fail("Free physics dummy state should not auto brake velocity.")
	main.training_dummy_state = "idle_brake"
	dummy.velocity = Vector2(1.0, 0.0)
	for i in range(24):
		main._update_training_dummy(0.1)
	if dummy.velocity.length() > 0.03:
		_fail("Idle brake dummy state should brake velocity, got %.3f" % dummy.velocity.length())
	print("TRAINING_BALL_DUMMY_STATE_MODES_PROBE ok")
	quit()
